//
//  NEIUserPreferences.swift
//  Neighborly
//

import Foundation

enum NEIUserPreferences {
    private static let searchRadiusKey = "searchRadiusKm"

    static var searchRadiusKm: Double {
        get {
            let stored = UserDefaults.standard.double(forKey: searchRadiusKey)
            return stored > 0 ? stored : 10.0
        }
        set { UserDefaults.standard.set(newValue, forKey: searchRadiusKey) }
    }
}
