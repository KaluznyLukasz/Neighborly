//
//  NEIReview.swift
//  Neighborly
//
//  Created by Łukasz Kałużny on 11/05/2026.
//

import Foundation

struct Review: Identifiable, Codable {
    var id: String?
    var transactionId: String
    var reviewerId: String
    var revieweeId: String
    var rating: Int       // 1–5
    var comment: String?
    var createdAt: Date
}
