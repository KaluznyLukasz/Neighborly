//
//  NEIPostRow.swift
//  Neighborly
//

import SwiftUI

/// Wiersz posta: kafelek kategorii, tytuł, adres, „Kategoria · czas”; „Paused” gdy nieaktywny.
struct NEIPostRow: View {
    let offer: Offer

    var body: some View {
        HStack(spacing: 12) {
            NEIRowIconTile(systemImage: offer.category.systemImage, color: offer.category.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(offer.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                if let address = offer.address, !address.isEmpty {
                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                // Kategoria · czas publikacji — zastępuje osobny badge, który ściskał adres.
                HStack(spacing: 4) {
                    Text(offer.category.displayName)
                        .foregroundStyle(offer.category.color)
                    Text("·")
                    Text(offer.createdAt.formatted(.relative(presentation: .named)))
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 8)

            if !offer.isActive {
                Text("Paused")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray5), in: .capsule)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

/// Zaokrąglony kafelek z ikoną SF Symbol na przygaszonym tle koloru — jak w Ustawieniach.
struct NEIRowIconTile: View {
    let systemImage: String
    let color: Color
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 40

    var body: some View {
        Image(systemName: systemImage)
            .font(.body)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.15), in: .rect(cornerRadius: 10))
            .accessibilityHidden(true)
    }
}
