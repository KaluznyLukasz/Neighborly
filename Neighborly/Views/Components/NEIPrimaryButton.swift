//
//  NEIPrimaryButton.swift
//  Neighborly
//

import SwiftUI

struct NEIPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isLoading)
    }
}
