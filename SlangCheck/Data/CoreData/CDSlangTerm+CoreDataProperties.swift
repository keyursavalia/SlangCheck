// Data/CoreData/CDSlangTerm+CoreDataProperties.swift
// SlangCheck
//
// @NSManaged properties and fetch request factory for CDSlangTerm.
// Optional attributes are modeled as Swift optionals per CoreData convention.

import Foundation
import CoreData

extension CDSlangTerm {

    // MARK: - Fetch Request

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSlangTerm> {
        NSFetchRequest<CDSlangTerm>(entityName: "CDSlangTerm")
    }

    // MARK: - Managed Properties

    /// Stable UUID. Non-optional in the data model.
    @NSManaged public var id: UUID?

    /// The slang term string (e.g., "No Cap"). Non-optional in the data model.
    @NSManaged public var term: String?

    /// Full definition text. Non-optional in the data model.
    @NSManaged public var definition: String?

    /// Standard English translation. Optional.
    @NSManaged public var standardEnglish: String?

    /// Example sentence. Optional.
    @NSManaged public var exampleSentence: String?

    /// Category raw string value. Non-optional in the data model.
    @NSManaged public var category: String?

    /// Origin / etymology string. Optional.
    @NSManaged public var origin: String?

    /// UsageFrequency raw string value. Non-optional in the data model.
    @NSManaged public var usageFrequency: String?

    /// JSON-encoded array of GenerationTag raw strings.
    @NSManaged public var generationTagsData: Data?

    /// The date the term was added.
    @NSManaged public var addedDate: Date?

    /// Whether this term is classified as "brainrot".
    @NSManaged public var isBrainrot: Bool

    /// Whether this entry is primarily an emoji slang term.
    @NSManaged public var isEmojiTerm: Bool

    // MARK: - Domain Model Conversion

    /// Converts this managed object to the domain `SlangTerm` model.
    /// Returns nil if any required field is missing or corrupted.
    func toDomainModel() -> SlangTerm? {
        guard
            let id            = id,
            let term          = term,
            let definition    = definition,
            let categoryStr   = category,
            let category      = SlangCategory(rawValue: categoryStr),
            let freqStr       = usageFrequency,
            let frequency     = UsageFrequency(rawValue: freqStr),
            let addedDate     = addedDate
        else {
            return nil
        }

        let generationTags: [GenerationTag]
        if let data = generationTagsData,
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            generationTags = decoded.compactMap { GenerationTag(rawValue: $0) }
        } else {
            generationTags = []
        }

        return SlangTerm(
            id:              id,
            term:            term,
            definition:      definition,
            standardEnglish: standardEnglish ?? "",
            exampleSentence: exampleSentence ?? "",
            category:        category,
            origin:          origin ?? "",
            usageFrequency:  frequency,
            generationTags:  generationTags,
            addedDate:       addedDate,
            isBrainrot:      isBrainrot,
            isEmojiTerm:     isEmojiTerm
        )
    }

    // MARK: - Populate from Domain Model

    /// Populates this managed object's fields from a `SlangTerm` domain model.
    func populate(from term: SlangTerm) {
        self.id              = term.id
        self.term            = term.term
        self.definition      = term.definition
        self.standardEnglish = term.standardEnglish
        self.exampleSentence = term.exampleSentence
        self.category        = term.category.rawValue
        self.origin          = term.origin
        self.usageFrequency  = term.usageFrequency.rawValue
        self.addedDate       = term.addedDate
        self.isBrainrot      = term.isBrainrot
        self.isEmojiTerm     = term.isEmojiTerm

        let tagStrings = term.generationTags.map(\.rawValue)
        self.generationTagsData = try? JSONEncoder().encode(tagStrings)
    }
}
