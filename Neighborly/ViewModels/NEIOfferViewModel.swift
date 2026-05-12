//
//  NEIOfferViewModel.swift
//  Neighborly
//

import Foundation
import CoreLocation
import UIKit

@MainActor
@Observable
final class NEIOfferViewModel {
    var title = ""
    var description = ""
    var address = ""
    var category: OfferCategory = .tools
    var selectedImage: UIImage?

    var isLoading = false
    var errorMessage: String?
    var didSave = false

    private let offerService = NEIOfferService()
    private let storageService = NEIStorageService()
    private let geocoder = CLGeocoder()

    func createOffer(ownerId: String, fallbackCoordinate: CLLocationCoordinate2D) async {
        guard validate() else { return }
        isLoading = true
        errorMessage = nil

        // Geocode address — fall back to GPS if geocoding fails
        let coordinate: CLLocationCoordinate2D
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            if let location = placemarks.first?.location {
                coordinate = location.coordinate
            } else {
                errorMessage = "Address not found. Try a more specific address."
                isLoading = false
                return
            }
        } catch {
            errorMessage = "Could not find address: \(error.localizedDescription)"
            isLoading = false
            return
        }

        var offer = Offer(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            category: category,
            address: address.trimmingCharacters(in: .whitespaces).isEmpty ? nil : address.trimmingCharacters(in: .whitespaces),
            ownerId: ownerId,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            imageURLs: [],
            isActive: true,
            createdAt: Date()
        )

        do {
            let offerId = try await offerService.createOffer(offer)
            offer.id = offerId

            if let image = selectedImage {
                let url = try await storageService.uploadOfferImage(image, offerId: offerId)
                offer.imageURLs = [url]
                try await offerService.updateOffer(offer)
            }

            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func validate() -> Bool {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Enter a title."
            return false
        }
        if description.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Enter a description."
            return false
        }
        if address.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Enter an address."
            return false
        }
        return true
    }
}
