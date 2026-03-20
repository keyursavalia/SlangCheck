// Data/CoreData/CDLexiconEntry+CoreDataProperties.swift
// SlangCheck
//
// @NSManaged properties and fetch request factory for CDLexiconEntry.

import Foundation
import CoreData

extension CDLexiconEntry {

    // MARK: - Fetch Request

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDLexiconEntry> {
        NSFetchRequest<CDLexiconEntry>(entityName: "CDLexiconEntry")
    }

    // MARK: - Managed Properties

    /// UUID of the saved `SlangTerm`.
    @NSManaged public var termID: UUID?

    /// Timestamp when the user saved this term.
    @NSManaged public var savedDate: Date?

    // MARK: - Domain Model Conversion

    /// Converts this managed object to the domain `LexiconEntry` model.
    /// Returns nil if any required field is missing.
    func toDomainModel() -> LexiconEntry? {
        guard let termID = termID, let savedDate = savedDate else { return nil }
        return LexiconEntry(termID: termID, savedDate: savedDate)
    }
}
