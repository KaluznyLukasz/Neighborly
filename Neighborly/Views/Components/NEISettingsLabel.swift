//
//  NEISettingsLabel.swift
//  Neighborly
//

import SwiftUI

/// Kolorowy kafelek z białym symbolem — jak ikony w aplikacji Ustawienia.
struct NEISettingsIcon: View {
    let systemImage: String
    let tint: Color

    @ScaledMetric(relativeTo: .body) private var scaledSide: CGFloat = 29

    // Kafelek rośnie z Dynamic Type, ale z limitem — przy największych rozmiarach
    // zabierałby pół wiersza. Symbol skaluje się razem z kafelkiem.
    private var side: CGFloat { min(scaledSide, 44) }

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: side * 0.52, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: side, height: side)
            .background(tint.gradient, in: .rect(cornerRadius: 7, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Ikona + tytuł wiersza ustawień. HStack zamiast `Label` — w wierszu List `Label`
/// bywa restylowany (zob. docs/learnings/list-row-restyles-label-in-button.md).
struct NEISettingsLabel: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            NEISettingsIcon(systemImage: systemImage, tint: tint)
            // Color(.label) zamiast .primary — w Button wewnątrz List tint nadpisuje styl hierarchiczny
            Text(title)
                .foregroundStyle(Color(.label))
        }
    }
}
