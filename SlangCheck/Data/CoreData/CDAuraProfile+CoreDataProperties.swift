// Data/CoreData/CDAuraProfile+CoreDataProperties.swift
// SlangCheck
//
// @NSManaged properties, fetch request factory, and domain model conversion
// for the CDAuraProfile managed object.

import CoreData
import Foundation

extension CDAuraProfile {

    // MARK: - Fetch Request

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAuraProfile> {
        NSFetchRequest<CDAuraProfile>(entityName: "CDAuraProfile")
    }

    // MARK: - Managed Properties

    /// Stable UUID matching the authenticated user's UID.
    @NSManaged public var id: UUID?

    /// Cumulative Aura Points earned. Stored as Int64 to match CoreData Integer 64.
    @NSManaged public var totalPoints: Int64

    /// Raw string value of `AuraTier`. Stored to avoid recomputation and allow direct CoreData queries.
    @NSManaged public var currentTierRaw: String?

    /// Consecutive-day quiz streak.
    @NSManaged public var streak: Int64

    /// UTC timestamp of the last streak-qualifying quiz completion.
    @NSManaged public var lastActivityDate: Date?

    /// User's display name shown on the shareable Aura Card.
    @NSManaged public var displayName: String?

    // MARK: - Domain Model Conversion

    /// Converts this managed object to an `AuraProfile` domain model.
    /// Returns `nil` if any required field is missing or corrupt.
    func toDomainModel() -> AuraProfile? {
        guard
            let id          = id,
            let displayName = displayName
        else { return nil }

        return AuraProfile(
            id: id,
            totalPoints: Int(totalPoints),
            streak: Int(streak),
            lastActivityDate: lastActivityDate,
            displayName: displayName
        )
    }

    // MARK: - Populate from Domain Model

    /// Overwrites this managed object's fields from an `AuraProfile` domain model.
    func populate(from profile: AuraProfile) {
        id               = profile.id
        totalPoints      = Int64(profile.totalPoints)
        currentTierRaw   = profile.currentTier.rawValue
        streak           = Int64(profile.streak)
        lastActivityDate = profile.lastActivityDate
        displayName      = profile.displayName
    }
}
