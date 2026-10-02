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

    // Powiadomienia o ogłoszeniach — klucze współdzielone z @AppStorage w ustawieniach
    static let nearbyAlertsKey = "nearbyAlertsEnabled"
    static let alertRepliesKey = "alertRepliesEnabled"

    static var nearbyAlertsEnabled: Bool {
        UserDefaults.standard.object(forKey: nearbyAlertsKey) as? Bool ?? true
    }

    static var alertRepliesEnabled: Bool {
        UserDefaults.standard.object(forKey: alertRepliesKey) as? Bool ?? true
    }

    // Ostatnia znana lokalizacja — odświeżanie w tle nie pyta GPS, tylko liczy odległość od niej
    private static let lastLatitudeKey = "lastKnownLatitude"
    private static let lastLongitudeKey = "lastKnownLongitude"

    static var lastKnownLocation: (latitude: Double, longitude: Double)? {
        get {
            let defaults = UserDefaults.standard
            guard defaults.object(forKey: lastLatitudeKey) != nil else { return nil }
            return (defaults.double(forKey: lastLatitudeKey), defaults.double(forKey: lastLongitudeKey))
        }
        set {
            let defaults = UserDefaults.standard
            if let newValue {
                defaults.set(newValue.latitude, forKey: lastLatitudeKey)
                defaults.set(newValue.longitude, forKey: lastLongitudeKey)
            } else {
                defaults.removeObject(forKey: lastLatitudeKey)
                defaults.removeObject(forKey: lastLongitudeKey)
            }
        }
    }
}
