import SwiftUI

struct NEIUserProfileView: View {
    let userId: String

    @State private var vm = NEIProfileViewModel()
    @Environment(\.dismiss) private var dismiss

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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await vm.load(userId: userId) }
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
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
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
        sectionCard(title: "Posts") {
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
}
