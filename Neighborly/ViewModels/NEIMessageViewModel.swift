//
//  NEIMessageViewModel.swift
//  Neighborly
//

import Foundation

@MainActor
@Observable
final class NEIMessageViewModel {
    var messages: [Message] = []
    var isSending = false
    var errorMessage: String?

    private let service = NEIMessageService()
    private var listeningTask: Task<Void, Never>?

    func startListening(transactionId: String) {
        listeningTask = Task {
            for await msgs in service.messageStream(transactionId: transactionId) {
                messages = msgs
            }
        }
    }

    func stopListening() {
        listeningTask?.cancel()
        listeningTask = nil
    }

    func send(transactionId: String, senderId: String, senderName: String, text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSending = true
        errorMessage = nil
        let msg = Message(senderId: senderId, senderName: senderName, text: trimmed, createdAt: Date())
        do {
            try await service.send(transactionId: transactionId, message: msg)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }
}
