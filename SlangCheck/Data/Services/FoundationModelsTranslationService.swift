// Data/Services/FoundationModelsTranslationService.swift
// SlangCheck
//
// Apple Intelligence translation service backed by SystemLanguageModel.
// Called when dictionary substitution finds zero matches.
// Compiled only when FoundationModels is available (iOS 26+).

import Foundation
import OSLog

#if canImport(FoundationModels)
import FoundationModels

// MARK: - FoundationModelsTranslationService

/// AI-powered translation using the on-device `SystemLanguageModel`.
///
/// Invoked only when `LocalTranslationService` finds zero dictionary substitutions,
/// meaning the input is a natural-language sentence with no direct glossary hits.
/// The full glossary is injected as grounding context so the model's output stays
/// anchored to real, documented slang terms rather than hallucinating new ones.
///
/// Returns `nil` when Apple Intelligence is unavailable (older device, turned off
/// in Settings, or model still loading) so the caller can surface a graceful fallback.
@available(iOS 26, *)
public struct FoundationModelsTranslationService: AITranslationService {

    public init() {}

    // MARK: - AITranslationService

    public func translate(
        text: String,
        direction: TranslationDirection,
        glossary: [SlangTerm]
    ) async -> String? {
        guard SystemLanguageModel.default.availability == .available else { return nil }

        let glossaryContext = buildGlossaryContext(from: glossary, direction: direction)
        let systemPrompt   = buildSystemPrompt(direction: direction, context: glossaryContext)
        let userPrompt     = buildUserPrompt(text: text, direction: direction)

        do {
            let session  = LanguageModelSession(instructions: Instructions(systemPrompt))
            let response = try await session.respond(to: userPrompt)
            let result   = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !result.isEmpty else { return nil }
            Logger.translator.debug("AI translation succeeded (\(direction.rawValue)).")
            return result
        } catch {
            Logger.translator.error("AI translation failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Prompt Construction

    private func buildSystemPrompt(direction: TranslationDirection, context: String) -> String {
        switch direction {
        case .standardToGenZ:
            return """
            You are a Gen Z slang translator. Convert Standard English sentences into authentic Gen Z / internet slang.

            Use ONLY terms from this glossary when making substitutions. Do not invent slang not in the list.
            Preserve the original meaning and tone. Output only the translated sentence — no explanation, no quotes.

            Glossary (Standard English → Gen Z):
            \(context)
            """
        case .genZToStandard:
            return """
            You are a Standard English translator. Convert Gen Z slang sentences into clear, natural Standard English.

            Use this glossary to understand what each slang term means. Output only the translated sentence — no explanation, no quotes.

            Glossary (Gen Z → Standard English):
            \(context)
            """
        }
    }

    private func buildUserPrompt(text: String, direction: TranslationDirection) -> String {
        switch direction {
        case .standardToGenZ: return "Translate to Gen Z slang: \(text)"
        case .genZToStandard: return "Translate to Standard English: \(text)"
        }
    }

    private func buildGlossaryContext(from glossary: [SlangTerm], direction: TranslationDirection) -> String {
        // Limit context to 40 terms to stay within model context window.
        let terms = Array(glossary.shuffled().prefix(40))
        return terms.map { term in
            switch direction {
            case .standardToGenZ: return "• \(term.standardEnglish) → \(term.term)"
            case .genZToStandard: return "• \(term.term): \(term.definition)"
            }
        }.joined(separator: "\n")
    }
}

#endif
