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
    var selectedCategory: OfferCategory? = nil

    private let offerService = NEIOfferService()

    var filteredOffers: [Offer] {
        offers.filter { offer in
            let matchesSearch = searchText.isEmpty ||
                offer.title.localizedCaseInsensitiveContains(searchText) ||
                offer.description.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || offer.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    func loadOffers(near coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        errorMessage = nil
        do {
            offers = try await offerService.fetchOffers(near: coordinate, radiusKm: 50.0)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
