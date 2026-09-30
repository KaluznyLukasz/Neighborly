//
//  NEICreateOfferView.swift
//  Neighborly
//

import SwiftUI
import CoreLocation
import PhotosUI
import MapKit

@MainActor
@Observable
final class AddressCompleter: NSObject, MKLocalSearchCompleterDelegate {
    var suggestions: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func update(query: String) {
        guard !query.isEmpty else { suggestions = []; return }
        completer.queryFragment = query
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = Array(completer.results.prefix(5))
        Task { @MainActor in self.suggestions = results }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in self.suggestions = [] }
    }
}

struct NEICreateOfferView: View {
    let ownerId: String
    let coordinate: CLLocationCoordinate2D
    let onSaved: () -> Void

    @State private var vm = NEIOfferViewModel()
    @State private var title = ""
    @State private var description = ""
    @State private var address = ""
    @State private var category: OfferCategory = .tools
    @State private var photosPickerItem: PhotosPickerItem?
    // Oryginał zostaje, żeby ponowna edycja zaczynała od pełnego zdjęcia, a nie od wykadrowanego
    @State private var originalImage: UIImage?
    @State private var photoCrop = NEIPhotoCrop()
    @State private var isEditingPhoto = false
    @State private var completer = AddressCompleter()
    @State private var showSuggestions = false
    @State private var skipNextChange = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    NEIInputField(label: "Title", placeholder: "e.g. Help walking my dog", text: $title)

                    NEIInputField(label: "Description", placeholder: "When, how long, what's needed...", text: $description)

                    addressField

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
            .navigationTitle("Post a Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.title = title
                        vm.description = description
                        vm.address = address
                        vm.category = category
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
                if saved { onSaved(); dismiss() }
            }
            .onChange(of: photosPickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let picked = UIImage.neiDownsampled(data: data) {
                        originalImage = picked
                        photoCrop = NEIPhotoCrop()
                        vm.selectedImage = picked
                    }
                }
            }
            .fullScreenCover(isPresented: $isEditingPhoto) {
                if let originalImage {
                    NEIPhotoCropView(image: originalImage, crop: photoCrop) { edited, crop in
                        vm.selectedImage = edited
                        photoCrop = crop
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var addressField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Address")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            TextField("e.g. ul. Marszałkowska 10, Warsaw", text: $address)
                .padding(12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onChange(of: address) { _, value in
                    if skipNextChange { skipNextChange = false; return }
                    completer.update(query: value)
                    showSuggestions = !value.isEmpty
                }

            if showSuggestions && !completer.suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(completer.suggestions, id: \.self) { suggestion in
                        Button {
                            let full = suggestion.subtitle.isEmpty
                                ? suggestion.title
                                : "\(suggestion.title), \(suggestion.subtitle)"
                            skipNextChange = true
                            address = full
                            showSuggestions = false
                            completer.suggestions = []
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        if suggestion !== completer.suggestions.last {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color(.separator).opacity(0.6), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
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
                            category = cat
                        } label: {
                            Label(cat.displayName, systemImage: cat.systemImage)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(category == cat ? Color.green : Color(.systemGray6))
                                .foregroundStyle(category == cat ? .white : .primary)
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

            if let image = vm.selectedImage {
                // Ten sam zestaw akcji co w formularzu alertu, ale w kafelku pasującym do tego ekranu
                VStack(spacing: 0) {
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
                    .accessibilityLabel("Selected photo")
                    .accessibilityHint("Opens the photo editor")

                    Divider()
                    Button("Edit Photo", systemImage: "crop.rotate") {
                        isEditingPhoto = true
                    }
                    .photoActionRow()

                    Divider().padding(.leading, 16)
                    PhotosPicker(selection: $photosPickerItem, matching: .images) {
                        Label("Replace Photo", systemImage: "photo.on.rectangle")
                    }
                    .photoActionRow()

                    Divider().padding(.leading, 16)
                    Button("Remove Photo", systemImage: "trash", role: .destructive) {
                        vm.selectedImage = nil
                        originalImage = nil
                        photosPickerItem = nil
                    }
                    .photoActionRow()
                    .foregroundStyle(.red)
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                PhotosPicker(selection: $photosPickerItem, matching: .images) {
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

private extension View {
    // Wiersz akcji wyglądający jak wiersz w Form (wysokość, wcięcie, pełna szerokość do tapnięcia)
    func photoActionRow() -> some View {
        frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
    }
}
