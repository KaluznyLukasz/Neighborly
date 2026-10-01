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

// Co znaczy termin przy transakcji: zwrot pożyczonej rzeczy albo umówiony dzień
// (naprawa, pomoc, jedzenie, usługa). Od tego zależą teksty i to, czy termin może być "po terminie".
enum TransactionDateKind {
    case returnDate, plannedDate
}

struct Transaction: Identifiable, Codable {
    @DocumentID var id: String?
    var offerId: String
    var offerTitle: String
    var requesterId: String
    var requesterName: String
    var ownerId: String
    // nil w transakcjach sprzed dodania pola — wtedy termin traktujemy jak zwrot, tak jak dotąd
    var offerCategory: OfferCategory?
    var status: TransactionStatus
    var message: String?
    // Termin ustawia właściciel po zaakceptowaniu; nil = bez terminu
    var dueDate: Date?
    var createdAt: Date
    var updatedAt: Date

    var dateKind: TransactionDateKind {
        offerCategory == nil || offerCategory == .items ? .returnDate : .plannedDate
    }

    var isOverdue: Bool {
        guard status == .accepted, dateKind == .returnDate, let dueDate else { return false }
        return dueDate < Calendar.current.startOfDay(for: Date())
    }
}
