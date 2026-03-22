// Core/Models/CrosswordCell.swift
// SlangCheck
//
// Represents a single cell in a crossword puzzle grid.
// Zero UIKit/SwiftUI/CoreData imports — platform-agnostic.

import Foundation

// MARK: - CrosswordCell

/// A single cell in a crossword puzzle grid.
///
/// Black cells (`.black`) are non-interactive barriers. Letter cells (`.letter`)
/// are tappable and accept keyboard input. The `clueNumber` field, when non-nil,
/// indicates this cell is the starting cell of an Across or Down entry and
/// renders the clue number label in the top-left corner.
public struct CrosswordCell: Codable, Identifiable, Hashable, Sendable {

    // MARK: - CellKind

    /// Whether the cell is a navigable letter square or a black barrier.
    public enum CellKind: String, Codable, Sendable {
        /// A non-interactive black square.
        case black
        /// An interactive square that accepts exactly one letter.
        case letter
    }

    // MARK: Properties

    /// Stable string ID in `"row-col"` format (e.g., `"0-2"`).
    public let id: String

    /// Zero-based row index from the top of the grid.
    public let row: Int

    /// Zero-based column index from the left of the grid.
    public let col: Int

    /// Whether this cell is a letter square or a black barrier.
    public let kind: CellKind

    /// Clue number displayed in this cell's top-left corner, when this cell
    /// begins an Across or Down entry. `nil` for all non-starting cells and
    /// all black cells.
    public let clueNumber: Int?

    // MARK: Initialization

    public init(row: Int, col: Int, kind: CellKind, clueNumber: Int? = nil) {
        self.row        = row
        self.col        = col
        self.id         = "\(row)-\(col)"
        self.kind       = kind
        self.clueNumber = clueNumber
    }

    // MARK: Derived

    /// `true` if this cell is a black barrier.
    public var isBlack: Bool { kind == .black }

    /// `true` if this cell is a letter square that accepts input.
    public var isLetter: Bool { kind == .letter }
}
