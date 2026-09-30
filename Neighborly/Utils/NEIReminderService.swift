//
//  NEIReminderService.swift
//  Neighborly
//

import Foundation
import UserNotifications

// Lokalne przypomnienia o zwrocie. Każde urządzenie planuje je samo dla transakcji, w których
// uczestniczy — bez backendu. Druga strona dostaje przypomnienie po otwarciu aplikacji
// (przy synchronizacji), więc termin ustawiony przez właściciela dociera z opóźnieniem.
enum NEIReminderService {
    private static let idPrefix = "return-"
    // 9:00 w dniu terminu i 18:00 dzień wcześniej
    private static let dueHour = 9
    private static let headsUpHour = 18

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // Zastępuje wszystkie zaplanowane przypomnienia stanem z `transactions`
    static func sync(transactions: [Transaction], userId: String) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
        )

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        for transaction in transactions {
            guard transaction.status == .accepted, let dueDate = transaction.dueDate, let id = transaction.id else { continue }
            let isOwner = transaction.ownerId == userId

            let dueTitle = isOwner ? "Due back today" : "Return due today"
            let dueBody = isOwner
                ? "\(transaction.requesterName) should return “\(transaction.offerTitle)” today."
                : "Time to return “\(transaction.offerTitle)”."
            let headsUpBody = isOwner
                ? "\(transaction.requesterName) should return “\(transaction.offerTitle)” tomorrow."
                : "Remember to return “\(transaction.offerTitle)” tomorrow."

            await schedule(id: "\(idPrefix)\(id)-due", title: dueTitle, body: dueBody, day: dueDate, hour: dueHour, dayOffset: 0)
            await schedule(id: "\(idPrefix)\(id)-eve", title: "Return due tomorrow", body: headsUpBody, day: dueDate, hour: headsUpHour, dayOffset: -1)
        }
    }

    private static func schedule(id: String, title: String, body: String, day: Date, hour: Int, dayOffset: Int) async {
        let calendar = Calendar.current
        guard
            let shifted = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: day)),
            let fireDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: shifted),
            fireDate > Date()
        else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try? await UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
