//
//  NEIEditProfileView.swift
//  Neighborly
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct NEIEditProfileView: View {
    @Bindable var vm: NEIProfileViewModel
    let userId: String
    @EnvironmentObject private var authService: NEIAuthService

    @State private var displayName: String
    @State private var bio: String
    @State private var email: String
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var avatarPreview: UIImage?
    @State private var photoLoadError: String?
    @State private var isChangingEmail = false
    @State private var showPasswordPrompt = false
    @State private var password = ""
    @State private var pendingEmail: String?
    private let originalEmail: String
    @Environment(\.dismiss) private var dismiss

    init(vm: NEIProfileViewModel, userId: String, currentDisplayName: String = "", currentEmail: String = "") {
        self.vm = vm
        self.userId = userId
        _displayName = State(initialValue: vm.user?.displayName ?? currentDisplayName)
        _bio         = State(initialValue: vm.user?.bio ?? "")
        _email       = State(initialValue: currentEmail)
        originalEmail = currentEmail
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    avatarSection

                    NEIInputField(label: "Display Name", placeholder: "Your name", text: $displayName)
                    NEIInputField(label: "Email", placeholder: "your@email.com", text: $email, keyboardType: .emailAddress)
                        .textInputAutocapitalization(.never)
                    NEIInputField(label: "Bio", placeholder: "Tell neighbors about yourself...", text: $bio)

                    NEIPrimaryButton("Save Changes", isLoading: vm.isSaving || isChangingEmail) {
                        Task { await save() }
                    }
                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: .init(
                get: { vm.errorMessage != nil || photoLoadError != nil },
                set: { if !$0 { vm.errorMessage = nil; photoLoadError = nil } }
            )) {
                Button("OK") { vm.errorMessage = nil; photoLoadError = nil }
            } message: {
                Text(vm.errorMessage ?? photoLoadError ?? "")
            }
            .alert("Enter Your Password", isPresented: $showPasswordPrompt) {
                SecureField("Password", text: $password)
                    .textContentType(.password)
                Button("Continue") { Task { await requestEmailChange(reauthenticating: true) } }
                Button("Cancel", role: .cancel) { password = "" }
            } message: {
                Text("Confirm it's you to change your email.")
            }
            .alert("Check Your Inbox", isPresented: .init(
                get: { pendingEmail != nil },
                set: { if !$0 { pendingEmail = nil } }
            ), presenting: pendingEmail) { _ in
                Button("OK") { dismiss() }
            } message: { address in
                Text("We sent a link to \(address). Your email changes after you tap it, then you'll sign in again.")
            }
            .onChange(of: photosPickerItem) { _, item in
                guard let item else { return }
                Task {
                    do {
                        guard let data = try await item.loadTransferable(type: Data.self) else {
                            photoLoadError = "Could not load image data."
                            return
                        }
                        guard let image = UIImage(data: data) else {
                            photoLoadError = "Could not decode image."
                            return
                        }
                        avatarPreview = image
                        await vm.uploadAvatar(image: image, userId: userId)
                    } catch {
                        photoLoadError = error.localizedDescription
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() async {
        await vm.updateProfile(userId: userId, displayName: displayName, bio: bio)
        guard vm.errorMessage == nil else { return }
        authService.refreshCurrentUser()
        if trimmedEmail.isEmpty || trimmedEmail.caseInsensitiveCompare(originalEmail) == .orderedSame {
            dismiss()
        } else {
            await requestEmailChange(reauthenticating: false)
        }
    }

    private func requestEmailChange(reauthenticating: Bool) async {
        isChangingEmail = true
        defer { isChangingEmail = false }
        do {
            if reauthenticating {
                let entered = password
                password = ""
                try await authService.reauthenticate(password: entered)
            }
            try await authService.requestEmailChange(to: trimmedEmail)
            pendingEmail = trimmedEmail
        } catch {
            switch AuthErrorCode(rawValue: (error as NSError).code) {
            case .requiresRecentLogin: showPasswordPrompt = true
            case .wrongPassword, .invalidCredential: vm.errorMessage = "That password isn't right."
            case .invalidEmail: vm.errorMessage = "That email address isn't valid."
            case .emailAlreadyInUse: vm.errorMessage = "Another account already uses that email."
            default: vm.errorMessage = error.localizedDescription
            }
        }
    }

    private var avatarSection: some View {
        PhotosPicker(selection: $photosPickerItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                if let preview = avatarPreview {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                } else {
                    NEIAvatarView(
                        url: vm.user?.avatarURL,
                        name: vm.user?.displayName ?? "",
                        size: 88,
                        base64: vm.user?.avatarBase64
                    )
                }

                Image(systemName: "camera.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.neiGreen)
                    .background(Color(.systemBackground).clipShape(Circle()))
            }
        }
        .overlay {
            if vm.isSaving {
                ProgressView()
                    .frame(width: 88, height: 88)
                    .background(.regularMaterial.opacity(0.8))
                    .clipShape(Circle())
            }
        }
    }
}
