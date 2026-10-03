//
//  NEIReminderService.swift
//  Neighborly
//

import BackgroundTasks
import Foundation
import FirebaseAuth
import UserNotifications

// Lokalne przypomnienia o terminie transakcji (zwrot rzeczy albo umówiony dzień). Każde
// urządzenie planuje je samo dla transakcji, w których uczestniczy — bez backendu. Termin
// ustawiony przez drugą stronę dociera przy otwarciu aplikacji, po powrocie z tła albo
// w odświeżaniu w tle (co najmniej co kilka godzin, kiedy system na to pozwoli).
enum NEIReminderService {
    // Prefiks zostaje "return-" — tak nazywały się przypomnienia z pierwszej wersji, więc
    // synchronizacja sprząta też te stare
    private static let idPrefix = "return-"
    private static let transactionIdKey = NEINotificationRouter.transactionIdKey

    private static let morningHour = 9
    private static let eveningHour = 18
    // iOS trzyma najwyżej 64 zaplanowane powiadomienia na aplikację — zostawiamy zapas
    private static let pendingLimit = 60

    struct Reminder: Equatable {
        let id: String
        let transactionId: String
        let title: String
        let body: String
        let fireDate: Date
    }

    nonisolated static let backgroundRefreshId = "app.me.kaluzny.lukasz.Neighborly.reminders"
    // Ogłoszenia sąsiedzkie są pilniejsze niż przypomnienia — prosimy o częste odświeżanie;
    // system i tak sam wydziela czas (zwykle rzadziej, gdy aplikacja jest rzadko używana)
    private static let backgroundRefreshInterval: TimeInterval = 30 * 60

    // Kolejne synchronizacje czekają na poprzednią — dwa równoległe sync (np. ContentView
    // i lista transakcji) przeplatałyby kasowanie i dodawanie
    private static var lastOperation: Task<Void, Never>?

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // Pełne pytanie o zgodę, gdy jeszcze go nie było (albo jest tylko cicha zgoda). W kolejce
    // razem z synchronizacją, więc ta poczeka na odpowiedź i nie poprosi w tym czasie o cichą zgodę.
    // Gdy dana funkcja (domyślnie przypomnienia) jest wyłączona w ustawieniach, nie pytamy wcale.
    static func requestAuthorizationIfNeeded(enabled: Bool = NEIUserPreferences.remindersEnabled) async {
        guard enabled else { return }
        await serialized {
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            guard status == .notDetermined || status == .provisional else { return }
            _ = await requestAuthorization()
        }
    }

