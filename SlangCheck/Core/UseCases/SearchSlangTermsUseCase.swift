// Core/UseCases/SearchSlangTermsUseCase.swift
// SlangCheck
//
// Single-responsibility use case: fuzzy search over a list of slang terms.
// Pure struct with no side effects. Fully testable without any mock infrastructure.

import Foundation

// MARK: - SearchSlangTermsUseCase

/// Filters a list of slang terms using a case-insensitive fuzzy match
/// across both the `term` and `definition` fields (FR-SR-002).
///
/// This is intentionally a pure function wrapped in a struct — no state, no dependencies.
/// The ViewModel is responsible for debouncing the query before calling this use case.
public struct SearchSlangTermsUseCase {

    public init() {}

    /// Filters and returns terms matching the query.
    ///
    /// - Parameters:
    ///   - terms: The full list of terms to search through.
    ///   - query: The search string. Empty string returns all terms unchanged.
    /// - Returns: Terms matching the query, preserving the input order.
    public func execute(terms: [SlangTerm], query: String) -> [SlangTerm] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return terms
        }
        return terms.filter { $0.matchesSearchQuery(query) }
    }
}
