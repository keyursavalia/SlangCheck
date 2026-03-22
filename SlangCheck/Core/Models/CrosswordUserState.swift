// Core/Models/CrosswordUserState.swift
// SlangCheck
//
// A user's in-progress state for a single CrosswordPuzzle.
// Persisted locally between app sessions, keyed by puzzleID.
// Zero UIKit/SwiftUI/CoreData imports — platform-agnostic.

import Foundation

// MARK: - CrosswordUserState

/// The mutable, user-specific progress for a single daily crossword puzzle.
///
/// This struct is kept separate from `CrosswordPuzzle` so the immutable,
/// server-provided puzzle definition is never mutated by user input.
/// `CrosswordUserState` is keyed by `puzzleID` and discarded when a new
/// day's puzzle loads.
///
/// All mutation helpers return new values; the struct is treated as
/// copy-on-write from the ViewModel's perspective.
public struct CrosswordUserState: Identifiable, Sendable {

    // MARK: Properties

    /// Matches `CrosswordPuzzle.id`.
    public let puzzleID: UUID

    /// `Identifiable` conformance — equal to `puzzleID`.
    public var id: UUID { puzzleID }

    /// The user's letter entries: cell ID (`"row-col"`) → single uppercase letter.
    /// Empty cells are absent from this dictionary.
    public var entries: [String: String]

    /// Cell IDs the user has revealed using the hint feature.
    public var revealedCellIDs: Set<String>

    /// `true` once the user has submitted and the puzzle has been validated.
    public var isCompleted: Bool

    /// UTC timestamp when `isCompleted` was first set to `true`. `nil` if not yet completed.
    public var completedAt: Date?

    /// UTC timestamp of the most recent letter entry, reveal, or clear action.
    public var lastModifiedAt: Date

    /// Number of reveal-hint credits remaining for this puzzle session.
    /// Starts at `CrosswordConstants.revealCreditCount` (5) and decrements on each reveal.
    public var revealCreditsRemaining: Int

    // MARK: Initialization

    public init(
        puzzleID: UUID,
        entries: [String: String] = [:],
        revealedCellIDs: Set<String> = [],
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        lastModifiedAt: Date = Date(),
        revealCreditsRemaining: Int = CrosswordConstants.revealCreditCount
    ) {
        self.puzzleID               = puzzleID
        self.entries                = entries
        self.revealedCellIDs        = revealedCellIDs
        self.isCompleted            = isCompleted
        self.completedAt            = completedAt
        self.lastModifiedAt         = lastModifiedAt
        self.revealCreditsRemaining = revealCreditsRemaining
    }

    // MARK: Derived

    /// Number of letter cells the user has filled in (includes revealed cells).
    public var filledCount: Int { entries.count }

    /// `true` if the user revealed at least one cell using the hint feature.
    public var usedReveal: Bool { !revealedCellIDs.isEmpty }

    /// Number of cells revealed via hint.
    public var revealCount: Int { revealedCellIDs.count }

    // MARK: Mutation Helpers

    /// Returns a new state with the given letter entered in the given cell.
    ///
    /// - Parameters:
    ///   - letter: A single uppercase ASCII letter.
    ///   - cellID: The cell's `"row-col"` identifier.
    public func entering(_ letter: String, at cellID: String, now: Date = Date()) -> CrosswordUserState {
        var updated = self
        updated.entries[cellID]  = letter.uppercased()
        updated.lastModifiedAt   = now
        return updated
    }

    /// Returns a new state with the given cell cleared.
    public func clearing(_ cellID: String, now: Date = Date()) -> CrosswordUserState {
        var updated = self
        updated.entries.removeValue(forKey: cellID)
        updated.lastModifiedAt = now
        return updated
    }

    /// Returns a new state with the given cell marked as revealed and filled,
    /// and `revealCreditsRemaining` decremented by one (clamped at zero).
    public func revealing(_ cellID: String, letter: String, now: Date = Date()) -> CrosswordUserState {
        var updated = self
        updated.entries[cellID]          = letter.uppercased()
        updated.revealedCellIDs.insert(cellID)
        updated.revealCreditsRemaining   = max(revealCreditsRemaining - 1, 0)
        updated.lastModifiedAt           = now
        return updated
    }

    /// Returns a new state marked as completed.
    public func completing(now: Date = Date()) -> CrosswordUserState {
        var updated = self
        updated.isCompleted    = true
        updated.completedAt    = now
        updated.lastModifiedAt = now
        return updated
    }
}

// MARK: - Codable

/// Manual `Codable` conformance so that `revealCreditsRemaining` degrades gracefully
/// when loading persisted state written before that field was added (treats missing
/// key as `CrosswordConstants.revealCreditCount`).
extension CrosswordUserState: Codable {

    private enum CodingKeys: String, CodingKey {
        case puzzleID, entries, revealedCellIDs, isCompleted, completedAt, lastModifiedAt, revealCreditsRemaining
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        puzzleID               = try c.decode(UUID.self,             forKey: .puzzleID)
        entries                = try c.decode([String: String].self,  forKey: .entries)
        revealedCellIDs        = try c.decode(Set<String>.self,       forKey: .revealedCellIDs)
        isCompleted            = try c.decode(Bool.self,              forKey: .isCompleted)
        completedAt            = try c.decodeIfPresent(Date.self,     forKey: .completedAt)
        lastModifiedAt         = try c.decode(Date.self,              forKey: .lastModifiedAt)
        // Field added later — default to full credits if the key is absent in old data.
        revealCreditsRemaining = try c.decodeIfPresent(Int.self,      forKey: .revealCreditsRemaining)
            ?? CrosswordConstants.revealCreditCount
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(puzzleID,               forKey: .puzzleID)
        try c.encode(entries,                forKey: .entries)
        try c.encode(revealedCellIDs,        forKey: .revealedCellIDs)
        try c.encode(isCompleted,            forKey: .isCompleted)
        try c.encodeIfPresent(completedAt,   forKey: .completedAt)
        try c.encode(lastModifiedAt,         forKey: .lastModifiedAt)
        try c.encode(revealCreditsRemaining, forKey: .revealCreditsRemaining)
    }
}
