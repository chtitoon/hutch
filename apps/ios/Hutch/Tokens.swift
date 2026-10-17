// Generated from design/tokens.json and design/light/logo.svg by `make tokens`. Do not edit.
import SwiftUI

/// Color roles from design/tokens.json. Each switches to its `color-dark` value in dark mode.
enum Palette {
    static let accent = Color(light: 0xD4A24C, dark: 0xD4A24C)
    static let background = Color(light: 0xF3F1EC, dark: 0x152319)
    static let border = Color(light: 0xDEDAD0, dark: 0x2B3D32)
    static let borderDashed = Color(light: 0xC9C5BA, dark: 0x3C5144)
    static let deep = Color(light: 0x1F3A31, dark: 0x1F3A31)
    static let deepRule = Color(light: 0x3A5A4E, dark: 0x3A5A4E)
    static let device = Color(light: 0x1B2420, dark: 0x0A120D)
    static let ink = Color(light: 0x1B2420, dark: 0xEEEDE8)
    static let inkMuted = Color(light: 0x4A554F, dark: 0xBAC4BD)
    static let inkSubtle = Color(light: 0x55605A, dark: 0x98A39C)
    static let onDeep = Color(light: 0xE9EEE9, dark: 0xE9EEE9)
    static let onDeepMuted = Color(light: 0xB4C3BA, dark: 0xB4C3BA)
    static let onSageTint = Color(light: 0x2C5A48, dark: 0xB5DCC6)
    static let sage = Color(light: 0x3E7A62, dark: 0x6AAA86)
    static let sageOnDeep = Color(light: 0x6AAA86, dark: 0x6AAA86)
    static let sageTint = Color(light: 0xE2EDE7, dark: 0x24402F)
    static let surface = Color(light: 0xFFFFFF, dark: 0x1D2E24)
    static let surfaceSunken = Color(light: 0xE8E5DD, dark: 0x0F1A13)
}

/// Corner radii, in points.
enum Radius {
    static let lg: CGFloat = 32
    static let md: CGFloat = 24
    static let pill: CGFloat = 999
    static let sm: CGFloat = 12
}

/// The 4-point spacing scale: `s4` is 4 × 4 = 16 points.
enum Space {
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s7: CGFloat = 28
    static let s8: CGFloat = 32
    static let s10: CGFloat = 40
    static let s12: CGFloat = 48
    static let s14: CGFloat = 56
    static let s16: CGFloat = 64
    static let s20: CGFloat = 80
    static let s22: CGFloat = 88
    static let s24: CGFloat = 96
    static let s28: CGFloat = 112
    static let s30: CGFloat = 120
}

/// Font family names. Bundle the fonts before using them (M1).
enum FontFamily {
    static let display = "Bricolage Grotesque"
    static let text = "Instrument Sans"
}

/// The shared canvas of the LogoMark and LogoWord images.
enum LogoCanvas {
    static let aspectRatio: CGFloat = 1440.0 / 413.0
}

private extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}
