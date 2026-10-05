//
//  NEIAllReviewsView.swift
//  Neighborly
//

import SwiftUI
import FirebaseAuth

struct NEIAllReviewsView: View {
    let reviews: [Review]

    @EnvironmentObject private var authService: NEIAuthService
    @State private var reportTarget: NEIReportTarget?

    private var uid: String { authService.currentUser?.uid ?? "" }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(reviews.enumerated()), id: \.element.id) { index, review in
                    if index > 0 {
                        Divider()
                    }
                    ReviewRow(review: review, onReport: review.reviewerId == uid ? nil : { reportTarget = .review(review) })
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(.separator).opacity(0.6), lineWidth: 0.5))
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .neiReportFlow(target: $reportTarget, reporterId: uid)
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
    }
}
