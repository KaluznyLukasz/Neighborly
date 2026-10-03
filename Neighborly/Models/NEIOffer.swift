//
//  NEIOffer.swift
//  Neighborly
//
//  Created by Łukasz Kałużny on 11/05/2026.
//

import Foundation
import CoreLocation
import FirebaseFirestore

// OfferCategory jest w Shared/NEIOfferCategory.swift (wspólne z widżetami)
struct Offer: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var category: OfferCategory
    var address: String?
    var ownerId: String
    var latitude: Double
    var longitude: Double
    var imageURLs: [String]
    var imageBase64: String?
    var isActive: Bool
    var createdAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
