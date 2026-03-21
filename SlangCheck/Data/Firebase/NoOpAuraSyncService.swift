// Data/Firebase/NoOpAuraSyncService.swift
// SlangCheck
//
// A no-operation AuraSyncService used when:
//   (a) Firebase SDK has not yet been added via SPM, or
//   (b) the user is not authenticated.
//
// In production the app uses FirebaseAuraSyncService once Firebase is integrated.
// AppEnvironment.production() selects the correct implementation at compile time
// via #if canImport(FirebaseFirestore).

import Foundation
import OSLog

// MARK: - NoOpAuraSyncService

/// An `AuraSyncService` that performs no network operations.
///
/// `syncProfile(_:)` simply returns `localProfile` unchanged, making it safe
/// to use as a placeholder before Firebase is configured. The local CoreData
/// cache is still written by `SyncAuraProfileUseCase` — only the remote sync
/// step is skipped.
public struct NoOpAuraSyncService: AuraSyncService {

    public init() {}

    /// Returns `localProfile` unchanged — no network call is made.
    public func syncProfile(_ localProfile: AuraProfile) async throws(AuraSyncError) -> AuraProfile {
        Logger.quizzes.debug("NoOpAuraSyncService: syncProfile called — no-op.")
        return localProfile
    }

    /// Does nothing — no network call is made.
    public func syncQuizResult(_ result: QuizResult) async throws(AuraSyncError) {
        Logger.quizzes.debug("NoOpAuraSyncService: syncQuizResult called — no-op.")
    }
}
