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
    var selectedOffer: Offer?

    private let offerService = NEIOfferService()

    func loadOffers(near coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        errorMessage = nil
        do {
            offers = try await offerService.fetchOffers(near: coordinate)
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
