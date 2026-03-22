// Data/Services/FoundationModelsQuizService.swift
// SlangCheck
//
// Apple Intelligence quiz enhancement service.
// Generates fresh example sentences and plausible definition distractors
// so every quiz session feels new. Compiled only on iOS 26+ with FoundationModels.

import Foundation
import OSLog

#if canImport(FoundationModels)
import FoundationModels

// MARK: - Generable Output Types

/// Structured AI output for quiz question enrichment.
@available(iOS 26, *)
@Generable
private struct QuizEnhancementOutput {

    @Guide(description: "A fresh, natural example sentence showing how a Gen Z person would actually use this slang term in real conversation. Different from the provided example. 1–2 sentences maximum.")
    var exampleSentence: String

    @Guide(description: "A plausible but clearly wrong definition for this slang term. Should sound believable to someone unfamiliar with Gen Z slang, but must NOT be the real definition.")
    var wrongDefinition1: String

    @Guide(description: "A second plausible but wrong definition for this slang term. Must be different from wrongDefinition1 and from the real definition.")
    var wrongDefinition2: String

    @Guide(description: "A third plausible but wrong definition for this slang term. Must be different from the other two wrong definitions and from the real definition.")
    var wrongDefinition3: String
}

// MARK: - FoundationModelsQuizService

/// Enriches quiz questions using the on-device `SystemLanguageModel`.
///
/// For each term, generates:
/// - A contextually fresh example sentence (used for all question types)
/// - Three plausible-but-wrong definitions (used for `.definitionPick` distractors)
///
/// `.termPick` and `.fillInBlank` distractors continue using real glossary terms
/// because AI-invented fake slang names are less pedagogically useful than
/// exposure to other real slang.
///
/// Returns `nil` when Apple Intelligence is unavailable; `GenerateQuizUseCase`
/// falls back to the static `SlangTerm.exampleSentence` and pool-based distractors.
@available(iOS 26, *)
public struct FoundationModelsQuizService: AIQuizGenerationService {

    public init() {}

    // MARK: - AIQuizGenerationService

    public func enhance(
        term: SlangTerm,
        allTerms: [SlangTerm],
        questionType: QuestionType
    ) async -> AIQuizEnhancement? {
        guard SystemLanguageModel.default.availability == .available else { return nil }

        let sentenceHint: String
        switch questionType {
        case .fillInBlank:
            sentenceHint = "The sentence must contain the exact slang term so it can be blanked out."
        case .definitionPick, .termPick:
            sentenceHint = "The sentence should feel like a real text message or social media post."
        }

        let prompt = buildPrompt(for: term, sentenceHint: sentenceHint)

        do {
            let session  = LanguageModelSession(
                instructions: Instructions(systemInstruction(for: term))
            )
            let response = try await session.respond(to: prompt, generating: QuizEnhancementOutput.self)
            let output   = response.content

            let distractors = [output.wrongDefinition1, output.wrongDefinition2, output.wrongDefinition3]
            Logger.quizzes.debug("AI quiz enhancement generated for '\(term.term)'.")
            return AIQuizEnhancement(exampleSentence: output.exampleSentence,
                                     definitionDistractors: distractors)
        } catch {
            Logger.quizzes.error("AI quiz enhancement failed for '\(term.term)': \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Prompt Construction

    private func systemInstruction(for term: SlangTerm) -> String {
        """
        You are a Gen Z slang quiz designer. Your output must be accurate, engaging, and culturally authentic.
        You know that the correct definition of "\(term.term)" is: "\(term.definition)".
        Never use the real definition as one of the wrong answers.
        """
    }

    private func buildPrompt(for term: SlangTerm, sentenceHint: String) -> String {
        """
        Slang term: \(term.term)
        Real definition: \(term.definition)
        Standard English equivalent: \(term.standardEnglish)
        Origin: \(term.origin)
        Existing example (do NOT copy this): \(term.exampleSentence)

        Create a quiz question enhancement:
        1. Write a NEW example sentence. \(sentenceHint)
        2. Write three wrong definitions that a non-Gen Z person might believe.
        """
    }
}

#endif
