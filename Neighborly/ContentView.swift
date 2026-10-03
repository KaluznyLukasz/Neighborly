//
//  ContentView.swift
//  Neighborly
//
//  Created by Łukasz Kałużny on 11/05/2026.
//

import SwiftUI
import FirebaseAuth

struct NEISplashView: View {
    @State private var scale: CGFloat = 0.4
    @State private var opacity: CGFloat = 0

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Image("NeighborlyIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                    .scaleEffect(scale)
                    .opacity(opacity)
                ProgressView()
                    .scaleEffect(1.2)
                    .opacity(opacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

enum NEITab: Hashable {
    case map, activity, profile, search
}

struct ContentView: View {
    @EnvironmentObject var authService: NEIAuthService
    @Environment(\.scenePhase) private var scenePhase
    @State private var transactionVM = NEITransactionViewModel()
    @State private var locationManager = LocationManager()
    @State private var showSplash = true
    @State private var selectedTab: NEITab = .map
    @State private var wasInBackground = false
    private let notificationRouter = NEINotificationRouter.shared
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        Group {
            if showSplash {
                NEISplashView()
                    .transition(.opacity)
            } else if authService.isAuthenticated {
                TabView(selection: $selectedTab) {
                    NEIMapView()
                        .tabItem {
                            Label("Map", systemImage: "map.fill")
                        }
                        .tag(NEITab.map)

                    NEITransactionListView(vm: transactionVM)
                        .tabItem {
                            Label("Activity", systemImage: "tray.fill")
                        }
                        .badge(transactionVM.pendingInboxCount > 0 ? transactionVM.pendingInboxCount : 0)
                        .tag(NEITab.activity)

                    NEIProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle.fill")
                        }
                        .tag(NEITab.profile)

                    NEISearchView()
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .tag(NEITab.search)
                }
                .environment(locationManager)
                .task {
                    if let uid = authService.currentUser?.uid { NEIAlertNotifier.shared.start(userId: uid) }
                    await loadTransactions()
                }
                // Po powrocie z tła: świeży badge i przypomnienia z terminami ustawionymi w międzyczasie
                // (z tła aplikacja przechodzi przez .inactive, więc pamiętamy, że była w tle)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background {
                        wasInBackground = true
                        NEIReminderService.scheduleBackgroundRefresh()
                    } else if phase == .active && wasInBackground {
                        wasInBackground = false
                        Task { await loadTransactions() }
                    }
                }
                // Tapnięte przypomnienie otwiera Activity; szczegóły otwiera już lista
                .onChange(of: notificationRouter.pendingTransactionId, initial: true) { _, id in
                    if id != nil { selectedTab = .activity }
                }
                // Ogłoszenia są na mapie (dzwonek) — tam otwiera się arkusz z ogłoszeniem
                .onChange(of: notificationRouter.pendingAlert, initial: true) { _, route in
                    if route != nil { selectedTab = .map }
                }
            } else {
                NEIAuthView(authService: authService)
            }
        }
        .preferredColorScheme(colorScheme)
        // Tapnięty widżet: te same ścieżki co tapnięte powiadomienie. Przy starcie od zera
        // router czeka, aż pojawi się TabView (onChange z initial: true).
        .onOpenURL { url in
            guard let link = NEIWidgetLink(url: url) else { return }
            switch link {
            case .activity: selectedTab = .activity
            case .transaction(let id): notificationRouter.pendingTransactionId = id
            case .alerts: notificationRouter.pendingAlert = NEIAlertRoute(alertId: "", viewerId: nil)
            case .alert(let id): notificationRouter.pendingAlert = NEIAlertRoute(alertId: id, viewerId: nil)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.easeInOut, value: authService.isAuthenticated)
        // Przypomnienia są lokalne — po wylogowaniu nie mogą przyjść następnej osobie na tym telefonie
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated {
                selectedTab = .map
                // Nowy view model: listy i badge poprzedniego konta nie przechodzą na następne
                transactionVM = NEITransactionViewModel()
                NEIAlertNotifier.shared.signOut()
                NEIWidgetSync.clear()
                Task { await NEIReminderService.cancelAll() }
            }
        }
        .task {
            let start = Date()
            let authTimeout: TimeInterval = 5
            while authService.isRestoring && Date().timeIntervalSince(start) < authTimeout {
                try? await Task.sleep(for: .milliseconds(50))
            }
            let elapsed = Date().timeIntervalSince(start)
            let remaining = 0.6 - elapsed
            if remaining > 0 { try? await Task.sleep(for: .seconds(remaining)) }
            withAnimation { showSplash = false }
        }
    }

    private func loadTransactions() async {
        guard let uid = authService.currentUser?.uid else { return }
        async let inbox: () = transactionVM.loadInbox(ownerId: uid)
        async let requests: () = transactionVM.loadMyRequests(requesterId: uid)
        _ = await (inbox, requests)
    }
}

#Preview {
    ContentView()
        .environmentObject(NEIAuthService())
}
