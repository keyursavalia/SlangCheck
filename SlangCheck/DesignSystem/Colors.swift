// DesignSystem/Colors.swift
// SlangCheck
//
// Single source of truth for all color tokens.
// All colors adapt automatically between Light ("Vibrant Day") and Dark ("Midnight Cyber") modes.
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
/// Usage:
/// ```swift
/// Text("No Cap").foregroundStyle(SlangColor.primary)
/// Rectangle().fill(SlangColor.background)
/// ```
public enum SlangColor {

    // MARK: - Core Semantic Tokens

    /// Aura Purple — CTAs, active states, highlights, selected elements.
    /// Light: #A855F7 Electric Lavender | Dark: #C084FC Neon Heliotrope
    public static var primary: Color {
        Color(lightHex: "A855F7", darkHex: "C084FC")
    }

    /// Rizz Green — success states, streaks, saved confirmations, correct answers.
    /// Light: #22C55E Vivid Emerald | Dark: #4ADE80 Cyber Mint
    public static var secondary: Color {
        Color(lightHex: "22C55E", darkHex: "4ADE80")
    }

    /// Page/screen background canvas.
    /// Light: #F8FAFC Frosted White | Dark: #0F172A Deep Slate
    public static var background: Color {
        Color(lightHex: "F8FAFC", darkHex: "0F172A")
    }

    /// Sunset Amber / Bright Gold — warnings, mid-level indicators, "Skip" action labels.
    /// Light: #F59E0B Sunset Amber | Dark: #FBBF24 Bright Gold
    public static var accent: Color {
        Color(lightHex: "F59E0B", darkHex: "FBBF24")
    }

    // MARK: - Surface Tokens

    /// Elevated surface color for cards and panels (slightly above background).
    /// Light: #FFFFFF | Dark: #1E293B
    public static var surface: Color {
        Color(lightHex: "FFFFFF", darkHex: "1E293B")
    }

    /// Subtle separator / divider color.
    /// Light: #E2E8F0 | Dark: #334155
    public static var separator: Color {
        Color(lightHex: "E2E8F0", darkHex: "334155")
    }

    // MARK: - Text Tokens

    /// Primary label color for body copy and headings.
    /// Uses SwiftUI's semantic primary, which already adapts to light/dark.
    public static var labelPrimary: Color { .primary }

    /// Secondary label color for captions, metadata, placeholder text.
    public static var labelSecondary: Color { .secondary }

    // MARK: - Semantic State Colors

    /// Error / incorrect answer state.
    /// Fixed: #EF4444 (red) — used for wrong answers and destructive actions.
    public static var errorRed: Color {
        Color(lightHex: "EF4444", darkHex: "EF4444")
    }

    // MARK: - Neumorphism Shadow Tokens

    /// Light shadow for neumorphic surfaces (light mode: white highlight; dark mode: dark highlight).
    public static var neumorphicShadowLight: Color {
        Color(lightHex: "FFFFFF", darkHex: "1E293B")
    }

    /// Dark shadow for neumorphic surfaces (light mode: blue-gray; dark mode: pure black).
    public static var neumorphicShadowDark: Color {
        Color(lightHex: "CBD5E1", darkHex: "000000")
    }
}

// MARK: - SlangColor UIColor Variants (for UIKit interop in HapticService, etc.)

extension SlangColor {
    /// Primary color as UIColor, for contexts requiring UIKit types.
    public static var primaryUI: UIColor {
        UIColor { tc in
            tc.userInterfaceStyle == .dark ? UIColor(hex: "C084FC") : UIColor(hex: "A855F7")
        }
    }
}
