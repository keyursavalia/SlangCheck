// SlangCheckTests/CrosswordScoringUseCaseTests.swift
// SlangCheck
//
// Unit tests for CrosswordScoringUseCase: base scoring, multiplier boundary,
// reveal/time penalties, clamping, and the perfect-completion Aura multiplier.

import XCTest
@testable import SlangCheck

// MARK: - CrosswordScoringUseCaseTests

final class CrosswordScoringUseCaseTests: XCTestCase {

    private let useCase = CrosswordScoringUseCase()

    // MARK: - Formula Constant Verification

    func testPerfectCompletionMultiplierIs1Point5() {
        XCTAssertEqual(CrosswordConstants.perfectCompletionMultiplier, 1.5, accuracy: 0.001)
    }

    func testPointsPerCorrectCellIs20() {
        XCTAssertEqual(CrosswordConstants.pointsPerCorrectCell, 20)
    }

    func testPenaltyPerRevealIs50() {
        XCTAssertEqual(CrosswordConstants.penaltyPerReveal, 50)
    }

    func testTimePenaltyPerMinuteIs1() {
        XCTAssertEqual(CrosswordConstants.timePenaltyPerMinute, 1)
    }

    func testMinimumScoreIsZero() {
        XCTAssertEqual(CrosswordConstants.minimumScore, 0)
    }

    // MARK: - Perfect Score (no reveals, no time)

    func testPerfectScoreNoRevealsNoTime() {
        let input = CrosswordScoringInput(
            correctCells:   20,
            totalCells:     20,
            revealsUsed:    0,
            elapsedSeconds: 0
        )
        // base = 20 × 20 = 400, no penalties, × 1.5 = 600
        XCTAssertEqual(useCase.score(for: input), 600)
    }

    // MARK: - No Multiplier (imperfect)

    func testImperfectScoreNoMultiplier() {
        let input = CrosswordScoringInput(
            correctCells:   18,
            totalCells:     20,
            revealsUsed:    0,
            elapsedSeconds: 0
        )
        // base = 18 × 20 = 360, isPerfect = false → × 1.0 = 360
        XCTAssertEqual(useCase.score(for: input), 360)
    }

    func testRevealedCellDisablesPerfectMultiplier() {
        let input = CrosswordScoringInput(
            correctCells:   20,
            totalCells:     20,
            revealsUsed:    1,
            elapsedSeconds: 0
        )
        // isPerfect = false (reveals > 0) → no multiplier
        // base = 400 - 50 = 350 × 1.0 = 350
        XCTAssertEqual(useCase.score(for: input), 350)
    }

    // MARK: - Reveal Penalty

    func testRevealPenaltyReducesScore() {
        let input = CrosswordScoringInput(
            correctCells:   10,
            totalCells:     20,
            revealsUsed:    2,
            elapsedSeconds: 0
        )
        // base = 10 × 20 = 200; reveal penalty = 2 × 50 = 100; net = 100
        XCTAssertEqual(useCase.score(for: input), 100)
    }

    func testMultipleRevealsPenaltyAccumulates() {
        let input = CrosswordScoringInput(
            correctCells:   5,
            totalCells:     10,
            revealsUsed:    3,
            elapsedSeconds: 0
        )
        // base = 5 × 20 = 100; reveal penalty = 3 × 50 = 150; net = -50 → clamped to 0
        XCTAssertEqual(useCase.score(for: input), 0)
    }

    // MARK: - Time Penalty

    func testTimePenaltyReducesScore() {
        let input = CrosswordScoringInput(
            correctCells:   10,
            totalCells:     20,
            revealsUsed:    0,
            elapsedSeconds: 5 * 60   // 5 minutes
        )
        // base = 10 × 20 = 200; time penalty = 5 × 1 = 5; net = 195
        XCTAssertEqual(useCase.score(for: input), 195)
    }

    func testElapsedSecondsTruncatedToMinutes() {
        let input = CrosswordScoringInput(
            correctCells:   10,
            totalCells:     20,
            revealsUsed:    0,
            elapsedSeconds: 90   // 1 minute 30 seconds → 1 whole minute
        )
        // time penalty = 1 × 1 = 1; net = 200 - 1 = 199
        XCTAssertEqual(useCase.score(for: input), 199)
    }

    // MARK: - Floor Clamping

    func testScoreNeverGoesNegative() {
        let input = CrosswordScoringInput(
            correctCells:   0,
            totalCells:     20,
            revealsUsed:    10,
            elapsedSeconds: 3600
        )
        // base = 0; heavy penalties → clamped to 0
        XCTAssertGreaterThanOrEqual(useCase.score(for: input), 0)
    }

    // MARK: - isPerfect Computed Property

    func testIsPerfectTrueWhenAllCorrectAndNoReveals() {
        let input = CrosswordScoringInput(
            correctCells: 20, totalCells: 20, revealsUsed: 0, elapsedSeconds: 0
        )
        XCTAssertTrue(input.isPerfect)
    }

    func testIsPerfectFalseWhenNotAllCorrect() {
        let input = CrosswordScoringInput(
            correctCells: 19, totalCells: 20, revealsUsed: 0, elapsedSeconds: 0
        )
        XCTAssertFalse(input.isPerfect)
    }

    func testIsPerfectFalseWhenRevealsUsed() {
        let input = CrosswordScoringInput(
            correctCells: 20, totalCells: 20, revealsUsed: 1, elapsedSeconds: 0
        )
        XCTAssertFalse(input.isPerfect)
    }

    // MARK: - Result Builder

    func testResultBuilderSetsAuraPointsEarned() {
        let input = CrosswordScoringInput(
            correctCells:   20,
            totalCells:     20,
            revealsUsed:    0,
            elapsedSeconds: 0
        )
        let puzzleID   = UUID()
        let puzzleDate = Date()
        let result     = useCase.result(puzzleID: puzzleID, puzzleDate: puzzleDate, input: input)
        XCTAssertEqual(result.auraPointsEarned, useCase.score(for: input))
        XCTAssertEqual(result.puzzleID,         puzzleID)
        XCTAssertTrue(result.isPerfect)
    }

    func testResultBuilderSetsIsPerfect() {
        let imperfect = CrosswordScoringInput(
            correctCells: 18, totalCells: 20, revealsUsed: 0, elapsedSeconds: 0
        )
        let result = useCase.result(puzzleID: UUID(), puzzleDate: Date(), input: imperfect)
        XCTAssertFalse(result.isPerfect)
    }
}
