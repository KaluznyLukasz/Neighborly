//
//  NEIAlert.swift
//  Neighborly
//

import Foundation
import CoreLocation
import FirebaseFirestore
import SwiftUI

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

// Krótkotrwałe ogłoszenie dla sąsiadów w okolicy — wygasa samo po `lifetime`
struct NeighborhoodAlert: Identifiable, Codable {
    @DocumentID var id: String?
    var kind: AlertKind
    var title: String
    var details: String
    var authorId: String
    var authorName: String
    var imageBase64: String?
    var latitude: Double
    var longitude: Double
    var createdAt: Date
    var expiresAt: Date

    static let lifetime: TimeInterval = 48 * 60 * 60
    static let maxTitleLength = 80
    static let maxDetailsLength = 500

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// Nawigacja po ID wystarcza — treść ogłoszenia nie zmienia się po utworzeniu
extension NeighborhoodAlert: Hashable {
    static func == (lhs: NeighborhoodAlert, rhs: NeighborhoodAlert) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// Rozmowa sąsiada z autorem ogłoszenia. ID dokumentu = ID sąsiada, który napisał pierwszy,
// więc autor widzi listę wątków, a każdy sąsiad ma dokładnie jeden wątek na ogłoszenie
struct AlertThread: Identifiable, Codable {
    @DocumentID var id: String?
    var viewerName: String
    var lastMessage: String
    var updatedAt: Date
}
