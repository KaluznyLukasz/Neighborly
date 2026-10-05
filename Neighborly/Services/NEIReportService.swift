//
//  NEIReportService.swift
//  Neighborly
//

import Foundation
import FirebaseFirestore

// Zgłoszenia treści (wytyczna App Store 1.2). Kolekcja `reports` jest tylko do zapisu —
// przegląda ją moderator w konsoli Firebase (docs/moderation.md).

enum NEIReportReason: String, Codable, CaseIterable, Identifiable {
    case spam, inappropriate, harassment, dangerous, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spam: "Spam or Scam"
        case .inappropriate: "Sexual or Violent Content"
        case .harassment: "Harassment or Hate Speech"
        case .dangerous: "Dangerous or Illegal"
        case .other: "Something Else"
        }
    }
}

enum NEIReportTargetType: String, Codable {
    case offer, alert, user, message, review

    var noun: String {
        switch self {
        case .offer: "offer"
        case .alert: "alert"
        case .user: "person"
        case .message: "message"
        case .review: "review"
        }
    }
}

// Co zgłaszamy. `id` to ID dokumentu, a dla wiadomości pełna ścieżka (rozmowy są podkolekcjami).
// `excerpt` zapisujemy w zgłoszeniu, żeby moderator widział treść nawet po jej usunięciu.
struct NEIReportTarget: Identifiable, Hashable {
    let type: NEIReportTargetType
    let targetId: String
    let ownerId: String
    let ownerName: String
    let excerpt: String

    var id: String { "\(type.rawValue):\(targetId)" }
}

extension NEIReportTarget {
    static func review(_ review: Review) -> NEIReportTarget {
        NEIReportTarget(
            type: .review,
            targetId: review.id ?? "",
            ownerId: review.reviewerId,
            ownerName: review.reviewerName,
            excerpt: review.comment ?? ""
        )
    }
}

struct NEIReport: Codable {
    var reporterId: String
    var targetType: NEIReportTargetType
    var targetId: String
    var targetOwnerId: String
    var excerpt: String
    var reason: NEIReportReason
    var status: String
    var createdAt: Date

    static let maxExcerptLength = 500
}

final class NEIReportService {
    private let db = Firestore.firestore()

    func submit(_ target: NEIReportTarget, reason: NEIReportReason, reporterId: String) async throws {
        let report = NEIReport(
            reporterId: reporterId,
            targetType: target.type,
            targetId: target.targetId,
            targetOwnerId: target.ownerId,
            excerpt: String(target.excerpt.prefix(NEIReport.maxExcerptLength)),
            reason: reason,
            status: "open",
            createdAt: Date()
        )
        let data = try Firestore.Encoder().encode(report)
        try await db.collection("reports").addDocument(data: data)
    }
}
