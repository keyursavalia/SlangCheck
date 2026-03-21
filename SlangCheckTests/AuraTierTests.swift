// SlangCheckTests/AuraTierTests.swift
// SlangCheck
//
// Unit tests for AuraTier: factory, progress, tier transitions, and Comparable.

import XCTest
@testable import SlangCheck

final class AuraTierTests: XCTestCase {

    // MARK: - Factory

    func testTierForZeroPointsIsUnc() {
        XCTAssertEqual(AuraTier.tier(for: 0), .unc)
    }

    func testTierForNegativePointsIsUnc() {
        XCTAssertEqual(AuraTier.tier(for: -100), .unc)
    }

    func testTierAtExactLurkThreshold() {
        XCTAssertEqual(AuraTier.tier(for: 1_000), .lurk)
    }

    func testTierBelowLurkThreshold() {
        XCTAssertEqual(AuraTier.tier(for: 999), .unc)
    }

    func testTierAtExactAuraFarmerThreshold() {
        XCTAssertEqual(AuraTier.tier(for: 5_000), .auraFarmer)
    }

    func testTierAtExactRizzlerThreshold() {
        XCTAssertEqual(AuraTier.tier(for: 15_000), .rizzler)
    }

    func testTierFarBeyondRizzlerIsRizzler() {
        XCTAssertEqual(AuraTier.tier(for: 1_000_000), .rizzler)
    }

    // MARK: - Progress

    func testProgressAtTierMinimumIsZero() {
        let progress = AuraTier.unc.progress(for: 0)
        XCTAssertEqual(progress, 0.0, accuracy: 0.001)
    }

    func testProgressAtTierMaximumIsOne() {
        let progress = AuraTier.unc.progress(for: 999)
        XCTAssertEqual(progress, 0.999, accuracy: 0.001)
    }

    func testProgressMidTier() {
        // lurk: 1000–4999, midpoint ≈ 2500 → progress ≈ 0.375
        let progress = AuraTier.lurk.progress(for: 2_500)
        XCTAssertEqual(progress, 0.375, accuracy: 0.001)
    }

    func testProgressForRizzlerAlwaysOne() {
        XCTAssertEqual(AuraTier.rizzler.progress(for: 15_000), 1.0, accuracy: 0.001)
        XCTAssertEqual(AuraTier.rizzler.progress(for: 999_999), 1.0, accuracy: 0.001)
    }

    // MARK: - Points to Next Tier

    func testPointsToNextTierFromUncMinimum() {
        XCTAssertEqual(AuraTier.unc.pointsToNextTier(from: 0), 1_000)
    }

    func testPointsToNextTierPartiallyThroughLurk() {
        XCTAssertEqual(AuraTier.lurk.pointsToNextTier(from: 2_000), 3_000)
    }

    func testPointsToNextTierIsNilForRizzler() {
        XCTAssertNil(AuraTier.rizzler.pointsToNextTier(from: 20_000))
    }

    func testPointsToNextTierClampsToZero() {
        // Should not return negative even if points exceed max (edge case guard).
        let result = AuraTier.unc.pointsToNextTier(from: 1_500)
        XCTAssertEqual(result, 0)
    }

    // MARK: - Comparable

    func testUncIsLessThanLurk() {
        XCTAssertLessThan(AuraTier.unc, AuraTier.lurk)
    }

    func testRizzlerIsGreatestTier() {
        for tier in AuraTier.allCases where tier != .rizzler {
            XCTAssertLessThan(tier, AuraTier.rizzler)
        }
    }

    func testAllCasesAreOrderedAscending() {
        let sorted = AuraTier.allCases.sorted()
        XCTAssertEqual(sorted, [.unc, .lurk, .auraFarmer, .rizzler])
    }
}
