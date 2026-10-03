//
//  NEIWidgetData.swift
//  Neighborly
//

import Foundation

// Dane widżetów. Aplikacja zapisuje migawkę we wspólnym kontenerze App Group, a widżety tylko ją
// czytają — rozszerzenie nie ma Firebase ani logowania. Teksty zależne od czasu ("tomorrow",
// "2 hr ago") liczy widżet dla każdego wpisu osi czasu, dlatego w migawce są surowe daty.

enum NEIWidgetKind {
    static let upNext = "NEIUpNextWidget"
    static let alerts = "NEIAlertsWidget"
}

// Zaakceptowane transakcje z terminem i liczba ochotników czekających na moją odpowiedź
struct NEIUpNextSnapshot: Codable, Equatable {
    struct Plan: Codable, Equatable, Identifiable {
        var id: String
        var title: String
        var category: OfferCategory
        // Zwrot pożyczonej rzeczy (może być po terminie) albo umówiony dzień
        var isReturn: Bool
        // Tylko przy moim poście — ochotnik nie zna imienia autora
        var volunteerName: String?
        var dueDate: Date
        var hasTime: Bool
    }

    var plans: [Plan]
    var waitingCount: Int
}

// Aktywne ogłoszenia w promieniu wyszukiwania, od najnowszego
struct NEIAlertsSnapshot: Codable, Equatable {
    struct Alert: Codable, Equatable, Identifiable {
        var id: String
        var kind: AlertKind
        var title: String
        var meters: Double
        var createdAt: Date
        var expiresAt: Date
    }

    var alerts: [Alert]
    // nil = "Any distance"
    var radiusKm: Double?
    // false = aplikacja nie zna jeszcze lokalizacji (brak zgody)
    var hasLocation: Bool
}

enum NEIWidgetStore {
    static let appGroup = "group.app.me.kaluzny.lukasz.Neighborly"
    private static let upNextKey = "widget.upNext"
    private static let alertsKey = "widget.alerts"

    // nil, gdy podpis nie ma uprawnienia App Group — wtedy widżety pokazują stan "otwórz aplikację"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    static var upNext: NEIUpNextSnapshot? { load(upNextKey) }
    static var alerts: NEIAlertsSnapshot? { load(alertsKey) }

    // true, gdy migawka się zmieniła — tylko wtedy warto przeładować widżet
    @discardableResult
    static func save(upNext: NEIUpNextSnapshot?) -> Bool { save(upNext, upNextKey) }

    @discardableResult
    static func save(alerts: NEIAlertsSnapshot?) -> Bool { save(alerts, alertsKey) }

    private static func load<T: Decodable>(_ key: String) -> T? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func save<T: Codable & Equatable>(_ value: T?, _ key: String) -> Bool {
        guard let defaults, value != load(key) else { return false }
        if let value, let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
        return true
    }
}

// Co otworzyć po tapnięciu widżetu. Aplikacja dostaje adres w onOpenURL (ContentView);
// schematu nie rejestrujemy — system przekazuje adres z widżetu prosto do aplikacji.
enum NEIWidgetLink: Equatable {
    case activity
    case transaction(id: String)
    case alerts
    case alert(id: String)

    private static let scheme = "neighborly"

    var url: URL {
        let path = switch self {
        case .activity: "activity"
        case .transaction(let id): "transaction/\(id)"
        case .alerts: "alerts"
        case .alert(let id): "alert/\(id)"
        }
        return URL(string: "\(Self.scheme)://\(path)") ?? URL(string: "\(Self.scheme)://activity")!
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        // "neighborly://alert/abc" → host "alert", pathComponents ["/", "abc"]
        let id = url.pathComponents.dropFirst().first
        switch (url.host(), id) {
        case ("activity", _): self = .activity
        case ("transaction", let id?): self = .transaction(id: id)
        case ("alerts", _): self = .alerts
        case ("alert", let id?): self = .alert(id: id)
        default: return nil
        }
    }
}
