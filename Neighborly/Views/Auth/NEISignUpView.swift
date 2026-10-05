//
//  NEISignUpView.swift
//  Neighborly
//

import SwiftUI

struct NEISignUpView: View {
    @Bindable var vm: NEIAuthViewModel
    let onSwitchToSignIn: () -> Void
    @FocusState private var focusedField: Field?

    private enum Field {
        case name, email, password, confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                NEIAuthHeader(title: "Create Account", subtitle: "Join your neighborhood today.")

                VStack(alignment: .leading, spacing: 8) {
                    NEIFieldGroup {
                        TextField("Full Name", text: $vm.displayName)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .name)
                            .onSubmit { focusedField = .email }

                        TextField("Email", text: $vm.email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit { focusedField = .password }

                        SecureField("Password", text: $vm.password)
                            .textContentType(.newPassword)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .password)
                            .onSubmit { focusedField = .confirmPassword }

                        SecureField("Confirm Password", text: $vm.confirmPassword)
                            .textContentType(.newPassword)
                            .submitLabel(.go)
                            .focused($focusedField, equals: .confirmPassword)
                            .onSubmit(signUp)
                    }

                    Text("Use at least 6 characters.")
                        .font(.footnote)
                        .foregroundStyle(Color(.secondaryLabel))
                        .padding(.horizontal, 16)
                }

                VStack(alignment: .leading, spacing: 8) {
                    NEIFieldGroup {
                        Toggle("I'm \(NEILegal.minimumAge) or older and agree to the Terms of Use.", isOn: $vm.acceptedTerms)
                    }

                    Text(legalLinks)
                        .font(.footnote)
                        .foregroundStyle(Color(.secondaryLabel))
                        .padding(.horizontal, 16)
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
                NEIPrimaryButton("Create Account", isLoading: vm.isLoading, action: signUp)

                Button(action: onSwitchToSignIn) {
                    Text("Already have an account? \(Text("Sign In").fontWeight(.semibold).foregroundStyle(.tint))")
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .font(.subheadline)
                .accessibilityInputLabels(["Sign In", "Already have an account? Sign In"])
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .tint(.green)
    }

    // Linki osobno pod przełącznikiem — w etykiecie Toggle VoiceOver ich nie udostępnia
    private var legalLinks: AttributedString {
        let markdown = "Read the [Terms of Use](\(NEILegal.termsURL.absoluteString)) and [Privacy Policy](\(NEILegal.privacyPolicyURL.absoluteString))."
        return (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }

    private func signUp() {
        focusedField = nil
        Task { await vm.signUp() }
    }
}
