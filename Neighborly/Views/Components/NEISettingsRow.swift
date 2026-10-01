//
//  NEISettingsRow.swift
//  Neighborly
//

import SwiftUI

/// Karta z tytułem sekcji — wspólny styl dla ekranów profilu/ustawień.
struct NEISectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NEISectionHeader(title: title)

            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .neiCardBackground()
        }
    }
}

/// Nagłówek sekcji w stylu grupowanych list systemowych (footnote, wielkie litery).
struct NEISectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.bottom, 8)
            .padding(.leading, 4)
            .accessibilityAddTraits(.isHeader)
    }
}

extension View {
    /// Tło karty: elewowany kolor grupowany, zaokrąglenie 14, cienki obrys i delikatny cień.
    func neiCardBackground() -> some View {
        self
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(.separator).opacity(0.6), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

/// Wiersz z kolorową ikoną, tytułem i opcjonalną zawartością końcową — wspólny styl
/// dla wierszy w `NEISectionCard`.
struct NEISettingsRow<Trailing: View>: View {
    let title: String
    let systemImage: String
    let tint: Color
    var showChevron: Bool = true
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            NEISettingsIcon(systemImage: systemImage, tint: tint)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Spacer()

            trailing()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

extension NEISettingsRow where Trailing == EmptyView {
    init(title: String, systemImage: String, tint: Color, showChevron: Bool = true) {
        self.init(title: title, systemImage: systemImage, tint: tint, showChevron: showChevron) { EmptyView() }
    }
}
