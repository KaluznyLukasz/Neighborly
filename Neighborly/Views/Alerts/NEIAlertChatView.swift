//
//  NEIAlertChatView.swift
//  Neighborly
//

import SwiftUI
import FirebaseAuth

// Do otwarcia rozmowy przy ogłoszeniu z NavigationPath (np. po tapnięciu w powiadomienie)
struct NEIAlertChatRoute: Hashable {
    let alert: NeighborhoodAlert
    let viewerId: String
    let viewerName: String
    let title: String
}

// Rozmowa sąsiada (viewerId = ID wątku) z autorem ogłoszenia — ten sam widok po obu stronach.
// Po wysłaniu zapisuje podgląd wątku z nadawcą (powiadomienie dostaje tylko druga strona).
// Gdy pisze sąsiad, notifier zaczyna czekać na odpowiedź autora. Otwarta rozmowa nie
// generuje powiadomień.
struct NEIAlertChatView: View {
    let route: NEIAlertChatRoute

    @EnvironmentObject var authService: NEIAuthService
    private let alertService = NEIAlertService()

    private var uid: String { authService.currentUser?.uid ?? "" }
    private var userName: String { authService.currentUser?.displayName ?? "Neighbor" }
    private var alertId: String { route.alert.id ?? "" }
    private var path: String { NEIMessageService.path(alertId: alertId, viewerId: route.viewerId) }

    var body: some View {
        NEIChatView(
            title: route.title,
            conversationPath: path,
            currentUserId: uid,
            currentUserName: userName
        ) { text in
            try? await alertService.upsertThread(
                alertId: alertId,
                viewerId: route.viewerId,
                viewerName: route.viewerName,
                lastMessage: text,
                senderId: uid
            )
            if uid == route.viewerId {
                NEIAlertNotifier.shared.didMessageAuthor(of: route.alert)
            }
            // Po pierwszej wiadomości widać, po co zgoda: żeby dowiedzieć się o odpowiedzi
            await NEIReminderService.requestAuthorizationIfNeeded(enabled: NEIUserPreferences.alertRepliesEnabled)
        }
        .onAppear { NEINotificationRouter.shared.visibleConversationPath = path }
        .onDisappear {
            if NEINotificationRouter.shared.visibleConversationPath == path {
                NEINotificationRouter.shared.visibleConversationPath = nil
            }
        }
    }
}

extension NEIAlertChatRoute {
    // Sąsiad pisze do autora
    static func toAuthor(of alert: NeighborhoodAlert, userId: String, userName: String) -> NEIAlertChatRoute {
        NEIAlertChatRoute(alert: alert, viewerId: userId, viewerName: userName, title: alert.authorName)
    }

    // Autor odpowiada sąsiadowi
    static func toViewer(of alert: NeighborhoodAlert, thread: AlertThread) -> NEIAlertChatRoute {
        NEIAlertChatRoute(alert: alert, viewerId: thread.id ?? "", viewerName: thread.viewerName, title: thread.viewerName)
    }
}
