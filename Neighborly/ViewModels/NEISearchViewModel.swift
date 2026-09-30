//
//  NEISearchViewModel.swift
//  Neighborly
//

import Foundation
import CoreLocation

@MainActor
@Observable
final class NEISearchViewModel {
    var offers: [Offer] = []
    var isLoading = false
    var errorMessage: String?
    var searchText: String = ""

    private let offerService = NEIOfferService()
    private let blockService = NEIBlockService()

    // Lista zawiera tylko aktywne oferty (patrz fetchOffers) — po dezaktywacji usuwamy
    // ofertę lokalnie zamiast pełnego przeładowania
    func setOfferActive(id: String, isActive: Bool) {
        guard !isActive else { return }
        offers.removeAll { $0.id == id }
    }

    var filteredOffers: [Offer] {
        guard !searchText.isEmpty else { return [] }
        return offers.filter { offer in
            offer.title.localizedCaseInsensitiveContains(searchText) ||
                offer.description.localizedCaseInsensitiveContains(searchText)
        }
    }

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
}
