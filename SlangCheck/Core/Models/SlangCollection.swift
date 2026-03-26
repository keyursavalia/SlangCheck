// Core/Models/SlangCollection.swift
// SlangCheck
//
// Value type representing a named user-curated collection of slang terms.
// Persisted to UserDefaults as part of a JSON-encoded [SlangCollection] array.

import Foundation

// MARK: - SlangCollection

/// A named collection of saved slang term IDs, created and managed by the user.
public struct SlangCollection: Codable, Identifiable, Hashable, Sendable {

    // MARK: Properties

    public let id: UUID

    /// User-visible name of the collection (e.g. "Want to Learn").
    public var name: String

    /// Ordered list of saved term IDs in this collection.
    public var termIDs: [UUID]

    /// True for the app-created default collection. Exactly one collection is the default.
    public var isDefault: Bool

    // MARK: Initializer

    public init(id: UUID = UUID(), name: String, termIDs: [UUID] = [], isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.termIDs = termIDs
        self.isDefault = isDefault
    }
}
