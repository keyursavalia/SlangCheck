// SlangCheckTests/AuraScoringEngineTests.swift
// SlangCheck
//
// Exhaustive unit tests for AuraScoringEngine.
// Covers: zero hints, max hints, zero time, max time, clamping, breakdown,
// result() factory, and all boundary conditions for C, H, T.

import XCTest
@testable import SlangCheck

final class AuraScoringEngineTests: XCTestCase {

    private let engine = AuraScoringEngine()

    // MARK: - Helpers

    private func input(
        correct: Int = 1,
        total: Int = 10,
        hints: Int = 0,
        seconds: TimeInterval = 0
    ) -> ScoringInput {
        ScoringInput(correctCount: correct, totalCount: total, hintsUsed: hints, elapsedSeconds: seconds)
    }

    // MARK: - Zero Hints / Zero Time (baseline)

    func testBaselineZeroHintsZeroTime() {
        // S = (5 × 100) / (1 + 0) - (0 × 2) = 500
        let score = engine.score(for: input(correct: 5, hints: 0, seconds: 0))
        XCTAssertEqual(score, 500)
    }

    func testSingleCorrectNoHintsNoTime() {
        // S = (1 × 100) / 1 - 0 = 100
        let score = engine.score(for: input(correct: 1, hints: 0, seconds: 0))
        XCTAssertEqual(score, 100)
    }

    func testAllTenCorrectNoHintsNoTime() {
        // S = (10 × 100) / 1 = 1000
        let score = engine.score(for: input(correct: 10, total: 10, hints: 0, seconds: 0))
        XCTAssertEqual(score, 1_000)
    }

    func testZeroCorrectIsZero() {
        // S = 0 / 1 - T*2 → always ≤ 0, clamped to 0
        let score = engine.score(for: input(correct: 0, hints: 0, seconds: 0))
        XCTAssertEqual(score, 0)
    }

    func testZeroCorrectWithTimeIsClamped() {
        // S = 0 / 1 - 3*2 = -6 → clamped to 0
        let score = engine.score(for: input(correct: 0, hints: 0, seconds: 180))
        XCTAssertEqual(score, 0)
    }

    // MARK: - Hint Penalty

    func testOneHintHalvesBaseScore() {
        // S = (4 × 100) / (1 + 1) - 0 = 400 / 2 = 200
        let score = engine.score(for: input(correct: 4, hints: 1, seconds: 0))
        XCTAssertEqual(score, 200)
    }

    func testTwoHintsDividesByThree() {
        // S = (3 × 100) / (1 + 2) - 0 = 300 / 3 = 100
        let score = engine.score(for: input(correct: 3, hints: 2, seconds: 0))
        XCTAssertEqual(score, 100)
    }

    func testNineHintsDividesByTen() {
        // S = (10 × 100) / (1 + 9) - 0 = 1000 / 10 = 100
        let score = engine.score(for: input(correct: 10, total: 10, hints: 9, seconds: 0))
        XCTAssertEqual(score, 100)
    }

    func testHighHintCountTruncatesIntegerDivision() {
        // S = (1 × 100) / (1 + 6) = 100 / 7 = 14 (truncated, not 14.28...)
        let score = engine.score(for: input(correct: 1, hints: 6, seconds: 0))
        XCTAssertEqual(score, 14)
    }

    func testManyHintsWithZeroCorrectIsZero() {
        // S = 0 / (1 + 99) = 0
        let score = engine.score(for: input(correct: 0, hints: 99, seconds: 0))
        XCTAssertEqual(score, 0)
    }

    // MARK: - Time Penalty

    func testOneMinuteTimePenalty() {
        // S = (5 × 100) / 1 - (1 × 2) = 500 - 2 = 498
        let score = engine.score(for: input(correct: 5, hints: 0, seconds: 60))
        XCTAssertEqual(score, 498)
    }

    func testFiveMinuteTimePenalty() {
        // S = (3 × 100) / 1 - (5 × 2) = 300 - 10 = 290
        let score = engine.score(for: input(correct: 3, hints: 0, seconds: 300))
        XCTAssertEqual(score, 290)
    }

    func testSubMinuteElapsedCountsAsZeroMinutes() {
        // 59 seconds → T = 0 (truncated), no time penalty
        let score = engine.score(for: input(correct: 2, hints: 0, seconds: 59))
        XCTAssertEqual(score, 200)
    }

    func testExactlyOneMinuteBoundary() {
        // 60 seconds → T = 1
        let score60 = engine.score(for: input(correct: 2, hints: 0, seconds: 60))
        let score59 = engine.score(for: input(correct: 2, hints: 0, seconds: 59))
        XCTAssertEqual(score60, score59 - 2)
    }

    func testTimePenaltyExceedsBaseScoreClampToZero() {
        // S = (1 × 100) / 1 - (60 × 2) = 100 - 120 = -20 → clamped to 0
        let score = engine.score(for: input(correct: 1, hints: 0, seconds: 3_600)) // 60 minutes
        XCTAssertEqual(score, 0)
    }

    func testLargeElapsedTimeAlwaysClampToZero() {
        let score = engine.score(for: input(correct: 10, total: 10, hints: 0, seconds: 100_000))
        XCTAssertEqual(score, 0)
    }

