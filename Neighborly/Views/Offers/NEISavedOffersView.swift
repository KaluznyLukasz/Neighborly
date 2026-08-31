//
//  NEISavedOffersView.swift
//  Neighborly
//

import SwiftUI

struct NEISavedOffersView: View {
    let currentUserId: String
    let currentUserName: String

    @State private var vm = NEIFavoriteViewModel()
    @State private var selectedOffer: Offer?

    var body: some View {
        Group {
            if vm.isLoading && vm.savedOffers.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.savedOffers.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Saved")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .init(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .task { await vm.loadSavedOffers(userId: currentUserId) }
        .sheet(item: $selectedOffer, onDismiss: {
            Task { await vm.loadSavedOffers(userId: currentUserId) }
        }) { offer in
            NEIOfferDetailView(
                offer: offer,
                currentUserId: currentUserId,
                currentUserName: currentUserName,
                onDelete: nil
            )
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Text("^[\(vm.savedOffers.count) offer](inflect: true) saved")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)

                ForEach(vm.savedOffers) { offer in
                    Button {
                        selectedOffer = offer
                    } label: {
                        SavedOfferCard(offer: offer) {
                            guard let id = offer.id else { return }
                            Task { await vm.removeSaved(offerId: id, userId: currentUserId) }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .refreshable { await vm.loadSavedOffers(userId: currentUserId) }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.neiGreenLight)
                    .frame(width: 84, height: 84)
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.neiGreen)
            }
            VStack(spacing: 4) {
                Text("No saved offers yet")
                    .font(.headline)
                Text("Tap the bookmark on any offer to keep it here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SavedOfferCard: View {
    let offer: Offer
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 5) {
                Text(offer.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    Label(offer.category.displayName, systemImage: offer.category.systemImage)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(offer.category.color.opacity(0.15))
                        .foregroundStyle(offer.category.color)
                        .clipShape(Capsule())

                    if !offer.isActive {
                        Text("Paused")
                            .font(.caption2)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                }

                if let address = offer.address, !address.isEmpty {
                    Label(address, systemImage: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Button(action: onRemove) {
                Image(systemName: "bookmark.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.neiGreen)
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let base64 = offer.imageBase64,
           let data = Data(base64Encoded: base64),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(offer.category.color.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: offer.category.systemImage)
                        .font(.title3)
                        .foregroundStyle(offer.category.color)
                )
        }
    }
}
