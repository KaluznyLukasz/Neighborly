//
//  NEIAuthHeader.swift
//  Neighborly
//

import SwiftUI

/// Nagłówek ekranów logowania i rejestracji: ikona aplikacji, tytuł, podtytuł.
struct NEIAuthHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(spacing: 12) {
            // PNG ma już wtopiony kształt ikony (przezroczyste rogi), więc bez clipShape
            Image("NeighborlyIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                .accessibilityHidden(true)
                .padding(.bottom, 4)

            Text(title)
                .font(.largeTitle.bold())

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }
}
