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

    func startListening(path: String) {
        stopListening()
        listeningTask = Task {
            for await msgs in service.messageStream(path: path) {
                messages = msgs
            }
        }
    }

    func stopListening() {
        listeningTask?.cancel()
        listeningTask = nil
    }

    @discardableResult
    func send(path: String, senderId: String, senderName: String, text: String) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        isSending = true
        errorMessage = nil
        let msg = Message(senderId: senderId, senderName: senderName, text: trimmed, createdAt: Date())
        defer { isSending = false }
        do {
            try await service.send(path: path, message: msg)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
