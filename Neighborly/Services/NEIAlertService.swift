//
//  NEIAlertService.swift
//  Neighborly
//

import Foundation
import CoreLocation
import FirebaseFirestore

final class NEIAlertService {
    private let db = Firestore.firestore()
    private let collection = "alerts"

    // Nasłuch na żywo: nowe ogłoszenia pojawiają się od razu, bez ponownego otwierania listy.
    // Jeden zakres na expiresAt — bez indeksu złożonego; odległość filtruje ViewModel po stronie klienta,
    // bo aktywnych (niewygasłych) ogłoszeń jest z natury niewiele
    func listenActive(
        onChange: @escaping @Sendable ([NeighborhoodAlert]) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) -> ListenerRegistration {
        db.collection(collection)
            .whereField("expiresAt", isGreaterThan: Timestamp(date: Date()))
            .addSnapshotListener { snapshot, error in
                if let error {
                    onError(error)
                    return
                }
                guard let snapshot else { return }
                // Nie gubimy po cichu dokumentów, których nie da się zdekodować
                let alerts = snapshot.documents.compactMap { doc -> NeighborhoodAlert? in
                    do {
                        return try doc.data(as: NeighborhoodAlert.self)
                    } catch {
                        NSLog("Alert \(doc.documentID) decode failed: \(error)")
                        return nil
                    }
                }
                onChange(alerts)
            }
    }

    func create(_ alert: NeighborhoodAlert) async throws {
        // setData(from:) bez completion gubi błędy reguł — opakowujemy w continuation
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            do {
                try db.collection(collection).document().setData(from: alert) { error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume()
                    }
                }
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    // Razem z wątkami i wiadomościami — podkolekcje nie znikają z dokumentem, a bez ogłoszenia
    // nikt by ich już nie przeczytał ani nie usunął (reguły sprawdzają autora ogłoszenia)
    func delete(id: String) async throws {
        guard !id.isEmpty else { return }
        let alert = db.collection(collection).document(id)
        for thread in try await alert.collection("threads").getDocuments().documents {
            let messages = try await thread.reference.collection("messages").getDocuments()
            let batch = db.batch()
            messages.documents.forEach { batch.deleteDocument($0.reference) }
            batch.deleteDocument(thread.reference)
            try await batch.commit()
        }
        try await alert.delete()
    }

    private func threads(alertId: String) -> CollectionReference {
        db.collection(collection).document(alertId).collection("threads")
    }

    func upsertThread(alertId: String, viewerId: String, viewerName: String, lastMessage: String, senderId: String) async throws {
        let thread = AlertThread(viewerName: viewerName, lastMessage: lastMessage, updatedAt: Date(), lastSenderId: senderId)
        let data = try Firestore.Encoder().encode(thread)
        try await threads(alertId: alertId).document(viewerId).setData(data, merge: true)
    }

    func fetchThreads(alertId: String) async throws -> [AlertThread] {
        let snapshot = try await threads(alertId: alertId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AlertThread.self) }
    }

    // MARK: - Do powiadomień

    // Puste ID wywróciłoby Firestore (niepoprawna ścieżka dokumentu)
    func fetch(id: String) async throws -> NeighborhoodAlert? {
        guard !id.isEmpty else { return nil }
        return try? await db.collection(collection).document(id).getDocument().data(as: NeighborhoodAlert.self)
    }

    // Jednorazowo (odświeżanie w tle) — to samo zapytanie co listenActive
    func fetchActive() async throws -> [NeighborhoodAlert] {
        let snapshot = try await db.collection(collection)
            .whereField("expiresAt", isGreaterThan: Timestamp(date: Date()))
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: NeighborhoodAlert.self) }
    }

    // Wątek sąsiada przy cudzym ogłoszeniu (ID wątku = ID sąsiada)
    func fetchThread(alertId: String, viewerId: String) async throws -> AlertThread? {
        guard !alertId.isEmpty, !viewerId.isEmpty else { return nil }
        return try? await threads(alertId: alertId).document(viewerId).getDocument().data(as: AlertThread.self)
    }

    // Moje ogłoszenia — jedna równość, bez indeksu złożonego; wygasłe odfiltrowuje wywołujący
    func listenMine(authorId: String, onChange: @escaping @Sendable ([NeighborhoodAlert]) -> Void) -> ListenerRegistration {
        db.collection(collection)
            .whereField("authorId", isEqualTo: authorId)
            .addSnapshotListener { snapshot, _ in
                guard let snapshot else { return }
                onChange(snapshot.documents.compactMap { try? $0.data(as: NeighborhoodAlert.self) })
            }
    }

    func listenThreads(alertId: String, onChange: @escaping @Sendable ([AlertThread]) -> Void) -> ListenerRegistration {
        threads(alertId: alertId).addSnapshotListener { snapshot, _ in
            guard let snapshot else { return }
            onChange(snapshot.documents.compactMap { try? $0.data(as: AlertThread.self) })
        }
    }

    func listenThread(alertId: String, viewerId: String, onChange: @escaping @Sendable (AlertThread?) -> Void) -> ListenerRegistration {
        threads(alertId: alertId).document(viewerId).addSnapshotListener { snapshot, _ in
            guard let snapshot else { return }
            onChange(try? snapshot.data(as: AlertThread.self))
        }
    }
}
