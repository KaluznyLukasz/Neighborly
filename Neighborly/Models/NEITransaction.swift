//
//  NEITransaction.swift
//  Neighborly
//
//  Created by Łukasz Kałużny on 11/05/2026.
//

import Foundation
import FirebaseFirestore

enum TransactionStatus: String, Codable {
    case pending   = "pending"
    case accepted  = "accepted"
    case rejected  = "rejected"
    case completed = "completed"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .pending:   return "Pending"
        case .accepted:  return "Accepted"
        case .rejected:  return "Rejected"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var color: String {
        switch self {
        case .pending:   return "orange"
        case .accepted:  return "green"
        case .rejected:  return "red"
        case .completed: return "blue"
        case .cancelled: return "gray"
        }
    }
}

struct Transaction: Identifiable, Codable {
    @DocumentID var id: String?
    var offerId: String
    var offerTitle: String
    var requesterId: String
    var requesterName: String
    var ownerId: String
    var status: TransactionStatus
    var message: String?
    var createdAt: Date
    var updatedAt: Date
}
