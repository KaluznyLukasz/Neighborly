//
//  NEIUserPreferences.swift
//  Neighborly
//

import Foundation

enum NEIUserPreferences {
    private static let searchRadiusKey = "searchRadiusKm"
    static let unlimitedRadiusKm = Double.infinity

    static var searchRadiusKm: Double {
        get {
            let stored = UserDefaults.standard.double(forKey: searchRadiusKey)
            return stored > 0 ? stored : 10.0
        }
        set { UserDefaults.standard.set(newValue, forKey: searchRadiusKey) }
    }

    // Klucz współdzielony z @AppStorage w ustawieniach; domyślnie włączone
    static let remindersKey = "remindersEnabled"

    static var remindersEnabled: Bool {
        UserDefaults.standard.object(forKey: remindersKey) as? Bool ?? true
    }
}
