// Core/Models/UserLexicon.swift
// SlangCheck
//
// Model representing the user's personal saved collection of slang terms.
// Immutable value type. Zero UIKit/SwiftUI/CoreData imports.

import Foundation

// MARK: - LexiconEntry

/// A single saved entry in the user's Personal Lexicon.
/// Stores the term's UUID and the timestamp when it was saved.
public struct LexiconEntry: Codable, Identifiable, Hashable, Sendable {

    /// The UUID of the `SlangTerm` that was saved.
    public let termID: UUID

    /// The date and time the user saved this term.
    public let savedDate: Date

    /// Uses `termID` as the stable Identifiable id to prevent duplication.
    public var id: UUID { termID }

    public init(termID: UUID, savedDate: Date) {
        self.termID   = termID
        self.savedDate = savedDate
    }
}

// MARK: - UserLexicon

/// The user's ordered personal collection of saved slang terms.
/// Terms are ordered by `savedDate` descending (most recent first) by default.
public struct UserLexicon: Codable, Sendable {

    // MARK: Properties

    /// All saved entries, ordered most-recent first.
    public private(set) var entries: [LexiconEntry]

    // MARK: Computed

    /// The set of saved term IDs for O(1) membership tests.
    public var savedTermIDs: Set<UUID> {
        Set(entries.map(\.termID))
    }

    /// Number of saved terms.
    public var count: Int { entries.count }

    // MARK: Initializer

    public init(entries: [LexiconEntry] = []) {
        self.entries = entries.sorted { $0.savedDate > $1.savedDate }
    }

    // MARK: Mutations

    /// Returns a new `UserLexicon` with the given term saved.
    /// If the term is already saved, the lexicon is returned unchanged.
    public func saving(termID: UUID) -> UserLexicon {
        guard !savedTermIDs.contains(termID) else { return self }
        let newEntry = LexiconEntry(termID: termID, savedDate: Date())
        return UserLexicon(entries: entries + [newEntry])
    }

    /// Returns a new `UserLexicon` with the given term removed.
    public func removing(termID: UUID) -> UserLexicon {
        UserLexicon(entries: entries.filter { $0.termID != termID })
    }

    /// Returns true if the given term is saved in this lexicon.
    public func contains(termID: UUID) -> Bool {
        savedTermIDs.contains(termID)
    }
}
