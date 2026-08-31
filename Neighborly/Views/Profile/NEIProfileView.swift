import SwiftUI
import FirebaseAuth

struct NEIProfileView: View {
    @EnvironmentObject var authService: NEIAuthService
    @State private var vm = NEIProfileViewModel()
    @State private var showEditSheet = false

    private var uid: String { authService.currentUser?.uid ?? "" }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    scrollContent
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showEditSheet, onDismiss: {
                Task { await vm.load(userId: uid) }
            }) {
                NEIEditProfileView(
                    vm: vm,
                    userId: uid,
                    currentDisplayName: authService.currentUser?.displayName ?? "",
                    currentEmail: authService.currentUser?.email ?? ""
                )
            }
            .task { await vm.load(userId: uid) }
        }
    }

    @ViewBuilder
    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroCard
                    .padding(.bottom, 20)

                VStack(spacing: 16) {
                    postsSection
                    reviewsSection
                    settingsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .refreshable { await vm.load(userId: uid) }
        .background(Color(.systemGroupedBackground))
    }

    private var heroCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                NEIAvatarView(
                    url: vm.user?.avatarURL,
                    name: vm.user?.displayName ?? authService.currentUser?.displayName ?? "",
                    size: 100,
                    base64: vm.user?.avatarBase64
                )
                .padding(.top, 28)

                VStack(spacing: 6) {
                    Text(vm.user?.displayName ?? authService.currentUser?.displayName ?? "")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let bio = vm.user?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    if let createdAt = vm.user?.createdAt {
                        Text("Member since \(createdAt, format: .dateTime.month(.wide).year())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                HStack(spacing: 0) {
                    statColumn(value: "\(vm.offers.count)", label: "Posts")
                    Divider().frame(height: 36)
                    statColumn(value: "\(vm.user?.reviewCount ?? 0)", label: "Reviews")
                    Divider().frame(height: 36)
                    let rc = vm.user?.reviewCount ?? 0
                    let ratingStr = rc > 0 ? String(format: "%.1f", vm.user?.rating ?? 0) : "—"
                    statColumn(value: ratingStr, label: "Rating")
                }
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 20,
                bottomTrailingRadius: 20,
                topTrailingRadius: 0
            )
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var postsSection: some View {
        sectionCard(title: "My Posts") {
            if vm.offers.isEmpty {
                Text("No posts yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(vm.offers.enumerated()), id: \.element.id) { index, offer in
                    if index > 0 {
                        Divider().padding(.leading, 52)
                    }
                    OfferRow(offer: offer)
                }
            }
        }
    }

    private var reviewsSection: some View {
        sectionCard(title: "Reviews") {
            if vm.reviews.isEmpty {
                Text("No reviews yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(vm.reviews.enumerated()), id: \.element.id) { index, review in
                    if index > 0 {
                        Divider()
                    }
                    ReviewRow(review: review)
                }
            }
        }
    }

    private var settingsSection: some View {
        sectionCard(title: "Account") {
            ShareLink(item: "Check out Neighborly — a neighbor-to-neighbor app for lending a hand and getting help nearby!") {
                settingsRow(title: "Invite Neighbors", systemImage: "square.and.arrow.up", iconColor: Color.neiAmber, iconBackground: Color.neiAmberLight, showChevron: false)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 52)

            NavigationLink {
                NEISavedOffersView(
                    currentUserId: uid,
                    currentUserName: vm.user?.displayName ?? authService.currentUser?.displayName ?? ""
                )
            } label: {
                settingsRow(title: "Saved Offers", systemImage: "bookmark.fill", iconColor: Color.neiGreen, iconBackground: Color.neiGreenLight)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 52)

            NavigationLink {
                NEIGuidelinesView()
            } label: {
                settingsRow(title: "Community Guidelines", systemImage: "hand.raised.fill", iconColor: Color(.systemGray), iconBackground: Color(.systemGray5))
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 52)

            NavigationLink {
                NEISettingsView(vm: vm, userId: uid)
            } label: {
                settingsRow(title: "Settings", systemImage: "gearshape.fill", iconColor: Color(.systemGray), iconBackground: Color(.systemGray5))
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 52)

            NavigationLink {
                NEIBlockedUsersView(currentUserId: uid)
            } label: {
                settingsRow(title: "Blocked Users", systemImage: "person.fill.xmark", iconColor: Color.neiRed, iconBackground: Color.neiRed.opacity(0.15))
            }
            .buttonStyle(.plain)
        }
    }

    private func settingsRow(title: String, systemImage: String, iconColor: Color, iconBackground: Color, showChevron: Bool = true) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: 9))

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.bottom, 8)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Edit") { showEditSheet = true }
                .foregroundStyle(Color.neiGreen)
        }
    }
}

struct OfferRow: View {
    let offer: Offer

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: offer.category.systemImage)
                .font(.subheadline)
                .foregroundStyle(Color.neiGreen)
                .frame(width: 36, height: 36)
                .background(Color.neiGreenLight)
                .clipShape(RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 2) {
                Text(offer.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let address = offer.address, !address.isEmpty {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(offer.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if !offer.isActive {
                    Text("Paused")
                        .font(.caption2)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                }
                Text(offer.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ReviewRow: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                NEIRatingView(rating: Double(review.rating), reviewCount: 0, starSize: 12, showNoReviewsText: false)
                Spacer()
                Text(review.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(review.reviewerName)
                .font(.caption)
                .fontWeight(.semibold)
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
