//
//  NEIOffer.swift
//  Neighborly
//
//  Created by Łukasz Kałużny on 11/05/2026.
//

import Foundation
import CoreLocation

enum OfferCategory: String, Codable, CaseIterable, Identifiable {
    case tools     = "tools"
    case help      = "help"
    case food      = "food"
    case services  = "services"
    case items     = "items"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tools:    return "Tools"
        case .help:     return "Help"
        case .food:     return "Food"
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
}

struct Offer: Identifiable, Codable {
    var id: String?
    var title: String
    var description: String
    var category: OfferCategory
    var ownerId: String
    var latitude: Double
    var longitude: Double
    var imageURLs: [String]
    var isActive: Bool
    var createdAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
