//
//  NEIOfferCategory.swift
//  Neighborly
//

import SwiftUI

// Wspólne z widżetami — bez Firebase, żeby rozszerzenie mogło to skompilować
enum OfferCategory: String, Codable, CaseIterable, Identifiable {
    case tools     = "tools"
    case help      = "help"
    case food      = "food"
    case services  = "services"
    case items     = "items"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tools:    return "Repairs"
        case .help:     return "General Help"
        case .food:     return "Food & Groceries"
        case .services: return "Services"
        case .items:    return "Items"
        }
    }

    var systemImage: String {
        switch self {
        case .tools:    return "wrench.and.screwdriver"
        case .help:     return "hands.and.sparkles"
        case .food:     return "fork.knife"
        case .services: return "person.fill.checkmark"
        case .items:    return "shippingbox"
        }
    }

    var color: Color {
        switch self {
        case .tools:    return .neiAmber
        case .help:     return .neiGreen
        case .food:     return .neiRed
        case .services: return .neiPurple
        case .items:    return .neiBlue
        }
    }
}
