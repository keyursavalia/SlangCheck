// Core/Services/TranslationServiceProtocol.swift
// SlangCheck
//
// Protocol definitions for the local translation engine.
// All types are platform-agnostic — zero UIKit/SwiftUI imports.

import Foundation

// MARK: - TranslationDirection

/// The direction of a translation operation.
public enum TranslationDirection: String, Codable, Hashable, Sendable, CaseIterable {
    case genZToStandard
    case standardToGenZ

    /// Label for the input language panel.
    public var inputLanguageLabel: String {
        switch self {
        case .genZToStandard: return String(localized: "translator.direction.genZ", defaultValue: "Gen Z / Slang")
        case .standardToGenZ: return String(localized: "translator.direction.standard", defaultValue: "Standard English")
        }
    }

    /// Label for the output language panel.
    public var outputLanguageLabel: String {
        switch self {
        case .genZToStandard: return String(localized: "translator.direction.standard", defaultValue: "Standard English")
        case .standardToGenZ: return String(localized: "translator.direction.genZ", defaultValue: "Gen Z / Slang")
        }
    }

    /// Placeholder text shown in the empty input field.
    public var inputPlaceholder: String {
        switch self {
        case .genZToStandard: return String(localized: "translator.input.placeholder.genZ", defaultValue: "Type some slang…")
        case .standardToGenZ: return String(localized: "translator.input.placeholder.standard", defaultValue: "Type in Standard English…")
        }
    }

    /// Returns the opposite direction.
    public var toggled: TranslationDirection {
        switch self {
        case .genZToStandard: return .standardToGenZ
        case .standardToGenZ: return .genZToStandard
        }
    }
}

// MARK: - TranslationResult

/// The result of a translation operation, including the translated text and a substitution log.
public struct TranslationResult: Sendable {

    /// The original, untranslated text.
    public let originalText: String

    /// The output text after all recognized terms have been substituted.
    public let translatedText: String

    /// The direction in which translation was performed.
    public let direction: TranslationDirection

    /// All substitutions that were applied, in the order they were matched.
    /// One entry per distinct matched term — not per occurrence.
    public let substitutions: [Substitution]

    /// `true` when at least one term substitution was made.
    public var hasSubstitutions: Bool { !substitutions.isEmpty }

    // MARK: Substitution

    /// A single term substitution record.
    public struct Substitution: Sendable, Identifiable {

        /// Stable identifier for SwiftUI list diffing.
        public let id: UUID

        /// The original token (or phrase) that was matched in the input.
        public let originalToken: String

        /// The replacement token that was inserted in the output.
        public let translatedToken: String

        /// The full ``SlangTerm`` record that was matched, for display in breakdowns.
        public let term: SlangTerm
    }
}

// MARK: - TranslationService

/// Abstraction over the translation engine.
/// The concrete implementation (`LocalTranslationService`) is in `Data/Services/`.
/// Using a protocol allows the engine to be swapped (e.g. a future remote API)
/// without any ViewModel changes.
public protocol TranslationService: Sendable {

    /// Translates `text` in the given `direction` and returns a ``TranslationResult``.
    func translate(text: String, direction: TranslationDirection) async throws -> TranslationResult
}
