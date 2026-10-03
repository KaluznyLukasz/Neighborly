//
//  NEIWidgetSync.swift
//  Neighborly
//

import CoreLocation
import FirebaseAuth
import Foundation
import WidgetKit

// Zapisuje migawki dla widżetów (Shared/NEIWidgetData.swift) i przeładowuje widżet tylko wtedy,
// gdy coś się zmieniło. Wołane tam, gdzie i tak odświeżamy przypomnienia i powiadomienia
// o ogłoszeniach — przy otwartej aplikacji i w odświeżaniu w tle.
enum NEIWidgetSync {
    // Średni widżet pokazuje najwyżej trzy pozycje; reszta to zapas na mijający czas
    private static let maxPlans = 10
    private static let maxAlerts = 10

    // Ostatnie ogłoszenia — po zmianie lokalizacji albo promienia liczymy migawkę od nowa bez Firestore.
    // Dopóki nie przyszła pierwsza lista, nie zapisujemy pustej (widżet pokazałby "All Quiet").
    private static var activeAlerts: [NeighborhoodAlert]?
    private static var blockedAuthors: Set<String> = []

    static func update(transactions: [Transaction], userId: String) {
        // Synchronizacja, która skończyła się po wylogowaniu, nie może zostawić cudzych danych
        guard Auth.auth().currentUser?.uid == userId else { return }
        let plans = transactions
            .filter { $0.status == .accepted }
            .compactMap { transaction -> NEIUpNextSnapshot.Plan? in
                guard let id = transaction.id, let due = transaction.dueDate else { return nil }
                let isReturn = transaction.dateKind == .returnDate
                // Umówiony dzień, który już minął, nie wróci na widżet — zwrot po terminie tak
                guard isReturn || !NEIDueDate.isPast(due, hasTime: false) else { return nil }
                return NEIUpNextSnapshot.Plan(
                    id: id,
                    title: transaction.offerTitle,
                    category: transaction.offerCategory ?? .items,
                    isReturn: isReturn,
                    volunteerName: transaction.ownerId == userId ? transaction.requesterName : nil,
                    dueDate: due,
                    hasTime: transaction.hasDueTime
                )
            }
            .sorted { $0.dueDate < $1.dueDate }
        let waiting = transactions.filter { $0.ownerId == userId && $0.status == .pending }.count
        save(upNext: NEIUpNextSnapshot(plans: Array(plans.prefix(maxPlans)), waitingCount: waiting))
    }

    static func update(alerts: [NeighborhoodAlert], blocked: Set<String>) {
        activeAlerts = alerts
        update(blocked: blocked)
    }

    static func update(blocked: Set<String>) {
        blockedAuthors = blocked
        refreshAlerts()
    }

    // Też po zmianie lokalizacji albo promienia wyszukiwania
    static func refreshAlerts() {
        guard Auth.auth().currentUser != nil, let activeAlerts else { return }
        guard let origin = NEIUserPreferences.lastKnownLocation else {
            save(alerts: NEIAlertsSnapshot(alerts: [], radiusKm: nil, hasLocation: false))
            return
        }
        let here = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let radiusKm = NEIUserPreferences.searchRadiusKm
        let now = Date()
        let nearby = activeAlerts
            .compactMap { alert -> NEIAlertsSnapshot.Alert? in
                guard let id = alert.id, alert.expiresAt > now, !blockedAuthors.contains(alert.authorId) else { return nil }
                let meters = here.distance(from: CLLocation(latitude: alert.latitude, longitude: alert.longitude))
                guard radiusKm.isInfinite || meters <= radiusKm * 1000 else { return nil }
                return NEIAlertsSnapshot.Alert(
                    id: id,
                    kind: alert.kind,
                    title: alert.title,
                    meters: meters,
                    createdAt: alert.createdAt,
                    expiresAt: alert.expiresAt
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
        save(alerts: NEIAlertsSnapshot(
            alerts: Array(nearby.prefix(maxAlerts)),
            radiusKm: radiusKm.isInfinite ? nil : radiusKm,
            hasLocation: true
        ))
    }

    // Wylogowanie: widżety nie mogą pokazywać danych poprzedniego konta
    static func clear() {
        activeAlerts = nil
        blockedAuthors = []
        save(upNext: nil)
        save(alerts: nil)
    }

    private static func save(upNext: NEIUpNextSnapshot?) {
        if NEIWidgetStore.save(upNext: upNext) {
            WidgetCenter.shared.reloadTimelines(ofKind: NEIWidgetKind.upNext)
        }
    }

    private static func save(alerts: NEIAlertsSnapshot?) {
        if NEIWidgetStore.save(alerts: alerts) {
            WidgetCenter.shared.reloadTimelines(ofKind: NEIWidgetKind.alerts)
        }
    }
}
