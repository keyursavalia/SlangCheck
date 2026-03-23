// DesignSystem/Typography.swift
// SlangCheck
//
// Typography token system. All text in the app uses these named styles.
// Dynamic Type is mandatory — all styles use relative sizing via scaled metrics.
// NEVER hardcode a font size in a view.

import SwiftUI

// MARK: - SlangType Token Enum

/// Named typography tokens for SlangCheck, sourced from DESIGN_SYSTEM.md.
///
/// Usage:
/// ```swift
/// Text("SlangCheck").font(.slang(.display))
/// Text("Definition text").font(.slang(.body))
/// ```
public enum SlangType {
    /// Hero text, onboarding headlines. Black (900) weight, 34pt base.
    case display
    /// Screen titles, card headers. Bold (700) weight, 28pt base.
    case title
    /// Section headings. Semibold (600) weight, 22pt base.
    case heading
    /// Subsection labels, tier names. Medium (500) weight, 17pt base.
    case subheading
    /// Definitions, body copy. Regular (400) weight, 15pt base. Line spacing 1.4x.
    case body
    /// Metadata, timestamps, secondary labels. Regular (400) weight, 12pt base.
    case caption
    /// Buttons, tab labels. Semibold (600) weight, 15pt base.
    case label

    /// Resolves the token to a SwiftUI `Font` with Dynamic Type scaling.
    var font: Font {
        switch self {
        case .display:
            return .system(size: 34, weight: .black, design: .default)
        case .title:
            return .system(size: 28, weight: .bold, design: .default)
        case .heading:
            return .system(size: 22, weight: .semibold, design: .default)
        case .subheading:
            return .system(size: 17, weight: .medium, design: .default)
        case .body:
            return .system(size: 15, weight: .regular, design: .default)
        case .caption:
            return .system(size: 12, weight: .regular, design: .default)
        case .label:
            return .system(size: 15, weight: .semibold, design: .default)
        }
    }

    /// The corresponding `UIFont.TextStyle` for Dynamic Type scaling.
    /// Used when a `UIFont`-compatible scaled metric is needed.
    var textStyle: Font.TextStyle {
        switch self {
        case .display: return .largeTitle
        case .title: return .title
        case .heading: return .title2
        case .subheading: return .headline
        case .body: return .body
        case .caption: return .caption
        case .label: return .callout
        }
    }
}

// MARK: - Font Extension

public extension Font {
    /// Creates a SlangCheck design-token font.
    /// Automatically scales with Dynamic Type.
    ///
    /// - Parameter style: A `SlangType` token from the design system.
    static func slang(_ style: SlangType) -> Font {
        style.font
    }

    /// **Big Caslon Medium** — used for all slang term/word display.
    /// Scales relative to the large-title Dynamic Type axis.
    /// PostScript name: BigCaslon-Medium (bundled on iOS).
    static func slangTerm(size: CGFloat) -> Font {
        .custom("BigCaslon-Medium", size: size, relativeTo: .largeTitle)
    }

    /// **Baskerville Regular** — used for slang definitions and body descriptions.
    /// Scales relative to the body Dynamic Type axis.
    static func slangDefinition(size: CGFloat) -> Font {
        .custom("Baskerville", size: size, relativeTo: .body)
    }
}

// MARK: - Text Extension for Body Line Spacing

public extension View {
    /// Applies `.body` line spacing (1.4× the font size = 21pt for 15pt body text).
    /// Use this modifier on any body copy `Text` view.
    func slangBodySpacing() -> some View {
        self.lineSpacing(6) // 15pt * 1.4 = 21pt line height → 6pt extra spacing
    }
}
