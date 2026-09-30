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
            async let fetched = offerService.fetchOffers(near: coordinate, radiusKm: NEIUserPreferences.searchRadiusKm)
            async let blockedIds = (try? await blockService.fetchBlockedUserIds(userId: currentUserId)) ?? []
            let (result, blocked) = try await (fetched, blockedIds)
            offers = result.filter { !blocked.contains($0.ownerId) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // Lista zawiera tylko aktywne oferty (patrz fetchOffers) — po dezaktywacji usuwamy
    // pinezkę lokalnie zamiast pełnego przeładowania; reaktywacja i tak wymaga
    // odświeżenia z serwera, więc tam zostawiamy pełny reload
    func setOfferActive(id: String, isActive: Bool) {
        guard !isActive else { return }
        offers.removeAll { $0.id == id }
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
