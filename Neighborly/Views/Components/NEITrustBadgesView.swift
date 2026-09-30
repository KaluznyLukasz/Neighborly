//
//  NEITrustBadgesView.swift
//  Neighborly
//

import SwiftUI

struct NEITrustBadgesView: View {
    let badges: [NEITrustBadge]
    @State private var selected: NEITrustBadge?

    var body: some View {
        if !badges.isEmpty {
            NEIFlowLayout(spacing: 8) {
                ForEach(badges) { badge in
                    Button {
                        selected = badge
                    } label: {
                        Label(badge.title, systemImage: badge.systemImage)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(badge.color.opacity(0.15), in: Capsule())
                            .foregroundStyle(badge.color)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Shows how this badge is earned")
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .alert(selected?.title ?? "", isPresented: Binding(
                get: { selected != nil },
                set: { if !$0 { selected = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(selected?.detail ?? "")
            }
        }
    }
}
