//
//  NEINotificationRouter.swift
//  Neighborly
//

import Foundation
import Observation
import UserNotifications

// Ogłoszenie do otwarcia po tapnięciu. viewerId != nil — od razu rozmowa z tym sąsiadem.
struct NEIAlertRoute: Equatable {
    let alertId: String
    let viewerId: String?
}

// Delegat centrum powiadomień: pokazuje powiadomienia także przy otwartej aplikacji, a tapnięcie
// zapamiętuje, co otworzyć. ContentView przełącza zakładkę, a lista transakcji albo mapa
// otwiera szczegóły i czyści pole.
@Observable
final class NEINotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NEINotificationRouter()

    nonisolated static let transactionIdKey = "transactionId"
    nonisolated static let alertIdKey = "alertId"
    nonisolated static let viewerIdKey = "viewerId"

    var pendingTransactionId: String?
    var pendingAlert: NEIAlertRoute?

    // Co użytkownik ma teraz przed oczami — o tym nie powiadamiamy
    var isViewingAlerts = false
    var visibleConversationPath: String?

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        let info = response.notification.request.content.userInfo
        if let id = info[Self.transactionIdKey] as? String {
            await MainActor.run { pendingTransactionId = id }
        } else if let id = info[Self.alertIdKey] as? String {
            let route = NEIAlertRoute(alertId: id, viewerId: info[Self.viewerIdKey] as? String)
            await MainActor.run { pendingAlert = route }
        }
    }
}
