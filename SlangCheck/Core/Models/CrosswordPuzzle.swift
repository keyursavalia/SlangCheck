// Core/Models/CrosswordPuzzle.swift
// SlangCheck
//
// The daily crossword puzzle, including the AES-GCM encrypted answer key.
// The answer key plaintext is never present on the client before revealAt.
// Zero UIKit/SwiftUI/CoreData imports — platform-agnostic.

import Foundation

// MARK: - CrosswordPuzzle

/// A complete daily crossword puzzle with an encrypted answer key.
///
/// ## Answer key security
/// The answer key is a `[String: String]` dictionary mapping cell IDs
/// (`"row-col"`) to their correct uppercase letter. Before distribution,
/// this dictionary is JSON-encoded and AES-GCM encrypted. The ciphertext
/// is stored in `encryptedAnswerKey` and the 12-byte nonce in `encryptionNonce`.
///
/// The symmetric decryption key is **never** bundled with the puzzle. It is
/// issued by a server-side Cloud Function at or after `revealAt`. The client
/// must call the key endpoint — it must not attempt to derive or brute-force
/// the key in advance. (Q-005 decision: encrypted payload + server-issued key.)
///
/// ## Grid layout
/// `cells` contains every cell in row-major order (row 0 col 0 → row N col M).
/// Black cells are included in the array; the grid is fully rectangular.
public struct CrosswordPuzzle: Codable, Identifiable, Sendable {

    // MARK: Properties

    /// Stable UUID, sourced from the Firestore document ID.
    public let id: UUID

    /// The calendar date this puzzle is valid for.
    /// Stored as a `Date` set to midnight UTC of the puzzle day.
    public let date: Date

    /// Number of rows in the grid.
    public let rows: Int

    /// Number of columns in the grid.
    public let cols: Int

    /// All cells in row-major order (row 0 col 0, row 0 col 1, …, row N col M).
    public let cells: [CrosswordCell]

    /// All clues (Across and Down) in ascending clue-number order.
    public let clues: [CrosswordClue]

    /// AES-GCM ciphertext + 16-byte authentication tag of the JSON-encoded answer key.
    /// Plaintext format (after decryption): `[String: String]` — cell ID → uppercase letter.
    public let encryptedAnswerKey: Data

    /// 12-byte AES-GCM nonce used during encryption. Must be unique per puzzle.
    public let encryptionNonce: Data

    /// UTC timestamp after which the server will release the decryption key.
    /// The client must not decrypt or display answers before this time.
    public let revealAt: Date

    // MARK: Initialization

    public init(
        id: UUID = UUID(),
        date: Date,
        rows: Int,
        cols: Int,
        cells: [CrosswordCell],
        clues: [CrosswordClue],
        encryptedAnswerKey: Data,
        encryptionNonce: Data,
        revealAt: Date
    ) {
        precondition(rows > 0 && cols > 0,    "Grid dimensions must be positive.")
        precondition(cells.count == rows * cols, "Cell count must equal rows × cols.")
        self.id                 = id
        self.date               = date
        self.rows               = rows
        self.cols               = cols
        self.cells              = cells
        self.clues              = clues
        self.encryptedAnswerKey = encryptedAnswerKey
        self.encryptionNonce    = encryptionNonce
        self.revealAt           = revealAt
    }

    // MARK: Derived

    /// `true` when the server's `revealAt` timestamp has passed locally.
    public var isRevealable: Bool { Date() >= revealAt }

    /// Returns the cell at the given row and column, or `nil` if out of bounds.
    public func cell(row: Int, col: Int) -> CrosswordCell? {
        guard row >= 0, row < rows, col >= 0, col < cols else { return nil }
        return cells[row * cols + col]
    }

    /// All Across clues, sorted by clue number ascending.
    public var acrossClues: [CrosswordClue] {
        clues.filter { $0.direction == .across }.sorted { $0.number < $1.number }
    }

    /// All Down clues, sorted by clue number ascending.
    public var downClues: [CrosswordClue] {
        clues.filter { $0.direction == .down }.sorted { $0.number < $1.number }
    }

    /// All letter cells (non-black), in row-major order.
    public var letterCells: [CrosswordCell] {
        cells.filter(\.isLetter)
    }

    /// Total number of letter cells in the puzzle.
    public var totalLetterCount: Int {
        cells.filter(\.isLetter).count
    }
}
