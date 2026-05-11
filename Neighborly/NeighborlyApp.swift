//
//  NeighborlyApp.swift
//  Neighborly
//
//  Created by Łukasz on 11/05/2026.
//

import SwiftUI
import FirebaseCore

// 1. Tworzymy delegata, który zainicjuje Firebase przy starcie
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct NeighborlyApp: App {
  // 2. Łączymy delegata z cyklem życia SwiftUI
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
