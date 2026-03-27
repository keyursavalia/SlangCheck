// Data/Firebase/NoOpAuthService.swift
// SlangCheck
//
// No-op implementations of AuthenticationService and UserProfileRepository.
// Used in:
//   • SwiftUI Previews
//   • Unit tests
//   • Production builds before the Firebase SDK is linked
//     (AppEnvironment.production() selects these when canImport(FirebaseAuth) is false)

import Foundation

// MARK: - NoOpAuthenticationService

/// A do-nothing `AuthenticationService` that always reports "not authenticated".
/// Never surfaces an error — callers simply never enter an authenticated state.
public struct NoOpAuthenticationService: AuthenticationService {

    public init() {}

    public var currentUserID: String? { nil }

    public func signInWithApple(
        identityToken: Data,
        nonce: String,
        fullName: String?
    ) async throws(AuthError) -> String {
        throw .unknown("Firebase Auth not configured.")
    }

    public func createAccount(email: String, password: String) async throws(AuthError) -> String {
        throw .unknown("Firebase Auth not configured.")
    }

    public func signIn(email: String, password: String) async throws(AuthError) -> String {
        throw .unknown("Firebase Auth not configured.")
    }

    public func signOut() throws(AuthError) {}

    public func deleteAccount() async throws(AuthError) {}
}

// MARK: - NoOpUserProfileRepository

/// An in-memory `UserProfileRepository` used for previews and tests.
/// Stores profiles in a local dictionary; nothing is ever sent to Firestore.
public final class NoOpUserProfileRepository: UserProfileRepository {

    private var store: [String: UserProfile] = [:]

    public init() {}

    public func fetchProfile(uid: String) async throws -> UserProfile? {
        store[uid]
    }

    public func saveProfile(_ profile: UserProfile) async throws {
        store[profile.id] = profile
    }

    public func updateDisplayName(_ name: String, uid: String) async throws {
        store[uid]?.displayName = name
    }

    public func updatePhotoURL(_ url: URL, uid: String) async throws {
        store[uid]?.photoURL = url
    }

    public func updatePreferences(_ prefs: UserPreferences, uid: String) async throws {
        if var profile = store[uid] {
            if let g = prefs.gender     { profile.gender     = g }
            if let a = prefs.ageRange   { profile.ageRange   = a }
            if let l = prefs.slangLevel { profile.slangLevel = l }
            if let g = prefs.goal       { profile.goal       = g }
            if let c = prefs.categories { profile.categories = c }
            store[uid] = profile
        }
    }

    public func uploadProfilePhoto(data: Data, uid: String) async throws -> URL {
        // Return a placeholder URL — no actual upload in previews/tests.
        // SAFE: Only reachable in non-production environments.
        URL(string: "https://placeholder.invalid/\(uid).jpg")!
    }

    public func deleteProfile(uid: String) async throws {
        store.removeValue(forKey: uid)
    }
}
