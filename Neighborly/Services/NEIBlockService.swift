//
//  NEIBlockService.swift
//  Neighborly
//

import Foundation
import FirebaseFirestore

struct NEIBlockedUser: Codable {
    var blockedUserId: String
    var blockedDisplayName: String
    var createdAt: Date
}

final class NEIBlockService {
    private let db = Firestore.firestore()

    private func blockedCollection(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("blocked")
    }

    func addBlock(userId: String, blockedUserId: String, blockedDisplayName: String) async throws {
        let block = NEIBlockedUser(blockedUserId: blockedUserId, blockedDisplayName: blockedDisplayName, createdAt: Date())
        // setData(from:) bez completion gubi błędy serwera/reguł — opakowujemy w continuation
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            do {
                try blockedCollection(userId: userId).document(blockedUserId)
                    .setData(from: block) { error in
                        if let error {
                            cont.resume(throwing: error)
                        } else {
                            cont.resume()
                        }
                    }
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    func removeBlock(userId: String, blockedUserId: String) async throws {
        try await blockedCollection(userId: userId).document(blockedUserId).delete()
    }

    func isBlocked(userId: String, blockedUserId: String) async throws -> Bool {
        let doc = try await blockedCollection(userId: userId).document(blockedUserId).getDocument()
        return doc.exists
    }

    func fetchBlockedUserIds(userId: String) async throws -> [String] {
        let snapshot = try await blockedCollection(userId: userId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: NEIBlockedUser.self) }.map { $0.blockedUserId }
    }

    func fetchBlockedUsers(userId: String) async throws -> [NEIUser] {
        let ids = try await fetchBlockedUserIds(userId: userId)
        var users: [NEIUser] = []
        for id in ids {
            let doc = try? await db.collection("users").document(id).getDocument()
            if let user = try? doc?.data(as: NEIUser.self) {
                users.append(user)
            }
        }
        return users
    }
}
