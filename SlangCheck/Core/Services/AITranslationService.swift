// Core/Services/AITranslationService.swift
// SlangCheck
//
// Protocol for AI-powered translation augmentation (Apple Intelligence on-device).
// Called only when dictionary substitution produces zero matches.
// Zero UIKit/SwiftUI/CoreData/FoundationModels imports — platform-agnostic contract.

import Foundation

// MARK: - AITranslationService

/// AI augmentation layer for the translation engine.
///
/// `LocalTranslationService` calls this only when dictionary-based substitution
/// produces no matches — i.e., the input is a natural-language sentence with no
/// direct term-by-term equivalents in the glossary.
///
/// Implementations backed by `SystemLanguageModel` must return `nil` when
/// Apple Intelligence is unavailable; callers treat `nil` as a signal to
/// surface the unmodified dictionary result.
///
/// **Privacy:** Implementations must process text entirely on-device.
/// No user input must leave the device. The concrete `FoundationModelsTranslationService`
/// enforces this via `SystemLanguageModel` (Apple Intelligence on-device LLM).
public protocol AITranslationService: Sendable {

    /// Translates `text` using contextual understanding of the slang glossary.
    ///
    /// - Parameters:
    ///   - text: The user's input text.
    ///   - direction: `.genZToStandard` or `.standardToGenZ`.
    ///   - glossary: The full local slang dictionary, used as grounding context.
    /// - Returns: The AI-generated translation, or `nil` if the model is unavailable.
    func translate(
        text: String,
        direction: TranslationDirection,
        glossary: [SlangTerm]
    ) async -> String?
}
