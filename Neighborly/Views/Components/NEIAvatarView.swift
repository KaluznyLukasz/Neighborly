//
//  NEIAvatarView.swift
//  Neighborly
//

import SwiftUI

struct NEIAvatarView: View {
    let url: String?
    let name: String
    var size: CGFloat = 48
    var base64: String? = nil

    var body: some View {
        Group {
            if let b64 = base64,
               let data = Data(base64Encoded: b64, options: .ignoreUnknownCharacters),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = url, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsView: some View {
        ZStack {
            Circle().fill(Color.neiGreen.opacity(0.2))
            Text(initials)
                .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.neiGreen)
        }
    }

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map(String.init).joined().uppercased()
    }
}
