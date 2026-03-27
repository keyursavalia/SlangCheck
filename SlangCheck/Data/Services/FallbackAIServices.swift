// Data/Services/FallbackAIServices.swift
// SlangCheck
//
// Composite AI services that try Apple Intelligence (FoundationModels) first,
// then fall back to the Gemini REST API. If both fail, returns nil (callers
// already handle nil via static fallback content).

import Foundation

// MARK: - FallbackQuizService

/// Tries the primary AI service (Apple Intelligence) first. On `nil`, delegates to Gemini.
struct FallbackQuizService: AIQuizGenerationService {

    let primary: any AIQuizGenerationService
    let fallback: any AIQuizGenerationService

    func enhance(
        term: SlangTerm,
        allTerms: [SlangTerm],
        questionType: QuestionType
    ) async -> AIQuizEnhancement? {
        if let result = await primary.enhance(term: term, allTerms: allTerms, questionType: questionType) {
            return result
        }
        return await fallback.enhance(term: term, allTerms: allTerms, questionType: questionType)
    }
}

// MARK: - FallbackCrosswordService

/// Tries the primary AI service (Apple Intelligence) first. On `nil`, delegates to Gemini.
struct FallbackCrosswordService: AICrosswordGenerationService {

    let primary: any AICrosswordGenerationService
    let fallback: any AICrosswordGenerationService

    func generateLayout(from glossary: [SlangTerm]) async -> AICrosswordLayout? {
        if let result = await primary.generateLayout(from: glossary) {
            return result
        }
        return await fallback.generateLayout(from: glossary)
    }
}
