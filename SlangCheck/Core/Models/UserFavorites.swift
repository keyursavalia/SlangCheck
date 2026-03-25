// Core/Models/UserFavorites.swift
// SlangCheck
//
// Model representing the user's liked (favorited) slang terms.
// Immutable value type. Zero UIKit/SwiftUI imports.

import Foundation

// MARK: - UserFavorites

/// The user's collection of liked/favorited slang terms.
/// Persisted to UserDefaults as a JSON-encoded blob.
public struct UserFavorites: Codable, Sendable {

    // MARK: Properties

    /// The set of liked term IDs for O(1) membership tests.
    public private(set) var likedTermIDs: Set<UUID>

    /// Number of liked terms.
    public var count: Int { likedTermIDs.count }

    // MARK: Initializer

    public init(likedTermIDs: Set<UUID> = []) {
        self.likedTermIDs = likedTermIDs
    }

    // MARK: Mutations

    /// Returns a new `UserFavorites` with the given term added.
    public func adding(termID: UUID) -> UserFavorites {
        var ids = likedTermIDs
        ids.insert(termID)
        return UserFavorites(likedTermIDs: ids)
    }

    /// Returns a new `UserFavorites` with the given term removed.
    public func removing(termID: UUID) -> UserFavorites {
        var ids = likedTermIDs
        ids.remove(termID)
        return UserFavorites(likedTermIDs: ids)
    }

    /// Returns true if the given term is liked.
    public func contains(termID: UUID) -> Bool {
        likedTermIDs.contains(termID)
    }
}
