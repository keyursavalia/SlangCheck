// Core/UseCases/AuraScoringEngine.swift
// SlangCheck
//
// Pure scoring logic for the Aura Economy.
// No dependencies — safe to use from any layer or test target.

import Foundation

// MARK: - ScoringInput

/// The raw inputs required to compute an Aura Points score for one quiz session.
public struct ScoringInput: Equatable, Sendable {

    /// Number of questions answered correctly.
    public let correctCount: Int

    /// Total number of questions in the session.
    public let totalCount: Int

    /// Number of hints consumed during the session.
    public let hintsUsed: Int

    /// Wall-clock duration of the session in seconds.
    public let elapsedSeconds: TimeInterval

    public init(correctCount: Int, totalCount: Int, hintsUsed: Int, elapsedSeconds: TimeInterval) {
        precondition(correctCount >= 0,          "correctCount must be non-negative.")
        precondition(totalCount > 0,             "totalCount must be positive.")
        precondition(correctCount <= totalCount, "correctCount cannot exceed totalCount.")
        precondition(hintsUsed >= 0,             "hintsUsed must be non-negative.")
        precondition(elapsedSeconds >= 0,        "elapsedSeconds must be non-negative.")
        self.correctCount   = correctCount
        self.totalCount     = totalCount
        self.hintsUsed      = hintsUsed
        self.elapsedSeconds = elapsedSeconds
    }

    /// Elapsed time expressed in whole minutes (truncated), matching the `T` term in the formula.
    public var elapsedMinutes: Int { Int(elapsedSeconds / 60) }
}

// MARK: - AuraScoringEngine

/// Computes the Aura Points earned for a single quiz session.
///
/// **Formula:** `S = (C × 100) / (1 + H) - (T × 2)`
///
/// | Symbol | Meaning |
/// |--------|---------|
/// | C      | Correct answers |
/// | H      | Hints used |
/// | T      | Elapsed time in whole minutes |
///
/// The result is floored at `minimumScore` (0) — a session can never subtract points.
///
/// `AuraScoringEngine` is a stateless `struct`. Instantiate once and reuse freely;
/// all methods are pure functions with no side effects.
public struct AuraScoringEngine: Sendable {

    // MARK: - Formula Constants

    /// Points awarded per correct answer before hint and time penalties. (`C` multiplier = 100)
    public static let pointsPerCorrectAnswer: Int = 100

    /// Penalty subtracted per elapsed minute. (`T` coefficient = 2)
    public static let timePenaltyPerMinute: Int = 2

    /// The floor value — a session can never yield a negative point award.
    public static let minimumScore: Int = 0

    // MARK: - Initialization

    public init() {}

    // MARK: - Scoring

    /// Returns the Aura Points earned for the given session inputs.
    ///
    /// Applies `S = (C × 100) / (1 + H) - (T × 2)`, then clamps to `minimumScore`.
    public func score(for input: ScoringInput) -> Int {
        let c = input.correctCount
        let h = input.hintsUsed
        let t = input.elapsedMinutes

        // Integer arithmetic: divides first to match the formula's intended precedence.
        // (C × 100) uses integer multiply; then we divide by (1 + H); then subtract time penalty.
        // Division is integer (truncated toward zero), which is appropriate for a point award.
        let raw = (c * Self.pointsPerCorrectAnswer) / (1 + h) - (t * Self.timePenaltyPerMinute)
        return Swift.max(raw, Self.minimumScore)
    }

    /// Builds a `QuizResult` from a session ID and scoring inputs, computing `auraPointsEarned`
    /// automatically via `score(for:)`.
    ///
    /// Use this as the single call-site for finalising a session so the score and the result
    /// record are always consistent.
    public func result(
        sessionID: UUID,
        input: ScoringInput,
        completedAt: Date = Date()
    ) -> QuizResult {
        QuizResult(
            id: sessionID,
            correctCount: input.correctCount,
            totalCount: input.totalCount,
            hintsUsed: input.hintsUsed,
            elapsedSeconds: input.elapsedSeconds,
            auraPointsEarned: score(for: input),
            completedAt: completedAt
        )
    }

    // MARK: - Breakdown

    /// Returns a human-readable breakdown of how the score was computed.
    /// Intended for the `QuizResultView` summary panel.
    public func breakdown(for input: ScoringInput) -> ScoringBreakdown {
        let c = input.correctCount
        let h = input.hintsUsed
        let t = input.elapsedMinutes

        let basePoints    = c * Self.pointsPerCorrectAnswer
        let afterHints    = basePoints / (1 + h)
        let timePenalty   = t * Self.timePenaltyPerMinute
        let finalScore    = Swift.max(afterHints - timePenalty, Self.minimumScore)
        let wasClamped    = (afterHints - timePenalty) < Self.minimumScore

        return ScoringBreakdown(
            basePoints: basePoints,
            afterHintPenalty: afterHints,
            timePenalty: timePenalty,
            finalScore: finalScore,
            wasClamped: wasClamped
        )
    }
}

// MARK: - ScoringBreakdown

/// An itemised view of how a final score was derived.
/// Consumed by the `QuizResultView` to show the user what each component contributed.
public struct ScoringBreakdown: Equatable, Sendable {

    /// Raw points before any penalties: `C × 100`.
    public let basePoints: Int

    /// Points remaining after the hint penalty: `basePoints / (1 + H)`.
    public let afterHintPenalty: Int

    /// Points deducted for elapsed time: `T × 2`.
    public let timePenalty: Int

    /// The final awarded score (never below 0).
    public let finalScore: Int

    /// `true` when the raw result was negative and was clamped to zero.
    public let wasClamped: Bool
}
