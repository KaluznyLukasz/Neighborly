//
//  NEIMapViewModel.swift
//  Neighborly
//

import Foundation
import CoreLocation
import MapKit

@MainActor
@Observable
final class NEIMapViewModel {
    var offers: [Offer] = []
    var isLoading = false
    var errorMessage: String?

    private let offerService = NEIOfferService()
    private let blockService = NEIBlockService()

    func loadOffers(near coordinate: CLLocationCoordinate2D, currentUserId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await offerService.fetchOffers(near: coordinate, radiusKm: NEIUserPreferences.searchRadiusKm)
            let blockedIds = (try? await blockService.fetchBlockedUserIds(userId: currentUserId)) ?? []
            offers = fetched.filter { !blockedIds.contains($0.ownerId) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteOffer(id: String) async {
        do {
            try await offerService.deleteOffer(id: id)
            offers.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
