// Data/Firebase/FirebaseAuraSyncService.swift
// SlangCheck
//
// Firestore-backed AuraSyncService. Conflict resolution: server-authoritative (Q-003).
//
// DEVELOPER ACTION REQUIRED — before this file compiles:
// 1. In Xcode → File → Add Package Dependencies → add Firebase iOS SDK:
//      https://github.com/firebase/firebase-ios-sdk
//    Select: FirebaseFirestore, FirebaseAuth
// 2. Add GoogleService-Info.plist to the SlangCheck target.
// 3. Call `FirebaseApp.configure()` in SlangCheckApp.init() before AppEnvironment.production().
// 4. AppEnvironment.production() auto-selects this implementation when
//    canImport(FirebaseFirestore) is true.
//
// Firestore document paths:
//   Profile:    users/{userID}/aura/profile
//   QuizResult: users/{userID}/quizResults/{resultID}

#if canImport(FirebaseFirestore) && canImport(FirebaseAuth)

import FirebaseAuth
import FirebaseFirestore
import Foundation
import OSLog

// MARK: - FirebaseAuraSyncService

/// Production `AuraSyncService` backed by Firebase Firestore.
///
/// **Auth:** Uses `FirebaseAuth.Auth.auth().currentUser`. If no user is signed in,
/// throws `AuraSyncError.unauthenticated` immediately — no network call is made.
///
/// **Conflict resolution (Q-003 — server-authoritative):**
/// `syncProfile(_:)` attempts a Firestore `setData` with `merge: false` followed
/// by an immediate `getDocument` to retrieve the current server snapshot.
/// The server document is the source of truth: whatever Firestore returns is
/// what gets stored in the local CoreData cache.
public struct FirebaseAuraSyncService: AuraSyncService {

    // MARK: - Firestore Paths

    private enum Path {
        static func auraProfile(userID: String) -> DocumentReference {
            Firestore.firestore()
                .collection("users")
                .document(userID)
                .collection("aura")
                .document("profile")
        }

        static func quizResult(userID: String, resultID: String) -> DocumentReference {
            Firestore.firestore()
                .collection("users")
                .document(userID)
                .collection("quizResults")
                .document(resultID)
        }
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - AuraSyncService

    public func syncProfile(_ localProfile: AuraProfile) async throws(AuraSyncError) -> AuraProfile {
        let userID = try authenticatedUserID()

        let data = encodeProfile(localProfile)
        let ref  = Path.auraProfile(userID: userID)

        do {
            // Write the local snapshot to Firestore.
            // `merge: false` overwrites the entire document so stale fields are removed.
            try await ref.setData(data)

            // Read back the server's canonical snapshot (server-authoritative).
            let snapshot = try await ref.getDocument()
            guard let serverProfile = decodeProfile(snapshot, localProfile: localProfile) else {
                // Decode failed — fall back to localProfile so the caller can continue.
                Logger.quizzes.error("Firestore profile decode failed; using local snapshot.")
                return localProfile
            }
            return serverProfile

        } catch let error as AuraSyncError {
            throw error
        } catch {
            Logger.quizzes.error("Firestore syncProfile error: \(error.localizedDescription)")
            throw AuraSyncError.syncFailed(underlying: error)
        }
    }

    public func syncQuizResult(_ result: QuizResult) async throws(AuraSyncError) {
        let userID = try authenticatedUserID()
        let ref    = Path.quizResult(userID: userID, resultID: result.id.uuidString)
        let data   = encodeQuizResult(result)

        do {
            // Quiz results are append-only — use merge: false to ensure idempotency.
            try await ref.setData(data)
            Logger.quizzes.debug("QuizResult synced to Firestore. id=\(result.id.uuidString)")
        } catch {
            Logger.quizzes.error("Firestore syncQuizResult error: \(error.localizedDescription)")
            throw AuraSyncError.syncFailed(underlying: error)
        }
    }

    // MARK: - Auth

    private func authenticatedUserID() throws(AuraSyncError) -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuraSyncError.unauthenticated
        }
        return uid
    }

    // MARK: - Encoding

    private func encodeProfile(_ profile: AuraProfile) -> [String: Any] {
        var data: [String: Any] = [
            "id":           profile.id.uuidString,
            "totalPoints":  profile.totalPoints,
            "currentTier":  profile.currentTier.rawValue,
            "streak":       profile.streak,
            "displayName":  profile.displayName
        ]
        if let lastActivity = profile.lastActivityDate {
            data["lastActivityDate"] = Timestamp(date: lastActivity)
        }
        return data
    }

    private func encodeQuizResult(_ result: QuizResult) -> [String: Any] {
        [
            "id":               result.id.uuidString,
            "correctCount":     result.correctCount,
            "totalCount":       result.totalCount,
            "hintsUsed":        result.hintsUsed,
            "elapsedSeconds":   result.elapsedSeconds,
            "auraPointsEarned": result.auraPointsEarned,
            "completedAt":      Timestamp(date: result.completedAt)
        ]
    }

    // MARK: - Decoding

    /// Decodes a Firestore `DocumentSnapshot` into an `AuraProfile`.
    /// Falls back to `localProfile` if any required field is missing.
    private func decodeProfile(
        _ snapshot: DocumentSnapshot,
        localProfile: AuraProfile
    ) -> AuraProfile? {
        guard
            snapshot.exists,
            let data         = snapshot.data(),
            let idString     = data["id"]          as? String,
            let id           = UUID(uuidString: idString),
            let totalPoints  = data["totalPoints"] as? Int,
            let streak       = data["streak"]      as? Int,
            let displayName  = data["displayName"] as? String
        else { return nil }

        let lastActivityDate = (data["lastActivityDate"] as? Timestamp)?.dateValue()

        return AuraProfile(
            id: id,
            totalPoints: totalPoints,
            streak: streak,
            lastActivityDate: lastActivityDate,
            displayName: displayName
        )
    }
}

#endif // canImport(FirebaseFirestore) && canImport(FirebaseAuth)
