// Features/Profile/LexiconViewModel.swift
// SlangCheck
//
// ViewModel for the Personal Lexicon screen. Manages sorted saved terms
// and handles removal with swipe-to-delete confirmation.

import Foundation
import OSLog

// MARK: - LexiconSortOrder

/// Sort options for the Personal Lexicon list (FR-L-003).
enum LexiconSortOrder: String, CaseIterable {
    case mostRecentFirst = "mostRecentFirst"
    case alphabetical    = "alphabetical"

    var displayName: String {
        switch self {
        case .mostRecentFirst: return String(localized: "lexicon.sort.recent", defaultValue: "Most Recent")
        case .alphabetical:    return String(localized: "lexicon.sort.alpha", defaultValue: "A–Z")
        }
    }
}

// MARK: - LexiconViewModel

/// Owns the state and business logic for the Personal Lexicon screen.
@Observable
@MainActor
final class LexiconViewModel {

    // MARK: - Published State

    /// Saved terms in the active sort order.
    private(set) var savedTerms: [SlangTerm] = []

    /// Current sort order selection.
    var sortOrder: LexiconSortOrder = .mostRecentFirst {
        didSet { applySortOrder() }
    }

    /// True while initial data is loading.
    private(set) var isLoading = true

    /// A user-facing error message, or nil.
    private(set) var errorMessage: String? = nil

    // MARK: - Private

    private let repository: any SlangTermRepository
    private let removeUseCase: RemoveTermFromLexiconUseCase

    private var lexicon: UserLexicon = UserLexicon()
    private var allTermsMap: [UUID: SlangTerm] = [:]
    private var lexiconObserverTask: Task<Void, Never>?

    // MARK: - Initialization

    init(repository: any SlangTermRepository) {
        self.repository    = repository
        self.removeUseCase = RemoveTermFromLexiconUseCase(repository: repository)
    }

    // MARK: - Lifecycle

    func onAppear() {
        Task { await loadInitialData() }
        startLexiconObserver()
    }

    func onDisappear() {
        lexiconObserverTask?.cancel()
    }

    // MARK: - Data Loading

    private func loadInitialData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all terms to build lookup map, then fetch lexicon.
            let terms = try await repository.fetchAllTerms()
            allTermsMap = Dictionary(uniqueKeysWithValues: terms.map { ($0.id, $0) })
            lexicon     = try await repository.fetchLexicon()
            rebuildSavedTerms()
        } catch {
            Logger.lexicon.error("LexiconViewModel load failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func rebuildSavedTerms() {
        let resolved = lexicon.entries.compactMap { entry -> SlangTerm? in
            allTermsMap[entry.termID]
        }
        savedTerms = sort(resolved)
    }

    private func applySortOrder() {
        savedTerms = sort(savedTerms)
    }

    private func sort(_ terms: [SlangTerm]) -> [SlangTerm] {
        switch sortOrder {
        case .mostRecentFirst:
            // Preserve lexicon order (already most-recent-first from UserLexicon).
            return terms
        case .alphabetical:
            return terms.sorted { $0.term.localizedCaseInsensitiveCompare($1.term) == .orderedAscending }
        }
    }

    // MARK: - Lexicon Observer

    private func startLexiconObserver() {
        lexiconObserverTask?.cancel()
        lexiconObserverTask = Task {
            for await updatedLexicon in repository.lexiconStream {
                guard !Task.isCancelled else { break }
                lexicon = updatedLexicon
                rebuildSavedTerms()
            }
        }
    }

    // MARK: - Mutations

    /// Removes a term from the lexicon (FR-L-004: swipe-to-delete).
    func remove(term: SlangTerm) {
        Task {
            do {
                try await removeUseCase.execute(termID: term.id)
            } catch {
                Logger.lexicon.error("Failed to remove term from lexicon: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
}
