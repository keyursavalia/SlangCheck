// Core/Repositories/CrosswordRepository.swift
// SlangCheck
//
// Data access protocol for the daily crossword: puzzle fetch, user state
// persistence, and decryption key retrieval.
// Zero UIKit/SwiftUI/CoreData/Firebase imports — platform-agnostic contract.

import Foundation

// MARK: - CrosswordRepositoryError

/// Typed errors thrown by `CrosswordRepository` implementations.
public enum CrosswordRepositoryError: LocalizedError, Sendable {
    case puzzleNotFound
    case fetchFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case keyUnavailable
    case keyFetchFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .puzzleNotFound:
            return String(localized: "error.crossword.puzzleNotFound",
                          defaultValue: "Today's crossword is not available yet.")
        case .fetchFailed(let err):
            return String(localized: "error.crossword.fetchFailed",
                          defaultValue: "Could not load the crossword: \(err.localizedDescription)")
        case .saveFailed(let err):
            return String(localized: "error.crossword.saveFailed",
                          defaultValue: "Could not save your progress: \(err.localizedDescription)")
        case .keyUnavailable:
            return String(localized: "error.crossword.keyUnavailable",
                          defaultValue: "Answers are not available yet. Check back after the reveal time.")
        case .keyFetchFailed(let err):
            return String(localized: "error.crossword.keyFetchFailed",
                          defaultValue: "Could not retrieve the answer key: \(err.localizedDescription)")
        }
    }
}

// MARK: - CrosswordRepository Protocol

/// Data access interface for the daily crossword feature.
///
/// Callers receive the today's `CrosswordPuzzle` (puzzle definition with
/// encrypted answer key), read/write the user's in-progress `CrosswordUserState`,
/// and fetch the symmetric decryption key from the server after `revealAt`.
///
/// ViewModels must never talk to Firestore or UserDefaults directly.
public protocol CrosswordRepository: Sendable {

    // MARK: Puzzle

    /// Fetches today's crossword puzzle.
    ///
    /// - Throws: `CrosswordRepositoryError.puzzleNotFound` if today's puzzle
    ///   has not yet been published to Firestore.
    func fetchTodaysPuzzle() async throws(CrosswordRepositoryError) -> CrosswordPuzzle

    // MARK: User State

    /// Fetches the locally-persisted user state for the given puzzle, or `nil`
    /// if the user has not yet started this puzzle.
    func fetchUserState(for puzzleID: UUID) async throws(CrosswordRepositoryError) -> CrosswordUserState?

    /// Upserts the user's in-progress state for the given puzzle.
    func saveUserState(_ state: CrosswordUserState) async throws(CrosswordRepositoryError)

    // MARK: Result

    /// Saves the completed puzzle result to local storage.
    func saveResult(_ result: CrosswordResult) async throws(CrosswordRepositoryError)

    /// Fetches all stored crossword results, sorted by `completedAt` descending.
    func fetchResults() async throws(CrosswordRepositoryError) -> [CrosswordResult]

    // MARK: Answer Key

    /// Requests the symmetric AES-256 decryption key from the server.
    ///
    /// The key is a 32-byte `Data` value issued by a Cloud Function only after
    /// `puzzle.revealAt` has passed. The client passes this key to
    /// `AnswerKeyService.decrypt(_:puzzle:)` to recover the answer dictionary.
    ///
    /// - Throws: `CrosswordRepositoryError.keyUnavailable` if `revealAt` has not
    ///   passed; `.keyFetchFailed` on network or server errors.
    func fetchDecryptionKey(for puzzleID: UUID) async throws(CrosswordRepositoryError) -> Data
}
