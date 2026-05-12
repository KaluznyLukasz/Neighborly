//
//  ContentView.swift
//  Neighborly
//
//  Created by Łukasz Kałużny on 11/05/2026.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authService: NEIAuthService
    @State private var transactionVM = NEITransactionViewModel()

    var body: some View {
        Group {
            if authService.isAuthenticated {
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
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(NEIAuthService())
}
