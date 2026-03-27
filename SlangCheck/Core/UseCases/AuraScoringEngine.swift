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

    /// Wall-clock duration of the session in seconds (stored for records; not used in score).
    public let elapsedSeconds: TimeInterval

    /// Questions that timed out without a user answer.
    public let unansweredCount: Int

    /// Bonus points accumulated from correct answers on premium-category questions.
    /// Computed by `QuizViewModel` using `AuraScoringEngine.categoryBonus(for:)`.
    public let categoryBonusPoints: Int

    public init(
        correctCount: Int,
        totalCount: Int,
        hintsUsed: Int,
        elapsedSeconds: TimeInterval,
        unansweredCount: Int = 0,
        categoryBonusPoints: Int = 0
    ) {
        precondition(correctCount >= 0,          "correctCount must be non-negative.")
        precondition(totalCount > 0,             "totalCount must be positive.")
        precondition(correctCount <= totalCount, "correctCount cannot exceed totalCount.")
        precondition(hintsUsed >= 0,             "hintsUsed must be non-negative.")
        precondition(elapsedSeconds >= 0,        "elapsedSeconds must be non-negative.")
        precondition(unansweredCount >= 0,       "unansweredCount must be non-negative.")
        precondition(categoryBonusPoints >= 0,   "categoryBonusPoints must be non-negative.")
        self.correctCount        = correctCount
        self.totalCount          = totalCount
        self.hintsUsed           = hintsUsed
        self.elapsedSeconds      = elapsedSeconds
        self.unansweredCount     = unansweredCount
        self.categoryBonusPoints = categoryBonusPoints
    }

    /// Questions answered incorrectly (not timed out).
    public var wrongCount: Int { max(0, totalCount - correctCount - unansweredCount) }
}

// MARK: - AuraScoringEngine

/// Computes the Aura Points earned for a single quiz session.
///
/// **Formula:** `S = max(0, (C × 100 + B) / (1 + H) - (W × 10) - (U × 25))`
///
/// | Symbol | Meaning |
/// |--------|---------|
/// | C      | Correct answers |
/// | B      | Category bonus points (premium categories award extra per correct answer) |
/// | H      | Hints used |
/// | W      | Wrong answers (answered, but incorrectly) |
/// | U      | Unanswered questions (timed out) |
///
/// Category bonus per correct answer (applied before hint division):
/// - `brainrot`, `emerging2026` → +20 pts  (rarest / hardest vocab)
/// - `gamingInternet`, `emoji` → +10 pts  (niche but learnable)
/// - all other categories → +0 pts
///
/// The result is floored at `minimumScore` (0) — a session can never subtract points.
///
/// `AuraScoringEngine` is a stateless `struct`. Instantiate once and reuse freely;
/// all methods are pure functions with no side effects.
public struct AuraScoringEngine: Sendable {

    // MARK: - Formula Constants

    /// Points awarded per correct answer before hint penalty. (`C` multiplier)
    public static let pointsPerCorrectAnswer: Int = 100

    /// Penalty per wrong answer (answered incorrectly, not timed out).
    public static let wrongAnswerPenalty: Int = 10

    /// Penalty per unanswered question (timed out).
    public static let unansweredPenalty: Int = 25

    /// Category bonus for premium brainrot / emerging vocabulary.
    public static let categoryBonusHigh: Int = 20

    /// Category bonus for niche gaming / emoji vocabulary.
    public static let categoryBonusMedium: Int = 10

    /// The floor value — a session can never yield a negative point award.
    public static let minimumScore: Int = 0

    // MARK: - Initialization

    public init() {}

    // MARK: - Category Bonus

    /// Returns the bonus points awarded when a question of the given category is answered correctly.
    public static func categoryBonus(for category: SlangCategory) -> Int {
        switch category {
        case .brainrot, .emerging2026:     return categoryBonusHigh
        case .gamingInternet, .emoji: return categoryBonusMedium
        default:                           return 0
        }
    }

    // MARK: - Scoring

    /// Returns the Aura Points earned for the given session inputs.
    ///
    /// Applies `S = max(0, (C × 100 + B) / (1 + H) - (W × 10) - (U × 25))`.
    public func score(for input: ScoringInput) -> Int {
        let c = input.correctCount
        let b = input.categoryBonusPoints
        let h = input.hintsUsed
        let w = input.wrongCount
        let u = input.unansweredCount

        // Integer arithmetic: base + bonus are summed before hint division to reward premium
        // category mastery even when hints are used.
        let afterHints = (c * Self.pointsPerCorrectAnswer + b) / (1 + h)
        let penalties  = (w * Self.wrongAnswerPenalty) + (u * Self.unansweredPenalty)
        let raw        = afterHints - penalties
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
            unansweredCount: input.unansweredCount,
            categoryBonusPoints: input.categoryBonusPoints,
            completedAt: completedAt
        )
    }

    // MARK: - Breakdown

    /// Returns a human-readable breakdown of how the score was computed.
    /// Intended for the `QuizResultView` summary panel.
    public func breakdown(for input: ScoringInput) -> ScoringBreakdown {
        let c = input.correctCount
        let b = input.categoryBonusPoints
        let h = input.hintsUsed
        let w = input.wrongCount
        let u = input.unansweredCount

        let basePoints          = c * Self.pointsPerCorrectAnswer
        let afterHints          = (basePoints + b) / (1 + h)
        let wrongPenalty        = w * Self.wrongAnswerPenalty
        let unansweredPenalty   = u * Self.unansweredPenalty
        let raw                 = afterHints - wrongPenalty - unansweredPenalty
        let finalScore          = Swift.max(raw, Self.minimumScore)

        return ScoringBreakdown(
            basePoints:           basePoints,
            categoryBonus:        b,
            afterHintPenalty:     afterHints,
            wrongAnswerPenalty:   wrongPenalty,
            unansweredPenalty:    unansweredPenalty,
            finalScore:           finalScore,
            wasClamped:           raw < Self.minimumScore
        )
    }
}

// MARK: - ScoringBreakdown

/// An itemised view of how a final score was derived.
/// Consumed by the `QuizResultView` to show the user what each component contributed.
public struct ScoringBreakdown: Equatable, Sendable {

    /// Raw points before any penalties: `C × 100`.
    public let basePoints: Int

    /// Bonus points from premium-category correct answers.
    public let categoryBonus: Int

    /// Points remaining after the hint penalty: `(basePoints + categoryBonus) / (1 + H)`.
    public let afterHintPenalty: Int

    /// Points deducted for incorrect answers: `W × 10`.
    public let wrongAnswerPenalty: Int

    /// Points deducted for timed-out questions: `U × 25`.
    public let unansweredPenalty: Int

    /// The final awarded score (never below 0).
    public let finalScore: Int

    /// `true` when the raw result was negative and was clamped to zero.
    public let wasClamped: Bool
}
