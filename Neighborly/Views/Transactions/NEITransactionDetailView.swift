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

    @State private var status: TransactionStatus
    @State private var dueDate: Date?
    @State private var showReviewSheet = false
    @State private var showChatSheet = false
    @State private var showProfileSheet = false
    @State private var canReview = false
    @Environment(\.dismiss) private var dismiss

    private let reviewService = NEIReviewService()
    private var isOwner: Bool { transaction.ownerId == currentUserId }
    private var otherPartyId: String { isOwner ? transaction.requesterId : transaction.ownerId }

    init(transaction: Transaction, currentUserId: String, currentUserName: String, vm: NEITransactionViewModel) {
        self.transaction = transaction
        self.currentUserId = currentUserId
        self.currentUserName = currentUserName
        self.vm = vm
        _status = State(initialValue: transaction.status)
        _dueDate = State(initialValue: transaction.dueDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusCard
                    detailCard

                    if status == .accepted {
                        returnCard
                    }

                    if let message = transaction.message {
                        messageCard(message)
                    }

                    actionButtons

                    if status == .completed {
                        if canReview {
                            NEIPrimaryButton("Leave a Review") {
                                showReviewSheet = true
                            }
                        } else {
                            Label("You reviewed this job", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
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
            .navigationDestination(isPresented: $showProfileSheet) {
                NEIUserProfileView(userId: otherPartyId)
            }
            .task {
                if status == .completed {
                    canReview = (try? await reviewService.hasReviewed(
                        transactionId: transaction.id ?? "",
                        reviewerId: currentUserId
                    )) == false
                    if canReview {
                        showReviewSheet = true
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
            NEIStatusBadge(status: status)
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

    private var isReturn: Bool { transaction.dateKind == .returnDate }

    private var isOverdue: Bool {
        guard status == .accepted, isReturn, let dueDate else { return false }
        return dueDate < Calendar.current.startOfDay(for: Date())
    }

    private var returnCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isOwner {
                Toggle(isReturn ? "Ask for return" : "Set a reminder", isOn: Binding(
                    get: { dueDate != nil },
                    set: { on in
                        let new = on ? Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) : nil
                        setDueDate(new)
                    }
                ))
                if let dueDate {
                    DatePicker(
                        isReturn ? "Return by" : "Planned for",
                        selection: Binding(get: { dueDate }, set: { setDueDate(Calendar.current.startOfDay(for: $0)) }),
                        in: Calendar.current.startOfDay(for: Date())...,
                        displayedComponents: .date
                    )
                }
                Text("Both of you get a reminder the day before and on the day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let dueDate {
                Label {
                    Text("\(isReturn ? "Return by" : "Planned for") \(dueDate, format: .dateTime.weekday(.wide).day().month(.wide))")
                } icon: {
                    Image(systemName: "calendar.badge.clock")
                }
                .font(.subheadline)
            } else {
                Label(isReturn ? "No return date set" : "No date set", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if isOverdue {
                Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func setDueDate(_ new: Date?) {
        dueDate = new
        Task { await vm.setDueDate(transaction: transaction, dueDate: new) }
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
        switch status {
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
                Task {
                    await vm.complete(transaction: transaction)
                    status = .completed
                    canReview = true
                    showReviewSheet = true
                }
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
