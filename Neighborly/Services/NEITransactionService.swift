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
        // Deterministyczne ID — jedna aplikacja na parę (oferta, wnioskodawca)
        let id = "\(transaction.offerId)_\(transaction.requesterId)"
        try db.collection(collection).document(id).setData(from: transaction, merge: false)
        return id
    }

    // Zwraca istniejącą transakcję dla pary (oferta, wnioskodawca), jeśli jest
    func existingTransaction(offerId: String, requesterId: String) async throws -> Transaction? {
        let id = "\(offerId)_\(requesterId)"
        let doc = try await db.collection(collection).document(id).getDocument()
        return try? doc.data(as: Transaction.self)
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

    func deleteTransaction(id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
}
