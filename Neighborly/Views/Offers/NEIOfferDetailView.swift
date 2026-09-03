//
//  NEIOfferDetailView.swift
//  Neighborly
//

import SwiftUI
import FirebaseFirestore

struct NEIOfferDetailView: View {
    let offer: Offer
    let currentUserId: String
    let currentUserName: String
    let onDelete: (() -> Void)?
    var onActiveChanged: ((Bool) -> Void)? = nil

    @State private var activeOverride: Bool?
    @State private var togglingActive = false
    @State private var showRequestSheet = false
    @State private var alreadyApplied = false
    @State private var checkingRequest = true
    @State private var justSent = false
    @State private var showOwnerProfile = false
    @State private var ownerUser: NEIUser?
    @State private var favoriteVM = NEIFavoriteViewModel()
    @Environment(\.dismiss) private var dismiss

    var isOwner: Bool { offer.ownerId == currentUserId }
    private var effectiveActive: Bool { activeOverride ?? offer.isActive }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerImage

                    VStack(alignment: .leading, spacing: 6) {
                        NEICategoryBadge(category: offer.category)
                        Text(offer.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Posted \(offer.createdAt, style: .relative) ago")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)

                    infoCard
                        .padding(.horizontal, 20)

                    detailsSection
                        .padding(.horizontal, 20)

                    ownerSection
                        .padding(.horizontal, 20)
                }
                .padding(.top, offer.imageBase64 == nil ? 12 : 0)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    Group {
                        if isOwner {
                            ownerActions
                        } else {
                            requestButton
                        }
                    }
                    .padding(20)
                }
                .background(.regularMaterial)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .task(id: offer.id) { await loadOwner() }
            .task(id: offer.id) {
                favoriteVM.favoriteOfferIds.removeAll()
                guard !isOwner, let offerId = offer.id else { return }
                await favoriteVM.checkFavorited(offerId: offerId, userId: currentUserId)
            }
            .task(id: offer.id) {
                alreadyApplied = false
                checkingRequest = true
                guard !isOwner, let offerId = offer.id else {
                    checkingRequest = false
                    return
                }
                let existing = try? await NEITransactionService()
                    .existingTransaction(offerId: offerId, requesterId: currentUserId)
                alreadyApplied = existing?.id != nil
                checkingRequest = false
            }
            .sheet(isPresented: $showRequestSheet) {
                NEIRequestView(
                    offer: offer,
                    requesterId: currentUserId,
                    requesterName: currentUserName,
                    onSent: {
                        alreadyApplied = true
                        justSent = true
                    }
                )
            }
            .navigationDestination(isPresented: $showOwnerProfile) {
                NEIUserProfileView(userId: offer.ownerId)
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Error", isPresented: .init(
                get: { favoriteVM.errorMessage != nil },
                set: { if !$0 { favoriteVM.errorMessage = nil } }
            )) {
                Button("OK") { favoriteVM.errorMessage = nil }
            } message: {
                Text(favoriteVM.errorMessage ?? "")
            }
            .overlay(alignment: .top) {
                if justSent {
                    requestSentBanner
                }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerImage: some View {
        if let base64 = offer.imageBase64,
           let data = Data(base64Encoded: base64),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()
                .clipShape(
                    UnevenRoundedRectangle(bottomLeadingRadius: 20, bottomTrailingRadius: 20)
                )
        }
    }

    // MARK: - Info

    private var infoCard: some View {
        VStack(spacing: 0) {
            if let address = offer.address, !address.isEmpty {
                infoRow(icon: "mappin.circle.fill", label: "Location", value: address)
                Divider().padding(.leading, 52)
            }
            infoRow(
                icon: "clock",
                label: "Posted",
                value: offer.createdAt.formatted(date: .abbreviated, time: .shortened)
            )
            Divider().padding(.leading, 52)
            infoRow(icon: "tag", label: "Category", value: offer.category.displayName)
        }
        .padding(.vertical, 4)
        .cardStyle()
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)
            Text(offer.description)
                .font(.body)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .cardStyle()
        }
    }

    // MARK: - Owner

    private var ownerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Posted by")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)
            Button {
                showOwnerProfile = true
            } label: {
                HStack(spacing: 12) {
                    NEIAvatarView(
                        url: ownerUser?.avatarURL,
                        name: ownerUser?.displayName ?? "",
                        size: 44,
                        base64: ownerUser?.avatarBase64
                    )
                    VStack(alignment: .leading, spacing: 1) {
                        Text(ownerUser?.displayName ?? "Loading…")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("View profile")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .cardStyle()
        }
    }

    private var favoriteButton: some View {
        Button {
            guard let offerId = offer.id else { return }
            Task { await favoriteVM.toggleFavorite(offerId: offerId, userId: currentUserId) }
        } label: {
            Image(systemName: favoriteVM.isFavorited(offer.id ?? "") ? "bookmark.fill" : "bookmark")
                .font(.headline)
                .foregroundStyle(Color.neiGreen)
                .frame(width: 52, height: 52)
                .background(Color.neiGreen.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var requestButton: some View {
        HStack(spacing: 12) {
            NEIPrimaryButton(
                alreadyApplied ? "Applied" : "Offer to Help",
                isLoading: checkingRequest
            ) {
                if !alreadyApplied && !checkingRequest { showRequestSheet = true }
            }
            favoriteButton
        }
    }

    private var requestSentBanner: some View {
        Label("You offered to help!", systemImage: "checkmark.circle.fill")
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(12)
            .background(Color.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation { justSent = false }
            }
    }

    private var ownerActions: some View {
        VStack(spacing: 12) {
            Label(effectiveActive ? "This is your request" : "Paused — hidden from map and search",
                  systemImage: effectiveActive ? "checkmark.seal.fill" : "pause.circle.fill")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            if let id = offer.id {
                Button {
                    let newValue = !effectiveActive
                    togglingActive = true
                    Task {
                        try? await NEIOfferService().setOfferActive(id: id, isActive: newValue)
                        activeOverride = newValue
                        togglingActive = false
                        onActiveChanged?(newValue)
                    }
                } label: {
                    Label(effectiveActive ? "Pause Offer" : "Reactivate Offer",
                          systemImage: effectiveActive ? "pause.circle" : "play.circle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.neiGreen.opacity(0.12))
                        .foregroundStyle(Color.neiGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(togglingActive)
            }

            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                    dismiss()
                } label: {
                    Text("Delete Request")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .padding(.top, 2)
            }
        }
    }

    private func loadOwner() async {
        let doc = try? await Firestore.firestore()
            .collection("users").document(offer.ownerId).getDocument()
        ownerUser = try? doc?.data(as: NEIUser.self)
    }
}

struct NEICategoryBadge: View {
    let category: OfferCategory

    var body: some View {
        Label(category.displayName, systemImage: category.systemImage)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(category.color.opacity(0.15))
            .foregroundStyle(category.color)
            .clipShape(Capsule())
    }
}

private extension View {
    /// Wspólny styl karty: tło elewowane + cienki obrys (kontrast też w dark mode).
    func cardStyle(cornerRadius: CGFloat = 14) -> some View {
        self
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color(.separator).opacity(0.6), lineWidth: 0.5)
            )
    }
}
