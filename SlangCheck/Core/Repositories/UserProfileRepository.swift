// Core/Repositories/UserProfileRepository.swift
// SlangCheck
//
// Protocol for reading and writing UserProfile data in Firestore.
// Firestore document path: users/{uid}
// Firebase Storage path:   profile_photos/{uid}
//
// Security model (to be applied in Firebase console):
//   Firestore: owners can write; any authenticated user can read (needed for leaderboard).
//   Storage:   public reads; owners can write up to 1 MB.

import Foundation

// MARK: - UserProfileRepository

/// Data access layer for `UserProfile` documents.
public protocol UserProfileRepository: Sendable {

    /// Fetch the profile for the given UID. Returns `nil` if no document exists yet (new user).
    func fetchProfile(uid: String) async throws -> UserProfile?

    /// Create or fully overwrite the profile document for the given UID.
    func saveProfile(_ profile: UserProfile) async throws

    /// Patch only the `displayName` field.
    func updateDisplayName(_ name: String, uid: String) async throws

    /// Patch only the `photoURL` field.
    func updatePhotoURL(_ url: URL, uid: String) async throws

    /// Patch user preference fields (gender, ageRange, slangLevel, goal, categories).
    func updatePreferences(_ prefs: UserPreferences, uid: String) async throws

    /// Compress and upload JPEG data to Firebase Storage; returns the public download URL.
    /// Callers should compress to ≤ 1 MB before passing data here.
    func uploadProfilePhoto(data: Data, uid: String) async throws -> URL

    /// Delete the Firestore document for the given UID. Called before `deleteAccount()`.
    func deleteProfile(uid: String) async throws
}

// MARK: - UserPreferences

/// A value type grouping user preference fields for a single Firestore patch.
public struct UserPreferences: Sendable {
    public var gender: String?
    public var ageRange: String?
    public var slangLevel: String?
    public var goal: String?
    public var categories: [String]?

    public init(
        gender: String? = nil,
        ageRange: String? = nil,
        slangLevel: String? = nil,
        goal: String? = nil,
        categories: [String]? = nil
    ) {
        self.gender     = gender
        self.ageRange   = ageRange
        self.slangLevel = slangLevel
        self.goal       = goal
        self.categories = categories
    }

    /// Converts to a Firestore-compatible dictionary, only including non-nil fields.
    public var firestoreData: [String: Any] {
        var data: [String: Any] = [:]
        if let gender     { data["gender"]     = gender }
        if let ageRange   { data["ageRange"]   = ageRange }
        if let slangLevel { data["slangLevel"] = slangLevel }
        if let goal       { data["goal"]       = goal }
        if let categories { data["categories"] = categories }
        return data
    }
}

// MARK: - UserProfileError

/// Typed errors from `UserProfileRepository`.
public enum UserProfileError: LocalizedError, Sendable {
    case notFound
    case saveFailed(String)
    case uploadFailed(String)
    case deleteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notFound:              return "Profile not found."
        case .saveFailed(let msg):   return "Could not save profile: \(msg)"
        case .uploadFailed(let msg): return "Could not upload photo: \(msg)"
        case .deleteFailed(let msg): return "Could not delete profile: \(msg)"
        }
    }
}
