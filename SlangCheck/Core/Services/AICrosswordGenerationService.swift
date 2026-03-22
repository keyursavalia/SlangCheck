// Core/Services/AICrosswordGenerationService.swift
// SlangCheck
//
// Protocol + value types for AI-powered crossword puzzle generation.
// The AI selects words and writes clues; a deterministic Swift builder
// produces a valid grid. Zero UIKit/FoundationModels imports.

import Foundation

// MARK: - AICrosswordEntry

/// A single term-clue pair for a crossword puzzle, selected and written by the AI.
///
/// `term` is an uppercase string from the slang glossary.
/// `clue` is a creative, engaging hint written by the AI in crossword style.
public struct AICrosswordEntry: Sendable {

    /// The slang term in uppercase (e.g., `"RIZZ"`). Letters only — no spaces.
    public let term: String

    /// The crossword clue text (e.g., `"Magnetic charm; what Kai Cenat has"`).
    public let clue: String

    public init(term: String, clue: String) {
        self.term = term.uppercased().filter(\.isLetter)
        self.clue = clue
    }
}

// MARK: - AICrosswordLayout

/// AI-generated term-and-clue pairs ready to be passed to `CrosswordLayoutBuilder`.
///
/// The AI selects 5–8 terms from the glossary that share letters and vary in
/// length (ideal for crossword intersections), then writes creative clue text
/// for each. The Swift `CrosswordLayoutBuilder` takes these entries and produces
/// a structurally valid `CrosswordPuzzle`.
public struct AICrosswordLayout: Sendable {

    /// Ordered list of term-clue pairs. Minimum 4 entries required by the builder.
    public let entries: [AICrosswordEntry]

    public init(entries: [AICrosswordEntry]) {
        self.entries = entries
    }
}

// MARK: - AICrosswordGenerationService

/// Generates a fresh crossword by selecting glossary terms and writing clue text.
///
/// Returns `nil` when Apple Intelligence is unavailable; callers fall back to
/// `SampleCrosswordRepository` (the hardcoded demo puzzle).
///
/// ## Separation of concerns
/// The AI is responsible for *content* (which words, what clues).
/// `CrosswordLayoutBuilder` is responsible for *structure* (valid grid geometry).
/// This separation ensures the puzzle is always valid regardless of AI output quality.
public protocol AICrosswordGenerationService: Sendable {

    /// Generates term-clue entries for a new crossword puzzle.
    ///
    /// - Parameter glossary: The full slang dictionary to select terms from.
    /// - Returns: An `AICrosswordLayout` with 4–8 entries, or `nil` if unavailable.
    func generateLayout(from glossary: [SlangTerm]) async -> AICrosswordLayout?
}
