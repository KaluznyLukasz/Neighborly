//
//  NEIAlert.swift
//  Neighborly
//

import Foundation
import CoreLocation
import FirebaseFirestore

// AlertKind jest w Shared/NEIAlertKind.swift (wspólne z widżetami)

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
    // Kto napisał ostatnią wiadomość — powiadamiamy tylko drugą stronę. nil w wątkach sprzed
    // dodania pola; o nich nie powiadamiamy.
    var lastSenderId: String?
}
