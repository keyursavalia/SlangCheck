// Core/UseCases/FetchSlangTermsUseCase.swift
// SlangCheck
//
// Use case for fetching and organizing slang terms from the repository.
// Handles sorting and grouping logic that does not belong in a ViewModel.

import Foundation

// MARK: - FetchSlangTermsUseCase

/// Orchestrates fetching slang terms from the repository and preparing them for display.
/// Encapsulates sort order and category-filter logic as single-responsibility concerns.
public struct FetchSlangTermsUseCase {

    private let repository: any SlangTermRepository

    public init(repository: any SlangTermRepository) {
        self.repository = repository
    }

    // MARK: All Terms (Glossary)

    /// Fetches all terms sorted alphabetically, grouped by first letter.
    /// Used by `GlossaryViewModel`.
    public func fetchAllGrouped() async throws(SlangRepositoryError) -> [String: [SlangTerm]] {
        let terms = try await repository.fetchAllTerms()
        return Dictionary(grouping: terms) { $0.firstLetter }
    }

    /// Fetches all terms filtered by category, sorted alphabetically.
    public func fetchByCategory(_ category: SlangCategory?) async throws(SlangRepositoryError) -> [SlangTerm] {
        guard let category else {
            return try await repository.fetchAllTerms()
        }
        return try await repository.fetchTerms(in: category)
    }

    // MARK: Swiper Queue

    /// Builds the Swiper card queue: terms NOT in the lexicon,
    /// ordered by `usageFrequency` descending, randomized within frequency groups (FR-S-007).
    public func fetchSwiperQueue(lexicon: UserLexicon) async throws(SlangRepositoryError) -> [SlangTerm] {
        let allTerms  = try await repository.fetchAllTerms()
        let savedIDs  = lexicon.savedTermIDs

        let available = allTerms.filter { !savedIDs.contains($0.id) }

        // Group by frequency, shuffle within each group, then concatenate high → emerging
        let byFrequency: [(UsageFrequency, [SlangTerm])] = ([.high, .medium, .low, .emerging] as [UsageFrequency]).compactMap { freq in
            let group = available.filter { $0.usageFrequency == freq }
            return group.isEmpty ? nil : (freq, group.shuffled())
        }

        return byFrequency.flatMap(\.1)
    }
}
