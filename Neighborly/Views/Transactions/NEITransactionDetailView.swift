//
//  NEITransactionDetailView.swift
//  Neighborly
//

import SwiftUI

struct NEITransactionDetailView: View {
    let transaction: Transaction
    let currentUserId: String
    let currentUserName: String
    let vm: NEITransactionViewModel

    @State private var showReviewSheet = false
    @State private var showChatSheet = false
    @State private var showProfileSheet = false
    @State private var canReview = false
    @Environment(\.dismiss) private var dismiss

    private let reviewService = NEIReviewService()
    private var isOwner: Bool { transaction.ownerId == currentUserId }
    private var otherPartyId: String { isOwner ? transaction.requesterId : transaction.ownerId }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusCard
                    detailCard

                    if let message = transaction.message {
                        messageCard(message)
                    }

                    actionButtons

                    if canReview && transaction.status == .completed {
                        NEIPrimaryButton("Leave a Review") {
                            showReviewSheet = true
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showChatSheet = true
                    } label: {
                        Image(systemName: "message.fill")
                    }
                    .tint(Color.green)
                }
            }
            .navigationDestination(isPresented: $showChatSheet) {
                NEIChatView(
                    transaction: transaction,
                    currentUserId: currentUserId,
                    currentUserName: currentUserName
                )
            }
            .sheet(isPresented: $showReviewSheet) {
                NEIReviewView(
                    transaction: transaction,
                    reviewerId: currentUserId,
                    revieweeId: otherPartyId
                ) { dismiss() }
            }
            .sheet(isPresented: $showProfileSheet) {
                NEIUserProfileView(userId: otherPartyId)
            }
            .task {
                if transaction.status == .completed {
                    canReview = (try? await reviewService.hasReviewed(
                        transactionId: transaction.id ?? "",
                        reviewerId: currentUserId
                    )) == false
                }
            }
        }
    }

    private var statusCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.offerTitle)
                    .font(.headline)
                Text(transaction.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            NEIStatusBadge(status: transaction.status)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isOwner {
                Button {
                    showProfileSheet = true
                } label: {
                    HStack {
                        Label("Volunteer: \(transaction.requesterName)", systemImage: "person.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Label("Your application", systemImage: "person.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func messageCard(_ msg: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Message")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text(msg)
                .font(.subheadline)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch transaction.status {
        case .pending where isOwner:
            VStack(spacing: 10) {
                NEIPrimaryButton("Accept Volunteer") {
                    Task { await vm.accept(transaction: transaction); dismiss() }
                }
                Button(role: .destructive) {
                    Task { await vm.reject(transaction: transaction); dismiss() }
                } label: {
                    Text("Decline")
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

        case .accepted where isOwner:
            NEIPrimaryButton("Mark as Completed") {
                Task { await vm.complete(transaction: transaction); dismiss() }
            }

        case .pending where !isOwner, .accepted where !isOwner:
            Button(role: .destructive) {
                Task { await vm.cancel(transaction: transaction); dismiss() }
            } label: {
                Text("Cancel Application")
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.red.opacity(0.1))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

        default:
            EmptyView()
        }
    }
}

struct NEIStatusBadge: View {
    let status: TransactionStatus

    var color: Color {
        switch status {
        case .pending:   return .orange
        case .accepted:  return .green
        case .rejected:  return .red
        case .completed: return .blue
        case .cancelled: return .gray
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
