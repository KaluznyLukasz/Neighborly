//
//  NEITrustBadge.swift
//  Neighborly
//

import Foundation
import SwiftUI

// Odznaki liczone z danych, które i tak są publiczne (recenzje, data dołączenia, liczba ogłoszeń) —
// nic nowego nie zapisujemy, więc nie da się ich podrobić w Firestore.
enum NEITrustBadge: String, CaseIterable, Identifiable {
    case topRated
    case trustedNeighbor
    case activeHelper
    case longTimeMember
    case newNeighbor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .topRated:        return "Top Rated"
        case .trustedNeighbor: return "Trusted Neighbor"
        case .activeHelper:    return "Active Helper"
        case .longTimeMember:  return "Long-time Member"
        case .newNeighbor:     return "New Neighbor"
        }
    }

    var detail: String {
        switch self {
        case .topRated:        return "4.5+ stars across 5 or more reviews"
        case .trustedNeighbor: return "10 or more reviews from neighbors"
        case .activeHelper:    return "3 or more posts shared"
        case .longTimeMember:  return "Neighbor for over a year"
        case .newNeighbor:     return "Joined in the last 30 days"
        }
    }

    var systemImage: String {
        switch self {
        case .topRated:        return "star.fill"
        case .trustedNeighbor: return "checkmark.seal.fill"
        case .activeHelper:    return "hands.sparkles.fill"
        case .longTimeMember:  return "house.fill"
        case .newNeighbor:     return "hand.wave.fill"
        }
    }

    var color: Color {
        switch self {
        case .topRated:        return .neiAmber
        case .trustedNeighbor: return .neiGreen
        case .activeHelper:    return .neiBlue
        case .longTimeMember:  return .neiPurple
        case .newNeighbor:     return .neiGray
        }
    }

    static func badges(for user: NEIUser, postCount: Int, now: Date = Date()) -> [NEITrustBadge] {
        var result: [NEITrustBadge] = []
        if user.reviewCount >= 10 { result.append(.trustedNeighbor) }
        if user.reviewCount >= 5 && user.rating >= 4.5 { result.append(.topRated) }
        if postCount >= 3 { result.append(.activeHelper) }

        let daysSinceJoin = Calendar.current.dateComponents([.day], from: user.createdAt, to: now).day ?? 0
        if daysSinceJoin >= 365 {
            result.append(.longTimeMember)
        } else if daysSinceJoin < 30 {
            result.append(.newNeighbor)
        }
        return result
    }
}
