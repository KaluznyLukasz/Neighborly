//
//  NEICreateOfferView.swift
//  Neighborly
//

import SwiftUI
import CoreLocation
import PhotosUI
import MapKit

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

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = Array(completer.results.prefix(5))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}

struct NEICreateOfferView: View {
    let ownerId: String
    let coordinate: CLLocationCoordinate2D
    let onSaved: () -> Void

    @State private var vm = NEIOfferViewModel()
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var completer = AddressCompleter()
    @State private var showSuggestions = false
    @State private var skipNextChange = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    NEIInputField(label: "Title", placeholder: "e.g. Help walking my dog", text: $vm.title)

                    NEIInputField(label: "Description", placeholder: "When, how long, what's needed...", text: $vm.description)

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
                       let image = UIImage(data: data) {
                        vm.selectedImage = image
                    }
                }
            }
        }
    }

    private var addressField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Address")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            TextField("e.g. ul. Marszałkowska 10, Warsaw", text: $vm.address)
                .padding(12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onChange(of: vm.address) { _, value in
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
                            vm.address = full
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
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
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
