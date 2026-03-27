// Core/Services/AIQuizGenerationService.swift
// SlangCheck
//
// Protocol + value types for AI-powered quiz question enhancement.
// Enriches quiz questions with fresh sentences and definition distractors
// so each session feels unique. Zero UIKit/FoundationModels imports.

import Foundation

// MARK: - AIQuizEnhancement

/// AI-generated enrichment for a single quiz question.
///
/// Replaces verbose glossary definitions with concise, quiz-friendly answer options
/// and creative question hints. This prevents the quiz from feeling like a copy-paste
/// of the glossary and forces users to actually think about the answers.
///
/// Key fields:
/// - `shortDefinition`: concise correct answer (5-10 words) for `.definitionPick`
/// - `shortDistractors`: 3 wrong answers matching the style/length of `shortDefinition`
/// - `questionHint`: creative scenario or description for `.termPick` stems
/// - `exampleSentence`: fresh sentence for `.fillInBlank` questions
public struct AIQuizEnhancement: Sendable {

    /// A fresh, contextually authentic example sentence using the slang term.
    public let exampleSentence: String

    /// Concise correct definition (5-10 words). Used as the answer choice text
    /// for `.definitionPick` instead of the full glossary definition.
    public let shortDefinition: String

    /// Three concise wrong definitions matching the length/style of `shortDefinition`.
    public let shortDistractors: [String]

    /// A creative hint, scenario, or vibe description for `.termPick` question stems.
    /// Example: "When someone walks into class late and doesn't care" → answer: "slay"
    public let questionHint: String

    public init(
        exampleSentence: String,
        shortDefinition: String,
        shortDistractors: [String],
        questionHint: String
    ) {
        precondition(shortDistractors.count == 3,
                     "AIQuizEnhancement requires exactly 3 shortDistractors.")
        self.exampleSentence  = exampleSentence
        self.shortDefinition  = shortDefinition
        self.shortDistractors = shortDistractors
        self.questionHint     = questionHint
    }
}

// MARK: - AIQuizGenerationService

/// Enriches a quiz question with AI-generated content.
///
/// Called per-term during `GenerateQuizUseCase.execute()`. Returns `nil` when
/// Apple Intelligence is unavailable; the use case falls back to static content.
///
/// The `questionType` parameter allows the AI to tailor its output — e.g.,
/// generating a sentence fragment for `.fillInBlank` vs. a conversational sentence
/// for `.definitionPick`.
public protocol AIQuizGenerationService: Sendable {

    /// Generates enriched content for a quiz question about `term`.
    ///
    /// - Parameters:
    ///   - term: The `SlangTerm` being tested.
    ///   - allTerms: The full glossary, used as negative examples to ensure
    ///     distractors don't accidentally describe another real term.
    ///   - questionType: Controls the style of the generated example sentence.
    /// - Returns: An `AIQuizEnhancement`, or `nil` if the model is unavailable.
    func enhance(
        term: SlangTerm,
        allTerms: [SlangTerm],
        questionType: QuestionType
    ) async -> AIQuizEnhancement?
}
