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
    // true = liczy się też godzina z dueDate; nil/false = cały dzień (dueDate to początek dnia)
    var dueHasTime: Bool?
    var createdAt: Date
    var updatedAt: Date

    var dateKind: TransactionDateKind {
        offerCategory == nil || offerCategory == .items ? .returnDate : .plannedDate
    }

    var hasDueTime: Bool { dueHasTime ?? false }

    var isOverdue: Bool {
        guard status == .accepted, dateKind == .returnDate, let dueDate else { return false }
        return NEIDueDate.isPast(dueDate, hasTime: hasDueTime)
    }
}

// Wspólne formatowanie i logika terminu — lista, szczegóły i przypomnienia mówią to samo
enum NEIDueDate {
    // Termin bez godziny mija dopiero po końcu dnia
    static func isPast(_ date: Date, hasTime: Bool, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        hasTime ? date < now : date < calendar.startOfDay(for: now)
    }

    // "Today", "Tomorrow at 15:00", "Thursday, 3 October" — dzień tygodnia tylko w ciągu tygodnia
    static func dayText(_ date: Date, hasTime: Bool, now: Date = Date(), calendar: Calendar = .current) -> String {
        let day: String
        if calendar.isDate(date, inSameDayAs: now) {
            day = "Today"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            day = "Tomorrow"
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            day = "Yesterday"
        } else if let days = daysBetween(now, date, calendar: calendar), (2...6).contains(days) {
            day = date.formatted(.dateTime.weekday(.wide))
        } else {
            day = date.formatted(.dateTime.weekday(.wide).day().month(.wide))
        }
        return hasTime ? "\(day) at \(timeText(date))" : day
    }

    // Krótka wersja do wiersza listy: "Today", "Tomorrow", "Thu, 3 Oct"
    static func shortDayText(_ date: Date, hasTime: Bool, now: Date = Date(), calendar: Calendar = .current) -> String {
        let day: String
        if calendar.isDate(date, inSameDayAs: now) {
            day = "today"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            day = "tomorrow"
        } else {
            day = date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        }
        return hasTime ? "\(day) at \(timeText(date))" : day
    }

    static func timeText(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    // Ile pełnych dni po terminie (0 = termin jest dziś lub później)
    static func daysOverdue(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> Int {
        max(0, daysBetween(date, now, calendar: calendar) ?? 0)
    }

    private static func daysBetween(_ from: Date, _ to: Date, calendar: Calendar) -> Int? {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: from), to: calendar.startOfDay(for: to)).day
    }
}
