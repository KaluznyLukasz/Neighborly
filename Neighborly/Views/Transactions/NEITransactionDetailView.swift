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
    @State private var dueHasTime: Bool
    @State private var showReviewSheet = false
    @State private var showChatSheet = false
    @State private var showProfileSheet = false
    @State private var canReview = false
    @State private var otherUser: NEIUser?
    // Wysokość treści — arkusz dopasowuje się do niej zamiast zostawiać pustą przestrzeń
    @State private var contentHeight: CGFloat = 480
    @Environment(\.dismiss) private var dismiss

    // Pasek nawigacji arkusza + dolny safe area; treść mierzymy bez nich
    private let sheetChromeHeight: CGFloat = 76

    private let reviewService = NEIReviewService()
    private var isOwner: Bool { transaction.ownerId == currentUserId }
    private var otherPartyId: String { isOwner ? transaction.requesterId : transaction.ownerId }
    // Nazwa wolontariusza jest w transakcji, więc widać ją od razu; właściciela dociągamy z profilu
    private var otherPartyName: String {
        otherUser?.displayName ?? (isOwner ? transaction.requesterName : "Owner")
    }

    init(transaction: Transaction, currentUserId: String, currentUserName: String, vm: NEITransactionViewModel) {
        self.transaction = transaction
        self.currentUserId = currentUserId
        self.currentUserName = currentUserName
        self.vm = vm
        _status = State(initialValue: transaction.status)
        _dueDate = State(initialValue: transaction.dueDate)
        _dueHasTime = State(initialValue: transaction.hasDueTime)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    otherPartySection

                    if let message = transaction.message {
                        messageSection(message)
                    }

                    if status == .accepted {
                        returnSection
                    }

                    if status == .completed && !canReview {
                        Label("You reviewed this job", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
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
                    .accessibilityLabel("Chat")
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
            // Alert listy jest pod arkuszem i się nie pokaże — błędy zapisu pokazujemy tutaj
            .alert("Something Went Wrong", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .navigationDestination(isPresented: $showProfileSheet) {
                NEIUserProfileView(userId: otherPartyId)
            }
            .task(id: otherPartyId) {
                otherUser = await NEIUserCache.shared.user(id: otherPartyId)
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
        .presentationDetents([.height(contentHeight + sheetChromeHeight), .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let category = transaction.offerCategory {
                    NEICategoryBadge(category: category)
                }
                Spacer()
                NEIStatusBadge(status: status)
            }
            Text(transaction.offerTitle)
                .font(.title2)
                .fontWeight(.bold)
            Text("Applied \(transaction.createdAt.formatted(.relative(presentation: .named)))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Other party

    private var otherPartySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            NEISectionLabel(isOwner ? "Volunteer" : "Posted by")
            Button {
                showProfileSheet = true
            } label: {
                HStack(spacing: 12) {
                    NEIAvatarView(
                        url: otherUser?.avatarURL,
                        name: otherPartyName,
                        size: 44,
                        base64: otherUser?.avatarBase64
                    )
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(otherPartyName)
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
                        .accessibilityHidden(true)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .cardStyle()
        }
    }

    // MARK: - Message

    private func messageSection(_ msg: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            NEISectionLabel("Message")
            Text(msg)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .cardStyle()
        }
    }

    // MARK: - Return / date

    private var returnSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            NEISectionLabel(transaction.dateKind == .returnDate ? "Return" : "Date")
            // Karta ma własne tło i stopkę z informacją o przypomnieniach
            NEIDueDateCard(
                dateKind: transaction.dateKind,
                isOwner: isOwner,
                userId: currentUserId,
                dueDate: due.date,
                hasTime: due.hasTime,
                onChange: setDueDate
            )
        }
    }

    // Termin czytamy z view modelu, więc po nieudanym zapisie karta wraca do poprzedniej
    // wartości. Lokalna kopia tylko dla transakcji, której nie ma na listach.
    private var due: (date: Date?, hasTime: Bool) {
        if let id = transaction.id, let live = vm.current(id: id) {
            return (live.dueDate, live.hasDueTime)
        }
        return (dueDate, dueHasTime)
    }

    private func setDueDate(_ new: Date?, hasTime: Bool) {
        dueDate = new
        dueHasTime = new != nil && hasTime
        vm.setDueDate(transaction: transaction, dueDate: new, hasTime: hasTime)
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionButtons: some View {
        switch status {
        case .pending where isOwner:
            VStack(spacing: 4) {
                // Arkusz zostaje otwarty — od razu pojawia się karta terminu
                NEIPrimaryButton("Accept Volunteer") {
                    Task {
                        if await vm.accept(transaction: transaction) {
                            withAnimation { status = .accepted }
                        }
                    }
                }
                Button(role: .destructive) {
                    Task { await vm.reject(transaction: transaction); dismiss() }
                } label: {
                    Text("Decline")
                        .font(.body)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, minHeight: 44)
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
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.red.opacity(0.12))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

        case .completed where canReview:
            NEIPrimaryButton("Leave a Review") {
                showReviewSheet = true
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
