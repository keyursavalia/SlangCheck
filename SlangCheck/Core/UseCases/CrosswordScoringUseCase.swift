// Core/UseCases/CrosswordScoringUseCase.swift
// SlangCheck
//
// Scoring logic for the daily crossword.
// Extends the base Aura Economy formula with a perfect-completion multiplier.
// No dependencies — safe to use from any layer or test target.

import Foundation

// MARK: - CrosswordConstants

/// Crossword-specific tuning constants. All values must be referenced by name.
public enum CrosswordConstants {

    /// Aura multiplier applied when the user completes the puzzle with zero reveals
    /// and 100% accuracy. Named constant per CLAUDE.md §2 (no magic numbers).
    public static let perfectCompletionMultiplier: Double = 1.5

    /// Points awarded per correct letter cell before penalties.
    public static let pointsPerCorrectCell: Int = 20

    /// Penalty subtracted per reveal (hint) used.
    public static let penaltyPerReveal: Int = 50

    /// Penalty subtracted per elapsed minute.
    public static let timePenaltyPerMinute: Int = 1

    /// The floor value — a crossword session can never yield a negative point award.
    public static let minimumScore: Int = 0

    /// Maximum number of cell-reveal hints available per puzzle session.
    public static let revealCreditCount: Int = 5

    /// Aura points deducted from the user's balance immediately when they use a reveal hint.
    /// Mirrors `penaltyPerReveal` so the real-time deduction matches the scoring penalty.
    public static let auraDeductionPerReveal: Int = 50
}

// MARK: - CrosswordScoringInput

/// Raw inputs required to compute an Aura Points score for one crossword session.
public struct CrosswordScoringInput: Equatable, Sendable {

    /// Number of letter cells the user filled in correctly.
    public let correctCells: Int

    /// Total number of letter cells in the puzzle.
    public let totalCells: Int

    /// Number of cells revealed using the hint feature.
    public let revealsUsed: Int

    /// Wall-clock duration from puzzle open to submission, in seconds.
    public let elapsedSeconds: TimeInterval

    public init(
        correctCells: Int,
        totalCells: Int,
        revealsUsed: Int,
        elapsedSeconds: TimeInterval
    ) {
        precondition(totalCells > 0,              "totalCells must be positive.")
        precondition(correctCells >= 0,           "correctCells must be non-negative.")
        precondition(correctCells <= totalCells,  "correctCells cannot exceed totalCells.")
        precondition(revealsUsed >= 0,            "revealsUsed must be non-negative.")
        precondition(elapsedSeconds >= 0,         "elapsedSeconds must be non-negative.")
        self.correctCells   = correctCells
        self.totalCells     = totalCells
        self.revealsUsed    = revealsUsed
        self.elapsedSeconds = elapsedSeconds
    }

    /// Elapsed time expressed in whole minutes (truncated).
    public var elapsedMinutes: Int { Int(elapsedSeconds / 60) }

    /// `true` if the user completed with zero reveals and 100% accuracy.
    public var isPerfect: Bool { revealsUsed == 0 && correctCells == totalCells }
}

// MARK: - CrosswordScoringUseCase

/// Computes the Aura Points earned for a completed crossword session.
///
/// **Formula:** `S = (C × 20 - R × 50 - T × 1) × M`
///
/// | Symbol | Meaning |
/// |--------|---------|
/// | C      | Correct cells |
/// | R      | Reveals used |
/// | T      | Elapsed time in whole minutes |
/// | M      | `CrosswordConstants.perfectCompletionMultiplier` (1.5) if perfect, else 1.0 |
///
/// The result is floored at `CrosswordConstants.minimumScore` (0).
public struct CrosswordScoringUseCase: Sendable {

    public init() {}

    // MARK: - Scoring

    /// Returns the Aura Points earned for the given crossword session inputs.
    public func score(for input: CrosswordScoringInput) -> Int {
        let base      = input.correctCells * CrosswordConstants.pointsPerCorrectCell
        let revealPen = input.revealsUsed  * CrosswordConstants.penaltyPerReveal
        let timePen   = input.elapsedMinutes * CrosswordConstants.timePenaltyPerMinute
        let raw       = base - revealPen - timePen
        let clamped   = Swift.max(raw, CrosswordConstants.minimumScore)
        let multiplier: Double = input.isPerfect ? CrosswordConstants.perfectCompletionMultiplier : 1.0
        return Int(Double(clamped) * multiplier)
    }

    /// Builds a `CrosswordResult` from a puzzle and session inputs,
    /// computing `auraPointsEarned` automatically.
    public func result(
        puzzleID: UUID,
        puzzleDate: Date,
        input: CrosswordScoringInput,
        completedAt: Date = Date()
    ) -> CrosswordResult {
        CrosswordResult(
            puzzleID: puzzleID,
            puzzleDate: puzzleDate,
            correctCells: input.correctCells,
            totalCells: input.totalCells,
            revealsUsed: input.revealsUsed,
            elapsedSeconds: input.elapsedSeconds,
            auraPointsEarned: score(for: input),
            isPerfect: input.isPerfect,
            completedAt: completedAt
        )
    }
}
