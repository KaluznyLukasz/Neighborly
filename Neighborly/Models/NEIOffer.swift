//
//  NEIOffer.swift
//  Neighborly
//
//  Created by Łukasz on 11/05/2026.
//

import Foundation
import CoreLocation

struct Offer: Identifiable, Codable {
    var id: String?
    var title: String
    var description: String
    var category: String
    var latitude: Double
    var longitude: Double
    var ownerId: String
    
    // Obliczane pole, ułatwi pracę z MapKit
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
