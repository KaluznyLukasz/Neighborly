//
//  NEICreateAlertView.swift
//  Neighborly
//

import SwiftUI
import FirebaseAuth
import PhotosUI

struct NEICreateAlertView: View {
    let vm: NEIAlertViewModel
    let onPosted: () async -> Void

    @EnvironmentObject var authService: NEIAuthService
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss

    @State private var kind: AlertKind = .general
    @State private var title = ""
    @State private var details = ""
    @State private var isPosting = false
    @State private var photoItem: PhotosPickerItem?
    // Oryginał zostaje, żeby ponowna edycja zaczynała od pełnego zdjęcia, a nie od wykadrowanego
    @State private var originalImage: UIImage?
    @State private var photoCrop = NEIPhotoCrop()
    @State private var image: UIImage?
    @State private var isEditingPhoto = false

    private var canPost: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isPosting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(AlertKind.allCases) { kind in
                            Label(kind.displayName, systemImage: kind.systemImage).tag(kind)
                        }
                    }
                }

                Section {
                    TextField("Title", text: $title)
                        .onChange(of: title) { _, new in
                            if new.count > NeighborhoodAlert.maxTitleLength {
                                title = String(new.prefix(NeighborhoodAlert.maxTitleLength))
                            }
                        }
                    TextField("Details (optional)", text: $details, axis: .vertical)
                        .lineLimit(3...8)
                        .onChange(of: details) { _, new in
                            if new.count > NeighborhoodAlert.maxDetailsLength {
                                details = String(new.prefix(NeighborhoodAlert.maxDetailsLength))
                            }
                        }
                }

                Section {
                    if let image {
                        Button {
                            isEditingPhoto = true
                        } label: {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 260)
                                .background(.fill.tertiary)
                                .accessibilityIgnoresInvertColors()
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                        .accessibilityLabel("Selected photo")
                        .accessibilityHint("Opens the photo editor")

                        Button("Edit Photo", systemImage: "crop.rotate") {
                            isEditingPhoto = true
                        }
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("Replace Photo", systemImage: "photo.on.rectangle")
                        }
                        Button("Remove Photo", systemImage: "trash", role: .destructive) {
                            self.image = nil
                            originalImage = nil
                            photoItem = nil
                        }
                        // W Form rola .destructive barwi tylko tekst — ikona zostaje w kolorze akcentu
                        .foregroundStyle(.red)
                    } else {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("Add Photo", systemImage: "camera.fill")
                        }
                    }
                } footer: {
                    Text("Neighbors within their search radius see this for 48 hours. Don't share phone numbers or exact addresses publicly.")
                }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let picked = UIImage.neiDownsampled(data: data) {
                        originalImage = picked
                        photoCrop = NEIPhotoCrop()
                        image = picked
                    }
                }
            }
            .fullScreenCover(isPresented: $isEditingPhoto) {
                if let originalImage {
                    NEIPhotoCropView(image: originalImage, crop: photoCrop) { edited, crop in
                        image = edited
                        photoCrop = crop
                    }
                }
            }
            .navigationTitle("New Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isPosting {
                        ProgressView()
                    } else {
                        Button("Post") { Task { await post() } }
                            .disabled(!canPost)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func post() async {
        guard let user = authService.currentUser, let coordinate = locationManager.userCoordinate else { return }
        isPosting = true
        let ok = await vm.post(
            kind: kind,
            title: title,
            details: details,
            image: image,
            author: (user.uid, user.displayName ?? "Neighbor"),
            at: coordinate
        )
        isPosting = false
        if ok {
            dismiss()
            await onPosted()
        }
    }
}
