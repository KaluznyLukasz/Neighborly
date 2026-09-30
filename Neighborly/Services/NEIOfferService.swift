//
//  NEIOfferService.swift
//  Neighborly
//

import Foundation
import Combine
import FirebaseFirestore
import CoreLocation

final class NEIOfferService {
    private let db = Firestore.firestore()
    private let collection = "offers"

    // Bounding-box geo query — single-field index only, isActive filtered server-side
    func fetchOffers(near coordinate: CLLocationCoordinate2D, radiusKm: Double = 5.0) async throws -> [Offer] {
        // radiusKm.isInfinite oznacza brak limitu — pomijamy filtr zakresu, bo Firestore nie obsługuje zapytań bez ograniczenia
        guard !radiusKm.isInfinite else {
            let snapshot = try await db.collection(collection)
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: Offer.self) }
        }

        let delta = radiusKm / 111.0 // 1° lat ≈ 111 km
        let minLat = coordinate.latitude - delta
        let maxLat = coordinate.latitude + delta

        let snapshot = try await db.collection(collection)
            .whereField("isActive", isEqualTo: true)
            .whereField("latitude", isGreaterThan: minLat)
            .whereField("latitude", isLessThan: maxLat)
            .order(by: "latitude")
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Offer.self) }
    }

    // Pobiera oferty po ID w jednym/kilku zapytaniach zamiast N osobnych round-tripów
    func fetchOffers(ids: [String]) async throws -> [Offer] {
        guard !ids.isEmpty else { return [] }
        let chunks = stride(from: 0, to: ids.count, by: 30).map {
            Array(ids[$0..<min($0 + 30, ids.count)])
        }
        return try await withThrowingTaskGroup(of: [Offer].self) { group in
            for chunk in chunks {
                group.addTask {
                    let snapshot = try await self.db.collection(self.collection)
                        .whereField(FieldPath.documentID(), in: chunk)
                        .getDocuments()
                    return snapshot.documents.compactMap { try? $0.data(as: Offer.self) }
                }
            }
            var results: [Offer] = []
            for try await chunkResult in group {
                results.append(contentsOf: chunkResult)
            }
            return results
        }
    }

    func createOffer(_ offer: Offer) async throws -> String {
        let ref = try db.collection(collection).addDocument(from: offer)
        return ref.documentID
    }

    func updateOffer(_ offer: Offer) async throws {
        guard let id = offer.id else { return }
        try db.collection(collection).document(id).setData(from: offer, merge: true)
    }

    func deleteOffer(id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }

    func fetchOffer(id: String) async throws -> Offer? {
        let doc = try await db.collection(collection).document(id).getDocument()
        return try? doc.data(as: Offer.self)
    }

    func countActiveOffers(ownerId: String) async throws -> Int {
        let snapshot = try await db.collection(collection)
            .whereField("ownerId", isEqualTo: ownerId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        return snapshot.documents.count
    }

    func setOfferActive(id: String, isActive: Bool) async throws {
        try await db.collection(collection).document(id).updateData(["isActive": isActive])
    }

    func fetchOffersByOwner(ownerId: String) async throws -> [Offer] {
        let snapshot = try await db.collection(collection)
            .whereField("ownerId", isEqualTo: ownerId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Offer.self) }
    }
}
