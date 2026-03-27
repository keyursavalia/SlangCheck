// Data/Services/GeminiCrosswordService.swift
// SlangCheck
//
// Gemini API fallback for crossword puzzle generation.
// Used when Apple Intelligence is unavailable (iOS < 26 or declined by user).

import Foundation
import OSLog

// MARK: - GeminiCrosswordService

/// Generates crossword layouts using the Gemini REST API.
///
/// Two-pass approach mirroring `FoundationModelsCrosswordService`:
/// 1. AI selects 7 crossword-compatible terms from the glossary.
/// 2. AI writes creative clues for each selected term.
///
/// Returns `nil` when the API key is missing or the request fails.
struct GeminiCrosswordService: AICrosswordGenerationService {

    private let client = GeminiAPIClient()

    // MARK: - AICrosswordGenerationService

    func generateLayout(from glossary: [SlangTerm]) async -> AICrosswordLayout? {
        guard glossary.count >= 7 else { return nil }

        // Limit glossary to avoid oversized prompts.
        let sampledGlossary = glossary.count > 30
            ? Array(glossary.shuffled().prefix(30))
            : glossary

        // Pass 1: Select terms.
        guard let selectedTermNames = await selectTerms(from: sampledGlossary) else { return nil }

        // Resolve names → SlangTerm objects for Pass 2 (search full glossary).
        let lookup = Dictionary(uniqueKeysWithValues: glossary.map { ($0.term.lowercased(), $0) })
        let resolved = selectedTermNames.compactMap { lookup[$0.lowercased()] }
        guard resolved.count >= 4 else {
            Logger.crossword.warning("Gemini resolved only \(resolved.count) terms; need ≥4.")
            return nil
        }

        // Pass 2: Generate clues in parallel.
        let entries = await generateClues(for: resolved)
        guard entries.count >= 4 else { return nil }

        Logger.crossword.info("Gemini crossword generated: \(entries.count) entries.")
        return AICrosswordLayout(entries: entries)
    }

    // MARK: - Pass 1: Term Selection

    private func selectTerms(from glossary: [SlangTerm]) async -> [String]? {
        let glossaryList = glossary.map { "• \($0.term) (\($0.definition))" }.joined(separator: "\n")

        let systemPrompt = """
            You are a crossword puzzle designer specialising in Gen Z slang.
            Select terms that work well together in a crossword grid.
            """

        let userPrompt = """
            From this Gen Z slang glossary, pick exactly 7 terms for a crossword puzzle.
            Prioritise terms that: are 3–9 letters (no spaces), have varied lengths, and may share letters.

            Glossary:
            \(glossaryList)
            """

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "terms": [
                    "type": "array",
                    "items": ["type": "string"],
                    "description": "Exactly 7 slang term names from the glossary"
                ]
            ],
            "required": ["terms"]
        ]

        guard let output: GeminiTermsOutput = await client.generate(
            systemInstruction: systemPrompt,
            prompt: userPrompt,
            schema: schema,
            as: GeminiTermsOutput.self
        ) else { return nil }

        let terms = output.terms.filter { !$0.isEmpty }
        Logger.crossword.debug("Gemini selected \(terms.count) crossword terms.")
        return terms.isEmpty ? nil : terms
    }

    // MARK: - Pass 2: Clue Generation

    private func generateClues(for terms: [SlangTerm]) async -> [AICrosswordEntry] {
        await withTaskGroup(of: AICrosswordEntry?.self, returning: [AICrosswordEntry].self) { group in
            for term in terms {
                group.addTask { await self.generateClue(for: term) }
            }
            var results: [AICrosswordEntry] = []
            for await entry in group {
                if let entry { results.append(entry) }
            }
            return results
        }
    }

    private func generateClue(for term: SlangTerm) async -> AICrosswordEntry? {
        let systemPrompt = """
            You are a crossword clue writer specialising in Gen Z and internet culture.
            Write clues that are clever, culturally authentic, and engaging for a modern audience.
            """

        let userPrompt = """
            Write a crossword clue for the slang term "\(term.term)".
            Definition: \(term.definition)
            Standard English: \(term.standardEnglish)
            """

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "clue": [
                    "type": "string",
                    "description": "A clever crossword-style clue (5–15 words)"
                ]
            ],
            "required": ["clue"]
        ]

        if let output: GeminiClueOutput = await client.generate(
            systemInstruction: systemPrompt,
            prompt: userPrompt,
            schema: schema,
            as: GeminiClueOutput.self
        ) {
            return AICrosswordEntry(term: term.term, clue: output.clue)
        }

        // Fallback to definition as clue.
        Logger.crossword.warning("Gemini clue fell back to definition for '\(term.term)'.")
        return AICrosswordEntry(term: term.term, clue: term.definition)
    }
}

// MARK: - Response Models

private struct GeminiTermsOutput: Decodable, Sendable {
    let terms: [String]
}

private struct GeminiClueOutput: Decodable, Sendable {
    let clue: String
}
