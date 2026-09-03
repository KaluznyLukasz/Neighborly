//
//  NEITransactionViewModel.swift
//  Neighborly
//

import Foundation

@MainActor
@Observable
final class NEITransactionViewModel {
    var inbox: [Transaction] = []
    var myRequests: [Transaction] = []
    var isLoading = false
    var errorMessage: String?

    private let transactionService = NEITransactionService()

    func loadInbox(ownerId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            inbox = try await transactionService.fetchInbox(ownerId: ownerId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMyRequests(requesterId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            myRequests = try await transactionService.fetchMyRequests(requesterId: requesterId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func accept(transaction: Transaction) async {
        await updateStatus(transaction: transaction, status: .accepted)
    }

    func reject(transaction: Transaction) async {
        await updateStatus(transaction: transaction, status: .rejected)
    }

    func complete(transaction: Transaction) async {
        await updateStatus(transaction: transaction, status: .completed)
    }

    func cancel(transaction: Transaction) async {
        await updateStatus(transaction: transaction, status: .cancelled)
    }

    func delete(transaction: Transaction) async {
        guard let id = transaction.id else { return }
        errorMessage = nil

        let inboxIndex = inbox.firstIndex { $0.id == id }
        let requestsIndex = myRequests.firstIndex { $0.id == id }
        if let i = inboxIndex { inbox.remove(at: i) }
        if let i = requestsIndex { myRequests.remove(at: i) }

        do {
            try await transactionService.deleteTransaction(id: id)
        } catch {
            errorMessage = error.localizedDescription
            if let i = inboxIndex, i <= inbox.count { inbox.insert(transaction, at: min(i, inbox.count)) }
            if let i = requestsIndex, i <= myRequests.count { myRequests.insert(transaction, at: min(i, myRequests.count)) }
        }
    }

    private func updateStatus(transaction: Transaction, status: TransactionStatus) async {
        guard let id = transaction.id else { return }
        errorMessage = nil
        do {
            try await transactionService.updateStatus(transactionId: id, status: status)
            update(id: id, status: status)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func update(id: String, status: TransactionStatus) {
        if let i = inbox.firstIndex(where: { $0.id == id }) {
            inbox[i].status = status
        }
        if let i = myRequests.firstIndex(where: { $0.id == id }) {
            myRequests[i].status = status
        }
    }

    var pendingInboxCount: Int {
        inbox.filter { $0.status == .pending }.count
    }
}
