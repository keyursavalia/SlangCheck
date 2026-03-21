// Core/UseCases/SyncAuraProfileUseCase.swift
// SlangCheck
//
// Orchestrates saving an AuraProfile locally and syncing it to Firestore
// in the background. Server-authoritative conflict resolution (Q-003):
// if the server returns a different profile, the local cache is overwritten.

import Foundation
import OSLog

// MARK: - SyncAuraProfileUseCase

/// Persists an `AuraProfile` locally and kicks off a non-blocking Firestore sync.
///
/// **Execution order:**
/// 1. Save `updatedProfile` to CoreData immediately so the UI reads fresh data
///    even when offline.
/// 2. Detach a background `Task` that calls `syncService.syncProfile(_:)`.
/// 3. If the server returns a different (server-authoritative) profile, overwrite
///    the local cache with it.
///
/// The background sync never throws to callers — failures are swallowed and logged
/// so the UI is never blocked or interrupted by a sync error.
public struct SyncAuraProfileUseCase: Sendable {

    // MARK: - Dependencies

    private let auraRepository: any AuraRepository
    private let syncService: any AuraSyncService

    // MARK: - Initialization

    public init(auraRepository: any AuraRepository, syncService: any AuraSyncService) {
        self.auraRepository = auraRepository
        self.syncService    = syncService
    }

    // MARK: - Execute

    /// Saves `updatedProfile` locally, then syncs to Firestore on a background task.
    ///
    /// - Parameter updatedProfile: The new profile state to persist and sync.
    /// - Throws: `AuraRepositoryError` if the **local** save fails.
    ///           Background sync failures are swallowed and logged — they do not throw.
    public func execute(updatedProfile: AuraProfile) async throws(AuraRepositoryError) {
        // Step 1 — Local write (blocking, must succeed for UI consistency).
        try await auraRepository.saveProfile(updatedProfile)
        Logger.quizzes.info("AuraProfile saved locally. totalPoints=\(updatedProfile.totalPoints)")

        // Step 2 — Background sync (non-blocking, best-effort).
        Task.detached(priority: .utility) { [auraRepository, syncService] in
            await performSync(
                profile: updatedProfile,
                auraRepository: auraRepository,
                syncService: syncService
            )
        }
    }

    /// Saves a `QuizResult` locally and syncs it to Firestore on a background task.
    ///
    /// - Parameter result: The completed session result to persist and sync.
    /// - Throws: `AuraRepositoryError` if the **local** save fails.
    public func saveAndSyncResult(_ result: QuizResult) async throws(AuraRepositoryError) {
        // Step 1 — Local write.
        try await auraRepository.saveQuizResult(result)
        Logger.quizzes.info("QuizResult saved locally. auraPointsEarned=\(result.auraPointsEarned)")

        // Step 2 — Background sync.
        Task.detached(priority: .utility) { [syncService] in
            do {
                try await syncService.syncQuizResult(result)
                Logger.quizzes.debug("QuizResult synced to Firestore. id=\(result.id.uuidString)")
            } catch {
                Logger.quizzes.error("QuizResult sync failed (non-fatal): \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Private Sync Helper

/// Free function so `Task.detached` does not capture `self`.
private func performSync(
    profile: AuraProfile,
    auraRepository: any AuraRepository,
    syncService: any AuraSyncService
) async {
    do {
        let serverProfile = try await syncService.syncProfile(profile)
        Logger.quizzes.debug("Aura sync succeeded. serverPoints=\(serverProfile.totalPoints)")

        // Server-authoritative (Q-003): if server returned a different value, overwrite local.
        if serverProfile != profile {
            Logger.quizzes.info(
                "Server-authoritative override: local=\(profile.totalPoints) server=\(serverProfile.totalPoints)"
            )
            try? await auraRepository.saveProfile(serverProfile)
        }
    } catch AuraSyncError.unauthenticated {
        // Expected when the user hasn't signed in yet — silent.
        Logger.quizzes.debug("Aura sync skipped: user is not authenticated.")
    } catch {
        Logger.quizzes.error("Aura sync failed (non-fatal): \(error.localizedDescription)")
    }
}
