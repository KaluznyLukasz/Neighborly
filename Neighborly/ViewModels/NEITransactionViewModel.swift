//
//  NEITransactionViewModel.swift
//  Neighborly
//

import Foundation

@MainActor
@Observable
final class NEITransactionViewModel {
    var inbox: [Transaction] = [] {
        didSet { pendingInboxCount = inbox.filter { $0.status == .pending }.count }
    }
    var myRequests: [Transaction] = []
    var isLoading = false
    var errorMessage: String?
    private(set) var pendingInboxCount = 0

    private let transactionService = NEITransactionService()
    // Przypomnienia synchronizujemy dopiero, gdy znamy obie listy — inaczej częściowy stan
    // skasowałby przypomnienia drugiej roli
    private var userId: String?
    private var hasLoadedInbox = false
    private var hasLoadedRequests = false
    // Licznik zmian terminu na transakcję — cofamy tylko ostatnią nieudaną
    private var dueDateEdits: [String: Int] = [:]

    func loadInbox(ownerId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            inbox = try await transactionService.fetchInbox(ownerId: ownerId)
            userId = ownerId
            hasLoadedInbox = true
            await syncReminders()
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
            userId = requesterId
            hasLoadedRequests = true
            await syncReminders()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @discardableResult
    func accept(transaction: Transaction) async -> Bool {
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

    // dueDate == nil czyści termin. Zmiana działa od razu: listy, karta i przypomnienia
    // aktualizują się natychmiast, a zapis idzie w tle. Nie czekamy na zapis, bo offline
    // Firestore kończy go dopiero po powrocie sieci. Błąd zapisu cofa zmianę, chyba że
    // w międzyczasie przyszła nowsza.
    func setDueDate(transaction: Transaction, dueDate: Date?, hasTime: Bool) {
        guard let id = transaction.id else { return }
        errorMessage = nil
        let hasTime = dueDate != nil && hasTime
        let previous = current(id: id) ?? transaction
        let edit = (dueDateEdits[id] ?? 0) + 1
        dueDateEdits[id] = edit
        apply(id: id) {
            $0.dueDate = dueDate
            $0.dueHasTime = dueDate == nil ? nil : hasTime
        }

        Task {
            // Pytamy o zgodę, gdy właściciel ustawia termin i widać, po co ona jest.
            // Przed synchronizacją, żeby ta nie zdążyła poprosić o cichą zgodę.
            if dueDate != nil { await NEIReminderService.requestAuthorizationIfNeeded() }
            await syncReminders()
        }

        Task {
            do {
                try await transactionService.setDueDate(transactionId: id, dueDate: dueDate, hasTime: hasTime)
            } catch {
                guard dueDateEdits[id] == edit else { return }
                errorMessage = error.localizedDescription
                apply(id: id) {
                    $0.dueDate = previous.dueDate
                    $0.dueHasTime = previous.dueHasTime
                }
                await syncReminders()
            }
        }
    }

    // Aktualny stan transakcji z list (może być nowszy niż kopia w otwartym widoku)
    func current(id: String) -> Transaction? {
        inbox.first { $0.id == id } ?? myRequests.first { $0.id == id }
    }

    private func apply(id: String, _ change: (inout Transaction) -> Void) {
        if let i = inbox.firstIndex(where: { $0.id == id }) { change(&inbox[i]) }
        if let i = myRequests.firstIndex(where: { $0.id == id }) { change(&myRequests[i]) }
    }

    private func syncReminders() async {
        guard hasLoadedInbox, hasLoadedRequests, let userId else { return }
        await NEIReminderService.sync(transactions: inbox + myRequests, userId: userId)
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

    @discardableResult
    private func updateStatus(transaction: Transaction, status: TransactionStatus) async -> Bool {
        guard let id = transaction.id else { return false }
        errorMessage = nil
        do {
            try await transactionService.updateStatus(transactionId: id, status: status)
            update(id: id, status: status)
            await syncReminders()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func update(id: String, status: TransactionStatus) {
        apply(id: id) { $0.status = status }
    }
}
