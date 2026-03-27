// Data/Services/GeminiQuizService.swift
// SlangCheck
//
// Gemini API fallback for quiz question enhancement.
// Used when Apple Intelligence is unavailable (iOS < 26 or declined by user).

import Foundation
import OSLog

// MARK: - GeminiQuizService

/// Enriches quiz questions using the Gemini REST API.
///
/// Mirror of `FoundationModelsQuizService`: generates a fresh example sentence
/// and three plausible-but-wrong definitions per term. Returns `nil` when the
/// API key is missing or the request fails.
struct GeminiQuizService: AIQuizGenerationService {

    private let client = GeminiAPIClient()

    // MARK: - AIQuizGenerationService

    func enhance(
        term: SlangTerm,
        allTerms: [SlangTerm],
        questionType: QuestionType
    ) async -> AIQuizEnhancement? {
        let sentenceHint: String
        switch questionType {
        case .fillInBlank:
            sentenceHint = "The sentence MUST contain the exact slang term '\(term.term)' so it can be blanked out."
        case .definitionPick, .termPick:
            sentenceHint = "The sentence should feel like a real text message or social media post."
        }

        let systemPrompt = """
            You are a fun, challenging Gen Z slang quiz designer. Your goal is to make quiz \
            questions that actually make players THINK — not just recognise copy-pasted definitions. \
            CRITICAL: The short definition MUST be a concise paraphrase (5–10 words), NOT the glossary text. \
            Wrong answers must match the same length and style as the correct short definition. \
            The question hint must describe a SITUATION or VIBE, never state the definition.
            """

        let userPrompt = """
            Slang term: \(term.term)
            Meaning (for your reference ONLY — do NOT copy this): \(term.definition)
            Standard English: \(term.standardEnglish)

            Generate the following:
            1. A NEW example sentence using "\(term.term)" in context. \(sentenceHint)
            2. A SHORT correct definition (5–10 words). Paraphrase casually — do NOT copy the meaning above.
            3. Three SHORT wrong definitions (5–10 words each) that sound plausible but are incorrect.
            4. A creative scenario/situation hint (10–20 words) describing WHEN someone would use this term. \
            Do NOT include the term itself in the hint.
            """

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "exampleSentence": [
                    "type": "string",
                    "description": "A fresh example sentence containing the slang term"
                ],
                "shortDefinition": [
                    "type": "string",
                    "description": "Concise correct definition in 5–10 words (paraphrased, NOT copied from glossary)"
                ],
                "wrongDefinition1": [
                    "type": "string",
                    "description": "First short wrong definition (5–10 words, matching style of shortDefinition)"
                ],
                "wrongDefinition2": [
                    "type": "string",
                    "description": "Second short wrong definition (5–10 words)"
                ],
                "wrongDefinition3": [
                    "type": "string",
                    "description": "Third short wrong definition (5–10 words)"
                ],
                "questionHint": [
                    "type": "string",
                    "description": "Creative scenario/situation hint (10–20 words) without using the term"
                ]
            ],
            "required": ["exampleSentence", "shortDefinition", "wrongDefinition1",
                         "wrongDefinition2", "wrongDefinition3", "questionHint"]
        ]

        guard let output: GeminiQuizOutput = await client.generate(
            systemInstruction: systemPrompt,
            prompt: userPrompt,
            schema: schema,
            as: GeminiQuizOutput.self
        ) else {
            Logger.quizzes.warning("Gemini quiz enhancement failed for '\(term.term)'.")
            return nil
        }

        Logger.quizzes.debug("Gemini quiz enhancement generated for '\(term.term)'.")
        return AIQuizEnhancement(
            exampleSentence: output.exampleSentence,
            shortDefinition: output.shortDefinition,
            shortDistractors: [
                output.wrongDefinition1,
                output.wrongDefinition2,
                output.wrongDefinition3
            ],
            questionHint: output.questionHint
        )
    }
}

// MARK: - Response Model

private struct GeminiQuizOutput: Decodable, Sendable {
    let exampleSentence: String
    let shortDefinition: String
    let wrongDefinition1: String
    let wrongDefinition2: String
    let wrongDefinition3: String
    let questionHint: String
}
