//
//  NEINotificationRouter.swift
//  Neighborly
//

import Foundation
import Observation
import UserNotifications

// Delegat centrum powiadomień: pokazuje przypomnienia także przy otwartej aplikacji, a tapnięcie
// zapamiętuje transakcję do otwarcia. ContentView przełącza wtedy na Activity, a lista otwiera
// szczegóły i czyści `pendingTransactionId`.
@Observable
final class NEINotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NEINotificationRouter()

    var pendingTransactionId: String?

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
        guard
            response.actionIdentifier == UNNotificationDefaultActionIdentifier,
            let id = response.notification.request.content.userInfo[NEIReminderService.transactionIdKey] as? String
        else { return }
        await MainActor.run { pendingTransactionId = id }
    }
}
