// Core/Models/AuraTier.swift
// SlangCheck
//
// Defines the gamification tier ladder for the Aura Economy (Iteration 3).
// Zero UIKit/SwiftUI imports — platform-agnostic.

import Foundation

// MARK: - AuraTier

/// The rank tier a user occupies based on their total Aura Points.
///
/// Tiers progress from lowest (`unc`) to highest (`rizzler`).
/// Each tier has a half-open point range `[lowerBound, upperBound)`.
/// The top tier (`rizzler`) has no upper bound.
public enum AuraTier: String, Codable, CaseIterable, Identifiable, Sendable, Comparable {

    /// Lowest tier — new or inactive user. 0–999 points.
    case unc        = "unc"

    /// Second tier — engaged user. 1 000–4 999 points.
    case lurk       = "lurk"

    /// Third tier — dedicated learner. 5 000–14 999 points.
    case auraFarmer = "aura_farmer"

    /// Top tier — elite status. 15 000+ points.
    case rizzler    = "rizzler"

    // MARK: Identifiable

    public var id: String { rawValue }

    // MARK: Display

    /// Human-readable tier name shown in the UI.
    public var displayName: String {
        switch self {
        case .unc:        return String(localized: "aura.tier.unc",        defaultValue: "Unc")
        case .lurk:       return String(localized: "aura.tier.lurk",       defaultValue: "Lurk")
        case .auraFarmer: return String(localized: "aura.tier.auraFarmer", defaultValue: "Aura Farmer")
        case .rizzler:    return String(localized: "aura.tier.rizzler",    defaultValue: "Rizzler")
        }
    }

    /// Short motivational subtitle displayed beneath the tier badge.
    public var subtitle: String {
        switch self {
        case .unc:        return String(localized: "aura.tier.unc.subtitle",        defaultValue: "Just getting started")
        case .lurk:       return String(localized: "aura.tier.lurk.subtitle",       defaultValue: "Learning the lingo")
        case .auraFarmer: return String(localized: "aura.tier.auraFarmer.subtitle", defaultValue: "Grinding every day")
        case .rizzler:    return String(localized: "aura.tier.rizzler.subtitle",    defaultValue: "Unmatched rizz")
        }
    }

    // MARK: Point Range

    /// The inclusive lower bound of points required for this tier.
    public var minimumPoints: Int {
        switch self {
        case .unc:        return 0
        case .lurk:       return 1_000
        case .auraFarmer: return 5_000
        case .rizzler:    return 15_000
        }
    }

    /// The exclusive upper bound of points for this tier, or `nil` for the top tier.
    public var maximumPoints: Int? {
        switch self {
        case .unc:        return 1_000
        case .lurk:       return 5_000
        case .auraFarmer: return 15_000
        case .rizzler:    return nil
        }
    }

    /// Progress within the current tier as a value in `[0.0, 1.0]`.
    ///
    /// Always returns `1.0` for the top tier (`rizzler`).
    public func progress(for totalPoints: Int) -> Double {
        guard let upperBound = maximumPoints else { return 1.0 }
        let span     = Double(upperBound - minimumPoints)
        let position = Double(totalPoints - minimumPoints)
        return Swift.min(Swift.max(position / span, 0.0), 1.0)
    }

    /// Points remaining until the next tier, or `nil` if already at the top.
    public func pointsToNextTier(from totalPoints: Int) -> Int? {
        guard let upperBound = maximumPoints else { return nil }
        return Swift.max(upperBound - totalPoints, 0)
    }

    // MARK: Factory

    /// Returns the correct tier for the given `totalPoints` value.
    public static func tier(for totalPoints: Int) -> AuraTier {
        // Iterate from highest to lowest so the first match wins.
        return AuraTier.allCases.reversed().first {
            totalPoints >= $0.minimumPoints
        } ?? .unc
    }

    // MARK: Comparable

    /// Tiers are ordered by their minimum point threshold.
    public static func < (lhs: AuraTier, rhs: AuraTier) -> Bool {
        lhs.minimumPoints < rhs.minimumPoints
    }
}
