// Features/Glossary/GlossaryViewModel.swift
// SlangCheck
//
// ViewModel for the Glossary screen. Manages term fetching, category filtering,
// and debounced search. @Observable for fine-grained SwiftUI view invalidation.

import Foundation
import OSLog

// MARK: - GlossaryViewModel

/// Owns the state and business logic for the Glossary screen.
/// All mutations happen on the main actor; background work uses async Tasks.
@Observable
@MainActor
final class GlossaryViewModel {

    // MARK: - Published State

    /// All terms currently matching the active category filter.
    private(set) var allTerms: [SlangTerm] = []

    /// Terms after applying the live search query. Empty query → same as `allTerms`.
    private(set) var displayedTerms: [SlangTerm] = []

    /// Alphabetically sorted section headers (first letters of terms in `displayedTerms`).
    private(set) var sectionHeaders: [String] = []

    /// Terms grouped by first letter, for the alphabetical section layout.
    private(set) var groupedTerms: [String: [SlangTerm]] = [:]

    /// The active category filter. `nil` means "All".
    var selectedCategory: SlangCategory? = nil {
        didSet { Task { await loadTerms() } }
    }

    /// The live search query, bound to the search text field.
    /// Mutations trigger a debounced filter update.
    var searchQuery: String = "" {
        didSet { scheduleSearchDebounce() }
    }

    /// The user's current lexicon, for displaying saved state in each row.
    private(set) var lexicon: UserLexicon = UserLexicon()

    /// Whether initial data is loading.
    private(set) var isLoading = false

    /// A user-facing error message, or nil if no error.
    private(set) var errorMessage: String? = nil

    // MARK: - Private

    private let fetchTermsUseCase: FetchSlangTermsUseCase
    private let searchUseCase = SearchSlangTermsUseCase()
    private let repository: any SlangTermRepository

    /// Task for debouncing search input. Cancelled and replaced on each keystroke.
    private var searchDebounceTask: Task<Void, Never>?

    /// Task that observes the lexicon stream for live save/remove updates.
    private var lexiconObserverTask: Task<Void, Never>?

    // MARK: - Initialization

    init(repository: any SlangTermRepository) {
        self.repository       = repository
        self.fetchTermsUseCase = FetchSlangTermsUseCase(repository: repository)
    }

    // MARK: - Lifecycle

    /// Called when the Glossary view appears. Loads terms and starts lexicon observation.
    func onAppear() {
        Task { await loadTerms() }
        startLexiconObserver()
    }

    /// Called when the Glossary view disappears. Cancels long-lived tasks.
    func onDisappear() {
        lexiconObserverTask?.cancel()
        searchDebounceTask?.cancel()
    }

    // MARK: - Term Loading

    private func loadTerms() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await fetchTermsUseCase.fetchByCategory(selectedCategory)
            allTerms = fetched
            applySearchFilter()
        } catch {
            Logger.glossary.error("Failed to load terms: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Search Debounce (FR-SR-003: 300ms)

    private func scheduleSearchDebounce() {
        searchDebounceTask?.cancel()
        searchDebounceTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(AppConstants.searchDebounceMilliseconds))
                guard !Task.isCancelled else { return }
                applySearchFilter()
            } catch {
                // Task was cancelled — normal flow, no action needed.
            }
        }
    }

    private func applySearchFilter() {
        displayedTerms = searchUseCase.execute(terms: allTerms, query: searchQuery)
        rebuildSections()
    }

    private func rebuildSections() {
        groupedTerms   = Dictionary(grouping: displayedTerms) { $0.firstLetter }
        sectionHeaders = groupedTerms.keys.sorted()
    }

    // MARK: - Lexicon Observation

    private func startLexiconObserver() {
        lexiconObserverTask?.cancel()
        lexiconObserverTask = Task {
            // Load initial lexicon state before subscribing to the stream.
            if let initial = try? await repository.fetchLexicon() {
                lexicon = initial
            }
            for await updatedLexicon in repository.lexiconStream {
                guard !Task.isCancelled else { break }
                lexicon = updatedLexicon
            }
        }
    }

    // MARK: - Lexicon Mutation

    /// Saves or removes the given term from the lexicon based on current state.
    func toggleLexicon(for term: SlangTerm) {
        Task {
            if lexicon.contains(termID: term.id) {
                let useCase = RemoveTermFromLexiconUseCase(repository: repository)
                try? await useCase.execute(termID: term.id)
            } else {
                let useCase = SaveTermToLexiconUseCase(repository: repository)
                try? await useCase.execute(termID: term.id)
            }
        }
    }
}
