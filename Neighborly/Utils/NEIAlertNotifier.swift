//
//  NEIAlertNotifier.swift
//  Neighborly
//

import Foundation
import CoreLocation
import FirebaseFirestore
import UserNotifications

// Powiadomienia o ogłoszeniach sąsiedzkich, bez backendu — wszystko lokalnie:
// - nowe ogłoszenie w okolicy (w promieniu wyszukiwania, najwyżej 25 km),
// - nowa wiadomość w rozmowie przy ogłoszeniu: autor dostaje wiadomości sąsiadów,
//   sąsiad odpowiedzi autora.
// Źródła: nasłuch Firestore, gdy aplikacja działa, i odświeżanie w tle, gdy nie działa (wtedy
// z opóźnieniem — system decyduje, kiedy aplikacja dostanie czas). Co już było powiadomione,
// trzymamy per użytkownik w UserDefaults, więc oba źródła nie dublują powiadomień.
@MainActor
final class NEIAlertNotifier {
    static let shared = NEIAlertNotifier()

    // Przy promieniu "Any distance" powiadamiamy tylko o tym, co naprawdę w okolicy
    static let maxRadiusKm = 25.0
    // Więcej nowych ogłoszeń naraz — jedno zbiorcze powiadomienie zamiast serii
    private static let summaryThreshold = 3
    private static let idPrefix = "alert-"

    private struct State: Codable {
        // Nie powiadamiamy o niczym sprzed pierwszego uruchomienia funkcji
        var baseline: Date
        // ID ogłoszenia → koniec ważności (do sprzątania)
        var notifiedAlerts: [String: Date] = [:]
        // "alertId/viewerId" → updatedAt wiadomości, o której już wiadomo
        var seenThreads: [String: Date] = [:]
        // Cudze ogłoszenia, do których autora napisałem → koniec ważności
        var joinedAlerts: [String: Date] = [:]
    }

    private let service = NEIAlertService()
    private var userId: String?
    private var blocked: Set<String> = []
    private var activeListener: ListenerRegistration?
    private var mineListener: ListenerRegistration?
    private var threadListeners: [String: ListenerRegistration] = [:]
    // Od kiedy działa nasłuch — starsze ogłoszenia nie dają powiadomienia na pierwszym planie
    private var listeningSince = Date()

    // MARK: - Nasłuch, gdy aplikacja działa

    func start(userId: String) {
        guard self.userId != userId else { return }
        stop()
        self.userId = userId
        listeningSince = Date()
        Task { blocked = Set((try? await NEIBlockService().fetchBlockedUserIds(userId: userId)) ?? []) }

        activeListener = service.listenActive(
            onChange: { [weak self] alerts in
                Task { @MainActor [weak self] in self?.activeAlertsChanged(alerts) }
            },
            onError: { _ in }
        )
        mineListener = service.listenMine(authorId: userId) { [weak self] alerts in
            Task { @MainActor [weak self] in self?.myAlertsChanged(alerts) }
        }
        for alertId in loadState(userId).joinedAlerts.keys {
            listenToJoined(alertId: alertId)
        }
    }

    func stop() {
        activeListener?.remove()
        mineListener?.remove()
        threadListeners.values.forEach { $0.remove() }
        activeListener = nil
        mineListener = nil
        threadListeners = [:]
        userId = nil
        blocked = []
    }

    // Wylogowanie: koniec nasłuchu i zdjęcie powiadomień poprzedniego konta
    func signOut() {
        stop()
        let center = UNUserNotificationCenter.current()
        Task {
            let delivered = await center.deliveredNotifications()
            center.removeDeliveredNotifications(
                withIdentifiers: delivered.map(\.request.identifier).filter { $0.hasPrefix(Self.idPrefix) }
            )
        }
    }

    // Sąsiad wysłał wiadomość autorowi — odtąd czekamy na odpowiedź
    func didMessageAuthor(of alert: NeighborhoodAlert) {
        guard let userId, let alertId = alert.id, alert.authorId != userId else { return }
        var state = loadState(userId)
        state.joinedAlerts[alertId] = alert.expiresAt
        saveState(state, userId)
        listenToJoined(alertId: alertId)
    }

    // Ogłoszenia sprzed startu nasłuchu tylko zapamiętujemy: to, co pojawiło się przy zamkniętej
    // aplikacji, widać i tak na mapie (licznik przy dzwonku). Liczy się data utworzenia, a nie
    // pierwszy odczyt — ten często przychodzi z pamięci podręcznej, a pełny dopiero po nim.
    private func activeAlertsChanged(_ alerts: [NeighborhoodAlert]) {
        guard let userId else { return }
        Task { await handleActive(alerts, userId: userId, blocked: blocked, silentBefore: listeningSince) }
    }

