//
//  NEITransactionService.swift
//  Neighborly
//

import Foundation
import FirebaseFirestore

final class NEITransactionService {
    private let db = Firestore.firestore()
    private let collection = "transactions"

    func createTransaction(_ transaction: Transaction) async throws -> String {
        let ref = try db.collection(collection).addDocument(from: transaction)
        return ref.documentID
    }

    // Owner's inbox — requests on their offers
    func fetchInbox(ownerId: String) async throws -> [Transaction] {
        let snapshot = try await db.collection(collection)
            .whereField("ownerId", isEqualTo: ownerId)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: Transaction.self) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func fetchMyRequests(requesterId: String) async throws -> [Transaction] {
        let snapshot = try await db.collection(collection)
            .whereField("requesterId", isEqualTo: requesterId)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: Transaction.self) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func updateStatus(transactionId: String, status: TransactionStatus) async throws {
        try await db.collection(collection).document(transactionId).updateData([
            "status": status.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])
    }

    func fetchTransaction(id: String) async throws -> Transaction? {
        let doc = try await db.collection(collection).document(id).getDocument()
        return try? doc.data(as: Transaction.self)
    }
}
