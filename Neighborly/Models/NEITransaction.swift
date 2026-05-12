//
//  NEITransaction.swift
//  Neighborly
//
//  Created by Łukasz Kałużny on 11/05/2026.
//

import Foundation

enum TransactionStatus: String, Codable {
    case pending   = "pending"
    case accepted  = "accepted"
    case rejected  = "rejected"
    case completed = "completed"
    case cancelled = "cancelled"
}

struct Transaction: Identifiable, Codable {
    var id: String?
    var offerId: String
    var requesterId: String
    var ownerId: String
    var status: TransactionStatus
    var message: String?
    var createdAt: Date
    var updatedAt: Date
}