    private func myAlertsChanged(_ alerts: [NeighborhoodAlert]) {
        guard let userId else { return }
        let active = alerts.filter { $0.expiresAt > Date() }
        let activeKeys = Set(active.compactMap { $0.id.map { "mine-\($0)" } })
        for (key, listener) in threadListeners where key.hasPrefix("mine-") && !activeKeys.contains(key) {
            listener.remove()
            threadListeners[key] = nil
        }
        for alert in active {
            guard let alertId = alert.id, threadListeners["mine-\(alertId)"] == nil else { continue }
            threadListeners["mine-\(alertId)"] = service.listenThreads(alertId: alertId) { [weak self] threads in
                Task { @MainActor [weak self] in
                    await self?.handleThreads(threads, of: alert, userId: userId, isAuthor: true)
                }
            }
        }
    }

    private func listenToJoined(alertId: String) {
        let key = "joined-\(alertId)"
        guard let userId, threadListeners[key] == nil else { return }
        threadListeners[key] = service.listenThread(alertId: alertId, viewerId: userId) { [weak self] thread in
            Task { @MainActor [weak self] in
                guard let self, let thread, self.userId == userId else { return }
                // Tytuł i autor do treści powiadomienia — pobieramy dopiero, gdy jest nowa wiadomość
                guard self.isNew(thread, alertId: alertId, userId: userId),
                      let alert = try? await self.service.fetch(id: alertId) else { return }
                await self.handleThreads([thread], of: alert, userId: userId, isAuthor: false)
            }
        }
    }

    // MARK: - Odświeżanie w tle

    func checkInBackground(userId: String) async {
        guard let active = try? await service.fetchActive() else { return }
        let blocked = Set((try? await NEIBlockService().fetchBlockedUserIds(userId: userId)) ?? [])
        await handleActive(active, userId: userId, blocked: blocked, silentBefore: nil)

        for alert in active where alert.authorId == userId {
            guard let alertId = alert.id, let threads = try? await service.fetchThreads(alertId: alertId) else { continue }
            await handleThreads(threads.filter { !blocked.contains($0.id ?? "") }, of: alert, userId: userId, isAuthor: true)
        }
        for alertId in loadState(userId).joinedAlerts.keys {
            guard let alert = active.first(where: { $0.id == alertId }),
                  let thread = try? await service.fetchThread(alertId: alertId, viewerId: userId) else { continue }
            await handleThreads([thread], of: alert, userId: userId, isAuthor: false)
        }
    }

    // MARK: - Nowe ogłoszenia w okolicy

    private func handleActive(_ alerts: [NeighborhoodAlert], userId: String, blocked: Set<String>, silentBefore: Date?) async {
        guard let origin = NEIUserPreferences.lastKnownLocation else { return }
        let here = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let radiusMeters = min(NEIUserPreferences.searchRadiusKm, Self.maxRadiusKm) * 1000
        let now = Date()
        var state = loadState(userId)

        let fresh: [(alert: NeighborhoodAlert, meters: Double)] = alerts.compactMap { alert in
            guard let id = alert.id,
                  state.notifiedAlerts[id] == nil,
                  alert.authorId != userId,
                  !blocked.contains(alert.authorId),
                  alert.expiresAt > now,
                  alert.createdAt > state.baseline else { return nil }
            let meters = here.distance(from: CLLocation(latitude: alert.latitude, longitude: alert.longitude))
            return meters <= radiusMeters ? (alert, meters) : nil
        }
        guard !fresh.isEmpty else { return }

        // Zapamiętujemy też, gdy nie powiadamiamy — po włączeniu nie przyjdzie zaległa seria
        for item in fresh { state.notifiedAlerts[item.alert.id ?? ""] = item.alert.expiresAt }
        saveState(state, userId)

        let toNotify = fresh.filter { item in silentBefore.map { item.alert.createdAt >= $0 } ?? true }
        guard !toNotify.isEmpty,
              NEIUserPreferences.nearbyAlertsEnabled,
              !NEINotificationRouter.shared.isViewingAlerts,
              await canNotify() else { return }

        if toNotify.count > Self.summaryThreshold {
            // Tapnięcie otwiera listę ogłoszeń (puste ID = bez konkretnego ogłoszenia)
            await post(
                id: "\(Self.idPrefix)new-summary-\(Int(now.timeIntervalSince1970))",
                title: "\(toNotify.count) new alerts nearby",
                subtitle: nil,
                body: toNotify.prefix(3).map(\.alert.title).joined(separator: " · "),
                thread: "alerts-nearby",
                userInfo: [NEINotificationRouter.alertIdKey: ""],
                imageBase64: nil
            )
            return
        }
        for item in toNotify.sorted(by: { $0.alert.createdAt < $1.alert.createdAt }) {
            let alert = item.alert
            let distance = Measurement(value: item.meters, unit: UnitLength.meters)
                .formatted(.measurement(width: .abbreviated, usage: .road))
            await post(
                id: "\(Self.idPrefix)new-\(alert.id ?? "")",
                title: alert.title,
                subtitle: "\(alert.kind.displayName) · \(distance) away",
                body: alert.details.isEmpty ? "Posted by \(alert.authorName)." : alert.details,
                thread: "alerts-nearby",
                userInfo: [NEINotificationRouter.alertIdKey: alert.id ?? ""],
                imageBase64: alert.imageBase64
            )
        }
    }

