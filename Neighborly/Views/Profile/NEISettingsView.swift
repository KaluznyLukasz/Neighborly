//
//  NEISettingsView.swift
//  Neighborly
//

import SwiftUI
import FirebaseAuth
import UserNotifications

struct NEISettingsView: View {
    @EnvironmentObject var authService: NEIAuthService
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Bindable var vm: NEIProfileViewModel
    let userId: String

    @State private var showEditSheet = false
    @State private var showSignOutAlert = false
    @State private var showPasswordResetAlert = false
    @State private var showDeleteAlert = false
    @State private var deletePassword = ""
    @State private var isDeleting = false
    @State private var notice: Notice?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var searchRadiusKm: Double = NEIUserPreferences.searchRadiusKm
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    @AppStorage(NEIUserPreferences.remindersKey) private var remindersOn = true
    @AppStorage(NEIUserPreferences.nearbyAlertsKey) private var nearbyAlertsOn = true
    @AppStorage(NEIUserPreferences.alertRepliesKey) private var alertRepliesOn = true

    private let radiusOptions: [Double] = [1, 3, 5, 10, 25, 50, 100, NEIUserPreferences.unlimitedRadiusKm]

    private struct Notice {
        let title: String
        let message: String
    }

    var body: some View {
        List {
            profileSection
            neighborhoodSection
            notificationsSection
            appearanceSection
            safetySection
            accountSection
            deleteSection
            aboutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshNotificationStatus() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshNotificationStatus() } }
        }
        .onChange(of: searchRadiusKm) { _, newValue in
            NEIUserPreferences.searchRadiusKm = newValue
            NEIWidgetSync.refreshAlerts()
        }
        .onChange(of: remindersOn) { _, enabled in
            Task { await applyReminderPreference(enabled) }
        }
        .onChange(of: nearbyAlertsOn) { _, enabled in
            if enabled { Task { await askForNotifications() } }
        }
        .onChange(of: alertRepliesOn) { _, enabled in
            if enabled { Task { await askForNotifications() } }
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
        .alert("Reset password?", isPresented: $showPasswordResetAlert) {
            Button("Send Link") { Task { await sendPasswordReset() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("We'll email a reset link to \(accountEmail).")
        }
        .alert("Delete Account?", isPresented: $showDeleteAlert) {
            SecureField("Password", text: $deletePassword)
                .textContentType(.password)
            Button("Delete", role: .destructive) { Task { await deleteAccount() } }
            Button("Cancel", role: .cancel) { deletePassword = "" }
        } message: {
            Text("This permanently deletes your account and profile. Enter your password to confirm.")
        }
        .alert(notice?.title ?? "", isPresented: .init(
            get: { notice != nil },
            set: { if !$0 { notice = nil } }
        ), presenting: notice) { _ in
            Button("OK") {}
        } message: { notice in
            Text(notice.message)
        }
    }

    // MARK: - Sekcje

    private var profileSection: some View {
        Section {
            Button {
                showEditSheet = true
            } label: {
                profileHeader
            }
            .accessibilityHint("Opens the profile editor")
        }
    }

    // Przy rozmiarach dostępności awatar ląduje nad tekstem — obok zostałby wąski pasek
    private var profileHeader: some View {
        let avatar = NEIAvatarView(
            url: vm.user?.avatarURL,
            name: displayName,
            size: 60,
            base64: vm.user?.avatarBase64
        )
        .accessibilityHidden(true)

        let names = VStack(alignment: .leading, spacing: 2) {
            Text(displayName)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.label))
            Text(accountEmail)
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
        }

        return Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    avatar
                    names
                }
            } else {
                HStack(spacing: 14) {
                    avatar
                    names
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var neighborhoodSection: some View {
        Section {
            Picker(selection: $searchRadiusKm) {
                ForEach(radiusOptions, id: \.self) { km in
                    Text(radiusText(km)).tag(km)
                }
            } label: {
                NEISettingsLabel(title: "Search Radius", systemImage: "mappin.and.ellipse", tint: Color.neiAmber)
            }
            .pickerStyle(.menu)
            .accessibilityValue(searchRadiusKm.isInfinite ? "Any distance" : "\(Int(searchRadiusKm)) kilometers")

            systemSettingRow(
                title: "Location Access",
                systemImage: "location.fill",
                tint: .blue,
                value: locationIsOn ? "On" : "Off"
            ) {
                if locationManager.authorizationStatus == .notDetermined {
                    locationManager.requestPermission()
                } else {
                    openURL(URL(string: UIApplication.openSettingsURLString)!)
                }
            }
        } header: {
            Text("Neighborhood")
        } footer: {
            Text("The map, search and neighborhood alerts show what's within this distance of you.")
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $remindersOn) {
                NEISettingsLabel(title: "Reminders", systemImage: "alarm.fill", tint: Color.neiGreen)
            }

            Toggle(isOn: $nearbyAlertsOn) {
                NEISettingsLabel(title: "Nearby Alerts", systemImage: "megaphone.fill", tint: Color.neiAmber)
            }

            Toggle(isOn: $alertRepliesOn) {
                NEISettingsLabel(title: "Alert Replies", systemImage: "bubble.left.and.bubble.right.fill", tint: Color.neiBlue)
            }

            systemSettingRow(
                title: "Notifications",
                systemImage: "bell.badge.fill",
                tint: Color.neiRed,
                value: notificationsAreOn ? "On" : "Off"
            ) {
                if notificationStatus == .notDetermined {
                    Task {
                        _ = await NEIReminderService.requestAuthorization()
                        await refreshNotificationStatus()
                    }
                } else {
                    openURL(URL(string: UIApplication.openNotificationSettingsURLString)!)
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text(remindersFooter)
        }
    }

    private var appearanceSection: some View {
        Section {
            Picker(selection: $appearanceMode) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            } label: {
                NEISettingsLabel(title: "Appearance", systemImage: "circle.righthalf.filled", tint: .indigo)
            }
            .pickerStyle(.menu)
        }
    }

    private var safetySection: some View {
        Section("Privacy & Safety") {
            NavigationLink {
                NEIBlockedUsersView(currentUserId: userId)
            } label: {
                NEISettingsLabel(title: "Blocked Users", systemImage: "person.fill.xmark", tint: Color.neiRed)
            }

            NavigationLink {
                NEIGuidelinesView()
            } label: {
                NEISettingsLabel(title: "Community Guidelines", systemImage: "hand.raised.fill", tint: Color(.systemGray))
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            Button {
                showPasswordResetAlert = true
            } label: {
                NEISettingsLabel(title: "Change Password", systemImage: "key.fill", tint: Color(.systemGray))
                    .contentShape(Rectangle())
            }
            .disabled(accountEmail.isEmpty)

            Button("Sign Out", role: .destructive) {
                showSignOutAlert = true
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    Text("Delete Account")
                    Spacer()
                    if isDeleting { ProgressView() }
                }
            }
            .disabled(isDeleting)
        } footer: {
            Text("Permanently deletes your account and profile. This can't be undone.")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: Bundle.main.appVersionString)
        }
    }

    // MARK: - Wiersz otwierający ustawienia systemowe

    private func systemSettingRow(
        title: String,
        systemImage: String,
        tint: Color,
        value: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                NEISettingsLabel(title: title, systemImage: systemImage, tint: tint)
                Spacer()
                Text(value)
                    .foregroundStyle(Color(.secondaryLabel))
                Image(systemName: "arrow.up.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
    }

    // MARK: - Dane pochodne

    private var displayName: String {
        vm.user?.displayName ?? authService.currentUser?.displayName ?? ""
    }

    // E-mail żyje tylko w Firebase Auth — dokument profilu jest publiczny
    private var accountEmail: String {
        authService.currentUser?.email ?? ""
    }

    private var locationIsOn: Bool {
        locationManager.authorizationStatus == .authorizedWhenInUse
            || locationManager.authorizationStatus == .authorizedAlways
    }

    private var notificationsAreOn: Bool {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: true
        default: false
        }
    }

    private var remindersFooter: String {
        if (remindersOn || nearbyAlertsOn || alertRepliesOn) && notificationStatus == .denied {
            return "Notifications are off for Neighborly. Turn them on in Settings to get reminders and alerts."
        }
        return "Reminders come the evening before a return date or planned day, and again on the day. "
            + "Nearby alerts cover your search radius, up to 25 km. "
            + "When Neighborly is closed, alerts and replies may arrive a little late."
    }

    private func radiusText(_ km: Double) -> String {
        km.isInfinite ? "Any distance" : "\(Int(km)) km"
    }

    // MARK: - Akcje

    private func refreshNotificationStatus() async {
        notificationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private func askForNotifications() async {
        await NEIReminderService.requestAuthorizationIfNeeded(enabled: true)
        await refreshNotificationStatus()
    }

    private func applyReminderPreference(_ enabled: Bool) async {
        if enabled {
            _ = await NEIReminderService.requestAuthorization()
            await NEIReminderService.resync(userId: userId)
        } else {
            await NEIReminderService.cancelAll()
        }
        await refreshNotificationStatus()
    }

    private func sendPasswordReset() async {
        let email = accountEmail
        do {
            try await authService.sendPasswordReset(email: email)
            notice = Notice(title: "Check Your Email", message: "We sent a reset link to \(email).")
        } catch {
            notice = Notice(title: "Couldn't Send Link", message: error.localizedDescription)
        }
    }

    private func deleteAccount() async {
        let password = deletePassword
        deletePassword = ""
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await authService.reauthenticate(password: password)
            try await authService.deleteAccount()
        } catch {
            notice = Notice(title: "Couldn't Delete Account", message: deleteErrorMessage(for: error))
        }
    }

    private func deleteErrorMessage(for error: Error) -> String {
        switch AuthErrorCode(rawValue: (error as NSError).code) {
        case .wrongPassword, .invalidCredential: "That password isn't right."
        default: error.localizedDescription
        }
    }
}

private extension Bundle {
    var appVersionString: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
