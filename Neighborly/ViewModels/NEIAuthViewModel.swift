//
//  NEIAuthViewModel.swift
//  Neighborly
//

import Foundation

@MainActor
@Observable
final class NEIAuthViewModel {
    var email = ""
    var password = ""
    var displayName = ""
    var confirmPassword = ""

    var isLoading = false
    var errorMessage: String?

    var resetEmail = ""
    var resetIsLoading = false
    var resetErrorMessage: String?
    var resetSuccessMessage: String?

    private let authService: NEIAuthService

    init(authService: NEIAuthService) {
        self.authService = authService
    }

    func signIn() async {
        guard validate(mode: .signIn) else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp() async {
        guard validate(mode: .signUp) else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await authService.signUp(email: email, password: password, displayName: displayName)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        try? authService.signOut()
    }

    func sendPasswordReset() async {
        resetErrorMessage = nil
        resetSuccessMessage = nil
        if resetEmail.trimmingCharacters(in: .whitespaces).isEmpty {
            resetErrorMessage = "Enter email."
            return
        }
        resetIsLoading = true
        do {
            try await authService.sendPasswordReset(email: resetEmail)
            resetSuccessMessage = "Password reset email sent. Check your inbox."
        } catch {
            resetErrorMessage = error.localizedDescription
        }
        resetIsLoading = false
    }

    private enum Mode { case signIn, signUp }

    private func validate(mode: Mode) -> Bool {
        errorMessage = nil
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Enter email."
            return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            return false
        }
        if mode == .signUp {
            if displayName.trimmingCharacters(in: .whitespaces).isEmpty {
                errorMessage = "Enter your name."
                return false
            }
            if password != confirmPassword {
                errorMessage = "Passwords don't match."
                return false
            }
        }
        return true
    }
}
