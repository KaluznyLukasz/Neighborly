//
//  NEIAuthService.swift
//  Neighborly
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

/// `updateEmail(to:)` jest oznaczone jako przestarzałe, bo Firebase woli link weryfikacyjny.
/// Celowo zmieniamy e-mail samym hasłem, więc wołamy je przez ten protokół, żeby każdy
/// build nie sypał ostrzeżeniem. Jeśli SDK usunie metodę, build tu padnie.
private protocol DirectEmailUpdating {
    func updateEmail(to email: String) async throws
}

extension FirebaseAuth.User: DirectEmailUpdating {}

enum EmailChangeResult {
    case changed
    case verificationSent
}

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
                if let user { await self?.removeLegacyProfileEmail(of: user) }
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

    /// Ponowne uwierzytelnienie hasłem — wołane przed `deleteAccount()`, bo Firebase Auth
    /// odmawia usunięcia konta bez świeżego logowania, a dokument w Firestore kasujemy
    /// pierwszy (po nieudanym `user.delete()` zostałoby konto bez profilu).
    func reauthenticate(password: String) async throws {
        guard let user = currentUser, let email = user.email else {
            throw NSError(domain: "NEIAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No signed-in user."])
        }
        try await user.reauthenticate(with: EmailAuthProvider.credential(withEmail: email, password: password))
    }

    /// Usuwa konto uzytkownika: dokument w Firestore, potem konto w Firebase Auth.
    /// Wolac po `reauthenticate(password:)` — bez swiezego zalogowania `user.delete()`
    /// sie nie powiedzie.
    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw NSError(domain: "NEIAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No signed-in user."])
        }
        try await db.collection("users").document(user.uid).delete()
        try await user.delete()
        currentUser = nil
    }

    /// Zmienia e-mail od razu po potwierdzeniu hasłem. Firebase pozwala na to tylko przy
    /// wyłączonej ochronie przed enumeracją e-maili (Authentication → Settings → User actions).
    /// Przy włączonej odrzuca `updateEmail` kodem `.operationNotAllowed` — wtedy wysyłamy link
    /// na nowy adres, a zmiana wchodzi po jego kliknięciu (i unieważnia sesję).
    func changeEmail(to email: String, password: String) async throws -> EmailChangeResult {
        try await reauthenticate(password: password)
        guard let user = currentUser else {
            throw NSError(domain: "NEIAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No signed-in user."])
        }
        do {
            try await (user as any DirectEmailUpdating).updateEmail(to: email)
            currentUser = auth.currentUser
            return .changed
        } catch let error as NSError where AuthErrorCode(rawValue: error.code) == .operationNotAllowed {
            try await user.sendEmailVerification(beforeUpdatingEmail: email)
            return .verificationSent
        }
    }

    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func refreshCurrentUser() {
        currentUser = auth.currentUser
    }

    /// Profil w `users` czyta każdy zalogowany, więc e-mail trzymamy tylko w Firebase Auth.
    /// Starsze dokumenty mają jeszcze pole `email` — właściciel czyści je przy logowaniu.
    /// `updateData` nie tworzy dokumentu, więc nie ściga się z `createUserDocument`.
    private func removeLegacyProfileEmail(of user: FirebaseAuth.User) async {
        try? await db.collection("users").document(user.uid).updateData(["email": FieldValue.delete()])
    }

    private func createUserDocument(user: FirebaseAuth.User, displayName: String) async throws {
        let data: [String: Any] = [
            "id": user.uid,
            "displayName": displayName,
            "rating": 0.0,
            "reviewCount": 0,
            "createdAt": Timestamp(date: Date())
        ]
        try await db.collection("users").document(user.uid).setData(data)
    }
}
