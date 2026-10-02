//
//  NEIFieldGroup.swift
//  Neighborly
//

import SwiftUI

/// Pola tekstowe w jednej zaokrąglonej karcie z separatorami — jak sekcja w Ustawieniach.
struct NEIFieldGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { subviews in
                ForEach(subviews) { subview in
                    subview
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)

                    if subview.id != subviews.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
    }
}
