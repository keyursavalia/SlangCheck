// Core/Models/CrosswordClue.swift
// SlangCheck
//
// A single crossword clue (Across or Down entry).
// Zero UIKit/SwiftUI/CoreData imports — platform-agnostic.

import Foundation

// MARK: - ClueDirection

/// The reading direction of a crossword entry.
public enum ClueDirection: String, Codable, CaseIterable, Sendable {
    case across = "across"
    case down   = "down"
}

// MARK: - CrosswordClue

/// A single crossword entry: a numbered clue and the IDs of cells it covers.
///
/// `cellIDs` is ordered from the starting cell to the last cell of the entry
/// (left-to-right for `.across`, top-to-bottom for `.down`). This ordering
/// is used for cursor navigation — advancing the cursor moves to the next
/// cell ID in the list.
public struct CrosswordClue: Codable, Identifiable, Hashable, Sendable {

    // MARK: Properties

    /// Composite ID: `"<number>-<direction>"` (e.g., `"1-across"`, `"2-down"`).
    public let id: String

    /// The clue number displayed in the grid cell that begins this entry.
    public let number: Int

    /// The reading direction of this entry.
    public let direction: ClueDirection

    /// The clue text shown to the user below the grid.
    public let text: String

    /// Ordered cell IDs (`"row-col"`) from the first letter to the last.
    public let cellIDs: [String]

    // MARK: Initialization

    public init(number: Int, direction: ClueDirection, text: String, cellIDs: [String]) {
        precondition(!cellIDs.isEmpty, "CrosswordClue must cover at least one cell.")
        self.number    = number
        self.direction = direction
        self.text      = text
        self.cellIDs   = cellIDs
        self.id        = "\(number)-\(direction.rawValue)"
    }

    // MARK: Derived

    /// Number of letters in this entry.
    public var length: Int { cellIDs.count }
}
