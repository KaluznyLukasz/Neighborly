//
//  NEICreateOfferView.swift
//  Neighborly
//

import SwiftUI
import CoreLocation
import PhotosUI

struct NEICreateOfferView: View {
    let ownerId: String
    let coordinate: CLLocationCoordinate2D
    let onSaved: () -> Void

    @State private var vm = NEIOfferViewModel()
    @State private var photosPickerItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    NEIInputField(label: "Title", placeholder: "e.g. Power Drill", text: $vm.title)

                    NEIInputField(label: "Description", placeholder: "Condition, availability...", text: $vm.description)

                    NEIInputField(label: "Address", placeholder: "e.g. ul. Marszałkowska 10, Warsaw", text: $vm.address)

                    categoryPicker

                    imagePicker

                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                }
                .padding(24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("New Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await vm.createOffer(ownerId: ownerId, fallbackCoordinate: coordinate) }
                    } label: {
                        if vm.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Post").fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.neiGreen)
                    .controlSize(.small)
                    .disabled(vm.isLoading)
                }
            }
            .onChange(of: vm.didSave) { _, saved in
                if saved {
                    onSaved()
                    dismiss()
                }
            }
            .onChange(of: photosPickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        vm.selectedImage = image
                    }
                }
            }
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Category")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(OfferCategory.allCases) { cat in
                        Button {
                            vm.category = cat
                        } label: {
                            Label(cat.displayName, systemImage: cat.systemImage)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(vm.category == cat ? Color.green : Color(.systemGray6))
                                .foregroundStyle(vm.category == cat ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var imagePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Photo (optional)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                if let image = vm.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                        VStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("Add Photo")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
