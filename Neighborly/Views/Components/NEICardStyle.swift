//
//  NEICardStyle.swift
//  Neighborly
//

import SwiftUI

extension View {
    /// Wspólny styl karty: tło elewowane + cienki obrys (kontrast też w dark mode).
    func cardStyle(cornerRadius: CGFloat = 14) -> some View {
        self
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color(.separator).opacity(0.6), lineWidth: 0.5)
            )
    }
}
