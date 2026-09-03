//
//  Color+NEI.swift
//  Neighborly
//

import SwiftUI
import UIKit

extension Color {
    static let neiGreen      = Color(hex: "#3CB371")
    static let neiOnyx       = Color(hex: "#1C1C1E")
    static let neiGray       = Color(hex: "#8E8E93")
    static let neiRed        = Color(hex: "#FF3B30")
    static let neiAmber      = Color(hex: "#FF9500")
    static let neiBlue   = Color(hex: "#5AC8FA")
    static let neiPurple = Color(hex: "#AF52DE")

    // Jasne kafelki pod ikony — w trybie ciemnym zamiast prawie-białego dajemy
    // półprzezroczysty odcień koloru marki, żeby był kontrast.
    static let neiGreenLight = Color(light: Color(hex: "#E8F5E9"),
                                     dark:  Color(hex: "#3CB371").opacity(0.22))
    static let neiAmberLight = Color(light: Color(hex: "#FFF3E0"),
                                     dark:  Color(hex: "#FF9500").opacity(0.22))

    /// Kolor zależny od trybu jasny/ciemny (bez katalogu zasobów).
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

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
