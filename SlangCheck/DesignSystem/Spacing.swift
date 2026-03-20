// DesignSystem/Spacing.swift
// SlangCheck
//
// Spacing token system. All layout values in the app reference these constants.
// Governed by a 4pt grid. NEVER hardcode a spacing value in a view.

import CoreFoundation

// MARK: - SlangSpacing Token Namespace

/// Named spacing tokens for SlangCheck, sourced from DESIGN_SYSTEM.md.
/// All values are multiples of 4pt.
///
/// Usage:
/// ```swift
/// .padding(SlangSpacing.md)
/// VStack(spacing: SlangSpacing.sm) { ... }
/// ```
public enum SlangSpacing {
    /// 4pt — Icon padding, micro gaps between tightly grouped elements.
    public static let xs: CGFloat = 4
    /// 8pt — Inline element gaps, button icon padding.
    public static let sm: CGFloat = 8
    /// 16pt — Card internal padding, form field gaps, screen edge margins.
    public static let md: CGFloat = 16
    /// 24pt — Section spacing between distinct content blocks.
    public static let lg: CGFloat = 24
    /// 32pt — Screen-level vertical rhythm, major layout divisions.
    public static let xl: CGFloat = 32
    /// 48pt — Hero section padding, onboarding illustration areas.
    public static let xxl: CGFloat = 48
}

// MARK: - Corner Radius Tokens

/// Named corner radius tokens for SlangCheck.
public enum SlangCornerRadius {
    /// 20pt — Glassmorphic cards (flashcards, modals, Aura Cards).
    public static let card: CGFloat = 20
    /// 14pt — List cells, smaller panels.
    public static let cell: CGFloat = 14
    /// 8pt — Progress bars, small chips/badges.
    public static let chip: CGFloat = 8
    /// 12pt — Buttons.
    public static let button: CGFloat = 12
    /// 24pt — Pill-shaped badges (tier badges).
    public static let pill: CGFloat = 24
}

// MARK: - Icon / Tap Target Tokens

/// Minimum tap target size per accessibility guidelines (WCAG / Apple HIG): 44×44pt.
public enum SlangTapTarget {
    public static let minimum: CGFloat = 44
}
