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
    @State private var image: UIImage?

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
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .listRowInsets(EdgeInsets())
                            .accessibilityLabel("Selected photo")
                        Button("Remove Photo", role: .destructive) {
                            self.image = nil
                            photoItem = nil
                        }
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
                       let picked = UIImage(data: data) {
                        image = picked
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
