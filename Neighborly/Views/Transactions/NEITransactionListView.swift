//
//  NEITransactionListView.swift
//  Neighborly
//

import SwiftUI
import FirebaseAuth

struct NEITransactionListView: View {
    @EnvironmentObject var authService: NEIAuthService
    @State private var vm = NEITransactionViewModel()
    @State private var myOffers: [Offer] = []
    @State private var selectedTab = 0
    @State private var selectedTransaction: Transaction?
    @State private var isLoadingOffers = false

    private let offerService = NEIOfferService()
    private var uid: String { authService.currentUser?.uid ?? "" }
    private var userName: String { authService.currentUser?.displayName ?? "User" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                segmentedControl

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    listContent
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Activity")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await loadAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(item: $selectedTransaction) { transaction in
                NEITransactionDetailView(
                    transaction: transaction,
                    currentUserId: uid,
                    currentUserName: userName,
                    vm: vm
                )
            }
            .alert("Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .task { await loadAll() }
        }
    }

    private var isLoading: Bool {
        selectedTab == 2 ? isLoadingOffers : vm.isLoading
    }

    @ViewBuilder
    private var listContent: some View {
        if selectedTab == 2 {
            // Każdy post jako osobna karta — sekcja na wiersz daje odstęp między nimi.
            List {
                ForEach(myOffers) { offer in
                    Section {
                        NEIPostRow(offer: offer)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await deleteOffer(offer) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(12)
            .contentMargins(.top, 4, for: .scrollContent)
            .overlay {
                if myOffers.isEmpty { emptyState }
            }
        } else {
            List {
                ForEach(selectedTab == 0 ? vm.inbox : vm.myRequests) { transaction in
                    Section {
                        TransactionRow(transaction: transaction, isInbox: selectedTab == 0)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedTransaction = transaction }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if transaction.status == .rejected || transaction.status == .cancelled || transaction.status == .completed {
                                    Button(role: .destructive) {
                                        Task { await vm.delete(transaction: transaction) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(12)
            .contentMargins(.top, 4, for: .scrollContent)
            .overlay {
                if (selectedTab == 0 ? vm.inbox : vm.myRequests).isEmpty {
                    emptyState
                }
            }
        }
    }

    private var segmentedControl: some View {
        Picker("", selection: $selectedTab) {
            Text("Volunteers").tag(0)
            Text("My Applications").tag(1)
            Text("My Posts").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(16)
        .background(Color(.systemGroupedBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedTab == 0 ? "person.wave.2" : selectedTab == 1 ? "paperplane" : "square.and.pencil")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(selectedTab == 0 ? "No volunteers yet" : selectedTab == 1 ? "No applications yet" : "No posts yet")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private func loadAll() async {
        isLoadingOffers = true
        async let inbox: () = vm.loadInbox(ownerId: uid)
        async let requests: () = vm.loadMyRequests(requesterId: uid)
        async let offers = (try? await offerService.fetchOffersByOwner(ownerId: uid)) ?? []
        let (_, _, fetchedOffers) = await (inbox, requests, offers)
        myOffers = fetchedOffers
        isLoadingOffers = false
    }

    private func deleteOffer(_ offer: Offer) async {
        guard let id = offer.id else { return }
        try? await offerService.deleteOffer(id: id)
        myOffers.removeAll { $0.id == id }
    }
}

private struct TransactionRow: View {
    let transaction: Transaction
    let isInbox: Bool

    var body: some View {
        HStack(spacing: 12) {
            NEIRowIconTile(
                systemImage: isInbox ? "person.fill" : "arrow.up.right",
                color: Color.neiGreen
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.offerTitle)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                if isInbox {
                    Text("Volunteer: \(transaction.requesterName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if transaction.status == .accepted, let dueDate = transaction.dueDate {
                    Label(
                        transaction.isOverdue ? "Overdue · \(dueDate.formatted(.dateTime.day().month()))" : "Return by \(dueDate.formatted(.dateTime.day().month()))",
                        systemImage: transaction.isOverdue ? "exclamationmark.triangle.fill" : "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(transaction.isOverdue ? .red : .secondary)
                } else {
                    Text(transaction.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 8)
            NEIStatusBadge(status: transaction.status)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
