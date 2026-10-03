//
//  NEIAlertKind.swift
//  Neighborly
//

import SwiftUI

// Wspólne z widżetami — bez Firebase, żeby rozszerzenie mogło to skompilować
enum AlertKind: String, Codable, CaseIterable, Identifiable {
    case lostPet   = "lostPet"
    case foundItem = "foundItem"
    case safety    = "safety"
    case utilities = "utilities"
    case general   = "general"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lostPet:   return "Lost Pet"
        case .foundItem: return "Lost & Found"
        case .safety:    return "Safety"
        case .utilities: return "Outage & Works"
        case .general:   return "Heads Up"
        }
    }

    var systemImage: String {
        switch self {
        case .lostPet:   return "pawprint.fill"
        case .foundItem: return "magnifyingglass"
        case .safety:    return "exclamationmark.shield.fill"
        case .utilities: return "bolt.trianglebadge.exclamationmark.fill"
        case .general:   return "megaphone.fill"
        }
    }

    var color: Color {
        switch self {
        case .lostPet:   return .neiAmber
        case .foundItem: return .neiBlue
        case .safety:    return .neiRed
        case .utilities: return .neiPurple
        case .general:   return .neiGreen
        }
    }
}
