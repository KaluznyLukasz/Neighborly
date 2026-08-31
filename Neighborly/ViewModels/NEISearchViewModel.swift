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
            let fetched = try await offerService.fetchOffers(near: coordinate, radiusKm: NEIUserPreferences.searchRadiusKm)
            let blockedIds = (try? await blockService.fetchBlockedUserIds(userId: currentUserId)) ?? []
            offers = fetched.filter { !blockedIds.contains($0.ownerId) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
