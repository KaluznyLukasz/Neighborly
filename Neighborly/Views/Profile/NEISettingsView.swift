//
//  NEISettingsView.swift
//  Neighborly
//

import SwiftUI
import FirebaseAuth

struct NEISettingsView: View {
    @EnvironmentObject var authService: NEIAuthService
    @Bindable var vm: NEIProfileViewModel
    let userId: String

    @State private var showEditSheet = false
    @State private var showSignOutAlert = false
    @State private var showDeleteAlert = false
    @State private var deleteErrorMessage: String?
    @State private var isDeleting = false

    var body: some View {
        List {
            Section("Account") {
                Button {
                    showEditSheet = true
                } label: {
                    HStack {
                        Label("Edit Profile", systemImage: "pencil")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    if isDeleting {
                        HStack {
                            Text("Deleting Account…")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Label("Delete Account", systemImage: "trash")
                    }
                }
                .disabled(isDeleting)
            }

            Section {
                Button(role: .destructive) {
                    showSignOutAlert = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }

            Section("About") {
                HStack {
                    Text("Neighborly")
                    Spacer()
                    Text("Version \(Bundle.main.appVersionString)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet, onDismiss: {
            Task { await vm.load(userId: userId) }
        }) {
            NEIEditProfileView(
                vm: vm,
                userId: userId,
                currentDisplayName: authService.currentUser?.displayName ?? "",
                currentEmail: authService.currentUser?.email ?? ""
            )
        }
        .alert("Sign out?", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) { authService.signOut() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Account?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and profile. This action cannot be undone.")
        }
        .alert("Couldn't Delete Account", isPresented: .init(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("OK") { deleteErrorMessage = nil }
        } message: {
            Text(deleteErrorMessage ?? "")
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        do {
            try await authService.deleteAccount()
        } catch {
            deleteErrorMessage = "\(error.localizedDescription) You may need to sign in again before deleting your account."
        }
        isDeleting = false
    }
}

private extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