    // Cicha (provisional) zgoda: bez pytania, powiadomienia trafiają tylko do centrum powiadomień.
    // Dla kogoś, kto jeszcze nie miał okazji odpowiedzieć na pytanie o zgodę.
    static func requestQuietAuthorizationIfUndetermined() async {
        let center = UNUserNotificationCenter.current()
        guard await center.notificationSettings().authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge, .provisional])
    }

    static func notificationsAllowed() async -> Bool {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: true
        default: false
        }
    }

    // Kasuje zaplanowane i już widoczne przypomnienia — przy wylogowaniu i wyłączeniu w ustawieniach
    static func cancelAll() async {
        await serialized {
            let center = UNUserNotificationCenter.current()
            let pending = await center.pendingNotificationRequests()
            center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter(isReminderId))
            let delivered = await center.deliveredNotifications()
            center.removeDeliveredNotifications(withIdentifiers: delivered.map(\.request.identifier).filter(isReminderId))
        }
    }

    // Pobiera transakcje od nowa, planuje przypomnienia i odświeża widżet — gdy żaden widok
    // nie ma ich załadowanych
    static func resync(userId: String) async {
        let service = NEITransactionService()
        async let inbox = try? service.fetchInbox(ownerId: userId)
        async let requests = try? service.fetchMyRequests(requesterId: userId)
        guard let inbox = await inbox, let requests = await requests else { return }
        NEIWidgetSync.update(transactions: inbox + requests, userId: userId)
        await sync(transactions: inbox + requests, userId: userId)
    }

    // MARK: - Odświeżanie w tle

    // Zgłasza kolejne odświeżenie; system sam wybiera chwilę, nie wcześniej niż za 30 min.
    // Ponowne zgłoszenie zastępuje poprzednie.
    static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundRefreshId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: backgroundRefreshInterval)
        try? BGTaskScheduler.shared.submit(request)
    }

    // Wywoływane przez system w tle: planuje następne odświeżenie, synchronizuje przypomnienia
    // z Firestore (żeby nie przyszło przypomnienie o transakcji, którą druga strona już zamknęła)
    // i sprawdza nowe ogłoszenia oraz wiadomości przy ogłoszeniach
    static func refreshInBackground() async {
        scheduleBackgroundRefresh()
        guard let userId = Auth.auth().currentUser?.uid else { return }
        async let reminders: () = resync(userId: userId)
        async let alerts: () = NEIAlertNotifier.shared.checkInBackground(userId: userId)
        _ = await (reminders, alerts)
    }

    // Zastępuje wszystkie zaplanowane przypomnienia stanem z `transactions` i zdejmuje z centrum
    // powiadomień te, których transakcja już się skończyła. Przy wyłączonych przypomnieniach
    // tylko czyści kolejkę.
    static func sync(transactions: [Transaction], userId: String) async {
        await serialized {
            let center = UNUserNotificationCenter.current()
            // Synchronizacja, która skończyła się po wylogowaniu (albo dla poprzedniego konta),
            // nie może zaplanować cudzych przypomnień — wtedy tylko czyści
            let isCurrentUser = Auth.auth().currentUser?.uid == userId
            let planned = NEIUserPreferences.remindersEnabled && isCurrentUser
                ? plan(for: transactions, userId: userId)
                : []
            // Wolontariusz nigdy nie ustawia terminu, więc nikt go nie zapytał o zgodę. Cicha
            // (provisional) zgoda nie pokazuje pytania, a przypomnienia trafiają do centrum
            // powiadomień; pełną zgodę proponuje karta terminu.
            if !planned.isEmpty { await requestQuietAuthorizationIfUndetermined() }
            let reminders = await notificationsAllowed() ? planned : []

            let pending = await center.pendingNotificationRequests()
            center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter(isReminderId))
            for reminder in reminders {
                try? await center.add(request(for: reminder))
            }

            let active = !isCurrentUser ? [] : Set(transactions.filter { $0.status == .accepted && $0.dueDate != nil }.compactMap(\.id))
            let stale = await center.deliveredNotifications().filter { notification in
                guard isReminderId(notification.request.identifier) else { return false }
                let id = notification.request.content.userInfo[transactionIdKey] as? String
                return id.map { !active.contains($0) } ?? true
            }
            center.removeDeliveredNotifications(withIdentifiers: stale.map(\.request.identifier))
        }
    }

    // MARK: - Plan

    // Dla każdej zaakceptowanej transakcji z terminem:
    // - wieczór przed (18:00),
    // - rano w dniu terminu (9:00) albo godzinę przed, jeśli termin ma godzinę,
    // - przy zwrocie: rano następnego dnia, gdyby rzecz nie wróciła (transakcja dalej otwarta).
    // Tylko przyszłe, najbliższe `pendingLimit`.
    static func plan(
        for transactions: [Transaction],
        userId: String,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [Reminder] {
        var reminders: [Reminder] = []

        for transaction in transactions where transaction.status == .accepted {
            guard let due = transaction.dueDate, let id = transaction.id else { continue }
            let day = calendar.startOfDay(for: due)
            let copy = ReminderCopy(transaction: transaction, isOwner: transaction.ownerId == userId)

            func add(_ kind: String, _ text: (title: String, body: String), at date: Date?) {
                guard let date, date > now else { return }
                reminders.append(Reminder(
                    id: "\(idPrefix)\(id)-\(kind)",
                    transactionId: id,
                    title: text.title,
                    body: text.body,
                    fireDate: date
                ))
            }

            add("eve", copy.eveningBefore, at: time(eveningHour, daysAfter: -1, day, calendar))
            if transaction.hasDueTime {
                add("soon", copy.hourBefore, at: calendar.date(byAdding: .hour, value: -1, to: due))
            } else {
                add("due", copy.morningOf, at: time(morningHour, daysAfter: 0, day, calendar))
            }
            if transaction.dateKind == .returnDate {
                add("late", copy.dayAfter, at: time(morningHour, daysAfter: 1, day, calendar))
            }
        }

        return Array(reminders.sorted { $0.fireDate < $1.fireDate }.prefix(pendingLimit))
    }

    private static func time(_ hour: Int, daysAfter: Int, _ day: Date, _ calendar: Calendar) -> Date? {
        calendar.date(byAdding: .day, value: daysAfter, to: day)
            .flatMap { calendar.date(bySettingHour: hour, minute: 0, second: 0, of: $0) }
    }

    private static func isReminderId(_ id: String) -> Bool {
        id.hasPrefix(idPrefix)
    }

    private static func request(for reminder: Reminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        // Przypomnienia jednej transakcji grupują się razem; tapnięcie otwiera transakcję
        content.threadIdentifier = "transaction-\(reminder.transactionId)"
        content.userInfo = [transactionIdKey: reminder.transactionId]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
    }

    private static func serialized(_ operation: @escaping () async -> Void) async {
        let previous = lastOperation
        let task = Task {
            await previous?.value
            await operation()
        }
        lastOperation = task
        await task.value
    }
}

// Teksty powiadomień. Zwrot dotyczy rzeczy (kategoria Items); w pozostałych kategoriach termin
// to umówiony dzień. Wolontariusz nie zna imienia właściciela z transakcji, więc pisze "the owner".
private struct ReminderCopy {
    let transaction: Transaction
    let isOwner: Bool

    private var title: String { "“\(transaction.offerTitle)”" }
    private var name: String { transaction.requesterName }
    private var isReturn: Bool { transaction.dateKind == .returnDate }
    private var time: String? {
        guard transaction.hasDueTime, let due = transaction.dueDate else { return nil }
        return NEIDueDate.timeText(due)
    }
    private var atTime: String { time.map { " at \($0)" } ?? "" }
    private var withWho: String { isOwner ? " with \(name)" : "" }

    var eveningBefore: (title: String, body: String) {
        if isReturn {
            return ("Due back tomorrow", isOwner
                ? "\(name) should return \(title) tomorrow\(atTime)."
                : "Remember to return \(title) tomorrow\(atTime).")
        }
        return ("Planned for tomorrow", "\(title)\(withWho) is tomorrow\(atTime).")
    }

    var morningOf: (title: String, body: String) {
        if isReturn {
            return ("Due back today", isOwner
                ? "\(name) should return \(title) today."
                : "Time to return \(title).")
        }
        return ("Planned for today", "\(title)\(withWho) is today.")
    }

    var hourBefore: (title: String, body: String) {
        let time = time ?? ""
        if isReturn {
            return ("Due back at \(time)", isOwner
                ? "\(name) should return \(title) in an hour."
                : "Return \(title) by \(time).")
        }
        return ("Coming up at \(time)", "\(title)\(withWho) starts in an hour.")
    }

    var dayAfter: (title: String, body: String) {
        isOwner
            ? ("Got \(title) back?", "It was due yesterday. Mark it as completed, or message \(name).")
            : ("Return overdue", "\(title) was due back yesterday. Return it, or message the owner to agree on a new date.")
    }
}
