//
//  Color+NEI.swift
//  Neighborly
//

import SwiftUI

extension Color {
    static let neiGreen      = Color(hex: "#3CB371")
    static let neiGreenLight = Color(hex: "#E8F5E9")
    static let neiOnyx       = Color(hex: "#1C1C1E")
    static let neiGray       = Color(hex: "#8E8E93")
    static let neiSurface    = Color(hex: "#F2F2F7")
    static let neiRed        = Color(hex: "#FF3B30")
    static let neiAmber      = Color(hex: "#FF9500")
    static let neiBlue   = Color(hex: "#5AC8FA")
    static let neiPurple = Color(hex: "#AF52DE")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
