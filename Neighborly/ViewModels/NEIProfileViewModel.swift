//
//  NEIProfileViewModel.swift
//  Neighborly
//

import Foundation
import FirebaseFirestore
import UIKit

@MainActor
@Observable
final class NEIProfileViewModel {
    var user: NEIUser?
    var offers: [Offer] = []
    var reviews: [Review] = []
    var isLoading = false
    var isSaving = false
    var errorMessage: String?

    private let db = Firestore.firestore()
    private let offerService = NEIOfferService()
    private let reviewService = NEIReviewService()
    private let storageService = NEIStorageService()

    func load(userId: String) async {
        isLoading = true
        errorMessage = nil
        async let userResult: NEIUser? = fetchUser(userId)
        async let offersResult: [Offer] = (try? offerService.fetchOffersByOwner(ownerId: userId)) ?? []
        async let reviewsResult: [Review] = (try? reviewService.fetchReviews(for: userId)) ?? []
        user = await userResult
        offers = await offersResult
        reviews = await reviewsResult
        isLoading = false
    }

    func updateProfile(displayName: String, bio: String) async {
        guard let uid = user?.id else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await db.collection("users").document(uid).updateData([
                "displayName": displayName,
                "bio": bio
            ])
            user?.displayName = displayName
            user?.bio = bio
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func uploadAvatar(image: UIImage, userId: String) async {
        isSaving = true
        errorMessage = nil
        do {
            let url = try await storageService.uploadAvatarImage(image, userId: userId)
            try await db.collection("users").document(userId).updateData(["avatarURL": url])
            user?.avatarURL = url
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func fetchUser(_ userId: String) async -> NEIUser? {
        let doc = try? await db.collection("users").document(userId).getDocument()
        return try? doc?.data(as: NEIUser.self)
    }
}
