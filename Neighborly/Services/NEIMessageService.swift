//
//  NEIMessageService.swift
//  Neighborly
//

import Foundation
import FirebaseFirestore

final class NEIMessageService {
    private let db = Firestore.firestore()

    private func messagesRef(transactionId: String) -> CollectionReference {
        db.collection("transactions").document(transactionId).collection("messages")
    }

    func send(transactionId: String, message: Message) async throws {
        let data = try Firestore.Encoder().encode(message)
        try await messagesRef(transactionId: transactionId).addDocument(data: data)
    }

    func messageStream(transactionId: String) -> AsyncStream<[Message]> {
        AsyncStream { continuation in
            let listener = messagesRef(transactionId: transactionId)
                .order(by: "createdAt")
                .addSnapshotListener { snapshot, _ in
                    let msgs = snapshot?.documents.compactMap { try? $0.data(as: Message.self) } ?? []
                    continuation.yield(msgs)
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }
}
