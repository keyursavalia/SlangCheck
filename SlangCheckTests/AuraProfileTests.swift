// SlangCheckTests/AuraProfileTests.swift
// SlangCheck
//
// Unit tests for AuraProfile: tier derivation, progress, mutation helpers,
// and promotion detection.

import XCTest
@testable import SlangCheck

final class AuraProfileTests: XCTestCase {

    // MARK: - Helpers

    private func makeProfile(
        points: Int = 0,
        streak: Int = 0,
        displayName: String = "TestUser"
    ) -> AuraProfile {
        AuraProfile(
            id: UUID(),
            totalPoints: points,
            streak: streak,
            lastActivityDate: nil,
            displayName: displayName
        )
    }

    // MARK: - Tier Derivation

    func testCurrentTierMatchesAuraTierFactory() {
        let profile = makeProfile(points: 3_000)
        XCTAssertEqual(profile.currentTier, AuraTier.tier(for: 3_000))
        XCTAssertEqual(profile.currentTier, .lurk)
    }

    func testZeroPointsIsUncTier() {
        let profile = makeProfile(points: 0)
        XCTAssertEqual(profile.currentTier, .unc)
    }

    // MARK: - Tier Progress

    func testTierProgressDelegatesToAuraTier() {
        let profile = makeProfile(points: 2_500)
        XCTAssertEqual(profile.tierProgress, AuraTier.lurk.progress(for: 2_500), accuracy: 0.001)
    }

    // MARK: - Points to Next Tier

    func testPointsToNextTierNilForRizzler() {
        let profile = makeProfile(points: 20_000)
        XCTAssertNil(profile.pointsToNextTier)
    }

    func testPointsToNextTierForUnc() {
        let profile = makeProfile(points: 500)
        XCTAssertEqual(profile.pointsToNextTier, 500)
    }

    // MARK: - Adding Points

    func testAddingPointsIncrementsTotalPoints() {
        let profile = makeProfile(points: 100)
        let updated = profile.adding(points: 200)
        XCTAssertEqual(updated.totalPoints, 300)
    }

    func testAddingPointsRecalculatesTier() {
        let profile = makeProfile(points: 900)
        XCTAssertEqual(profile.currentTier, .unc)
        let updated = profile.adding(points: 200)
        XCTAssertEqual(updated.currentTier, .lurk)
    }

    func testAddingNegativePointsDoesNotGoBelowZero() {
        let profile = makeProfile(points: 50)
        let updated = profile.adding(points: -200)
        XCTAssertEqual(updated.totalPoints, 0)
    }

    func testAddingPointsPreservesIdentityAndStreak() {
        let id = UUID()
        let profile = AuraProfile(id: id, totalPoints: 0, streak: 5, lastActivityDate: nil, displayName: "Dev")
        let updated = profile.adding(points: 100)
        XCTAssertEqual(updated.id, id)
        XCTAssertEqual(updated.streak, 5)
        XCTAssertEqual(updated.displayName, "Dev")
    }

    // MARK: - Would Promote

    func testWouldPromoteReturnsTrueWhenCrossing1000() {
        let profile = makeProfile(points: 900)
        XCTAssertTrue(profile.wouldPromote(with: 200))
    }

    func testWouldPromoteReturnsFalseWhenStayingInSameTier() {
        let profile = makeProfile(points: 100)
        XCTAssertFalse(profile.wouldPromote(with: 50))
    }

    func testWouldPromoteReturnsFalseAtTopTier() {
        let profile = makeProfile(points: 20_000)
        XCTAssertFalse(profile.wouldPromote(with: 5_000))
    }

    // MARK: - Streak

    func testIncrementingStreakAddsOne() {
        let profile = makeProfile(streak: 3)
        let updated = profile.incrementingStreak(now: Date())
        XCTAssertEqual(updated.streak, 4)
    }

    func testIncrementingStreakSetsLastActivityDate() {
        let now = Date()
        let profile = makeProfile()
        let updated = profile.incrementingStreak(now: now)
        XCTAssertEqual(updated.lastActivityDate, now)
    }

    func testResetStreakSetsStreakToZero() {
        let profile = makeProfile(streak: 10)
        let updated = profile.resetStreak()
        XCTAssertEqual(updated.streak, 0)
    }

    func testResetStreakPreservesPoints() {
        let profile = makeProfile(points: 5_000, streak: 10)
        let updated = profile.resetStreak()
        XCTAssertEqual(updated.totalPoints, 5_000)
    }
}
