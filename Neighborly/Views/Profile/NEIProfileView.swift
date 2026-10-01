import SwiftUI
import FirebaseAuth

struct NEIProfileView: View {
    @EnvironmentObject var authService: NEIAuthService
    @State private var vm = NEIProfileViewModel()
    @State private var destination: Destination?

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
            .alert("Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .task { await vm.load(userId: uid) }
            .navigationDestination(item: $destination) { destination in
                switch destination {
                case .allReviews:
                    NEIAllReviewsView(reviews: vm.reviews)
                case .savedOffers:
                    NEISavedOffersView(
                        currentUserId: uid,
                        currentUserName: vm.user?.displayName ?? authService.currentUser?.displayName ?? ""
                    )
                case .guidelines:
                    NEIGuidelinesView()
                case .settings:
                    NEISettingsView(vm: vm, userId: uid)
                case .blockedUsers:
                    NEIBlockedUsersView(currentUserId: uid)
                }
            }
        }
    }

    // Kilka NavigationLink w jednym wierszu List odpala wszystkie naraz — dlatego
    // przyciski ustawiają cel, a nawigację robi .navigationDestination(item:).
    private enum Destination: Hashable {
        case allReviews, savedOffers, guidelines, settings, blockedUsers
    }

    // List zamiast ScrollView — tylko w List działa .swipeActions na postach.
    // Wiersze bez tła i separatorów, więc wygląd zostaje jak w zwykłym stosie kart.
    @ViewBuilder
    private var scrollContent: some View {
        List {
            heroCard
                .profileRow(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0))

            postsSection

            reviewsSection
                .profileRow(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            settingsSection
                .profileRow(EdgeInsets(top: 8, leading: 16, bottom: 24, trailing: 16))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 0, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, 0)
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

                if let user = vm.user {
                    NEITrustBadgesView(badges: NEITrustBadge.badges(for: user, postCount: vm.offers.count))
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(heroShape)
        .overlay(heroShape.strokeBorder(Color(.separator).opacity(0.6), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var heroShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 20,
            bottomTrailingRadius: 20,
            topTrailingRadius: 0
        )
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

    @ViewBuilder
    private var postsSection: some View {
        if vm.offers.isEmpty {
            NEISectionCard(title: "My Posts") {
                Text("No posts yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
            .profileRow(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
        } else {
            // Każdy post jako osobny wiersz-karta — ten sam wygląd co w Activity → My Posts,
            // z usuwaniem przez przesunięcie.
            NEISectionHeader(title: "My Posts")
                .frame(maxWidth: .infinity, alignment: .leading)
                .profileRow(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

            ForEach(vm.offers) { offer in
                NEIPostRow(offer: offer)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .neiCardBackground()
                    .profileRow(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await vm.deleteOffer(offer) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private var reviewsSection: some View {
        NEISectionCard(title: "Reviews") {
            if vm.reviews.isEmpty {
                Text("No reviews yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(vm.reviews.prefix(3).enumerated()), id: \.element.id) { index, review in
                    if index > 0 {
                        Divider()
                    }
                    ReviewRow(review: review)
                }
                if vm.reviews.count > 3 {
                    Divider()
                    Button {
                        destination = .allReviews
                    } label: {
                        HStack {
                            Text("See All \(vm.reviews.count) Reviews")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.neiGreen)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var settingsSection: some View {
        NEISectionCard(title: "Account") {
            ShareLink(item: "Check out Neighborly — a neighbor-to-neighbor app for lending a hand and getting help nearby!") {
                NEISettingsRow(title: "Invite Neighbors", systemImage: "square.and.arrow.up", iconColor: Color.neiAmber, iconBackground: Color.neiAmberLight, showChevron: false)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 52)

            Button {
                destination = .savedOffers
            } label: {
                NEISettingsRow(title: "Saved Offers", systemImage: "bookmark.fill", iconColor: Color.neiGreen, iconBackground: Color.neiGreenLight)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 52)

            Button {
                destination = .guidelines
            } label: {
                NEISettingsRow(title: "Community Guidelines", systemImage: "hand.raised.fill", iconColor: Color(.systemGray), iconBackground: Color(.systemGray5))
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 52)

            Button {
                destination = .settings
            } label: {
                NEISettingsRow(title: "Settings", systemImage: "gearshape.fill", iconColor: Color(.systemGray), iconBackground: Color(.systemGray5))
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 52)

            Button {
                destination = .blockedUsers
            } label: {
                NEISettingsRow(title: "Blocked Users", systemImage: "person.fill.xmark", iconColor: Color.neiRed, iconBackground: Color.neiRed.opacity(0.15))
            }
            .buttonStyle(.plain)
        }
    }

}

private extension View {
    /// Wiersz List bez tła i separatora — karta rysuje własne tło.
    func profileRow(_ insets: EdgeInsets) -> some View {
        self
            .listRowInsets(insets)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
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
        HStack(alignment: .top, spacing: 12) {
            NEIAvatarView(url: nil, name: review.reviewerName, size: 36, base64: nil)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(review.reviewerName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(review.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                NEIRatingView(rating: Double(review.rating), reviewCount: 0, starSize: 12, showNoReviewsText: false)
                if let comment = review.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(4)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
