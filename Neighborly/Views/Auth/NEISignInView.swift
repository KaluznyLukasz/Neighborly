//
//  NEISignInView.swift
//  Neighborly
//

import SwiftUI

struct NEISignInView: View {
    @Bindable var vm: NEIAuthViewModel
    let onSwitchToSignUp: () -> Void
    @State private var showForgotPassword = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                VStack(spacing: 16) {
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
                        placeholder: "••••••••",
                        text: $vm.password,
                        isSecure: true
                    )

                    Button("Forgot password?") {
                        showForgotPassword = true
                    }
                    .font(.caption)
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                NEIPrimaryButton("Sign In", isLoading: vm.isLoading) {
                    Task { await vm.signIn() }
                }

                Button("Don't have an account? Sign Up") {
                    onSwitchToSignUp()
                }
                .font(.subheadline)
                .foregroundStyle(.green)
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showForgotPassword) {
            NEIForgotPasswordView(vm: vm)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "house.and.flag.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Neighborly")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Borrow, share, help nearby.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 40)
    }
}
