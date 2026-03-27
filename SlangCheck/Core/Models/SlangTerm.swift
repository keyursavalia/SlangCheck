// Core/Models/SlangTerm.swift
// SlangCheck
//
// Pure Swift model for a slang term. Zero UIKit, SwiftUI, or CoreData imports.
// This type is platform-agnostic and portable to watchOS/visionOS.

import Foundation

// MARK: - SlangCategory

/// The thematic category of a slang term, sourced from DATABASE.md.
/// Raw values are the exact strings used in the seed JSON and Firestore.
public enum SlangCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case foundationalDescriptor     = "foundational_descriptor"
    case brainrot                   = "brainrot"
    case socialArchetype            = "social_archetype"
    case relationship               = "relationship"
    case gamingInternet             = "gaming_internet"
    case reaction                   = "reaction"
    case aesthetic                  = "aesthetic"
    case emerging2026               = "emerging_2026"
    case emoji                      = "emoji"
    case regionalBayArea            = "regional_bay_area"
    case regionalSouthernCalifornia = "regional_southern_california"

    public var id: String { rawValue }

    /// Human-readable display name for UI filter labels.
    public var displayName: String {
        switch self {
        case .foundationalDescriptor:     return String(localized: "category.foundationalDescriptor",     defaultValue: "Descriptors")
        case .brainrot:                   return String(localized: "category.brainrot",                   defaultValue: "Brainrot")
        case .socialArchetype:            return String(localized: "category.socialArchetype",            defaultValue: "Archetypes")
        case .relationship:               return String(localized: "category.relationship",               defaultValue: "Relationships")
        case .gamingInternet:             return String(localized: "category.gamingInternet",             defaultValue: "Gaming")
        case .reaction:                   return String(localized: "category.reaction",                   defaultValue: "Reactions")
        case .aesthetic:                  return String(localized: "category.aesthetic",                  defaultValue: "Aesthetics")
        case .emerging2026:               return String(localized: "category.emerging2026",               defaultValue: "Emerging")
        case .emoji:                      return String(localized: "category.emoji",                      defaultValue: "Emoji")
        case .regionalBayArea:            return String(localized: "category.regionalBayArea",            defaultValue: "Bay Area")
        case .regionalSouthernCalifornia: return String(localized: "category.regionalSouthernCalifornia", defaultValue: "SoCal")
        }
    }
}

// MARK: - UsageFrequency

/// How frequently a slang term appears in everyday usage.
public enum UsageFrequency: String, Codable, Sendable, Comparable {
    case high     = "high"     // Core vocabulary; used daily
    case medium   = "medium"   // Widely understood; used regularly
    case low      = "low"      // Niche; context-specific
    case emerging = "emerging" // Trending; not yet mainstream

    /// Numeric rank for sorting. Higher value = more frequent.
    private var rank: Int {
        switch self {
        case .high:     return 3
        case .medium:   return 2
        case .low:      return 1
        case .emerging: return 0
        }
    }

    public static func < (lhs: UsageFrequency, rhs: UsageFrequency) -> Bool {
        lhs.rank < rhs.rank
    }
}

// MARK: - GenerationTag

/// The generational cohort(s) that primarily use a slang term.
public enum GenerationTag: String, Codable, Sendable {
    case genZ        = "genZ"
    case genAlpha    = "genAlpha"
    case millennials = "millennials"
}

// MARK: - SlangTerm

/// A single slang dictionary entry. Immutable value type.
/// Conforms to `Codable` for JSON seed loading, `Identifiable` for SwiftUI lists,
/// `Hashable` for Set operations, and `Sendable` for concurrent use.
public struct SlangTerm: Codable, Identifiable, Hashable, Sendable {

    // MARK: Properties

    /// Stable UUID identifier. Matches the `id` field in the seed JSON.
    public let id: UUID

    /// The slang term itself (e.g., "No Cap").
    public let term: String

    /// Abbreviated part of speech (e.g., "v.", "adj.", "n.").
    public let partOfSpeechShort: String

    /// Full part of speech (e.g., "verb", "adjective", "noun").
    public let partOfSpeechFull: String

