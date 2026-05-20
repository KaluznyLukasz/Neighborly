//
//  NEIAuthService.swift
//  Neighborly
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class NEIAuthService: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?
    @Published var isRestoring = true

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        authStateHandle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isRestoring = false
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }

    var isAuthenticated: Bool { currentUser != nil }

    func signUp(email: String, password: String, displayName: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        currentUser = auth.currentUser
        try await createUserDocument(user: result.user, displayName: displayName)
    }

    func signIn(email: String, password: String) async throws {
        let result = try await auth.signIn(withEmail: email, password: password)
        currentUser = result.user
    }

    func signOut() {
        try? auth.signOut()
        currentUser = nil
    }

    func refreshCurrentUser() {
        currentUser = auth.currentUser
    }

    private func createUserDocument(user: FirebaseAuth.User, displayName: String) async throws {
        let data: [String: Any] = [
            "id": user.uid,
            "displayName": displayName,
            "email": user.email ?? "",
            "rating": 0.0,
            "reviewCount": 0,
            "createdAt": Timestamp(date: Date())
        ]
        try await db.collection("users").document(user.uid).setData(data)
    }
}
