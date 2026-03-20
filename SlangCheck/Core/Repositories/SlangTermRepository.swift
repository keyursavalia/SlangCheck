// Core/Repositories/SlangTermRepository.swift
// SlangCheck
//
// Protocol defining the data access contract for slang terms and the user lexicon.
// ViewModels and UseCases depend only on this protocol, never on CoreData directly.
// Zero UIKit/SwiftUI/CoreData imports — this is a Core layer file.

import Foundation

// MARK: - Repository Error Types

/// Typed errors thrown by `SlangTermRepository` implementations.
public enum SlangRepositoryError: LocalizedError, Sendable {
    case seedFileNotFound
    case seedDataCorrupted(underlying: Error)
    case fetchFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case termNotFound(id: UUID)

    public var errorDescription: String? {
        switch self {
        case .seedFileNotFound:
            return String(localized: "error.repository.seedNotFound",
                          defaultValue: "The slang dictionary seed file could not be found.")
        case .seedDataCorrupted(let err):
            return String(localized: "error.repository.seedCorrupted",
                          defaultValue: "The slang dictionary data is corrupted: \(err.localizedDescription)")
        case .fetchFailed(let err):
            return String(localized: "error.repository.fetchFailed",
                          defaultValue: "Could not load slang terms: \(err.localizedDescription)")
        case .saveFailed(let err):
            return String(localized: "error.repository.saveFailed",
                          defaultValue: "Could not save: \(err.localizedDescription)")
        case .deleteFailed(let err):
            return String(localized: "error.repository.deleteFailed",
                          defaultValue: "Could not delete: \(err.localizedDescription)")
        case .termNotFound(let id):
            return String(localized: "error.repository.termNotFound",
                          defaultValue: "Term with ID \(id.uuidString) was not found.")
        }
    }
}

// MARK: - SlangTermRepository Protocol

/// The data access interface for all slang term and lexicon operations.
///
/// Implementations must be safe to call from any Swift concurrency context.
/// The concrete implementation is `CoreDataSlangTermRepository`.
public protocol SlangTermRepository: Sendable {

    // MARK: - Dictionary Operations

    /// Seeds the local database from the bundled JSON file if the database is empty.
    /// Safe to call on every launch; it is a no-op if data already exists.
    func seedIfNeeded() async throws(SlangRepositoryError)

    /// Fetches all slang terms, sorted alphabetically by `term`.
    func fetchAllTerms() async throws(SlangRepositoryError) -> [SlangTerm]

    /// Fetches terms filtered by category, sorted alphabetically.
    func fetchTerms(in category: SlangCategory) async throws(SlangRepositoryError) -> [SlangTerm]

    /// Fetches a single term by its UUID.
    func fetchTerm(id: UUID) async throws(SlangRepositoryError) -> SlangTerm

    // MARK: - Lexicon Operations

    /// Fetches the user's complete Personal Lexicon.
    func fetchLexicon() async throws(SlangRepositoryError) -> UserLexicon

    /// Adds a term to the user's Personal Lexicon.
    /// If the term is already saved, this is a no-op.
    func addToLexicon(termID: UUID) async throws(SlangRepositoryError)

    /// Removes a term from the user's Personal Lexicon.
    /// If the term is not in the lexicon, this is a no-op.
    func removeFromLexicon(termID: UUID) async throws(SlangRepositoryError)

    /// Returns a stream that emits the updated `UserLexicon` whenever the lexicon changes.
    /// Used by ViewModels to reactively observe lexicon state.
    var lexiconStream: AsyncStream<UserLexicon> { get }
}