    // MARK: - Combined Hint + Time Penalties

    func testHintAndTimePenaltyTogether() {
        // S = (4 × 100) / (1 + 1) - (2 × 2) = 200 - 4 = 196
        let score = engine.score(for: input(correct: 4, hints: 1, seconds: 120))
        XCTAssertEqual(score, 196)
    }

    func testHintAndTimePenaltyCombinedResultingInZero() {
        // S = (1 × 100) / (1 + 9) - (5 × 2) = 10 - 10 = 0
        let score = engine.score(for: input(correct: 1, hints: 9, seconds: 300))
        XCTAssertEqual(score, 0)
    }

    func testHintAndTimePenaltyCombinedResultingInNegativeClamped() {
        // S = (1 × 100) / (1 + 9) - (6 × 2) = 10 - 12 = -2 → clamped to 0
        let score = engine.score(for: input(correct: 1, hints: 9, seconds: 360))
        XCTAssertEqual(score, 0)
    }

    // MARK: - Score Minimum

    func testScoreIsNeverNegative() {
        // Sweep across a wide range of adversarial inputs.
        for hints in [0, 1, 5, 99] {
            for minutes in [0, 1, 10, 100, 1000] {
                let score = engine.score(for: input(correct: 0, hints: hints, seconds: TimeInterval(minutes * 60)))
                XCTAssertGreaterThanOrEqual(score, 0, "Score was negative for hints=\(hints) minutes=\(minutes)")
            }
        }
    }

    // MARK: - result() Factory

    func testResultFactoryMatchesDirectScore() {
        let sid   = UUID()
        let inp   = input(correct: 7, total: 10, hints: 2, seconds: 90)
        let result = engine.result(sessionID: sid, input: inp)
        XCTAssertEqual(result.auraPointsEarned, engine.score(for: inp))
        XCTAssertEqual(result.id, sid)
        XCTAssertEqual(result.correctCount, 7)
        XCTAssertEqual(result.totalCount, 10)
        XCTAssertEqual(result.hintsUsed, 2)
        XCTAssertEqual(result.elapsedSeconds, 90)
    }

    func testResultAccuracyComputed() {
        let result = engine.result(sessionID: UUID(), input: input(correct: 3, total: 10, hints: 0, seconds: 0))
        XCTAssertEqual(result.accuracy, 0.3, accuracy: 0.001)
    }

    func testResultIsPerfectWhenAllCorrect() {
        let result = engine.result(sessionID: UUID(), input: input(correct: 10, total: 10, hints: 0, seconds: 0))
        XCTAssertTrue(result.isPerfect)
    }

    func testResultIsNotPerfectWhenSomeMissed() {
        let result = engine.result(sessionID: UUID(), input: input(correct: 9, total: 10, hints: 0, seconds: 0))
        XCTAssertFalse(result.isPerfect)
    }

    func testResultIsHintFreeWhenNoHintsUsed() {
        let result = engine.result(sessionID: UUID(), input: input(correct: 5, hints: 0, seconds: 0))
        XCTAssertTrue(result.isHintFree)
    }

    // MARK: - Breakdown

    func testBreakdownBasePoints() {
        let bd = engine.breakdown(for: input(correct: 5, hints: 0, seconds: 0))
        XCTAssertEqual(bd.basePoints, 500)
    }

    func testBreakdownAfterHintPenalty() {
        // (4 × 100) / (1 + 1) = 200
        let bd = engine.breakdown(for: input(correct: 4, hints: 1, seconds: 0))
        XCTAssertEqual(bd.afterHintPenalty, 200)
    }

    func testBreakdownTimePenalty() {
        // T = 3 minutes → penalty = 6
        let bd = engine.breakdown(for: input(correct: 5, hints: 0, seconds: 180))
        XCTAssertEqual(bd.timePenalty, 6)
    }

    func testBreakdownFinalScoreMatchesScore() {
        let inp = input(correct: 6, hints: 2, seconds: 120)
        let bd  = engine.breakdown(for: inp)
        XCTAssertEqual(bd.finalScore, engine.score(for: inp))
    }

    func testBreakdownWasClampedWhenNegative() {
        // (1 × 100) / 1 - (60 × 2) = 100 - 120 = -20 → clamped
        let bd = engine.breakdown(for: input(correct: 1, hints: 0, seconds: 3_600))
        XCTAssertTrue(bd.wasClamped)
        XCTAssertEqual(bd.finalScore, 0)
    }

    func testBreakdownWasNotClampedWhenPositive() {
        let bd = engine.breakdown(for: input(correct: 10, total: 10, hints: 0, seconds: 0))
        XCTAssertFalse(bd.wasClamped)
        XCTAssertEqual(bd.finalScore, 1_000)
    }

    // MARK: - Constants

    func testPointsPerCorrectAnswerConstant() {
        XCTAssertEqual(AuraScoringEngine.pointsPerCorrectAnswer, 100)
    }

    func testTimePenaltyPerMinuteConstant() {
        XCTAssertEqual(AuraScoringEngine.timePenaltyPerMinute, 2)
    }

    func testMinimumScoreConstant() {
        XCTAssertEqual(AuraScoringEngine.minimumScore, 0)
    }
}
