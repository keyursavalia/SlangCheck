// Data/Services/LocalTranslationService.swift
// SlangCheck
//
// Concrete TranslationService that operates entirely on-device using the
// CoreData repository. No network calls. No user input text leaves the device.
//
// When Apple Intelligence is available, sentences with zero dictionary matches
// are passed to the AI service for contextual translation (e.g. "He was shouting"
// → "He was crashing out"). The dictionary result is always tried first.

import Foundation
import OSLog

// MARK: - LocalTranslationService

/// Translates text using the local slang term dictionary via ``TranslateTextUseCase``.
/// When the dictionary finds no substitutions, delegates to ``AITranslationService``
/// for contextual translation powered by Apple Intelligence (iOS 26+).
///
/// Per the Q-001 decision (2026-03-20): translation is local-only; no text leaves the device.
/// The AI service is on-device (`SystemLanguageModel`) — this guarantee is preserved.
public struct LocalTranslationService: TranslationService {

    private let useCase:    TranslateTextUseCase
    private let aiService:  any AITranslationService
    private let repository: any SlangTermRepository

    /// - Parameters:
    ///   - repository: The data source from which all slang terms are loaded.
    ///   - aiService:  The Apple Intelligence service used when dictionary lookup yields nothing.
    ///                 Pass `NoOpAITranslationService()` on devices that do not support AI.
    public init(repository: any SlangTermRepository, aiService: any AITranslationService) {
        self.useCase    = TranslateTextUseCase(repository: repository)
        self.aiService  = aiService
        self.repository = repository
    }

    // MARK: - TranslationService

    public func translate(text: String, direction: TranslationDirection) async throws -> TranslationResult {
        // Typed throws from the use case are bridged to untyped throws here.
        let dictionaryResult = try await useCase.translate(text: text, direction: direction)

        // Dictionary found at least one substitution — return immediately.
        guard dictionaryResult.substitutions.isEmpty else {
            return dictionaryResult
        }

        // No dictionary matches: attempt contextual AI translation.
        // The glossary is re-fetched here (fast CoreData read) so the AI is grounded
        // in the real term list rather than potentially hallucinating new slang.
        let glossary = (try? await repository.fetchAllTerms()) ?? []
        guard let aiText = await aiService.translate(text: text, direction: direction, glossary: glossary),
              !aiText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            Logger.translator.info("AI translation unavailable; returning unmodified text.")
            return dictionaryResult
        }

        Logger.translator.debug("AI translation applied (\(direction.rawValue)).")
        // AI produces a free-form translation — no per-term substitution metadata.
        return TranslationResult(
            originalText:   text,
            translatedText: aiText,
            direction:      direction,
            substitutions:  []
        )
    }
}
