//
//  NEIAllReviewsView.swift
//  Neighborly
//

import SwiftUI

struct NEIAllReviewsView: View {
    let reviews: [Review]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(reviews.enumerated()), id: \.element.id) { index, review in
                    if index > 0 {
                        Divider()
                    }
                    ReviewRow(review: review)
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
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
    }
}
