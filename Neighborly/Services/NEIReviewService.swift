//
//  NEIReviewService.swift
//  Neighborly
//

import Foundation
import Combine
import FirebaseFirestore

final class NEIReviewService {
    private let db = Firestore.firestore()
    private let collection = "reviews"

    func submitReview(_ review: Review) async throws {
        let reviewRef = db.collection(collection).document()
        let userRef = db.collection("users").document(review.revieweeId)

        // Transakcja zamiast doczytywania wszystkich recenzji — średnią liczymy przyrostowo
        // z aktualnego rating/reviewCount, więc koszt jest stały niezależnie od liczby recenzji
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            db.runTransaction({ transaction, errorPointer in
                let userSnapshot: DocumentSnapshot
                do {
                    userSnapshot = try transaction.getDocument(userRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                let currentRating = userSnapshot.get("rating") as? Double ?? 0
                let currentCount = userSnapshot.get("reviewCount") as? Int ?? 0
                let newCount = currentCount + 1
                let newRating = (currentRating * Double(currentCount) + Double(review.rating)) / Double(newCount)

                do {
                    try transaction.setData(from: review, forDocument: reviewRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
                transaction.updateData([
                    "reviewCount": newCount,
                    "rating": newRating
                ], forDocument: userRef)
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

    func fetchReviews(for userId: String) async throws -> [Review] {
        let snapshot = try await db.collection(collection)
            .whereField("revieweeId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Review.self) }
    }

    func hasReviewed(transactionId: String, reviewerId: String) async throws -> Bool {
        let snapshot = try await db.collection(collection)
            .whereField("transactionId", isEqualTo: transactionId)
            .whereField("reviewerId", isEqualTo: reviewerId)
            .getDocuments()
        return !snapshot.isEmpty
    }
}
