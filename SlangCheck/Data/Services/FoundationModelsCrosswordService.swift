// Data/Services/FoundationModelsCrosswordService.swift
// SlangCheck
//
// Apple Intelligence crossword generation service.
// Two-step process: AI selects crossword-compatible terms, then writes creative clues.
// Grid construction is handled deterministically by CrosswordLayoutBuilder.
// Compiled only on iOS 26+ with FoundationModels.

import Foundation
import OSLog

#if canImport(FoundationModels)
import FoundationModels

// MARK: - Generable Output Types

/// AI-selected terms suitable for a crossword grid.
@available(iOS 26, *)
@Generable
private struct SelectedTermsOutput {

    @Guide(description: "Exactly 7 slang terms chosen from the provided glossary. Pick terms that: (1) are 3–9 letters when spaces are removed, (2) have varied lengths, (3) likely share at least one letter with another selected term. Return only the term names, not definitions.")
    var terms: [String]
}

/// AI-generated creative clue for a single crossword entry.
@available(iOS 26, *)
@Generable
private struct CrosswordClueOutput {

    @Guide(description: "A clever, engaging crossword-style clue for this slang term. 5–15 words. Be witty, culturally relevant, and slightly tricky but solvable. Do NOT include the term itself in the clue.")
    var clue: String
}

// MARK: - FoundationModelsCrosswordService

/// Generates a fresh daily crossword layout using the on-device `SystemLanguageModel`.
///
/// ## Two-pass approach
/// **Pass 1 — Word selection:** The AI scans the full glossary and picks 7 terms
/// with properties favourable for crossword intersections (varied length, shared letters).
///
/// **Pass 2 — Clue writing:** For each selected term, the AI writes a creative clue
/// in crossword style. Passes are independent to keep each model call focused.
///
/// Returns `nil` when Apple Intelligence is unavailable; the caller
/// (`AIGeneratedCrosswordRepository`) falls back to `SampleCrosswordRepository`.
@available(iOS 26, *)
public struct FoundationModelsCrosswordService: AICrosswordGenerationService {

    public init() {}

    // MARK: - AICrosswordGenerationService

    public func generateLayout(from glossary: [SlangTerm]) async -> AICrosswordLayout? {
        guard SystemLanguageModel.default.availability == .available else {
            Logger.crossword.info("Apple Intelligence not available for crossword generation.")
            return nil
        }
        guard glossary.count >= 7 else {
            Logger.crossword.warning("Glossary too small for crossword: \(glossary.count) terms.")
            return nil
        }

        // Limit the glossary sent to the model to avoid exceeding context limits.
        // Sample 30 terms (shuffled) — enough variety for 7 crossword entries.
        let sampledGlossary = glossary.count > 30
            ? Array(glossary.shuffled().prefix(30))
            : glossary

        // Pass 1: Select terms.
        guard let selectedTermNames = await selectTerms(from: sampledGlossary) else { return nil }

        // Resolve term names back to SlangTerm objects for Pass 2 (search full glossary).
        let termLookup = Dictionary(uniqueKeysWithValues: glossary.map { ($0.term.lowercased(), $0) })
        let resolved: [SlangTerm] = selectedTermNames.compactMap { name in
            termLookup[name.lowercased()]
        }
        guard resolved.count >= 4 else {
            Logger.crossword.warning("AI resolved only \(resolved.count)/\(selectedTermNames.count) terms; need ≥4. Names: \(selectedTermNames)")
            return nil
        }

        // Pass 2: Generate clues (parallel — one session per term).
        let entries = await generateClues(for: resolved)
        guard entries.count >= 4 else { return nil }

        Logger.crossword.info("AI crossword generated: \(entries.count) entries.")
        return AICrosswordLayout(entries: entries)
    }

    // MARK: - Pass 1: Term Selection

    private func selectTerms(from glossary: [SlangTerm]) async -> [String]? {
        let glossaryList = glossary.map { "• \($0.term) (\($0.definition))" }.joined(separator: "\n")

        let session = LanguageModelSession(instructions: Instructions("""
            You are a crossword puzzle designer specialising in Gen Z slang.
            Select terms that work well together in a crossword grid.
            """))

        let prompt = """
            From this Gen Z slang glossary, pick exactly 7 terms for a crossword puzzle.
            Prioritise terms that: are 3–9 letters (no spaces), have varied lengths, and may share letters.

            Glossary:
            \(glossaryList)
            """

        do {
            let response = try await session.respond(to: prompt, generating: SelectedTermsOutput.self)
            let terms    = response.content.terms.filter { !$0.isEmpty }
            Logger.crossword.info("AI selected \(terms.count) crossword terms: \(terms.joined(separator: ", "))")
            return terms.isEmpty ? nil : terms
        } catch {
            Logger.crossword.error("Crossword term selection failed: \(error)")
            return nil
        }
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
        let session = LanguageModelSession(instructions: Instructions("""
            You are a crossword clue writer specialising in Gen Z and internet culture.
            Write clues that are clever, culturally authentic, and engaging for a modern audience.
            """))

        let prompt = """
            Write a crossword clue for the slang term "\(term.term)".
            Definition: \(term.definition)
            Standard English: \(term.standardEnglish)
            """

        do {
            let response = try await session.respond(to: prompt, generating: CrosswordClueOutput.self)
            return AICrosswordEntry(term: term.term, clue: response.content.clue)
        } catch {
            // Use definition as fallback clue so this term is still included.
            Logger.crossword.warning("Clue generation fell back to definition for '\(term.term)'.")
            return AICrosswordEntry(term: term.term, clue: term.definition)
        }
    }
}

#endif
