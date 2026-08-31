//
//  NEIFavoriteService.swift
//  Neighborly
//

import Foundation
import FirebaseFirestore

struct NEIFavorite: Codable {
    var offerId: String
    var createdAt: Date
}

final class NEIFavoriteService {
    private let db = Firestore.firestore()

    private func favoritesCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("favorites")
    }

    func addFavorite(userId: String, offerId: String) async throws {
        let favorite = NEIFavorite(offerId: offerId, createdAt: Date())
        // setData(from:) bez completion gubi błędy serwera/reguł — opakowujemy w continuation
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            do {
                try favoritesCollection(userId: userId).document(offerId)
                    .setData(from: favorite) { error in
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

    func removeFavorite(userId: String, offerId: String) async throws {
        try await favoritesCollection(userId: userId).document(offerId).delete()
    }

    func isFavorited(userId: String, offerId: String) async throws -> Bool {
        let doc = try await favoritesCollection(userId: userId).document(offerId).getDocument()
        return doc.exists
    }

    func fetchFavoriteOfferIds(userId: String) async throws -> [String] {
        let snapshot = try await favoritesCollection(userId: userId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: NEIFavorite.self) }.map { $0.offerId }
    }
}
