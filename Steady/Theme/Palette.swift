//
//  Palette.swift
//  Steady
//
//  Every colour token from design/steady-design-reference.md §2, light and dark.
//  This is the only file in the app that is allowed to name a literal colour.
//

import SwiftUI
import UIKit

/// The complete Steady colour palette.
///
/// Both themes are complete and independent, and the theme follows the system
/// setting only — there is no manual toggle anywhere in the product. Every token
/// is a dynamic colour that resolves against the trait collection, so a single
/// `Palette.ink` is correct in both appearances.
nonisolated enum Palette {

    // MARK: - Tokens

    /// Screen background.
    static let bg = dynamic(light: .hex(0xF4F4F2), dark: .hex(0x0E100F))

    /// Cards, tab bar, stepper buttons.
    static let sur = dynamic(light: .hex(0xFFFFFF), dark: .hex(0x191D1B))

    /// Primary text; fill of the neutral primary button.
    static let ink = dynamic(light: .hex(0x111312), dark: .hex(0xF2F3F1))

    /// Labels, secondary text, inactive segments.
    static let mut = dynamic(light: .hex(0x6B6F6D), dark: .hex(0x8B908D))

    /// Accent: trend line, interactive text, Save/Update fill.
    ///
    /// Authored in OKLCH, not sRGB. The hex figures in the design reference are
    /// approximations for eyeballing only; these are the authored values,
    /// converted through OKLab into Display P3 so both themes stay perceptually
    /// matched. The light accent sits marginally outside sRGB, which is exactly
    /// why it is not defined as a hex triplet.
    static let ac = dynamic(
        light: .oklch(l: 0.52, c: 0.13, h: 235),
        dark: .oklch(l: 0.76, c: 0.12, h: 235)
    )

    /// Text on an accent fill. Deliberately *not* white in dark mode — the dark
    /// accent is a light blue, so its label is near-black.
    static let acink = dynamic(light: .hex(0xFFFFFF), dark: .hex(0x0A1015))

    /// Delta badge fill, check-circle fill.
    static let acsoft = dynamic(light: .hex(0xE5EEF5), dark: .hex(0x17303F))

    /// Text on `acsoft`.
    static let acsoftink = dynamic(light: .hex(0x215480), dark: .hex(0x9FD2F2))

    /// Area fill under the trend line.
    static let glow = dynamic(
        light: .rgba(33, 84, 128, 0.14),
        dark: .rgba(120, 190, 235, 0.20)
    )

    /// Raw daily dots and the thin raw polyline. Much stronger in dark, because
    /// the dots need more presence against a near-black ground.
    static let raw = dynamic(
        light: .rgba(17, 19, 18, 0.32),
        dark: .rgba(224, 232, 230, 0.50)
    )

    /// Hairline dividers.
    static let line = dynamic(
        light: .rgba(0, 0, 0, 0.13),
        dark: .rgba(255, 255, 255, 0.15)
    )

    /// Delete, and only delete. Never a colour code for a weight gain.
    static let danger = dynamic(
        light: .oklch(l: 0.45, c: 0.17, h: 8),
        dark: .oklch(l: 0.70, c: 0.15, h: 8)
    )

    /// Text on a danger fill.
    static let dangerink = dynamic(light: .hex(0xFFFFFF), dark: .hex(0x1A0C0B))

    /// Destructive-button fill in the confirm sheet.
    static let dangersoft = dynamic(
        light: .hex(0xF7E9EC),
        dark: .rgba(232, 120, 140, 0.15)
    )

    // MARK: - Ruler (design reference §5)

    /// Every fifth tick on the ruler strip.
    static let tickMajor = dynamic(
        light: .rgba(17, 19, 18, 0.42),
        dark: .rgba(242, 243, 241, 0.62)
    )

    /// The remaining ruler ticks.
    static let tickMinor = dynamic(
        light: .rgba(17, 19, 18, 0.16),
        dark: .rgba(242, 243, 241, 0.24)
    )

    // MARK: - Delete confirmation (design reference §7.7)

    /// The scrim over the blurred screen behind the delete sheet.
    static let scrim = Color(uiColor: .rgba(10, 9, 14, 0.5))

    /// The only shadow in the product.
    static let sheetShadow = Color(uiColor: .rgba(10, 9, 14, 0.4))

    // MARK: - Construction

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

// MARK: - Literal colour construction

nonisolated private extension UIColor {

    /// An opaque sRGB colour from a `0xRRGGBB` literal.
    static func hex(_ value: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }

    /// An sRGB colour from CSS-style 0–255 channels and a 0–1 alpha.
    static func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }

    /// A colour authored in OKLCH, converted through OKLab and CIE XYZ (D65)
    /// into Display P3.
    ///
    /// Display P3 rather than sRGB because that is what the browser the concept
    /// was drawn in resolves `oklch()` against on a modern iPhone, and because
    /// the light accent falls just outside sRGB — clipping it would desaturate
    /// exactly the colour the whole design hangs on.
    static func oklch(l: CGFloat, c: CGFloat, h: CGFloat) -> UIColor {
        let radians = h * .pi / 180
        let a = c * cos(radians)
        let b = c * sin(radians)

        // OKLab -> nonlinear LMS -> linear LMS
        let lL = pow(l + 0.3963377774 * a + 0.2158037573 * b, 3)
        let mL = pow(l - 0.1055613458 * a - 0.0638541728 * b, 3)
        let sL = pow(l - 0.0894841775 * a - 1.2914855480 * b, 3)

        // linear LMS -> CIE XYZ (D65)
        let x =  1.2268798758 * lL - 0.5578149945 * mL + 0.2813910502 * sL
        let y = -0.0405757626 * lL + 1.1122868033 * mL - 0.0717110667 * sL
        let z = -0.0763729497 * lL - 0.4214933324 * mL + 1.5869240198 * sL

        // CIE XYZ (D65) -> linear Display P3
        let r =  2.4934969119 * x - 0.9313836179 * y - 0.4027107845 * z
        let g = -0.8294889696 * x + 1.7626640603 * y + 0.0236246858 * z
        let bl =  0.0358458302 * x - 0.0761723893 * y + 0.9568845240 * z

        return UIColor(
            displayP3Red: encode(r),
            green: encode(g),
            blue: encode(bl),
            alpha: 1
        )
    }

    /// The sRGB transfer function, which Display P3 shares.
    private static func encode(_ channel: CGFloat) -> CGFloat {
        let v = Swift.min(Swift.max(channel, 0), 1)
        return v <= 0.0031308 ? 12.92 * v : 1.055 * pow(v, 1 / 2.4) - 0.055
    }
}
