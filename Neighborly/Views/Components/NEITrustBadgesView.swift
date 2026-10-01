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
                        // HStack zamiast Label — wiersz List przestylowuje Label
                        // (chowa tytuł i rozciąga kapsułę w pionie).
                        HStack(spacing: 4) {
                            Image(systemName: badge.systemImage)
                                .symbolEffect(.bounce, value: selected == badge)
                            Text(badge.title)
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(badge.color.opacity(0.15), in: Capsule())
                        .foregroundStyle(badge.color)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: selected)
                    .accessibilityHint("Shows how this badge is earned")
                    // Mały dymek przy odznace zamiast alertu; na iPhonie domyślnie
                    // rozwinąłby się jako arkusz, więc wymuszamy popover.
                    .popover(isPresented: isPresented(badge)) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: badge.systemImage)
                                .font(.subheadline)
                                .foregroundStyle(badge.color)
                                .frame(width: 32, height: 32)
                                .background(badge.color.opacity(0.15), in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(badge.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(badge.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: 280, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .presentationCompactAdaptation(.popover)
                    }
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
    }

    private func isPresented(_ badge: NEITrustBadge) -> Binding<Bool> {
        Binding(
            get: { selected == badge },
            set: { if !$0 && selected == badge { selected = nil } }
        )
    }
}
