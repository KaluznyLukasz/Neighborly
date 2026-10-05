import SwiftUI
import FirebaseAuth

struct NEIUserProfileView: View {
    let userId: String

    @EnvironmentObject var authService: NEIAuthService
    @State private var vm = NEIProfileViewModel()
    @State private var blockVM = NEIBlockViewModel()
    @State private var showBlockAlert = false
    @State private var showUnblockAlert = false
    @State private var reportTarget: NEIReportTarget?

    var body: some View {
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
        .task { await vm.load(userId: userId) }
        .task { await blockVM.checkBlocked(userId: userId, currentUserId: authService.currentUser?.uid ?? "") }
        .alert("Block \(vm.user?.displayName ?? "this user")?", isPresented: $showBlockAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Block", role: .destructive) {
                Task {
                    await blockVM.toggleBlock(
                        blockedUserId: userId,
                        blockedDisplayName: vm.user?.displayName ?? "",
                        currentUserId: authService.currentUser?.uid ?? ""
                    )
                }
            }
        } message: {
            Text("You won't see their posts or alerts, and they can't message you or respond to your posts.")
        }
        .alert("Unblock \(vm.user?.displayName ?? "this user")?", isPresented: $showUnblockAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Unblock", role: .destructive) {
                Task {
                    await blockVM.toggleBlock(
                        blockedUserId: userId,
                        blockedDisplayName: vm.user?.displayName ?? "",
                        currentUserId: authService.currentUser?.uid ?? ""
                    )
                }
            }
        } message: {
            Text("You'll see their posts and alerts again, and they can message you.")
        }
        .neiReportFlow(target: $reportTarget, reporterId: authService.currentUser?.uid ?? "") {
            blockVM.blockedUserIds.insert(userId)
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
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
                    if userId != authService.currentUser?.uid {
                        blockSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .refreshable { await vm.load(userId: userId) }
    }

    private var heroCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                NEIAvatarView(
                    url: vm.user?.avatarURL,
                    name: vm.user?.displayName ?? "",
                    size: 100,
                    base64: vm.user?.avatarBase64
                )
                .padding(.top, 28)

                VStack(spacing: 6) {
                    Text(vm.user?.displayName ?? "")
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
            NEISectionCard(title: "Posts") {
                Text("No posts yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            }
        } else {
            // Każdy post jako osobna karta — ten sam wygląd co w Profile → My Posts.
            VStack(alignment: .leading, spacing: 0) {
                NEISectionHeader(title: "Posts")
                VStack(spacing: 10) {
                    ForEach(vm.offers) { offer in
                        NEIPostRow(offer: offer)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .neiCardBackground()
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
                    ReviewRow(review: review, onReport: reportAction(for: review))
                }
                if vm.reviews.count > 3 {
                    Divider()
                    NavigationLink {
                        NEIAllReviewsView(reviews: vm.reviews)
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

    private func reportAction(for review: Review) -> (() -> Void)? {
        guard review.reviewerId != authService.currentUser?.uid else { return nil }
        return { reportTarget = .review(review) }
    }

    private var blockSection: some View {
        NEISectionCard(title: "Trust & Safety") {
            Button {
                if blockVM.isBlocked(userId) {
                    showUnblockAlert = true
                } else {
                    showBlockAlert = true
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill.xmark")
                        .font(.subheadline)
                        .foregroundStyle(blockVM.isBlocked(userId) ? Color(.systemGray) : Color.neiRed)
                        .frame(width: 36, height: 36)
                        .background(blockVM.isBlocked(userId) ? Color(.systemGray5) : Color.neiRed.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 9))

                    Text(blockVM.isBlocked(userId) ? "Unblock User" : "Block User")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(blockVM.isBlocked(userId) ? .primary : Color.neiRed)

                    Spacer()
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                reportTarget = NEIReportTarget(
                    type: .user,
                    targetId: userId,
                    ownerId: userId,
                    ownerName: vm.user?.displayName ?? "This person",
                    excerpt: [vm.user?.displayName, vm.user?.bio].compactMap { $0 }.joined(separator: " — ")
                )
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "flag.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.neiRed)
                        .frame(width: 36, height: 36)
                        .background(Color.neiRed.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .accessibilityHidden(true)

                    Text("Report User")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.neiRed)

                    Spacer()
                }
                .padding(.vertical, 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
