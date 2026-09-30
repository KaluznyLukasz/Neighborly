//
//  NEIMessageService.swift
//  Neighborly
//

import Foundation
import FirebaseFirestore

final class NEIMessageService {
    private let db = Firestore.firestore()

    // Ścieżka rozmowy, np. "transactions/{id}/messages" albo "alerts/{id}/threads/{uid}/messages"
    static func path(transactionId: String) -> String { "transactions/\(transactionId)/messages" }
    static func path(alertId: String, viewerId: String) -> String { "alerts/\(alertId)/threads/\(viewerId)/messages" }

    private func messagesRef(path: String) -> CollectionReference {
        db.collection(path)
    }

    func send(path: String, message: Message) async throws {
        let data = try Firestore.Encoder().encode(message)
        try await messagesRef(path: path).addDocument(data: data)
    }

    func messageStream(path: String) -> AsyncStream<[Message]> {
        AsyncStream { continuation in
            // Trzymamy zdekodowane wiadomości po ID i łatamy tylko zmienione dokumenty —
            // inaczej każda nowa wiadomość dekodowałaby całą historię czatu od nowa
            var byId: [String: Message] = [:]
            var order: [String] = []

            let listener = messagesRef(path: path)
                .order(by: "createdAt")
                .addSnapshotListener { snapshot, _ in
                    guard let snapshot else { return }
                    for change in snapshot.documentChanges {
                        let id = change.document.documentID
                        switch change.type {
                        case .added, .modified:
                            if let msg = try? change.document.data(as: Message.self) {
                                if byId[id] == nil { order.insert(id, at: min(Int(change.newIndex), order.count)) }
                                byId[id] = msg
                            }
                        case .removed:
                            byId.removeValue(forKey: id)
                            order.removeAll { $0 == id }
                        }
                    }
                    continuation.yield(order.compactMap { byId[$0] })
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }
}
