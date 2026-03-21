// Data/CoreData/CDQuizResult+CoreDataProperties.swift
// SlangCheck
//
// @NSManaged properties, fetch request factory, and domain model conversion
// for the CDQuizResult managed object.

import CoreData
import Foundation

extension CDQuizResult {

    // MARK: - Fetch Request

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDQuizResult> {
        NSFetchRequest<CDQuizResult>(entityName: "CDQuizResult")
    }

    // MARK: - Managed Properties

    /// Stable UUID matching `QuizSession.id` / `QuizResult.id`.
    @NSManaged public var id: UUID?

    /// Number of questions answered correctly.
    @NSManaged public var correctCount: Int64

    /// Total number of questions in the session.
    @NSManaged public var totalCount: Int64

    /// Number of hints used.
    @NSManaged public var hintsUsed: Int64

    /// Wall-clock session duration in seconds.
    @NSManaged public var elapsedSeconds: Double

    /// Aura Points awarded for this session.
    @NSManaged public var auraPointsEarned: Int64

    /// UTC timestamp when the last answer was submitted.
    @NSManaged public var completedAt: Date?

    // MARK: - Domain Model Conversion

    /// Converts this managed object to a `QuizResult` domain model.
    /// Returns `nil` if any required field is missing or corrupt.
    func toDomainModel() -> QuizResult? {
        guard
            let id          = id,
            let completedAt = completedAt,
            totalCount > 0
        else { return nil }

        return QuizResult(
            id: id,
            correctCount: Int(correctCount),
            totalCount: Int(totalCount),
            hintsUsed: Int(hintsUsed),
            elapsedSeconds: elapsedSeconds,
            auraPointsEarned: Int(auraPointsEarned),
            completedAt: completedAt
        )
    }

    // MARK: - Populate from Domain Model

    /// Populates this managed object's fields from a `QuizResult` domain model.
    func populate(from result: QuizResult) {
        id               = result.id
        correctCount     = Int64(result.correctCount)
        totalCount       = Int64(result.totalCount)
        hintsUsed        = Int64(result.hintsUsed)
        elapsedSeconds   = result.elapsedSeconds
        auraPointsEarned = Int64(result.auraPointsEarned)
        completedAt      = result.completedAt
    }
}
