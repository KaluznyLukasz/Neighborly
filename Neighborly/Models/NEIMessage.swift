//
//  NEIMessage.swift
//  Neighborly
//

import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var senderId: String
    var senderName: String
    var text: String
    var createdAt: Date
}
