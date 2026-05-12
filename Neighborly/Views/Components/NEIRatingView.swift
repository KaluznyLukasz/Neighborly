//
//  NEIRatingView.swift
//  Neighborly
//

import SwiftUI

struct NEIRatingView: View {
    let rating: Double
    let reviewCount: Int
    var starSize: CGFloat = 14

    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: starName(for: i))
                        .font(.system(size: starSize))
                        .foregroundStyle(.yellow)
                }
            }
            Text(String(format: "%.1f", rating))
                .font(.system(size: starSize, weight: .semibold))
            if reviewCount > 0 {
                Text("(\(reviewCount))")
                    .font(.system(size: starSize))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func starName(for position: Int) -> String {
        let filled = Double(position) <= rating
        let half   = Double(position) - 0.5 <= rating && Double(position) > rating
        if filled  { return "star.fill" }
        if half    { return "star.leadinghalf.filled" }
        return "star"
    }
}