    /// Full definition suitable for display in the Glossary and Swiper detail.
    public let definition: String

    /// Standard English equivalent for the Translator (Iteration 2).
    public let standardEnglish: String

    /// An example sentence demonstrating the term in context.
    public let exampleSentence: String

    /// Thematic category for filtering.
    public let category: SlangCategory

    /// Origin / etymology note.
    public let origin: String

    /// How frequently the term is used in everyday speech.
    public let usageFrequency: UsageFrequency

    /// Generational cohorts that primarily use this term.
    public let generationTags: [GenerationTag]

    /// ISO 8601 date the term was added to the database.
    public let addedDate: Date

    /// Whether this term falls under the "brainrot" subculture dialect.
    public let isBrainrot: Bool

    /// Whether this entry is primarily an emoji with a coded meaning.
    public let isEmojiTerm: Bool

    // MARK: Initializer

    public init(
        id: UUID,
        term: String,
        partOfSpeechShort: String = "",
        partOfSpeechFull: String = "",
        definition: String,
        standardEnglish: String,
        exampleSentence: String,
        category: SlangCategory,
        origin: String,
        usageFrequency: UsageFrequency,
        generationTags: [GenerationTag],
        addedDate: Date,
        isBrainrot: Bool,
        isEmojiTerm: Bool
    ) {
        self.id = id
        self.term = term
        self.partOfSpeechShort = partOfSpeechShort
        self.partOfSpeechFull = partOfSpeechFull
        self.definition = definition
        self.standardEnglish = standardEnglish
        self.exampleSentence = exampleSentence
        self.category = category
        self.origin = origin
        self.usageFrequency = usageFrequency
        self.generationTags = generationTags
        self.addedDate = addedDate
        self.isBrainrot = isBrainrot
        self.isEmojiTerm = isEmojiTerm
    }

    // MARK: Codable Keys

    private enum CodingKeys: String, CodingKey {
        case id, term, partOfSpeechShort, partOfSpeechFull
        case definition, standardEnglish, exampleSentence
        case category, origin, usageFrequency, generationTags = "generationTag"
        case addedDate, isBrainrot, isEmojiTerm
    }

    // MARK: Search

    /// Returns true if this term matches the given search query via case-insensitive substring match
    /// on both `term` and `definition` fields (FR-SR-002: fuzzy match across term and definition).
    public func matchesSearchQuery(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let lowered = query.lowercased()
        return term.lowercased().contains(lowered)
            || definition.lowercased().contains(lowered)
    }

    /// The first letter of the term, uppercased, for alphabetical section grouping.
    public var firstLetter: String {
        String(term.prefix(1)).uppercased()
    }
}

// MARK: - Custom Decoder (ISO 8601 date string support)

extension SlangTerm {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id                = try container.decode(UUID.self,             forKey: .id)
        term              = try container.decode(String.self,           forKey: .term)
        partOfSpeechShort = try container.decodeIfPresent(String.self,  forKey: .partOfSpeechShort) ?? ""
        partOfSpeechFull  = try container.decodeIfPresent(String.self,  forKey: .partOfSpeechFull)  ?? ""
        definition        = try container.decode(String.self,           forKey: .definition)
        standardEnglish   = try container.decode(String.self,          forKey: .standardEnglish)
        exampleSentence   = try container.decode(String.self,          forKey: .exampleSentence)
        category          = try container.decode(SlangCategory.self,    forKey: .category)
        origin            = try container.decode(String.self,           forKey: .origin)
        usageFrequency    = try container.decode(UsageFrequency.self,   forKey: .usageFrequency)
        generationTags    = try container.decode([GenerationTag].self,  forKey: .generationTags)
        isBrainrot        = try container.decode(Bool.self,             forKey: .isBrainrot)
        isEmojiTerm       = try container.decode(Bool.self,             forKey: .isEmojiTerm)

        let dateString = try container.decode(String.self, forKey: .addedDate)
        let formatter  = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        if let parsed = formatter.date(from: dateString) {
            addedDate = parsed
        } else {
            addedDate = Date()
        }
    }
}
