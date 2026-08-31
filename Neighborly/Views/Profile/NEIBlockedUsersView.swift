//
//  NEIBlockedUsersView.swift
//  Neighborly
//

import SwiftUI

struct NEIBlockedUsersView: View {
    let currentUserId: String

    @State private var vm = NEIBlockViewModel()
    @State private var userPendingUnblock: NEIUser?

    var body: some View {
        Group {
            if vm.isLoading && vm.blockedUsers.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.blockedUsers.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .init(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .alert(
            "Unblock \(userPendingUnblock?.displayName ?? "this user")?",
            isPresented: .init(
                get: { userPendingUnblock != nil },
                set: { if !$0 { userPendingUnblock = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { userPendingUnblock = nil }
            Button("Unblock") {
                if let user = userPendingUnblock {
                    Task {
                        await vm.toggleBlock(
                            blockedUserId: user.id ?? "",
                            blockedDisplayName: user.displayName,
                            currentUserId: currentUserId
                        )
                    }
                }
                userPendingUnblock = nil
            }
        } message: {
            Text("You'll be able to see their offers again.")
        }
        .task { await vm.loadBlockedUsers(currentUserId: currentUserId) }
    }

    private var content: some View {
        List {
            ForEach(vm.blockedUsers, id: \.id) { user in
                BlockedUserRow(user: user) {
                    userPendingUnblock = user
                }
            }
        }
        .listStyle(.plain)
        .refreshable { await vm.loadBlockedUsers(currentUserId: currentUserId) }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.neiRed.opacity(0.15))
                    .frame(width: 84, height: 84)
                Image(systemName: "person.fill.xmark")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.neiRed)
            }
            VStack(spacing: 4) {
                Text("No blocked users")
                    .font(.headline)
                Text("People you block won't be able to show you their offers.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct BlockedUserRow: View {
    let user: NEIUser
    let onUnblock: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NEIAvatarView(
                url: user.avatarURL,
                name: user.displayName,
                size: 44,
                base64: user.avatarBase64
            )

            Text(user.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Spacer()

            Button("Unblock", action: onUnblock)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.neiRed)
        }
        .padding(.vertical, 4)
    }
}
