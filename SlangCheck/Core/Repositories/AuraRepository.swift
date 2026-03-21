// Core/Repositories/AuraRepository.swift
// SlangCheck
//
// Data access protocol for the Aura Economy: the local AuraProfile cache
// and the quiz result history. Zero UIKit/SwiftUI/CoreData imports.

import Foundation

// MARK: - AuraRepositoryError

/// Typed errors thrown by `AuraRepository` implementations.
public enum AuraRepositoryError: LocalizedError, Sendable {
    case fetchFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case deleteFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let err):
            return String(localized: "error.aura.fetchFailed",
                          defaultValue: "Could not load Aura data: \(err.localizedDescription)")
        case .saveFailed(let err):
            return String(localized: "error.aura.saveFailed",
                          defaultValue: "Could not save Aura data: \(err.localizedDescription)")
        case .deleteFailed(let err):
            return String(localized: "error.aura.deleteFailed",
                          defaultValue: "Could not delete Aura data: \(err.localizedDescription)")
        }
    }
}

// MARK: - AuraRepository Protocol

/// Data access interface for the local Aura Economy cache.
///
/// All reads and writes go through this protocol. The concrete implementation
/// (`CoreDataAuraRepository`) uses CoreData with a background write context.
/// ViewModels must never talk to CoreData directly.
///
/// The app is single-user locally, so there is no `userID` parameter on
/// these methods — the profile is stored as a single record identified by
/// its own `id` (which matches the authenticated user's UID when signed in).
public protocol AuraRepository: Sendable {

    // MARK: Profile

    /// Fetches the locally-cached `AuraProfile`, or `nil` if none has been saved yet.
    func fetchProfile() async throws(AuraRepositoryError) -> AuraProfile?

    /// Upserts an `AuraProfile` in the local cache.
    ///
    /// If a record with `profile.id` already exists it is overwritten; otherwise
    /// a new record is inserted. This is the single write path for both local
    /// updates and server-authoritative overwrites from the sync service.
    func saveProfile(_ profile: AuraProfile) async throws(AuraRepositoryError)

    // MARK: Quiz History

    /// Inserts a `QuizResult` into the local history log.
    ///
    /// Each call inserts a new record — results are never updated after creation.
    func saveQuizResult(_ result: QuizResult) async throws(AuraRepositoryError)

    /// Fetches all stored `QuizResult` records, sorted by `completedAt` descending.
    func fetchQuizHistory() async throws(AuraRepositoryError) -> [QuizResult]
}
