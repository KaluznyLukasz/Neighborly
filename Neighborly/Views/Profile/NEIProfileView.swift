//
//  NEIProfileView.swift
//  Neighborly
//

import SwiftUI
import FirebaseAuth

struct NEIProfileView: View {
    @EnvironmentObject var authService: NEIAuthService
    @State private var vm = NEIProfileViewModel()
    @State private var showEditSheet = false
    @State private var showSignOutAlert = false

    private var uid: String { authService.currentUser?.uid ?? "" }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    profileContent
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showEditSheet) {
                if let _ = vm.user {
                    NEIEditProfileView(vm: vm, userId: uid)
                }
            }
            .alert("Sign out?", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) { authService.signOut() }
                Button("Cancel", role: .cancel) {}
            }
            .task { await vm.load(userId: uid) }
        }
    }

    @ViewBuilder
    private var profileContent: some View {
        List {
            Section {
                headerSection
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            if !vm.offers.isEmpty {
                Section("My Offers (\(vm.offers.count))") {
                    ForEach(vm.offers) { offer in
                        OfferRow(offer: offer)
                    }
                }
            }

            if !vm.reviews.isEmpty {
                Section("Reviews (\(vm.reviews.count))") {
                    ForEach(vm.reviews) { review in
                        ReviewRow(review: review)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showSignOutAlert = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            NEIAvatarView(
                url: vm.user?.avatarURL,
                name: vm.user?.displayName ?? authService.currentUser?.displayName ?? "",
                size: 80
            )

            VStack(spacing: 4) {
                Text(vm.user?.displayName ?? authService.currentUser?.displayName ?? "")
                    .font(.title2)
                    .fontWeight(.bold)

                if let bio = vm.user?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                NEIRatingView(
                    rating: vm.user?.rating ?? 0,
                    reviewCount: vm.user?.reviewCount ?? 0
                )
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Edit") { showEditSheet = true }
                .foregroundStyle(Color.neiGreen)
        }
    }
}

private struct OfferRow: View {
    let offer: Offer

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: offer.category.systemImage)
                .font(.subheadline)
                .foregroundStyle(Color.neiGreen)
                .frame(width: 32, height: 32)
                .background(Color.neiGreenLight)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(offer.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(offer.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

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
        .padding(.vertical, 2)
    }
}

private struct ReviewRow: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                NEIRatingView(rating: Double(review.rating), reviewCount: 0, starSize: 12)
                Spacer()
                Text(review.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(review.reviewerName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            if let comment = review.comment, !comment.isEmpty {
                Text(comment)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 4)
    }
}
