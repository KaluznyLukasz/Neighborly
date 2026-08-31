//
//  NEIBlockViewModel.swift
//  Neighborly
//

import Foundation

@MainActor
@Observable
final class NEIBlockViewModel {
    var blockedUserIds: Set<String> = []
    var blockedUsers: [NEIUser] = []
    var isLoading = false
    var errorMessage: String?

    private let blockService = NEIBlockService()

    func isBlocked(_ userId: String) -> Bool {
        blockedUserIds.contains(userId)
    }

    func checkBlocked(userId: String, currentUserId: String) async {
        do {
            let blocked = try await blockService.isBlocked(userId: currentUserId, blockedUserId: userId)
            if blocked {
                blockedUserIds.insert(userId)
            } else {
                blockedUserIds.remove(userId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleBlock(blockedUserId: String, blockedDisplayName: String, currentUserId: String) async {
        let wasBlocked = blockedUserIds.contains(blockedUserId)

        // Optimistic update
        if wasBlocked {
            blockedUserIds.remove(blockedUserId)
        } else {
            blockedUserIds.insert(blockedUserId)
        }

        do {
            if wasBlocked {
                try await blockService.removeBlock(userId: currentUserId, blockedUserId: blockedUserId)
                blockedUsers.removeAll { $0.id == blockedUserId }
            } else {
                try await blockService.addBlock(userId: currentUserId, blockedUserId: blockedUserId, blockedDisplayName: blockedDisplayName)
            }
        } catch {
            // Roll back on failure
            if wasBlocked {
                blockedUserIds.insert(blockedUserId)
            } else {
                blockedUserIds.remove(blockedUserId)
            }
            errorMessage = error.localizedDescription
        }
    }

    func loadBlockedUsers(currentUserId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let users = try await blockService.fetchBlockedUsers(userId: currentUserId)
            blockedUsers = users
            blockedUserIds = Set(users.compactMap { $0.id })
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
