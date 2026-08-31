//
//  NEIFavoriteViewModel.swift
//  Neighborly
//

import Foundation

@MainActor
@Observable
final class NEIFavoriteViewModel {
    var favoriteOfferIds: Set<String> = []
    var savedOffers: [Offer] = []
    var isLoading = false
    var errorMessage: String?

    private let favoriteService = NEIFavoriteService()
    private let offerService = NEIOfferService()

    func isFavorited(_ offerId: String) -> Bool {
        favoriteOfferIds.contains(offerId)
    }

    func checkFavorited(offerId: String, userId: String) async {
        do {
            let favorited = try await favoriteService.isFavorited(userId: userId, offerId: offerId)
            if favorited {
                favoriteOfferIds.insert(offerId)
            } else {
                favoriteOfferIds.remove(offerId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite(offerId: String, userId: String) async {
        let wasFavorited = favoriteOfferIds.contains(offerId)

        // Optimistic update
        if wasFavorited {
            favoriteOfferIds.remove(offerId)
        } else {
            favoriteOfferIds.insert(offerId)
        }

        do {
            if wasFavorited {
                try await favoriteService.removeFavorite(userId: userId, offerId: offerId)
            } else {
                try await favoriteService.addFavorite(userId: userId, offerId: offerId)
            }
        } catch {
            // Roll back on failure
            if wasFavorited {
                favoriteOfferIds.insert(offerId)
            } else {
                favoriteOfferIds.remove(offerId)
            }
            errorMessage = error.localizedDescription
        }
    }

    func removeSaved(offerId: String, userId: String) async {
        let previous = savedOffers
        savedOffers.removeAll { $0.id == offerId }
        favoriteOfferIds.remove(offerId)
        do {
            try await favoriteService.removeFavorite(userId: userId, offerId: offerId)
        } catch {
            savedOffers = previous
            favoriteOfferIds.insert(offerId)
            errorMessage = error.localizedDescription
        }
    }

    func loadSavedOffers(userId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let ids = try await favoriteService.fetchFavoriteOfferIds(userId: userId)
            favoriteOfferIds = Set(ids)
            var offers: [Offer] = []
            for id in ids {
                if let offer = try? await offerService.fetchOffer(id: id) {
                    offers.append(offer)
                }
            }
            savedOffers = offers
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
