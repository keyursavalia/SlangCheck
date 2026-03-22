// Data/Services/NoOpAIServices.swift
// SlangCheck
//
// Graceful-degradation implementations of all three AI service protocols.
// Used when FoundationModels is unavailable (iOS < 26, Apple Intelligence
// disabled in Settings, or unsupported device). Always return nil — callers
// interpret nil as "use static fallback".

import Foundation

// MARK: - NoOpAITranslationService

/// Returns `nil` for every call, causing `LocalTranslationService` to surface
/// the dictionary-based result (which may be empty if no terms matched).
public struct NoOpAITranslationService: AITranslationService {
    public init() {}
    public func translate(text: String, direction: TranslationDirection, glossary: [SlangTerm]) async -> String? { nil }
}

// MARK: - NoOpAIQuizService

/// Returns `nil` for every call, causing `GenerateQuizUseCase` to use the
/// static `SlangTerm.exampleSentence` and pool-based distractors.
public struct NoOpAIQuizService: AIQuizGenerationService {
    public init() {}
    public func enhance(term: SlangTerm, allTerms: [SlangTerm], questionType: QuestionType) async -> AIQuizEnhancement? { nil }
}

// MARK: - NoOpAICrosswordService

/// Returns `nil` for every call, causing `AIGeneratedCrosswordRepository` to
/// fall back to `SampleCrosswordRepository` (the hardcoded demo puzzle).
public struct NoOpAICrosswordService: AICrosswordGenerationService {
    public init() {}
    public func generateLayout(from glossary: [SlangTerm]) async -> AICrosswordLayout? { nil }
}
