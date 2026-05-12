//
//  NEIEditProfileView.swift
//  Neighborly
//

import SwiftUI
import PhotosUI

struct NEIEditProfileView: View {
    @Bindable var vm: NEIProfileViewModel
    let userId: String

    @State private var displayName: String
    @State private var bio: String
    @State private var photosPickerItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    init(vm: NEIProfileViewModel, userId: String) {
        self.vm = vm
        self.userId = userId
        _displayName = State(initialValue: vm.user?.displayName ?? "")
        _bio         = State(initialValue: vm.user?.bio ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    avatarSection
                    NEIInputField(label: "Display Name", placeholder: "Your name", text: $displayName)
                    NEIInputField(label: "Bio", placeholder: "Tell neighbors about yourself...", text: $bio)

                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    NEIPrimaryButton("Save Changes", isLoading: vm.isSaving) {
                        Task {
                            await vm.updateProfile(displayName: displayName, bio: bio)
                            if vm.errorMessage == nil { dismiss() }
                        }
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
            .onChange(of: photosPickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await vm.uploadAvatar(image: image, userId: userId)
                    }
                }
            }
        }
    }

    private var avatarSection: some View {
        PhotosPicker(selection: $photosPickerItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                NEIAvatarView(url: vm.user?.avatarURL, name: vm.user?.displayName ?? "", size: 88)

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
