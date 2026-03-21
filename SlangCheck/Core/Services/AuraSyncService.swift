// Core/Services/AuraSyncService.swift
// SlangCheck
//
// Protocol for syncing the Aura Economy to Firebase Firestore.
// Conflict resolution: server-authoritative (Q-003).
// Zero UIKit/SwiftUI/CoreData/Firebase imports — platform-agnostic contract.

import Foundation

// MARK: - AuraSyncError

/// Errors thrown by `AuraSyncService` implementations.
public enum AuraSyncError: LocalizedError, Sendable {
    /// The user is not authenticated. Sync is deferred until sign-in.
    case unauthenticated
    /// A Firestore network or decode error.
    case syncFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return String(localized: "error.sync.unauthenticated",
                          defaultValue: "Sign in to sync your Aura Points.")
        case .syncFailed(let err):
            return String(localized: "error.sync.failed",
                          defaultValue: "Sync failed: \(err.localizedDescription)")
        }
    }
}

// MARK: - AuraSyncService Protocol

/// Synchronises the local Aura Economy state with Firebase Firestore.
///
/// **Conflict resolution (Q-003):** server-authoritative.
/// `syncProfile(_:)` writes the local snapshot to Firestore and returns the
/// server's canonical value. If the server's value differs from the local
/// snapshot (e.g., another device wrote a higher total), the caller must
/// persist the returned profile, overwriting the local cache.
///
/// Sync is best-effort and fire-and-forget from the ViewModel's perspective:
/// callers should not block the UI waiting for sync to complete.
/// `SyncAuraProfileUseCase` enforces this contract.
public protocol AuraSyncService: Sendable {

    /// Writes `localProfile` to Firestore and returns the server-authoritative snapshot.
    ///
    /// - Parameter localProfile: The current local `AuraProfile`.
    /// - Returns: The profile as confirmed (and potentially updated) by the server.
    /// - Throws: `AuraSyncError.unauthenticated` if not signed in;
    ///           `AuraSyncError.syncFailed` on network or Firestore errors.
    func syncProfile(_ localProfile: AuraProfile) async throws(AuraSyncError) -> AuraProfile

    /// Writes a `QuizResult` to Firestore.
    ///
    /// This is a write-only operation — quiz results are never modified after creation.
    /// Failures are logged but do not affect local state.
    func syncQuizResult(_ result: QuizResult) async throws(AuraSyncError)
}
