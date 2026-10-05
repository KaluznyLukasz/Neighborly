//
//  NEIAccountDeletionService.swift
//  Neighborly
//

import Foundation
import FirebaseFirestore

// Kasuje dane konta z Firestore przed usunięciem konta w Firebase Auth (wytyczna App Store
// 5.1.1(v), RODO art. 17). Nie ma backendu, więc kaskadę robi klient, a reguły pozwalają
// właścicielowi kasować jego dane (firestore.rules). Każdy krok można powtórzyć: po błędzie
// konto zostaje, a następna próba dokończy resztę.
//
// Zostają: zgłoszenia (`reports`, potrzebne moderacji, nie da się ich czytać z aplikacji)
// i recenzje innych osób o tym użytkowniku (bez profilu nie są nigdzie widoczne).
final class NEIAccountDeletionService {
    private let db = Firestore.firestore()
    // Limit batcha to 500 zapisów — zostawiamy zapas
    private let batchLimit = 450

    func deleteAllData(userId: String) async throws {
        // Pusta ścieżka w document("") wywala aplikację (docs/learnings/firestore-empty-document-path-crashes.md)
        guard !userId.isEmpty else { return }
        try await deleteOffers(ownerId: userId)
        try await deleteAlerts(authorId: userId)
        try await deleteTransactions(userId: userId)
        try await deleteRemainingMessages(senderId: userId)
        try await deleteReviews(reviewerId: userId)
        let profile = db.collection("users").document(userId)
        try await deleteCollection(profile.collection("favorites"))
        try await deleteCollection(profile.collection("blocked"))
    }

    // MARK: - Kroki

    private func deleteOffers(ownerId: String) async throws {
        let snapshot = try await db.collection("offers").whereField("ownerId", isEqualTo: ownerId).getDocuments()
        try await deleteAll(snapshot.documents.map(\.reference))
    }

    // Ogłoszenie razem z wątkami i wiadomościami — podkolekcje nie znikają z dokumentem
    private func deleteAlerts(authorId: String) async throws {
        let snapshot = try await db.collection("alerts").whereField("authorId", isEqualTo: authorId).getDocuments()
        for alert in snapshot.documents {
            let threads = try await alert.reference.collection("threads").getDocuments()
            for thread in threads.documents {
                try await deleteThread(thread.reference)
            }
            try await alert.reference.delete()
        }
    }

    // Transakcje obu ról. Reguły kasują tylko zakończone, więc aktywne najpierw anulujemy.
    private func deleteTransactions(userId: String) async throws {
        let transactions = db.collection("transactions")
        let owned = try await transactions.whereField("ownerId", isEqualTo: userId).getDocuments()
        let requested = try await transactions.whereField("requesterId", isEqualTo: userId).getDocuments()
        let documents = owned.documents + requested.documents
        let deletable: Set<String> = [
            TransactionStatus.rejected.rawValue,
            TransactionStatus.cancelled.rawValue,
            TransactionStatus.completed.rawValue
        ]

        for document in documents {
            let status = document.get("status") as? String ?? ""
            if !deletable.contains(status) {
                try await document.reference.updateData([
                    "status": TransactionStatus.cancelled.rawValue,
                    "updatedAt": Timestamp(date: Date())
                ])
            }
            try await deleteCollection(document.reference.collection("messages"))
            try await document.reference.delete()
        }
    }

    // Wiadomości w wątkach przy cudzych ogłoszeniach (i resztki po wcześniejszych krokach).
    // Wątek, w którym użytkownik pisał jako sąsiad (ID wątku = jego uid), znika cały.
    // Zapytanie po grupie kolekcji wymaga wyjątku indeksu w firestore.indexes.json.
    private func deleteRemainingMessages(senderId: String) async throws {
        let snapshot = try await db.collectionGroup("messages").whereField("senderId", isEqualTo: senderId).getDocuments()
        var threads: [String: DocumentReference] = [:]
        var messages: [DocumentReference] = []
        for document in snapshot.documents {
            if let thread = document.reference.parent.parent,
               thread.parent.collectionID == "threads",
               thread.documentID == senderId {
                threads[thread.path] = thread
            } else {
                messages.append(document.reference)
            }
        }
        try await deleteAll(messages)
        for thread in threads.values {
            try await deleteThread(thread)
        }
    }

    // Recenzje wystawione przez użytkownika. Średnią ocenianego cofamy tak, jak liczy ją
    // NEIReviewService — przyrostowo, w transakcji.
    private func deleteReviews(reviewerId: String) async throws {
        let snapshot = try await db.collection("reviews").whereField("reviewerId", isEqualTo: reviewerId).getDocuments()
        for review in snapshot.documents {
            let rating = review.get("rating") as? Int ?? 0
            let revieweeId = review.get("revieweeId") as? String ?? ""
            try await deleteReview(review.reference, rating: rating, revieweeId: revieweeId)
        }
    }

    private func deleteReview(_ reviewRef: DocumentReference, rating: Int, revieweeId: String) async throws {
        guard !revieweeId.isEmpty else {
            try await reviewRef.delete()
            return
        }
        let userRef = db.collection("users").document(revieweeId)
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            db.runTransaction({ transaction, errorPointer in
                let userSnapshot: DocumentSnapshot
                do {
                    userSnapshot = try transaction.getDocument(userRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                // Konto ocenianego mogło już zniknąć — wtedy samo usunięcie recenzji
                if userSnapshot.exists {
                    let currentRating = userSnapshot.get("rating") as? Double ?? 0
                    let currentCount = userSnapshot.get("reviewCount") as? Int ?? 0
                    let newCount = max(currentCount - 1, 0)
                    let newRating = newCount > 0
                        ? (currentRating * Double(currentCount) - Double(rating)) / Double(newCount)
                        : 0
                    transaction.updateData([
                        "reviewCount": newCount,
                        "rating": min(max(newRating, 0), 5)
                    ], forDocument: userRef)
                }
                transaction.deleteDocument(reviewRef)
                return nil
            }) { _, error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume()
                }
            }
        }
    }

    // MARK: - Pomocnicze

    private func deleteThread(_ thread: DocumentReference) async throws {
        try await deleteCollection(thread.collection("messages"))
        try await thread.delete()
    }

    private func deleteCollection(_ collection: CollectionReference) async throws {
        let snapshot = try await collection.getDocuments()
        try await deleteAll(snapshot.documents.map(\.reference))
    }

    private func deleteAll(_ refs: [DocumentReference]) async throws {
        for start in stride(from: 0, to: refs.count, by: batchLimit) {
            let batch = db.batch()
            for ref in refs[start..<min(start + batchLimit, refs.count)] {
                batch.deleteDocument(ref)
            }
            try await batch.commit()
        }
    }
}
