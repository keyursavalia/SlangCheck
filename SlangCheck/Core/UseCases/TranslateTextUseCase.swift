// Core/UseCases/TranslateTextUseCase.swift
// SlangCheck
//
// Pure translation logic. Zero UIKit, SwiftUI, or CoreData imports.
// Algorithm: greedy longest-match-first via NSRegularExpression word boundaries,
// with delimiter expansion and verb inflection matching for natural sentence input.

import Foundation

// MARK: - TranslateTextUseCase

/// Translates free-form text using the slang term dictionary fetched from the repository.
///
/// **Algorithm:**
/// 1. Fetch all terms from the repository.
/// 2. Build a lookup table of (pattern → replacement) pairs:
///    - genZ→standard: slang term + common inflected forms (capping → lying)
///    - standard→genZ: every `/`- and `,`-separated meaning token + inflected forms (lying → capping)
/// 3. Sort entries by pattern length descending (longest-match-first) so "no cap" is
///    tried before "cap", preventing partial matches.
/// 4. For each entry, construct a case-insensitive `\b…\b` regex and apply globally.
/// 5. Collect one ``TranslationResult/Substitution`` per distinct matched term.
///
/// **Inflection support:**
/// Single-word meaning ↔ single-word slang pairs also generate present-participle
/// and third-person-singular entries, enabling "you are lying" → "you are capping".
/// Inflections are skipped when the slang term is clearly adjectival (ends in consonant+y
/// or past-participle -ed) to prevent nonsensical output like "saltying".
///
/// **Known limitation (v1):** replacements are applied sequentially, so a translated word
/// that coincidentally matches a later entry could be substituted a second time.
/// Extremely rare in practice with realistic slang/English content.
public struct TranslateTextUseCase {

    private let repository: any SlangTermRepository

    public init(repository: any SlangTermRepository) {
        self.repository = repository
    }

    // MARK: - Public

