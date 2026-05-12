//
//  ContentView.swift
//  Neighborly
//
//  Created by Łukasz Kałużny on 11/05/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: NEIAuthService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                NEIMapView()
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
