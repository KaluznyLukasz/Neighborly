//
//  NEISignInView.swift
//  Neighborly
//

import SwiftUI

struct NEISignInView: View {
    @Bindable var vm: NEIAuthViewModel
    let onSwitchToSignUp: () -> Void
    @State private var showForgotPassword = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                NEIAuthHeader(title: "Neighborly", subtitle: "Borrow, share, help nearby.")

                VStack(alignment: .trailing, spacing: 12) {
                    NEIFieldGroup {
                        TextField("Email", text: $vm.email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit { focusedField = .password }

                        SecureField("Password", text: $vm.password)
                            .textContentType(.password)
                            .submitLabel(.go)
                            .focused($focusedField, equals: .password)
                            .onSubmit(signIn)
                    }

                    Button("Forgot password?") {
                        showForgotPassword = true
                    }
                    .font(.footnote)
                }

                if let error = vm.errorMessage {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 16) {
                NEIPrimaryButton("Sign In", isLoading: vm.isLoading, action: signIn)

                Button(action: onSwitchToSignUp) {
                    Text("Don't have an account? \(Text("Sign Up").fontWeight(.semibold).foregroundStyle(.tint))")
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .font(.subheadline)
                .accessibilityInputLabels(["Sign Up", "Don't have an account? Sign Up"])
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .tint(.green)
        .sheet(isPresented: $showForgotPassword) {
            NEIForgotPasswordView(vm: vm)
        }
    }

    private func signIn() {
        focusedField = nil
        Task { await vm.signIn() }
    }
}