    public func translate(
        text: String,
        direction: TranslationDirection
    ) async throws(SlangRepositoryError) -> TranslationResult {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return TranslationResult(originalText: text, translatedText: text,
                                     direction: direction, substitutions: [])
        }
        let allTerms = try await repository.fetchAllTerms()
        return performTranslation(text: text, terms: allTerms, direction: direction)
    }

    // MARK: - Core Algorithm

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

            let fullRange = NSRange(location: 0, length: (workingText as NSString).length)
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

            // Escape $ and \ so NSRegularExpression doesn't treat them as backreferences.
            let safeReplacement = entry.replacement
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "$",  with: "\\$")

            workingText = regex.stringByReplacingMatches(
                in: workingText,
                range: NSRange(location: 0, length: (workingText as NSString).length),
                withTemplate: safeReplacement
            )
        }

        return TranslationResult(originalText: text, translatedText: workingText,
                                 direction: direction, substitutions: substitutions)
    }

    // MARK: - Lookup Builder

    private typealias LookupEntry = (original: String, replacement: String, term: SlangTerm)

    /// Builds and sorts the full lookup table for the given direction.
    private func buildLookup(terms: [SlangTerm], direction: TranslationDirection) -> [LookupEntry] {
        var entries: [LookupEntry] = []

        switch direction {

        case .genZToStandard:
            for term in terms {
                let primary = primaryMeaning(of: term.standardEnglish)
                guard !primary.isEmpty else { continue }

                // Base entry: "Cap" → "Lie"
                entries.append((original: term.term, replacement: primary, term: term))

                // Inflected entries for single-word slang ↔ single-word meaning.
                // Allows "capping" → "lying", "caps" → "lies".
                addInflectedEntries(slangPhrase: term.term, meaningPhrase: primary,
                                    term: term, to: &entries)
            }

        case .standardToGenZ:
            for term in terms {
                // Split on both "/" and "," — the seed uses "/" as primary separator.
                // "Bitter / Upset" → ["Bitter", "Upset"]
                // "Lie / Falsehood" → ["Lie", "Falsehood"]
                let meanings = splitMeanings(term.standardEnglish)

                for meaning in meanings {
                    // Base entry: "Bitter" → "Salty"
                    entries.append((original: meaning, replacement: term.term, term: term))

                    // Inflected entries: "lying" → "capping", "lies" → "caps".
                    addInflectedEntries(slangPhrase: term.term, meaningPhrase: meaning,
                                        term: term, to: &entries,
                                        inputIsSlang: false)
                }
            }
        }

        // Longest-match-first prevents "cap" from shadowing "no cap".
        return entries.sorted { $0.original.count > $1.original.count }
    }

    /// Appends present-participle and third-person-singular inflection pairs for a
    /// single-word slang ↔ single-word meaning combination.
    ///
    /// Skipped when:
    /// - Either phrase is multi-word (inflection becomes ambiguous).
    /// - The slang term ends in consonant+y ("Salty" → would produce "saltying") or
    ///   -ed ("Snatched" → would produce "snatcheding"), indicating an adjectival form.
    private func addInflectedEntries(
        slangPhrase: String,
        meaningPhrase: String,
        term: SlangTerm,
        to entries: inout [LookupEntry],
        inputIsSlang: Bool = true  // true = pattern is slang, false = pattern is meaning
    ) {
        let slangWords   = slangPhrase.components(separatedBy: " ").filter { !$0.isEmpty }
        let meaningWords = meaningPhrase.components(separatedBy: " ").filter { !$0.isEmpty }

        guard slangWords.count == 1, meaningWords.count == 1,
              let sWord = slangWords.first, let mWord = meaningWords.first
        else { return }

        // Guard: skip adjectival slang forms that produce nonsensical -ing outputs.
        if endsInConsonantPlusY(sWord) || sWord.lowercased().hasSuffix("ed") { return }

        // Determine (patternWord, replacementWord) based on direction.
        let (patternBase, replacementBase) = inputIsSlang
            ? (sWord, mWord)   // genZ→standard: pattern=slang, replacement=meaning
            : (mWord, sWord)   // standard→genZ: pattern=meaning, replacement=slang

        // Present participle: "Cap" → "capping"; "lie" → "lying"
        let ingPattern     = presentParticiple(of: patternBase)
        let ingReplacement = presentParticiple(of: replacementBase)
        if ingPattern.lowercased() != patternBase.lowercased() {
            entries.append((original: ingPattern, replacement: ingReplacement, term: term))
        }

        // Third-person singular: "Cap" → "caps"; "lie" → "lies"
        let sPattern     = thirdPersonSingular(of: patternBase)
        let sReplacement = thirdPersonSingular(of: replacementBase)
        if sPattern.lowercased() != patternBase.lowercased() {
            entries.append((original: sPattern, replacement: sReplacement, term: term))
        }
    }

    // MARK: - Meaning Splitting

    /// Splits a `standardEnglish` string into individual meaning tokens.
    /// Handles both slash-separated ("Bitter / Upset") and comma-separated values.
    private func splitMeanings(_ standardEnglish: String) -> [String] {
        standardEnglish
            .components(separatedBy: CharacterSet(charactersIn: "/,"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Returns the first meaning token — used as the concise genZ→standard replacement.
    private func primaryMeaning(of standardEnglish: String) -> String {
        splitMeanings(standardEnglish).first ?? standardEnglish
    }

    // MARK: - Verb Inflection Helpers

    /// Returns the present participle (-ing form) of an English verb.
    ///
    /// Rules applied (in order):
    /// - `-ie` ending → drop `ie`, add `ying`: "lie" → "lying", "die" → "dying"
    /// - `-e` ending (not `-ee`): drop `e`, add `ing`: "make" → "making"
    /// - CVC pattern (consonant-vowel-consonant): double final consonant: "cap" → "capping"
    /// - Default: append `ing`: "steal" → "stealing"
    private func presentParticiple(of verb: String) -> String {
        let v = verb.lowercased()
        guard !v.hasSuffix("ing") else { return v }

        if v.hasSuffix("ie") {
            return String(v.dropLast(2)) + "ying"
        }
        if v.hasSuffix("e") && !v.hasSuffix("ee") && v.count > 2 {
            return String(v.dropLast()) + "ing"
        }
        if shouldDoubleConsonant(v) {
            return v + String(v.last!) + "ing"
        }
        return v + "ing"
    }

    /// Returns the third-person singular present tense (-s/-es form).
    private func thirdPersonSingular(of verb: String) -> String {
        let v = verb.lowercased()
        // Consonant + y → replace y with ies: "study" → "studies"
        if v.hasSuffix("y"), let penultimate = v.dropLast().last,
           !"aeiou".contains(penultimate) {
            return String(v.dropLast()) + "ies"
        }
        // Sibilant / affricate endings → add es
        let esEndings = ["s", "sh", "ch", "x", "z"]
        if esEndings.contains(where: { v.hasSuffix($0) }) {
            return v + "es"
        }
        return v + "s"
    }

    /// `true` when the final three characters form a consonant-vowel-consonant pattern,
    /// indicating the final consonant should be doubled before adding a vowel suffix.
    private func shouldDoubleConsonant(_ word: String) -> Bool {
        let vowels = "aeiou"
        guard word.count >= 3 else { return false }
        let chars = Array(word)
        let last       = chars[chars.count - 1]
        let secondLast = chars[chars.count - 2]
        let thirdLast  = chars[chars.count - 3]
        let notDoubleable: Set<Character> = ["w", "x", "y"]
        return !vowels.contains(last) && !notDoubleable.contains(last)
            && vowels.contains(secondLast)
            && !vowels.contains(thirdLast)
    }

    /// `true` when `word` ends in a consonant followed by `y` (e.g. "salty", "sketchy"),
    /// which indicates an adjectival form that should not receive verb inflections.
    private func endsInConsonantPlusY(_ word: String) -> Bool {
        guard word.count >= 2 else { return false }
        let chars = Array(word.lowercased())
        return chars.last == "y" && !"aeiou".contains(chars[chars.count - 2])
    }
}
