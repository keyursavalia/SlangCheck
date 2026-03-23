// Core/Models/UserProfile.swift
// SlangCheck
//
// Represents an authenticated user's profile stored in Firestore at `users/{uid}`.
// username is auto-generated at account creation and is immutable.
// displayName is user-editable. Both are public to support future leaderboard reads.

import Foundation

// MARK: - UserProfile

/// An authenticated user's profile.
///
/// - `id`: Firebase Auth UID — the stable, immutable account identifier.
/// - `username`: Auto-generated immutable handle, e.g. `user_a3f7b2c1`. Never changes post-creation.
/// - `displayName`: User-editable name shown throughout the UI.
/// - `photoURL`: Optional URL to the user's JPEG in Firebase Storage (`profile_photos/{uid}`).
/// - `auraPoints`: Cumulative Aura Points synced from the Aura Economy system.
public struct UserProfile: Identifiable, Hashable, Sendable, Codable {

    /// Firebase Auth UID.
    public let id: String

    /// Immutable handle auto-generated from the UID on first sign-in.
    public let username: String

    /// User-editable display name.
    public var displayName: String

    /// Email address. Stored on the profile but hidden from other users' views.
    public let email: String

    /// Public download URL of the user's profile photo. `nil` until they upload one.
    public var photoURL: URL?

    /// Cumulative Aura Points. Written by the Aura Economy sync pipeline.
    public var auraPoints: Int

    /// UTC timestamp of account creation.
    public let createdAt: Date

    public init(
        id: String,
        username: String,
        displayName: String,
        email: String,
        photoURL: URL? = nil,
        auraPoints: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id          = id
        self.username    = username
        self.displayName = displayName
        self.email       = email
        self.photoURL    = photoURL
        self.auraPoints  = auraPoints
        self.createdAt   = createdAt
    }

    // MARK: - Username Generation

    /// Derives the immutable username from a Firebase UID.
    ///
    /// Format: `user_` + the first 8 lowercase hex characters of the UID (hyphens stripped).
    /// Example: UID `3F7B2C1A-…` → `user_3f7b2c1a`.
    public static func generateUsername(from uid: String) -> String {
        let clean  = uid.replacingOccurrences(of: "-", with: "")
        let prefix = String(clean.prefix(8)).lowercased()
        return "user_\(prefix)"
    }
}
