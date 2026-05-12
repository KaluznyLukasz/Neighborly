//
//  NEIUser.swift
//  Neighborly
//
//  Created by Łukasz Kałużny on 11/05/2026.
//

import Foundation
import CoreLocation

struct NEIUser: Identifiable, Codable {
    var id: String?
    var displayName: String
    var email: String
    var avatarURL: String?
    var bio: String?
    var latitude: Double?
    var longitude: Double?
    var rating: Double
    var reviewCount: Int
    var createdAt: Date

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
