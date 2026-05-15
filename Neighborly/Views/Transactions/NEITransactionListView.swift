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
            .task { await loadAll() }
        }
    }

    private var isLoading: Bool {
        selectedTab == 2 ? isLoadingOffers : vm.isLoading
    }

    @ViewBuilder
    private var listContent: some View {
        if selectedTab == 2 {
            List {
                ForEach(myOffers) { offer in
                    OfferRow(offer: offer)
                        .listRowBackground(Color(.systemBackground))
                }
                .onDelete { indexSet in
                    Task { await deleteOffers(at: indexSet) }
                }
            }
            .listStyle(.plain)
            .overlay {
                if myOffers.isEmpty { emptyState }
            }
        } else {
            List {
                ForEach(selectedTab == 0 ? vm.inbox : vm.myRequests) { transaction in
                    TransactionRow(transaction: transaction, isInbox: selectedTab == 0)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedTransaction = transaction }
                        .listRowBackground(Color(.systemBackground))
                }
            }
            .listStyle(.plain)
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
        async let inbox: () = vm.loadInbox(ownerId: uid)
        async let requests: () = vm.loadMyRequests(requesterId: uid)
        _ = await (inbox, requests)
        await loadMyOffers()
    }

    private func loadMyOffers() async {
        isLoadingOffers = true
        myOffers = (try? await offerService.fetchOffersByOwner(ownerId: uid)) ?? []
        isLoadingOffers = false
    }

    private func deleteOffers(at indexSet: IndexSet) async {
        for index in indexSet {
            let offer = myOffers[index]
            guard let id = offer.id else { continue }
            try? await offerService.deleteOffer(id: id)
        }
        myOffers.remove(atOffsets: indexSet)
    }
}

private struct TransactionRow: View {
    let transaction: Transaction
    let isInbox: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: isInbox ? "person.crop.circle" : "arrow.up.circle")
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.offerTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if isInbox {
                    Text("Volunteer: \(transaction.requesterName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(transaction.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
            NEIStatusBadge(status: transaction.status)
        }
        .padding(.vertical, 8)
    }
}

private struct OfferRow: View {
    let offer: Offer

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: offer.category.systemImage)
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(offer.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let address = offer.address, !address.isEmpty {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(offer.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            NEICategoryBadge(category: offer.category)
        }
        .padding(.vertical, 8)
    }
}
