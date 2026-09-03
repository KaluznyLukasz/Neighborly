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

    // Bounding-box geo query — single-field index only, isActive filtered client-side
    func fetchOffers(near coordinate: CLLocationCoordinate2D, radiusKm: Double = 5.0) async throws -> [Offer] {
        let delta = radiusKm / 111.0 // 1° lat ≈ 111 km
        let minLat = coordinate.latitude - delta
        let maxLat = coordinate.latitude + delta

        let snapshot = try await db.collection(collection)
            .whereField("latitude", isGreaterThan: minLat)
            .whereField("latitude", isLessThan: maxLat)
            .order(by: "latitude")
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: Offer.self) }
            .filter { $0.isActive }
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
        try await fetchOffersByOwner(ownerId: ownerId).filter { $0.isActive }.count
    }

    func setOfferActive(id: String, isActive: Bool) async throws {
        try await db.collection(collection).document(id).updateData(["isActive": isActive])
    }

    func fetchOffersByOwner(ownerId: String) async throws -> [Offer] {
        let snapshot = try await db.collection(collection)
            .whereField("ownerId", isEqualTo: ownerId)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: Offer.self) }
            .sorted { $0.createdAt > $1.createdAt }
    }
}
