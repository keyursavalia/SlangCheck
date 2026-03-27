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

    @Guide(description: "A fresh, natural example sentence showing how a Gen Z person would actually use this slang term in real conversation. 1–2 sentences maximum. Must contain the term itself.")
    var exampleSentence: String

    @Guide(description: "A SHORT, punchy correct definition of this slang term in 5–10 words. Do NOT copy the glossary definition. Paraphrase it in casual, simple language a quiz player can quickly read. Example format: 'To show off confidently' or 'Being overly dramatic about something'.")
    var shortDefinition: String

    @Guide(description: "A short wrong definition (5–10 words) that sounds plausible but is incorrect. Must match the style and length of the short correct definition. Do NOT use the real definition.")
    var wrongDefinition1: String

    @Guide(description: "A second short wrong definition (5–10 words). Different from wrongDefinition1, same length/style.")
    var wrongDefinition2: String

    @Guide(description: "A third short wrong definition (5–10 words). Different from the other two, same length/style.")
    var wrongDefinition3: String

    @Guide(description: "A creative scenario, vibe, or situation that describes when someone would use this term — WITHOUT using the term itself. Should feel like a riddle or 'what would you call it when...' hint. Example: 'When your friend shows up in a fire outfit and everyone stares' (answer: slay). 10–20 words.")
    var questionHint: String
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

        let prompt = buildPrompt(for: term, questionType: questionType)

        do {
            let session  = LanguageModelSession(
                instructions: Instructions(systemInstruction)
            )
            let response = try await session.respond(to: prompt, generating: QuizEnhancementOutput.self)
            let output   = response.content

            let distractors = [output.wrongDefinition1, output.wrongDefinition2, output.wrongDefinition3]
            Logger.quizzes.debug("AI quiz enhancement generated for '\(term.term)'.")
            return AIQuizEnhancement(
                exampleSentence: output.exampleSentence,
                shortDefinition: output.shortDefinition,
                shortDistractors: distractors,
                questionHint: output.questionHint
            )
        } catch {
            Logger.quizzes.error("AI quiz enhancement failed for '\(term.term)': \(error)")
            return nil
        }
    }

    // MARK: - Prompt Construction

    private var systemInstruction: String {
        """
        You are a fun, challenging Gen Z slang quiz designer. Your goal is to make quiz \
        questions that actually make players THINK — not just recognise copy-pasted definitions.

        CRITICAL RULES:
        • The short definition MUST be a concise paraphrase (5–10 words), NOT the glossary text.
        • Wrong answers must be the SAME length and style as the correct short definition.
        • The question hint must describe a SITUATION or VIBE, never state the definition.
        • The example sentence must contain the actual slang term.
        • Be culturally authentic, witty, and engaging. Think TikTok, not textbook.
        """
    }

    private func buildPrompt(for term: SlangTerm, questionType: QuestionType) -> String {
        let sentenceHint: String
        switch questionType {
        case .fillInBlank:
            sentenceHint = "The sentence MUST contain the exact slang term '\(term.term)' so it can be blanked out."
        case .definitionPick, .termPick:
            sentenceHint = "The sentence should feel like a real text message or social media post."
        }

        return """
        Slang term: \(term.term)
        Meaning (for your reference ONLY — do NOT copy this): \(term.definition)
        Standard English: \(term.standardEnglish)

        Generate the following:
        1. A NEW example sentence using "\(term.term)" in context. \(sentenceHint)
        2. A SHORT correct definition (5–10 words). Paraphrase casually — do NOT copy the meaning above.
        3. Three SHORT wrong definitions (5–10 words each) that sound plausible but are incorrect. \
        They must match the style and length of the correct short definition.
        4. A creative scenario/situation hint (10–20 words) that describes WHEN someone would \
        use this term. Do NOT include the term itself in the hint.
        """
    }
}

#endif
