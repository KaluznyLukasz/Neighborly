//
//  NEISignUpView.swift
//  Neighborly
//

import SwiftUI

struct NEISignUpView: View {
    @Bindable var vm: NEIAuthViewModel
    let onSwitchToSignIn: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                VStack(spacing: 16) {
                    NEIInputField(
                        label: "Full Name",
                        placeholder: "Jan Kowalski",
                        text: $vm.displayName
                    )

                    NEIInputField(
                        label: "Email",
                        placeholder: "you@example.com",
                        text: $vm.email,
                        keyboardType: .emailAddress
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    NEIInputField(
                        label: "Password",
                        placeholder: "Min. 6 characters",
                        text: $vm.password,
                        isSecure: true
                    )

                    NEIInputField(
                        label: "Confirm Password",
                        placeholder: "••••••••",
                        text: $vm.confirmPassword,
                        isSecure: true
                    )
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                NEIPrimaryButton("Create Account", isLoading: vm.isLoading) {
                    Task { await vm.signUp() }
                }

                Button("Already have an account? Sign In") {
                    onSwitchToSignIn()
                }
                .font(.subheadline)
                .foregroundStyle(.green)
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "house.and.flag.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Join your neighborhood today.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 40)
    }
}
