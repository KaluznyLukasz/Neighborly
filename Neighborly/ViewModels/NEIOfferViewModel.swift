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
    private let geocoder = CLGeocoder()

    func createOffer(ownerId: String, fallbackCoordinate: CLLocationCoordinate2D) async {
        guard validate() else { return }
        isLoading = true
        errorMessage = nil

        let coordinate: CLLocationCoordinate2D
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            if let location = placemarks.first?.location {
                coordinate = location.coordinate
            } else {
                errorMessage = "Address not found — try selecting a suggestion from the list."
                isLoading = false
                return
            }
        } catch {
            errorMessage = "Address not found — check spelling or pick a suggestion."
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
            imageBase64: compressedBase64(from: selectedImage),
            isActive: true,
            createdAt: Date()
        )

        do {
            _ = try await offerService.createOffer(offer)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func compressedBase64(from image: UIImage?) -> String? {
        guard let image else { return nil }
        let maxDimension: CGFloat = 600
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.5)?.base64EncodedString()
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
