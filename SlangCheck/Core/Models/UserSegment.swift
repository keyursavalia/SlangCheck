// Core/Models/UserSegment.swift
// SlangCheck
//
// The user's self-identified audience segment, selected during onboarding.
// Influences initial Swiper card ordering and onboarding copy.

import Foundation

// MARK: - UserSegment

/// The target audience segment a user identifies with during onboarding (FR-O-002).
public enum UserSegment: String, Codable, CaseIterable, Sendable {
    /// Millennials / GenX trying to understand younger generations.
    case unc             = "unc"
    /// Users who want to stay current with internet culture.
    case trendSeeker     = "trendSeeker"
    /// Users fascinated by sociolinguistics of modern slang.
    case languageEnthusiast = "languageEnthusiast"

    /// Display name shown in onboarding selection UI.
    public var displayName: String {
        switch self {
        case .unc:              return String(localized: "segment.unc.name", defaultValue: "The Unc")
        case .trendSeeker:      return String(localized: "segment.trendSeeker.name", defaultValue: "Trend-Seeker")
        case .languageEnthusiast: return String(localized: "segment.languageEnthusiast.name", defaultValue: "Language Enthusiast")
        }
    }

    /// Short description shown in onboarding selection UI.
    public var description: String {
        switch self {
        case .unc:
            return String(localized: "segment.unc.description",
                          defaultValue: "Trying to understand what the younger generation is saying")
        case .trendSeeker:
            return String(localized: "segment.trendSeeker.description",
                          defaultValue: "Staying relevant with internet culture")
        case .languageEnthusiast:
            return String(localized: "segment.languageEnthusiast.description",
                          defaultValue: "Fascinated by the evolution of language")
        }
    }

    /// SF Symbol name representing this segment.
    public var symbolName: String {
        switch self {
        case .unc:               return "person.crop.circle.badge.questionmark"
        case .trendSeeker:       return "bolt.circle"
        case .languageEnthusiast: return "text.book.closed"
        }
    }
}
