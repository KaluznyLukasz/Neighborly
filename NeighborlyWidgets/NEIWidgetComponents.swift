//
//  NEIWidgetComponents.swift
//  NeighborlyWidgets
//

import SwiftUI
import UIKit
import WidgetKit

// Nagłówek obu widżetów: ikona w kolorze marki, nazwa, po prawej licznik
struct NEIWidgetHeader<Trailing: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.neiGreen)
                .widgetAccentable()
                .accessibilityHidden(true)
            Text(title)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 4)
            trailing
        }
        .font(.caption.weight(.semibold))
        .lineLimit(1)
    }
}

extension NEIWidgetHeader where Trailing == EmptyView {
    init(title: String, systemImage: String) {
        self.init(title: title, systemImage: systemImage) { EmptyView() }
    }
}

// Kafelek z ikoną jak w wierszach aplikacji (NEIRowIconTile). Tło to przezroczysty kolor,
// więc w trybie przyciemnianym (tinted / clear) zostaje delikatne, a ikona przyjmuje akcent.
struct NEIWidgetIconTile: View {
    let systemImage: String
    let color: Color
    @ScaledMetric(relativeTo: .subheadline) private var size: CGFloat = 30

    var body: some View {
        Image(systemName: systemImage)
            .font(.subheadline)
            .foregroundStyle(color)
            .widgetAccentable()
            .frame(width: size, height: size)
            .background(color.opacity(0.15), in: .rect(cornerRadius: size * 0.27))
            .accessibilityHidden(true)
    }
}

// Pusty stan: tytuł i jedno zdanie, co tu się pojawi albo co zrobić
struct NEIWidgetMessage: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

extension View {
    // Tło jak w widżetach systemowych: białe w jasnym, grafitowe w ciemnym trybie
    func neiWidgetBackground() -> some View {
        containerBackground(Color(.secondarySystemGroupedBackground), for: .widget)
    }
}
