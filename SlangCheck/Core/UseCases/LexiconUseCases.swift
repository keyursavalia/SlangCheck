// Core/UseCases/LexiconUseCases.swift
// SlangCheck
//
// Use cases for Personal Lexicon operations: save and remove.
// Each use case is a single-responsibility struct.

import Foundation
import OSLog

// MARK: - SaveTermToLexiconUseCase

/// Saves a slang term to the user's Personal Lexicon.
/// No-op if the term is already saved.
public struct SaveTermToLexiconUseCase {

    private let repository: any SlangTermRepository

    public init(repository: any SlangTermRepository) {
        self.repository = repository
    }

    /// - Parameter termID: The UUID of the `SlangTerm` to save.
    /// - Throws: `SlangRepositoryError.saveFailed` if persistence fails.
    public func execute(termID: UUID) async throws(SlangRepositoryError) {
        Logger.lexicon.info("Saving term \(termID.uuidString) to lexicon.")
        try await repository.addToLexicon(termID: termID)
    }
}

// MARK: - RemoveTermFromLexiconUseCase

/// Removes a slang term from the user's Personal Lexicon.
/// No-op if the term is not currently saved.
public struct RemoveTermFromLexiconUseCase {

    private let repository: any SlangTermRepository

    public init(repository: any SlangTermRepository) {
        self.repository = repository
    }

    /// - Parameter termID: The UUID of the `SlangTerm` to remove.
    /// - Throws: `SlangRepositoryError.deleteFailed` if persistence fails.
    public func execute(termID: UUID) async throws(SlangRepositoryError) {
        Logger.lexicon.info("Removing term \(termID.uuidString) from lexicon.")
        try await repository.removeFromLexicon(termID: termID)
    }
}
