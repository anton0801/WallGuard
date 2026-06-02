import SwiftUI

struct WGColor {
    // Backgrounds
    static let bg            = Color(hex: "0F172A")
    static let bgDeep        = Color(hex: "111827")
    static let bgSoft        = Color(hex: "1A1F2E")
    static let card          = Color(hex: "1E293B")
    static let cardHover     = Color(hex: "263244")
    static let divider       = Color(hex: "334155")

    // Primary accent - yellow
    static let yellow        = Color(hex: "FACC15")
    static let yellowActive  = Color(hex: "EAB308")
    static let yellowGlow    = Color(hex: "FDE047")

    // Secondary accent - orange
    static let orange        = Color(hex: "F97316")
    static let orangeSoft    = Color(hex: "FB923C")

    // Structure accent - blue
    static let blue          = Color(hex: "3B82F6")
    static let blueSoft      = Color(hex: "60A5FA")

    // Status
    static let success       = Color(hex: "22C55E")
    static let warning       = Color(hex: "FACC15")
    static let danger        = Color(hex: "EF4444")

    // Text
    static let textPrimary   = Color(hex: "F8FAFC")
    static let textSecondary = Color(hex: "CBD5E1")
    static let textMuted     = Color(hex: "64748B")

    // Glows
    static let yellowGlowFill = Color(hex: "FACC15").opacity(0.35)
    static let orangeGlowFill = Color(hex: "F97316").opacity(0.3)
}

extension Color {
    init(hex: String) {
        let sc = Scanner(string: hex)
        var rgb: UInt64 = 0
        sc.scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >>  8) & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }
}
