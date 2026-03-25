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
    /// All tokens use Noticia Text so the app has a consistent editorial voice.
    var font: Font {
        switch self {
        case .display:
            return .custom("NoticiaText-Bold", size: 34, relativeTo: .largeTitle)
        case .title:
            return .custom("NoticiaText-Bold", size: 28, relativeTo: .title)
        case .heading:
            return .custom("NoticiaText-Bold", size: 22, relativeTo: .title2)
        case .subheading:
            return .custom("NoticiaText-Regular", size: 17, relativeTo: .headline)
        case .body:
            return .custom("NoticiaText-Regular", size: 15, relativeTo: .body)
        case .caption:
            return .custom("NoticiaText-Regular", size: 12, relativeTo: .caption)
        case .label:
            return .custom("NoticiaText-Bold", size: 15, relativeTo: .callout)
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

    /// **Noticia Text Regular** — used for all slang term/word display.
    /// Scales relative to the large-title Dynamic Type axis.
    /// PostScript name: NoticiaText-Regular (bundled in app via FontsInfo.plist).
    static func slangTerm(size: CGFloat) -> Font {
        .custom("NoticiaText-Bold", size: size, relativeTo: .largeTitle)
    }

    /// **System font** — used for slang definitions and body descriptions.
    /// Scales relative to the body Dynamic Type axis.
    static func slangDefinition(size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
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
