//
//  NeighborlyApp.swift
//  Neighborly
//
//  Created by Łukasz Kałużny on 11/05/2026.
//

import SwiftUI
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Delegat musi być ustawiony przed końcem startu, inaczej tapnięcie w przypomnienie
        // przy zamkniętej aplikacji przepada
        UNUserNotificationCenter.current().delegate = NEINotificationRouter.shared
        return true
    }
}

@main
struct NeighborlyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = NEIAuthService()

    // Firebase konfigurujemy tutaj, nie w AppDelegate: .backgroundTask sprawia, że SwiftUI buduje
    // scenę (i NEIAuthService z Auth.auth()) przed didFinishLaunching — wtedy aplikacja padała
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
        .backgroundTask(.appRefresh(NEIReminderService.backgroundRefreshId)) {
            await NEIReminderService.refreshInBackground()
        }
    }
}
