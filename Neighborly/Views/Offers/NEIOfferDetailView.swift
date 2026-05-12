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

    @State private var showRequestSheet = false
    @State private var requestSent = false
    @Environment(\.dismiss) private var dismiss

    var isOwner: Bool { offer.ownerId == currentUserId }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            grabHandle

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let urlString = offer.imageURLs.first, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color(.systemGray5)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    HStack {
                        NEICategoryBadge(category: offer.category)
                        Spacer()
                        Text(offer.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(offer.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(offer.description)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Divider()

                    if isOwner {
                        ownerActions
                    } else {
                        requestButton
                    }
                }
                .padding(20)
            }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showRequestSheet) {
            NEIRequestView(
                offer: offer,
                requesterId: currentUserId,
                requesterName: currentUserName,
                onSent: { requestSent = true }
            )
        }
        .overlay(alignment: .top) {
            if requestSent {
                requestSentBanner
            }
        }
    }

    private var grabHandle: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var requestButton: some View {
        NEIPrimaryButton(requestSent ? "Request Sent!" : "Request This") {
            if !requestSent { showRequestSheet = true }
        }
    }

    private var requestSentBanner: some View {
        Label("Request sent successfully!", systemImage: "checkmark.circle.fill")
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
                withAnimation { requestSent = false }
            }
    }

    private var ownerActions: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("This is your offer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                    dismiss()
                } label: {
                    Label("Delete Offer", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
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
            .background(Color.green.opacity(0.15))
            .foregroundStyle(.green)
            .clipShape(Capsule())
    }
}
