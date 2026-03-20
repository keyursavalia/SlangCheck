// Core/UseCases/TranslateTextUseCase.swift
// SlangCheck
//
// Pure translation logic. Zero UIKit, SwiftUI, or CoreData imports.
// Algorithm: greedy longest-match-first via NSRegularExpression word boundaries.

import Foundation

// MARK: - TranslateTextUseCase

/// Translates free-form text using the slang term dictionary fetched from the repository.
///
/// **Algorithm:**
/// 1. Fetch all terms from the repository.
/// 2. Build a lookup table keyed by the source phrase (slang term or standard English meaning).
/// 3. Sort entries by source phrase length descending so longer phrases (e.g. "no cap")
///    are attempted before their sub-phrases (e.g. "cap"). This prevents partial matches.
/// 4. For each entry, construct a case-insensitive `\b...\b` word-boundary regex
///    and apply it globally across the working text.
/// 5. Collect one ``TranslationResult/Substitution`` per distinct matched term.
///
/// **Known limitation (v1):** replacements are applied sequentially, so a translated word
/// that coincidentally matches a later lookup entry could be substituted a second time.
/// This is extremely rare with realistic slang/English content and is accepted for Iteration 2.
public struct TranslateTextUseCase {

    private let repository: any SlangTermRepository

    /// - Parameter repository: The data source from which all slang terms are loaded.
    public init(repository: any SlangTermRepository) {
        self.repository = repository
    }

    // MARK: - Public

    /// Translates `text` in the given `direction`.
    /// - Returns: A ``TranslationResult`` containing the translated text and a substitution log.
    /// - Throws: ``SlangRepositoryError`` if term loading fails.
    public func translate(
        text: String,
        direction: TranslationDirection
    ) async throws(SlangRepositoryError) -> TranslationResult {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return TranslationResult(
                originalText: text,
                translatedText: text,
                direction: direction,
                substitutions: []
            )
        }
        let allTerms = try await repository.fetchAllTerms()
        return performTranslation(text: text, terms: allTerms, direction: direction)
    }

    // MARK: - Algorithm

    private func performTranslation(
        text: String,
        terms: [SlangTerm],
        direction: TranslationDirection
    ) -> TranslationResult {
        let lookup = buildLookup(terms: terms, direction: direction)
        var workingText   = text
        var substitutions: [TranslationResult.Substitution] = []

        for entry in lookup {
            let escapedPattern = NSRegularExpression.escapedPattern(for: entry.original)
            let pattern = "(?i)\\b\(escapedPattern)\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }

            let nsText    = workingText as NSString
            let fullRange = NSRange(location: 0, length: nsText.length)
            guard !regex.matches(in: workingText, range: fullRange).isEmpty else { continue }

            // One substitution record per matched term regardless of occurrence count.
            if !substitutions.contains(where: { $0.term.id == entry.term.id }) {
                substitutions.append(TranslationResult.Substitution(
                    id: UUID(),
                    originalToken: entry.original,
                    translatedToken: entry.replacement,
                    term: entry.term
                ))
            }

            // Escape $ and \ in the template to prevent NSRegularExpression
            // from interpreting them as backreference syntax.
            let safeReplacement = entry.replacement
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "$", with: "\\$")

            workingText = regex.stringByReplacingMatches(
                in: workingText,
                range: NSRange(location: 0, length: (workingText as NSString).length),
                withTemplate: safeReplacement
            )
        }

        return TranslationResult(
            originalText: text,
            translatedText: workingText,
            direction: direction,
            substitutions: substitutions
        )
    }

    // MARK: - Lookup Builder

    private typealias LookupEntry = (original: String, replacement: String, term: SlangTerm)

    /// Builds a sorted lookup table for the given direction.
    /// Sorted by `original` length descending so longer phrases take priority over sub-phrases.
    private func buildLookup(terms: [SlangTerm], direction: TranslationDirection) -> [LookupEntry] {
        var entries: [LookupEntry] = []

        switch direction {
        case .genZToStandard:
            for term in terms {
                let replacement = primaryMeaning(of: term.standardEnglish)
                guard !replacement.isEmpty else { continue }
                entries.append((original: term.term, replacement: replacement, term: term))
            }

        case .standardToGenZ:
            for term in terms {
                // Expand each comma-separated meaning into its own lookup entry.
                let meanings = term.standardEnglish
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                for meaning in meanings {
                    entries.append((original: meaning, replacement: term.term, term: term))
                }
            }
        }

        // Longest-match-first prevents "cap" from shadowing "no cap".
        return entries.sorted { $0.original.count > $1.original.count }
    }

    /// Extracts the first comma-separated token from a `standardEnglish` string.
    /// Produces a concise, sentence-friendly replacement word (e.g. "Delicious" from "Delicious, Amazing").
    private func primaryMeaning(of standardEnglish: String) -> String {
        standardEnglish
            .components(separatedBy: ",")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? standardEnglish
    }
}
