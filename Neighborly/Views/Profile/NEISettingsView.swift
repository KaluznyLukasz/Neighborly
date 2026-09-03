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
    @State private var searchRadiusKm: Double = NEIUserPreferences.searchRadiusKm
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    private let radiusOptions: [Double] = [5, 10, 25, 50, 100]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                accountCard
                preferencesCard
                signOutButton
                aboutFooter
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: searchRadiusKm) { _, newValue in
            NEIUserPreferences.searchRadiusKm = newValue
        }
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

    private var accountCard: some View {
        NEISectionCard(title: "Account") {
            Button {
                showEditSheet = true
            } label: {
                NEISettingsRow(title: "Edit Profile", systemImage: "pencil", iconColor: Color.neiGreen, iconBackground: Color.neiGreenLight)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 52)

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                NEISettingsRow(
                    title: "Delete Account",
                    systemImage: "trash",
                    iconColor: Color.neiRed,
                    iconBackground: Color.neiRed.opacity(0.15),
                    showChevron: false
                ) {
                    if isDeleting { ProgressView() }
                }
                .foregroundStyle(Color.neiRed)
            }
            .buttonStyle(.plain)
            .disabled(isDeleting)
        }
    }

    private var preferencesCard: some View {
        NEISectionCard(title: "Preferences") {
            NEISettingsRow(
                title: "Search Radius",
                systemImage: "location.circle.fill",
                iconColor: Color.neiAmber,
                iconBackground: Color.neiAmberLight,
                showChevron: false
            ) {
                Picker("", selection: $searchRadiusKm) {
                    ForEach(radiusOptions, id: \.self) { km in
                        Text("\(Int(km)) km").tag(km)
                    }
                }
                .pickerStyle(.menu)
                .tint(.secondary)
            }

            Divider().padding(.leading, 52)

            NEISettingsRow(
                title: "Appearance",
                systemImage: "circle.righthalf.filled",
                iconColor: Color.neiAmber,
                iconBackground: Color.neiAmberLight,
                showChevron: false
            ) {
                Picker("", selection: $appearanceMode) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.menu)
                .tint(.secondary)
            }

            Divider().padding(.leading, 52)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                NEISettingsRow(
                    title: "Notifications",
                    systemImage: "bell.fill",
                    iconColor: Color.neiGreen,
                    iconBackground: Color.neiGreenLight
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            showSignOutAlert = true
        } label: {
            Text("Sign Out")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.neiRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(.separator).opacity(0.6), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private var aboutFooter: some View {
        Text("Neighborly · Version \(Bundle.main.appVersionString)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
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
