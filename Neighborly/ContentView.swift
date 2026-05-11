//
//  ContentView.swift
//  Neighborly
//
//  Created by Łukasz on 11/05/2026.
//

import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Neighborly Project")
            
            Button("Test Firestore") {
                let db = Firestore.firestore()
                db.collection("test").addDocument(data: ["status": "działa!"]) { error in
                    if let error = error {
                        print("Błąd: \(error.localizedDescription)")
                    } else {
                        print("Sukces! Firebase połączony.")
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
