// Core/Models/CrosswordResult.swift
// SlangCheck
//
// The persisted, scored outcome of a completed daily crossword session.
// Zero UIKit/SwiftUI/CoreData imports — platform-agnostic.

import Foundation

// MARK: - CrosswordResult

/// The final, immutable record of a completed daily crossword puzzle.
///
/// `CrosswordResult` is written to local storage after the user submits
/// the puzzle and optionally synced to Firestore when connectivity is
/// available. The perfect-completion Aura multiplier is applied during
/// scoring and reflected in `auraPointsEarned`.
public struct CrosswordResult: Codable, Identifiable, Equatable, Sendable {

    // MARK: Properties

    /// Stable UUID for this result. Unique per user per puzzle date.
    public let id: UUID

    /// The `CrosswordPuzzle.id` this result corresponds to.
    public let puzzleID: UUID

    /// The calendar date of the puzzle (mirrors `CrosswordPuzzle.date`).
    public let puzzleDate: Date

    /// Number of letter cells the user filled in correctly before submission.
    public let correctCells: Int

    /// Total number of letter cells in the puzzle.
    public let totalCells: Int

    /// Number of cells the user revealed using the hint feature.
    public let revealsUsed: Int

    /// Wall-clock seconds from when the puzzle was first opened to submission.
    public let elapsedSeconds: TimeInterval

    /// Aura Points awarded, as computed by `CrosswordScoringUseCase`.
    /// Includes the `CrosswordConstants.perfectCompletionMultiplier` when applicable.
    public let auraPointsEarned: Int

    /// `true` if the user completed the puzzle with zero reveals and 100% accuracy.
    public let isPerfect: Bool

    /// UTC timestamp when the user submitted the puzzle.
    public let completedAt: Date

    // MARK: Initialization

    public init(
        id: UUID = UUID(),
        puzzleID: UUID,
        puzzleDate: Date,
        correctCells: Int,
        totalCells: Int,
        revealsUsed: Int,
        elapsedSeconds: TimeInterval,
        auraPointsEarned: Int,
        isPerfect: Bool,
        completedAt: Date = Date()
    ) {
        precondition(totalCells > 0,              "totalCells must be positive.")
        precondition(correctCells >= 0,           "correctCells must be non-negative.")
        precondition(correctCells <= totalCells,  "correctCells cannot exceed totalCells.")
        precondition(revealsUsed >= 0,            "revealsUsed must be non-negative.")
        precondition(elapsedSeconds >= 0,         "elapsedSeconds must be non-negative.")
        precondition(auraPointsEarned >= 0,       "auraPointsEarned must be non-negative.")
        self.id               = id
        self.puzzleID         = puzzleID
        self.puzzleDate       = puzzleDate
        self.correctCells     = correctCells
        self.totalCells       = totalCells
        self.revealsUsed      = revealsUsed
        self.elapsedSeconds   = elapsedSeconds
        self.auraPointsEarned = auraPointsEarned
        self.isPerfect        = isPerfect
        self.completedAt      = completedAt
    }

    // MARK: Derived

    /// Fraction of cells answered correctly, in `[0.0, 1.0]`.
    public var accuracy: Double {
        Double(correctCells) / Double(totalCells)
    }

    /// Elapsed time as whole minutes (truncated), used in the scoring formula.
    public var elapsedMinutes: Int {
        Int(elapsedSeconds / 60)
    }
}
