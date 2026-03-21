// Core/Models/AuraProfile.swift
// SlangCheck
//
// The gamification state snapshot for a single user in the Aura Economy.
// Immutable value type. Zero UIKit/SwiftUI/CoreData imports.

import Foundation

// MARK: - AuraProfile

/// A point-in-time snapshot of a user's Aura Economy standing.
///
/// `AuraProfile` is the canonical representation passed between layers.
/// Persistence (CoreData cache) and remote state (Firestore) are handled
/// by their respective repository implementations — this struct knows
/// nothing about storage.
///
/// `currentTier` is always derivable from `totalPoints` via `AuraTier.tier(for:)`.
/// It is stored explicitly here so consumers do not need to recompute it
/// on every access, and so it can be compared against a cached value to
/// detect tier-promotion events.
public struct AuraProfile: Codable, Identifiable, Equatable, Sendable {

    // MARK: Properties

    /// Stable UUID that matches the authenticated user's UID.
    public let id: UUID

    /// Cumulative Aura Points earned across all quiz sessions and activities.
    public let totalPoints: Int

    /// The tier derived from `totalPoints`. Always consistent with `AuraTier.tier(for: totalPoints)`.
    public let currentTier: AuraTier

    /// Number of consecutive days the user has completed at least one quiz.
    public let streak: Int

    /// ISO 8601 timestamp of the last streak-qualifying activity.
    /// `nil` if the user has never completed a quiz.
    public let lastActivityDate: Date?

    /// The user's display name sourced from their authenticated profile.
    /// Rendered on the shareable Aura Card (Q-004: include display name).
    public let displayName: String

    // MARK: Initialization

    public init(
        id: UUID,
        totalPoints: Int,
        streak: Int,
        lastActivityDate: Date?,
        displayName: String
    ) {
        self.id               = id
        self.totalPoints      = totalPoints
        self.currentTier      = AuraTier.tier(for: totalPoints)
        self.streak           = streak
        self.lastActivityDate = lastActivityDate
        self.displayName      = displayName
    }

    // MARK: Derived Helpers

    /// Progress fraction within the current tier, in `[0.0, 1.0]`.
    public var tierProgress: Double {
        currentTier.progress(for: totalPoints)
    }

    /// Points remaining before the next tier promotion, or `nil` at the top tier.
    public var pointsToNextTier: Int? {
        currentTier.pointsToNextTier(from: totalPoints)
    }

    /// Returns `true` if applying `additionalPoints` would cause a tier change.
    ///
    /// Use this to trigger the tier-promotion haptic / animation in the ViewModel.
    public func wouldPromote(with additionalPoints: Int) -> Bool {
        let newTier = AuraTier.tier(for: totalPoints + additionalPoints)
        return newTier > currentTier
    }

    // MARK: Mutation Helpers

    /// Returns a new `AuraProfile` with `additionalPoints` added to the total.
    /// `currentTier` is automatically recalculated.
    public func adding(points additionalPoints: Int) -> AuraProfile {
        AuraProfile(
            id: id,
            totalPoints: max(totalPoints + additionalPoints, 0),
            streak: streak,
            lastActivityDate: lastActivityDate,
            displayName: displayName
        )
    }

    /// Returns a new `AuraProfile` with the streak incremented by one and `lastActivityDate` set to now.
    public func incrementingStreak(now: Date = Date()) -> AuraProfile {
        AuraProfile(
            id: id,
            totalPoints: totalPoints,
            streak: streak + 1,
            lastActivityDate: now,
            displayName: displayName
        )
    }

    /// Returns a new `AuraProfile` with the streak reset to zero.
    public func resetStreak() -> AuraProfile {
        AuraProfile(
            id: id,
            totalPoints: totalPoints,
            streak: 0,
            lastActivityDate: lastActivityDate,
            displayName: displayName
        )
    }
}
