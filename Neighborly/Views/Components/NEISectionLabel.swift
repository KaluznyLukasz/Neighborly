//
//  NEISectionLabel.swift
//  Neighborly
//

import SwiftUI

/// Mały nagłówek nad kartą (WIELKIE LITERY) — wspólny dla ekranów szczegółów.
struct NEISectionLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.leading, 4)
            .accessibilityAddTraits(.isHeader)
    }
}
