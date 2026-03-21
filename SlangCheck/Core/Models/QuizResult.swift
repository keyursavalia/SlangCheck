// Core/Models/QuizResult.swift
// SlangCheck
//
// The persisted outcome of a single scored quiz session.
// Zero UIKit/SwiftUI/CoreData imports — platform-agnostic.

import Foundation

// MARK: - QuizResult

/// The final, immutable record of a completed quiz session.
///
/// `QuizResult` is written to CoreData (local cache) and Firestore (remote)
/// at the end of each session. It carries the raw inputs used for scoring
/// so the score can be recomputed or audited without re-running the session.
public struct QuizResult: Codable, Identifiable, Equatable, Sendable {

    // MARK: Properties

    /// Stable UUID. Matches the `QuizSession.id` that produced this result.
    public let id: UUID

    /// Number of questions the user answered correctly.
    public let correctCount: Int

    /// Total number of questions in the session.
    public let totalCount: Int

    /// Number of hints the user consumed during the session.
    public let hintsUsed: Int

    /// Wall-clock seconds from the first question presented to the last answer submitted.
    public let elapsedSeconds: TimeInterval

    /// Aura Points awarded for this session, computed by `AuraScoringEngine`.
    public let auraPointsEarned: Int

    /// UTC timestamp when the last answer was submitted.
    public let completedAt: Date

    // MARK: Initialization

    public init(
        id: UUID,
        correctCount: Int,
        totalCount: Int,
        hintsUsed: Int,
        elapsedSeconds: TimeInterval,
        auraPointsEarned: Int,
        completedAt: Date = Date()
    ) {
        precondition(correctCount >= 0,           "correctCount must be non-negative.")
        precondition(totalCount > 0,              "totalCount must be positive.")
        precondition(correctCount <= totalCount,  "correctCount cannot exceed totalCount.")
        precondition(hintsUsed >= 0,              "hintsUsed must be non-negative.")
        precondition(elapsedSeconds >= 0,         "elapsedSeconds must be non-negative.")
        precondition(auraPointsEarned >= 0,       "auraPointsEarned must be non-negative.")
        self.id                = id
        self.correctCount      = correctCount
        self.totalCount        = totalCount
        self.hintsUsed         = hintsUsed
        self.elapsedSeconds    = elapsedSeconds
        self.auraPointsEarned  = auraPointsEarned
        self.completedAt       = completedAt
    }

    // MARK: Derived

    /// Fraction of questions answered correctly, in `[0.0, 1.0]`.
    public var accuracy: Double {
        Double(correctCount) / Double(totalCount)
    }

    /// Elapsed time as whole minutes (truncated), matching the `T` input in the scoring formula.
    public var elapsedMinutes: Int {
        Int(elapsedSeconds / 60)
    }

    /// `true` if the user answered every question correctly.
    public var isPerfect: Bool { correctCount == totalCount }

    /// `true` if the user used no hints at all.
    public var isHintFree: Bool { hintsUsed == 0 }
}
