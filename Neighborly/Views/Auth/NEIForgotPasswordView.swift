//
//  NEIForgotPasswordView.swift
//  Neighborly
//

import SwiftUI

struct NEIForgotPasswordView: View {
    @Bindable var vm: NEIAuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                        Text("Reset your password")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Enter your email and we'll send you a reset link.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    NEIInputField(
                        label: "Email",
                        placeholder: "you@example.com",
                        text: $vm.resetEmail,
                        keyboardType: .emailAddress
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    NEIPrimaryButton("Send Reset Link", isLoading: vm.resetIsLoading) {
                        Task { await vm.sendPasswordReset() }
                    }

                    if let success = vm.resetSuccessMessage {
                        Text(success)
                            .font(.caption)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if let error = vm.resetErrorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
