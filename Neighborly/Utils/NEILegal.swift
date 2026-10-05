//
//  NEILegal.swift
//  Neighborly
//

import Foundation

// Strony prawne leżą w web/ i są wdrażane na Firebase Hosting (firebase.json → "hosting").
// Te same adresy wpisujemy w App Store Connect (Privacy Policy URL, Support URL).
enum NEILegal {
    static let privacyPolicyURL = URL(string: "https://neighborly-d3c33.web.app/privacy")!
    static let termsURL = URL(string: "https://neighborly-d3c33.web.app/terms")!
    static let supportURL = URL(string: "https://neighborly-d3c33.web.app/support")!

    // TODO: przed wysłaniem do App Store podmienić na prawdziwy adres (także w web/*.html)
    static let contactEmail = "contact@example.com"
    static var contactURL: URL { URL(string: "mailto:\(contactEmail)")! }

    // Wersja regulaminu zapisywana przy rejestracji (users/{uid}.termsVersion) — data publikacji
    static let termsVersion = "2026-10-04"
    static let minimumAge = 18
}
