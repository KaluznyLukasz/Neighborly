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
        // Batch: write review + update user rating atomically
        let batch = db.batch()

        let reviewRef = db.collection(collection).document()
        try batch.setData(from: review, forDocument: reviewRef)

        // Increment reviewCount and recalculate rating on the reviewee's doc
        let userRef = db.collection("users").document(review.revieweeId)
        batch.updateData([
            "reviewCount": FieldValue.increment(Int64(1))
        ], forDocument: userRef)

        try await batch.commit()

        // Recalculate average rating separately (batch can't read + write atomically without transaction)
        try await recalculateRating(for: review.revieweeId)
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

    private func recalculateRating(for userId: String) async throws {
        let snapshot = try await db.collection(collection)
            .whereField("revieweeId", isEqualTo: userId)
            .getDocuments()
        let ratings = snapshot.documents.compactMap { try? $0.data(as: Review.self) }.map { Double($0.rating) }
        guard !ratings.isEmpty else { return }
        let avg = ratings.reduce(0, +) / Double(ratings.count)
        try await db.collection("users").document(userId).updateData(["rating": avg])
    }
}
