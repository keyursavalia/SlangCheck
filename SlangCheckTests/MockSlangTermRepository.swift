// SlangCheckTests/MockSlangTermRepository.swift
// SlangCheck
//
// In-memory mock repository for unit tests. Implements SlangTermRepository
// without any CoreData dependency.

import Foundation
@testable import SlangCheck

// MARK: - MockSlangTermRepository

/// An in-memory mock of SlangTermRepository for unit testing.
/// Pre-populated with sample terms in init.
final class MockSlangTermRepository: SlangTermRepository, @unchecked Sendable {

    // MARK: - State

    var terms: [SlangTerm]
    var lexiconEntries: [LexiconEntry] = []

    private var lexiconContinuation: AsyncStream<UserLexicon>.Continuation?

    // MARK: - Configuration

    var shouldThrowOnFetch = false
    var shouldThrowOnSave  = false

    // MARK: - Initialization

    init(terms: [SlangTerm] = MockSlangTermRepository.sampleTerms()) {
        self.terms = terms
    }

    // MARK: - SlangTermRepository

    func seedIfNeeded() async throws(SlangRepositoryError) {
        // No-op in mock — terms are pre-populated.
    }

    func fetchAllTerms() async throws(SlangRepositoryError) -> [SlangTerm] {
        if shouldThrowOnFetch { throw SlangRepositoryError.fetchFailed(underlying: MockError.forced) }
        return terms.sorted { $0.term < $1.term }
    }

    func fetchTerms(in category: SlangCategory) async throws(SlangRepositoryError) -> [SlangTerm] {
        if shouldThrowOnFetch { throw SlangRepositoryError.fetchFailed(underlying: MockError.forced) }
        return terms.filter { $0.category == category }.sorted { $0.term < $1.term }
    }

    func fetchTerm(id: UUID) async throws(SlangRepositoryError) -> SlangTerm {
        guard let term = terms.first(where: { $0.id == id }) else {
            throw SlangRepositoryError.termNotFound(id: id)
        }
        return term
    }

    func fetchLexicon() async throws(SlangRepositoryError) -> UserLexicon {
        return UserLexicon(entries: lexiconEntries)
    }

    func addToLexicon(termID: UUID) async throws(SlangRepositoryError) {
        if shouldThrowOnSave { throw SlangRepositoryError.saveFailed(underlying: MockError.forced) }
        guard !lexiconEntries.contains(where: { $0.termID == termID }) else { return }
        lexiconEntries.append(LexiconEntry(termID: termID, savedDate: Date()))
        notifyLexiconChanged()
    }

    func removeFromLexicon(termID: UUID) async throws(SlangRepositoryError) {
        lexiconEntries.removeAll { $0.termID == termID }
        notifyLexiconChanged()
    }

    var lexiconStream: AsyncStream<UserLexicon> {
        AsyncStream { continuation in
            self.lexiconContinuation = continuation
        }
    }

    // MARK: - Helpers

    private func notifyLexiconChanged() {
        lexiconContinuation?.yield(UserLexicon(entries: lexiconEntries))
    }

    // MARK: - Sample Data

    static func sampleTerms() -> [SlangTerm] {
        [
            SlangTerm(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                term: "No Cap",
                definition: "An intensifier meaning 'for real' or 'honestly'.",
                standardEnglish: "Honestly",
                exampleSentence: "No cap, that was amazing.",
                category: .foundationalDescriptor,
                origin: "AAVE",
                usageFrequency: .high,
                generationTags: [.genZ],
                addedDate: Date(),
                isBrainrot: false,
                isEmojiTerm: false
            ),
            SlangTerm(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                term: "Rizz",
                definition: "Short for charisma; the ability to charm or flirt successfully.",
                standardEnglish: "Charisma",
                exampleSentence: "He's got mad rizz.",
                category: .relationship,
                origin: "Popularized by Kai Cenat",
                usageFrequency: .high,
                generationTags: [.genZ],
                addedDate: Date(),
                isBrainrot: false,
                isEmojiTerm: false
            ),
            SlangTerm(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                term: "Skibidi",
                definition: "An absurdist filler word that can mean good or bad depending on context.",
                standardEnglish: "Nonsensical exclamation",
                exampleSentence: "That's so skibidi.",
                category: .brainrot,
                origin: "Skibidi Toilet YouTube series",
                usageFrequency: .high,
                generationTags: [.genAlpha],
                addedDate: Date(),
                isBrainrot: true,
                isEmojiTerm: false
            ),
            SlangTerm(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                term: "Mid",
                definition: "Mediocre, average, or underwhelming.",
                standardEnglish: "Average",
                exampleSentence: "That movie was so mid.",
                category: .foundationalDescriptor,
                origin: "Gaming culture",
                usageFrequency: .high,
                generationTags: [.genZ, .genAlpha],
                addedDate: Date(),
                isBrainrot: false,
                isEmojiTerm: false
            ),
            SlangTerm(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
                term: "Bussin'",
                definition: "Extremely good or delicious.",
                standardEnglish: "Delicious / Amazing",
                exampleSentence: "These tacos are bussin'!",
                category: .foundationalDescriptor,
                origin: "AAVE",
                usageFrequency: .medium,
                generationTags: [.genZ],
                addedDate: Date(),
                isBrainrot: false,
                isEmojiTerm: false
            )
        ]
    }
}

// MARK: - MockError

enum MockError: Error {
    case forced
}
