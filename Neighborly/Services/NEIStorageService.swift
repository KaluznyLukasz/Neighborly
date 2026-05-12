//
//  NEIStorageService.swift
//  Neighborly
//

import Foundation
import FirebaseStorage
import UIKit

final class NEIStorageService {
    private let storage = Storage.storage()

    func uploadOfferImage(_ image: UIImage, offerId: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.invalidImage
        }
        let path = "offers/\(offerId)/\(UUID().uuidString).jpg"
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    func uploadAvatarImage(_ image: UIImage, userId: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }
        let path = "avatars/\(userId).jpg"
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    enum StorageError: LocalizedError {
        case invalidImage
        var errorDescription: String? { "Could not process image." }
    }
}
