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

struct ContentView: View {
    @EnvironmentObject var authService: NEIAuthService
    @State private var transactionVM = NEITransactionViewModel()
    @State private var showSplash = true
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
                TabView {
                    NEIMapView()
                        .tabItem {
                            Label("Map", systemImage: "map.fill")
                        }

                    NEITransactionListView()
                        .tabItem {
                            Label("Activity", systemImage: "tray.fill")
                        }
                        .badge(transactionVM.pendingInboxCount > 0 ? transactionVM.pendingInboxCount : 0)

                    NEIProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle.fill")
                        }

                    NEISearchView()
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                }
                .task {
                    if let uid = authService.currentUser?.uid {
                        await transactionVM.loadInbox(ownerId: uid)
                    }
                }
            } else {
                NEIAuthView(authService: authService)
            }
        }
        .preferredColorScheme(colorScheme)
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.easeInOut, value: authService.isAuthenticated)
        .task {
            let start = Date()
            let authTimeout: TimeInterval = 5
            while authService.isRestoring && Date().timeIntervalSince(start) < authTimeout {
                try? await Task.sleep(for: .milliseconds(50))
            }
            let elapsed = Date().timeIntervalSince(start)
            let remaining = 1.8 - elapsed
            if remaining > 0 { try? await Task.sleep(for: .seconds(remaining)) }
            withAnimation { showSplash = false }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NEIAuthService())
}
