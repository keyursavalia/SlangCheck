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
            return .custom("Montserrat-Bold", size: 34, relativeTo: .largeTitle)
        case .title:
            return .custom("Montserrat-Bold", size: 28, relativeTo: .title)
        case .heading:
            return .custom("Montserrat-Bold", size: 22, relativeTo: .title2)
        case .subheading:
            return .custom("Montserrat-Medium", size: 17, relativeTo: .headline)
        case .body:
            return .custom("Montserrat-Regular", size: 15, relativeTo: .body)
        case .caption:
            return .custom("Montserrat-Regular", size: 12, relativeTo: .caption)
        case .label:
            return .custom("Montserrat-SemiBold", size: 15, relativeTo: .callout)
        }
    }

    /// The corresponding `UIFont.TextStyle` for Dynamic Type scaling.
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
    static func slang(_ style: SlangType) -> Font {
        style.font
    }

    /// **Montserrat Bold** — used for all slang term/word display.
    static func slangTerm(size: CGFloat) -> Font {
        .custom("NoticiaText-Bold", size: size, relativeTo: .largeTitle)
    }

    /// **Montserrat Regular** — used for slang definitions and body descriptions.
    static func slangDefinition(size: CGFloat) -> Font {
        .custom("Montserrat-Regular", size: size, relativeTo: .body)
    }

    /// Convenience initialiser matching the `.system(size:weight:)` call pattern.
    /// Maps SwiftUI font weights to Montserrat PostScript names.
    /// Falls back to Montserrat-Regular for unrecognised weights.
    static func montserrat(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .black:                    name = "Montserrat-Black"
        case .heavy:                    name = "Montserrat-ExtraBold"
        case .bold:                     name = "Montserrat-Bold"
        case .semibold:                 name = "Montserrat-SemiBold"
        case .medium:                   name = "Montserrat-Medium"
        case .light:                    name = "Montserrat-Light"
        default:                        name = "Montserrat-Regular"
        }
        return .custom(name, size: size)
    }
}

// MARK: - Text Extension for Body Line Spacing

public extension View {
    /// Applies `.body` line spacing (1.4× the font size = 21pt for 15pt body text).
    func slangBodySpacing() -> some View {
        self.lineSpacing(6)
    }
}