    // MARK: - Wiadomości w rozmowach

    private func isNew(_ thread: AlertThread, alertId: String, userId: String) -> Bool {
        guard let viewerId = thread.id, let sender = thread.lastSenderId, sender != userId else { return false }
        let state = loadState(userId)
        return thread.updatedAt > (state.seenThreads["\(alertId)/\(viewerId)"] ?? state.baseline)
    }

    private func handleThreads(_ threads: [AlertThread], of alert: NeighborhoodAlert, userId: String, isAuthor: Bool) async {
        guard let alertId = alert.id else { return }
        let new = threads.filter { isNew($0, alertId: alertId, userId: userId) && !blocked.contains($0.lastSenderId ?? "") }
        guard !new.isEmpty else { return }

        var state = loadState(userId)
        for thread in new { state.seenThreads["\(alertId)/\(thread.id ?? "")"] = thread.updatedAt }
        saveState(state, userId)

        guard NEIUserPreferences.alertRepliesEnabled, await canNotify() else { return }
        for thread in new {
            let viewerId = thread.id ?? ""
            // Rozmowa jest otwarta — wiadomość i tak widać
            if NEINotificationRouter.shared.visibleConversationPath == NEIMessageService.path(alertId: alertId, viewerId: viewerId) {
                continue
            }
            await post(
                id: "\(Self.idPrefix)reply-\(alertId)-\(viewerId)-\(Int(thread.updatedAt.timeIntervalSince1970))",
                title: isAuthor ? thread.viewerName : alert.authorName,
                subtitle: "Re: \(alert.title)",
                body: thread.lastMessage,
                thread: "alert-\(alertId)-\(viewerId)",
                userInfo: [NEINotificationRouter.alertIdKey: alertId, NEINotificationRouter.viewerIdKey: viewerId],
                imageBase64: nil
            )
        }
    }

    // MARK: - Wspólne

    // Kto jeszcze nie odpowiadał na pytanie o zgodę, dostaje cichą zgodę (bez pytania)
    private func canNotify() async -> Bool {
        await NEIReminderService.requestQuietAuthorizationIfUndetermined()
        return await NEIReminderService.notificationsAllowed()
    }

    private func post(
        id: String,
        title: String,
        subtitle: String?,
        body: String,
        thread: String,
        userInfo: [String: String],
        imageBase64: String?
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle { content.subtitle = subtitle }
        content.body = body
        content.sound = .default
        content.threadIdentifier = thread
        content.userInfo = userInfo
        if let imageBase64, let attachment = Self.attachment(base64: imageBase64) {
            content.attachments = [attachment]
        }
        try? await UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: id, content: content, trigger: nil))
    }

    // Zdjęcie ogłoszenia jako miniatura w powiadomieniu. System przenosi plik do siebie.
    private static func attachment(base64: String) -> UNNotificationAttachment? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
        guard (try? data.write(to: url)) != nil else { return nil }
        return try? UNNotificationAttachment(identifier: "photo", url: url)
    }

    // MARK: - Stan

    private func stateKey(_ userId: String) -> String { "alertNotifier.\(userId)" }

    private func loadState(_ userId: String) -> State {
        if let data = UserDefaults.standard.data(forKey: stateKey(userId)),
           let state = try? JSONDecoder().decode(State.self, from: data) {
            return state
        }
        let fresh = State(baseline: Date())
        saveState(fresh, userId)
        return fresh
    }

    // Przy zapisie sprzątamy wygasłe ogłoszenia; ogłoszenie żyje 48 h, więc wątki starsze
    // niż 3 dni już się nie odezwą
    private func saveState(_ state: State, _ userId: String) {
        var state = state
        let now = Date()
        state.notifiedAlerts = state.notifiedAlerts.filter { $0.value > now }
        state.joinedAlerts = state.joinedAlerts.filter { $0.value > now }
        state.seenThreads = state.seenThreads.filter { $0.value > now.addingTimeInterval(-3 * 24 * 60 * 60) }
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: stateKey(userId))
        }
    }
}
