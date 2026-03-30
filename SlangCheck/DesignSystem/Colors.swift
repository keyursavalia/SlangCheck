// DesignSystem/Colors.swift
// SlangCheck
//
// Single source of truth for all color tokens.
// Palette: "Chill & Cozy" — warm linens, dusty blue, muted olive, soft blush.
// All colors adapt automatically between Light ("Warm Linen") and Dark ("Cozy Night") modes.
// NEVER use a hex literal outside of this file.

import SwiftUI
import UIKit

// MARK: - Color Extension: Light/Dark Adaptive Initializer

extension Color {
    /// Creates a color that automatically switches between light and dark mode values.
    init(lightHex: String, darkHex: String) {
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: darkHex)
                : UIColor(hex: lightHex)
        })
    }
}

// MARK: - UIColor Hex Initializer (Internal Use Only)

extension UIColor {
    /// Initializes a UIColor from a hex string. Internal to the design system only.
    /// - Parameter hex: A 6-character hex string, with or without a leading `#`.
    convenience init(hex: String) {
        let clean = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8) & 0xFF) / 255
        let b = CGFloat(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - SlangColor Design Token Enum

/// The canonical color token system for SlangCheck.
/// Reference these tokens in all views. Never use raw hex values.
///
/// Palette philosophy: "Chill & Cozy" — warm linens and dusty tones that encourage
/// relaxed reading. No neon or high-saturation hues.
///
/// Usage:
/// ```swift
/// Text("No Cap").foregroundStyle(SlangColor.primary)
/// Rectangle().fill(SlangColor.background)
/// ```
public enum SlangColor {

    // MARK: - Core Semantic Tokens

    /// Muted Olive / Warm Sand — brand color, CTAs, active states, bookmarks, highlights.
    /// Light: #8F917C Warm Olive | Dark: #D0BEA3 Warm Sand
    public static var primary: Color {
        Color(lightHex: "8F917C", darkHex: "D0BEA3")
    }

    /// Soft Periwinkle — save confirmations, success states, correct answers, streaks.
    /// Light: #BAC8E0 Dusty Periwinkle | Dark: #BAC8E0 Dusty Periwinkle
    public static var secondary: Color {
        Color(lightHex: "BAC8E0", darkHex: "BAC8E0")
    }

    /// Page/screen background canvas.
    /// Light: #E1C7B7 Warm Clay | Dark: #1F1F1F Warm Charcoal
    public static var background: Color {
        Color(lightHex: "FAF3DD", darkHex: "1F1F1F")
//          Color(lightHex: "E4C3AD", darkHex: "1F1F1F")
    }

    /// Warm Sand / Soft Blush — attention states, "Skip" labels, chips, example blockquotes.
    /// Light: #D0BEA3 Warm Sand | Dark: #EBDBD3 Soft Blush
    public static var accent: Color {
        Color(lightHex: "D0BEA3", darkHex: "EBDBD3")
    }

    // MARK: - Surface Tokens

    /// Card / panel surface — slightly elevated above background, the parchment layer.
    /// Light: #EBDBD3 Warm Blush | Dark: #272420 Warm Near-Black
    public static var cardSurface: Color {
        Color(lightHex: "EBDBD3", darkHex: "272420")
    }

    /// Elevated surface color for list cells and settings panels.
    /// Light: #F0EDE8 Warm Off-White | Dark: #252220 Warm Dark
    public static var surface: Color {
        Color(lightHex: "F0EDE8", darkHex: "252220")
    }

    /// Subtle separator / divider color.
    /// Light: #DCCFC7 Muted Blush | Dark: #383230 Warm Dark Border
    public static var separator: Color {
        Color(lightHex: "DCCFC7", darkHex: "383230")
    }

    // MARK: - Text Tokens

    /// Primary label color for body copy and headings.
    /// Uses SwiftUI's semantic primary, which already adapts to light/dark.
    public static var labelPrimary: Color { .primary }

    /// Secondary label color for captions, metadata, placeholder text.
    public static var labelSecondary: Color { .secondary }

    // MARK: - Semantic State Colors

    /// Error / incorrect answer state — warm terracotta, softer than pure red.
    /// Light: #B05A52 Warm Terracotta | Dark: #C87870 Dusty Rose Red
    public static var errorRed: Color {
        Color(lightHex: "B05A52", darkHex: "C87870")
    }

    // MARK: - Onboarding Token

    /// Onboarding teal — selected option rows and CTA buttons in the onboarding flow.
    /// #98C1BE (unified across light and dark mode)
    public static var onboardingTeal: Color {
        Color(lightHex: "98C1BE", darkHex: "98C1BE")
    }

    // MARK: - Neumorphism Shadow Tokens

    /// Light shadow for neumorphic surfaces (highlight side).
    /// Light: #FFFFFF White Highlight | Dark: #2D2A27 Warm Lifted
    public static var neumorphicShadowLight: Color {
        Color(lightHex: "FFFFFF", darkHex: "2D2A27")
    }

    /// Dark shadow for neumorphic surfaces (shadow side).
    /// Light: #D4C9BF Warm Taupe Shadow | Dark: #131110 Deep Warm Black
    public static var neumorphicShadowDark: Color {
        Color(lightHex: "D4C9BF", darkHex: "131110")
    }

    // MARK: - Hard Drop Shadow Token

    /// Crisp hard-shadow layer placed behind cards and pill buttons (offset 3–4pt).
    /// Light: near-black for strong contrast against cream surfaces.
    /// Dark: warm sand cream so the lift reads as warmth rather than depth.
    public static var hardShadow: Color {
        Color(lightHex: "1C1C1E", darkHex: "FFFFFF")
    }

    // MARK: - Crossword Cell Tokens

    /// Barrier (non-input) cell fill in the crossword grid.
    /// Light: near-black (classic crossword convention) | Dark: warm deep charcoal
    /// — clearly distinct from the cream input cells in both modes.
    public static var crosswordBarrierCell: Color {
        Color(lightHex: "1C1C1E", darkHex: "2E2A26")
    }

    /// Input (letter) cell fill in the crossword grid.
    /// Light: white | Dark: warm cream — clearly signals "type here" in both modes.
    public static var crosswordInputCell: Color {
        Color(lightHex: "FFFFFF", darkHex: "EAE0D4")
    }
}

// MARK: - SlangColor UIColor Variants (for UIKit interop)

extension SlangColor {
    /// Primary color as UIColor, for contexts requiring UIKit types.
    public static var primaryUI: UIColor {
        UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(hex: "D0BEA3")
                : UIColor(hex: "8F917C")
        }
    }
}
