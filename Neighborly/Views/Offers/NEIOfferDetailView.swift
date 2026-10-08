//
//  NEIOfferDetailView.swift
//  Neighborly
//

import SwiftUI

struct NEIOfferDetailView: View {
    let offer: Offer
    let currentUserId: String
    let currentUserName: String
    let onDelete: (() -> Void)?
    var onActiveChanged: ((Bool) -> Void)? = nil

    @State private var activeOverride: Bool?
    @State private var togglingActive = false
    @State private var showRequest = false
    @State private var showDeleteConfirmation = false
    @State private var alreadyApplied = false
    @State private var checkingRequest = true
    @State private var justSent = false
    @State private var showOwnerProfile = false
    @State private var ownerUser: NEIUser?
    @State private var favoriteVM = NEIFavoriteViewModel()
    @State private var reportTarget: NEIReportTarget?
    @Environment(\.dismiss) private var dismiss

    var isOwner: Bool { offer.ownerId == currentUserId }
    private var effectiveActive: Bool { activeOverride ?? offer.isActive }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerImage

                    titleBlock
                        .padding(.horizontal, 20)

                    detailsSection
                        .padding(.horizontal, 20)

                    if let address = offer.address, !address.isEmpty {
                        locationSection(address)
                            .padding(.horizontal, 20)
                    }

                    // Własny post nie potrzebuje karty "Posted by" z własnym profilem
                    if !isOwner {
                        ownerSection
                            .padding(.horizontal, 20)

                        reportButton
                            .padding(.horizontal, 20)
                    }
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
            // Task rusza też po powrocie z NEIRequestView. Zapis aplikacji nie czeka na serwer,
            // więc odczyt tuż po nim dostaje odmowę z reguł (dokumentu jeszcze tam nie ma)
            // i cofał przycisk do "Offer to Help". Raz ustawionego "Applied" nie cofamy.
            .task(id: offer.id) {
                guard !alreadyApplied, !isOwner, let offerId = offer.id else {
                    checkingRequest = false
                    return
                }
                let existing = try? await NEITransactionService()
                    .existingTransaction(offerId: offerId, requesterId: currentUserId)
                if existing?.id != nil { alreadyApplied = true }
                checkingRequest = false
            }
            // Push zamiast sheeta — arkusz na arkuszu wygląda źle
            .navigationDestination(isPresented: $showRequest) {
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
            .neiReportFlow(target: $reportTarget, reporterId: currentUserId)
            .confirmationDialog("Delete this request?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete Request", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("This can't be undone.")
            }
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
           let uiImage = NEIBase64ImageCache.decodedImage(base64: base64) {
            Image(uiImage: uiImage)
                .resizable()
                // Całe zdjęcie, żeby kadr wybrany w edytorze był widoczny
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 400)
                .background(.fill.tertiary)
                .accessibilityIgnoresInvertColors()
                .clipShape(
                    UnevenRoundedRectangle(bottomLeadingRadius: 20, bottomTrailingRadius: 20)
                )
        }
    }

    // MARK: - Title

    // Kategoria i data już są w nagłówku — nie powtarzamy ich w osobnej karcie
    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                NEICategoryBadge(category: offer.category)
                if isOwner && !effectiveActive {
                    Label("Paused", systemImage: "pause.circle.fill")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(Color.orange)
                        .clipShape(Capsule())
                }
            }
            Text(offer.title)
                .font(.title2)
                .fontWeight(.bold)
            Text("Posted \(offer.createdAt.formatted(.relative(presentation: .named)))")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if isOwner && !effectiveActive {
                Text("Hidden from map and search")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Location

    private func locationSection(_ address: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            NEISectionLabel("Location")
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(address)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                Spacer(minLength: 0)
            }
            .padding(14)
            .cardStyle()
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            NEISectionLabel("Details")
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
            NEISectionLabel("Posted by")
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

    // Jak "Report a Problem" w App Store — dyskretny link pod treścią
    private var reportButton: some View {
        Button {
            reportTarget = NEIReportTarget(
                type: .offer,
                targetId: offer.id ?? "",
                ownerId: offer.ownerId,
                ownerName: ownerUser?.displayName ?? "The owner",
                excerpt: "\(offer.title)\n\(offer.description)"
            )
        } label: {
            Label("Report Offer", systemImage: "flag")
                .font(.subheadline)
                .foregroundStyle(Color.neiRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(offer.id == nil)
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
                if !alreadyApplied && !checkingRequest { showRequest = true }
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

    // Jeden niski rząd, tak jak przy "Offer to Help" + zakładka — dłuższy pasek zjadał
    // większość arkusza w medium detent i nie dało się przewinąć szczegółów.
    private var ownerActions: some View {
        HStack(spacing: 12) {
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

            if onDelete != nil {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.headline)
                        .foregroundStyle(.red)
                        .frame(width: 52, height: 52)
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityLabel("Delete Request")
            }
        }
    }

    private func loadOwner() async {
        ownerUser = await NEIUserCache.shared.user(id: offer.ownerId)
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
