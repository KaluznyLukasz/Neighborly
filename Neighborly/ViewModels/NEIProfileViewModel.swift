//
//  NEIProfileViewModel.swift
//  Neighborly
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
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

    func load(userId: String) async {
        // Po wylogowaniu widok dostaje jeszcze `uid == ""`, a `document("")` rzuca wyjątek
        // Obj-C, którego `try?` nie łapie — aplikacja leci (SIGABRT).
        guard !userId.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        async let userResult: NEIUser? = fetchUser(userId)
        async let offersResult: [Offer] = (try? offerService.fetchOffersByOwner(ownerId: userId)) ?? []
        async let reviewsResult: [Review] = fetchReviews(userId)
        user = await userResult
        offers = await offersResult
        reviews = await reviewsResult
        isLoading = false
    }

    func deleteOffer(_ offer: Offer) async {
        guard let id = offer.id else { return }
        do {
            try await offerService.deleteOffer(id: id)
            offers.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Zapisuje imię i bio. E-mail zmienia się osobno przez `NEIAuthService.changeEmail`,
    /// bo żyje tylko w Firebase Auth (dokument profilu czyta każdy zalogowany).
    func updateProfile(userId: String, displayName: String, bio: String) async {
        guard !NEIContentFilter.isObjectionable(displayName, bio) else {
            errorMessage = NEIContentFilter.rejectionMessage
            return
        }
        isSaving = true
        errorMessage = nil
        do {
            try await db.collection("users").document(userId).setData([
                "displayName": displayName,
                "bio": bio
            ], merge: true)

            user?.displayName = displayName
            user?.bio = bio

            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = displayName
            try? await changeRequest?.commitChanges()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func uploadAvatar(image: UIImage, userId: String) async {
        isSaving = true
        errorMessage = nil
        let maxDimension: CGFloat = 400
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        guard let base64 = resized.jpegData(compressionQuality: 0.6)?.base64EncodedString() else {
            isSaving = false
            return
        }
        do {
            try await db.collection("users").document(userId).setData(["avatarBase64": base64], merge: true)
            user?.avatarBase64 = base64
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func fetchUser(_ userId: String) async -> NEIUser? {
        let doc = try? await db.collection("users").document(userId).getDocument()
        return try? doc?.data(as: NEIUser.self)
    }

    private func fetchReviews(_ userId: String) async -> [Review] {
        do {
            return try await reviewService.fetchReviews(for: userId)
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }
}
