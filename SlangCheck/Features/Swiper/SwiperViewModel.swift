// Features/Swiper/SwiperViewModel.swift
// SlangCheck
//
// ViewModel for the Swiper (flashcard stack) screen.
// Interaction model: swipe-up advances; Save button persists to a Collection.

import Foundation
import OSLog
import SwiftUI

// MARK: - SwiperViewModel

/// Owns the state and business logic for the Swiper tab.
@Observable
@MainActor
final class SwiperViewModel {

    // MARK: - State

    /// The current card stack. Index 0 is the top card.
    private(set) var cardQueue: [SlangTerm] = []

    /// Cards previously swiped through; last element is the most recently dismissed card.
    private(set) var historyStack: [SlangTerm] = []

    /// True when there is at least one card in history to navigate back to.
    var canGoBack: Bool { !historyStack.isEmpty }

    /// True when the queue is exhausted.
    private(set) var isQueueEmpty = false

    /// The user's lexicon, observed reactively to keep `isTopCardSaved` in sync.
    private(set) var lexicon: UserLexicon = UserLexicon()

    /// The user's liked terms, persisted to UserDefaults.
    private(set) var favorites: UserFavorites = UserFavorites()

    /// True while the initial queue is being loaded.
    private(set) var isLoading = true

    /// A user-facing error message, or nil.
    private(set) var errorMessage: String? = nil

    /// Total number of terms in the session queue (set once on first load, resets on reshuffle).
    private(set) var totalTermCount: Int = 0

    // MARK: - Collections

    /// The user's saved collections, loaded from UserDefaults.
    private(set) var collections: [SlangCollection] = []

    /// Non-nil when a save-to-collection toast should be shown.
    private(set) var saveToastCollectionName: String? = nil

    // MARK: - Private

    private let fetchTermsUseCase: FetchSlangTermsUseCase
    private let saveToLexiconUseCase: SaveTermToLexiconUseCase
    private let removeFromLexiconUseCase: RemoveTermFromLexiconUseCase
    private let repository: any SlangTermRepository
    let hapticService: any HapticServiceProtocol

    /// When non-nil, the swiper loads only these term IDs (favorites/collection feed mode).
    private let filterTermIDs: [UUID]?

    /// When non-nil, the queue is rotated so this term appears first.
    private let startAtTermID: UUID?

    private var lexiconObserverTask: Task<Void, Never>?
    private var toastDismissTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        repository: any SlangTermRepository,
        hapticService: any HapticServiceProtocol,
        filterTermIDs: [UUID]? = nil,
        startAtTermID: UUID? = nil
    ) {
        self.repository                = repository
        self.hapticService             = hapticService
        self.fetchTermsUseCase         = FetchSlangTermsUseCase(repository: repository)
        self.saveToLexiconUseCase      = SaveTermToLexiconUseCase(repository: repository)
        self.removeFromLexiconUseCase  = RemoveTermFromLexiconUseCase(repository: repository)
        self.favorites                 = Self.loadFavorites()
        self.filterTermIDs             = filterTermIDs
        self.startAtTermID             = startAtTermID
        self.collections               = Self.loadCollections()
    }

    // MARK: - Lifecycle

    func onAppear() {
        Task { await loadQueue() }
        if filterTermIDs == nil {
            startLexiconObserver()
        }
    }

    func onDisappear() {
        lexiconObserverTask?.cancel()
        toastDismissTask?.cancel()
    }

    // MARK: - Queue Loading

    private func loadQueue() async {
        isLoading = true
        errorMessage = nil

        do {
            if let filterIDs = filterTermIDs {
                // Favorites/collection feed mode — load only the specified terms.
                cardQueue = try await fetchTermsUseCase.fetchTermsByIDs(filterIDs)
            } else {
                let currentLexicon = try await repository.fetchLexicon()
                lexicon = currentLexicon
                cardQueue = try await fetchTermsUseCase.fetchSwiperQueue(lexicon: currentLexicon)
            }
            // If startAtTermID is set, put terms before it into history so the
            // user can swipe both backward and forward from the selected term.
            if let startID = startAtTermID,
               let idx = cardQueue.firstIndex(where: { $0.id == startID }) {
                historyStack = Array(cardQueue[..<idx])
                cardQueue    = Array(cardQueue[idx...])
            } else {
                historyStack = []
            }
            totalTermCount = historyStack.count + cardQueue.count
            isQueueEmpty = cardQueue.isEmpty
        } catch {
            Logger.swiper.error("Failed to load swiper queue: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Card Actions

    /// Advances to the next card — triggered by swipe-up gesture.
    func swipeUp() {
        guard !cardQueue.isEmpty else { return }
        hapticService.swipeCompleted()
        historyStack.append(cardQueue.removeFirst())
        isQueueEmpty = cardQueue.isEmpty
    }

    /// Returns to the previous card — triggered by swipe-down gesture.
    func swipeDown() {
        guard let previous = historyStack.popLast() else { return }
        hapticService.swipeCompleted()
        cardQueue.insert(previous, at: 0)
        isQueueEmpty = false
    }

    /// Saves the current top card to the Lexicon and default Collection.
    /// Applies an optimistic in-memory update immediately.
    func saveCurrentCard() {
        guard let top = cardQueue.first,
              !lexicon.savedTermIDs.contains(top.id) else { return }
        hapticService.swipeCompleted()
        lexicon = lexicon.saving(termID: top.id)
        let collectionName = saveTermToDefaultCollection(termID: top.id)
        showSaveToast(collectionName: collectionName)
        Task {
            do {
                try await saveToLexiconUseCase.execute(termID: top.id)
            } catch {
                Logger.swiper.error("Save to lexicon failed: \(error.localizedDescription)")
                lexicon = lexicon.removing(termID: top.id)
            }
        }
    }

    /// Toggles save state for the current top card.
    /// If saved → removes from lexicon and all collections.
    /// If not saved → saves to lexicon and default collection.
    func toggleSaveCurrentCard() {
        guard let top = cardQueue.first else { return }
        if lexicon.savedTermIDs.contains(top.id) {
            hapticService.swipeCompleted()
            lexicon = lexicon.removing(termID: top.id)
            var updated = collections
            for i in updated.indices {
                updated[i].termIDs.removeAll { $0 == top.id }
            }
            collections = updated
            Self.saveCollections(updated)
            Task {
                do {
                    try await removeFromLexiconUseCase.execute(termID: top.id)
                } catch {
                    Logger.swiper.error("Remove from lexicon failed: \(error.localizedDescription)")
                    lexicon = lexicon.saving(termID: top.id)
                }
            }
        } else {
            saveCurrentCard()
        }
    }

    /// Reshuffles all terms back into the queue.
    func reshuffleAll() {
        Task { await loadQueue() }
    }

    /// Whether the current top card is saved in the user's Lexicon.
    var isTopCardSaved: Bool {
        guard let top = cardQueue.first else { return false }
        return lexicon.savedTermIDs.contains(top.id)
    }

    /// Whether the current top card is liked/favorited.
    var isTopCardLiked: Bool {
        guard let top = cardQueue.first else { return false }
        return favorites.contains(termID: top.id)
    }

    /// Toggles the liked state of the current top card.
    func toggleFavoriteCurrentCard() {
        guard let top = cardQueue.first else { return }
        hapticService.swipeCompleted()
        favorites = favorites.contains(termID: top.id)
            ? favorites.removing(termID: top.id)
            : favorites.adding(termID: top.id)
        Self.saveFavorites(favorites)
    }

    // MARK: - Collections

    /// Toggles a term's membership in a specific collection.
    /// Also updates lexicon state accordingly.
    func toggleTermInCollection(_ collectionID: UUID, termID: UUID) {
        var updated = collections
        guard let idx = updated.firstIndex(where: { $0.id == collectionID }) else { return }

        if updated[idx].termIDs.contains(termID) {
            updated[idx].termIDs.removeAll { $0 == termID }
            // Unsave from lexicon if not in any remaining collection.
            let stillInAny = updated.contains { $0.termIDs.contains(termID) }
            if !stillInAny && lexicon.savedTermIDs.contains(termID) {
                lexicon = lexicon.removing(termID: termID)
                Task { try? await removeFromLexiconUseCase.execute(termID: termID) }
            }
        } else {
            updated[idx].termIDs.append(termID)
            if !lexicon.savedTermIDs.contains(termID) {
                lexicon = lexicon.saving(termID: termID)
                Task { try? await saveToLexiconUseCase.execute(termID: termID) }
            }
        }
        collections = updated
        Self.saveCollections(updated)
    }

    /// Creates a new empty collection with the given name.
    @discardableResult
    func createCollection(name: String) -> SlangCollection {
        let new = SlangCollection(name: name)
        var updated = collections
        updated.append(new)
        collections = updated
        Self.saveCollections(updated)
        return new
    }

    /// Dismisses the save toast immediately.
    func dismissSaveToast() {
        toastDismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.25)) {
            saveToastCollectionName = nil
        }
    }

    // MARK: - Private Collection Helpers

    @discardableResult
    private func saveTermToDefaultCollection(termID: UUID) -> String {
        ensureDefaultCollectionExists()
        var updated = collections
        guard let idx = updated.firstIndex(where: { $0.isDefault }) else {
            return "Want to Learn"
        }
        if !updated[idx].termIDs.contains(termID) {
            updated[idx].termIDs.append(termID)
        }
        collections = updated
        Self.saveCollections(updated)
        return updated[idx].name
    }

    private func ensureDefaultCollectionExists() {
        guard !collections.contains(where: { $0.isDefault }) else { return }
        let defaultCollection = SlangCollection(name: "Want to Learn", isDefault: true)
        var updated = [defaultCollection] + collections
        collections = updated
        Self.saveCollections(updated)
    }

    private func showSaveToast(collectionName: String) {
        toastDismissTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            saveToastCollectionName = collectionName
        }
        toastDismissTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                saveToastCollectionName = nil
            }
        }
    }

    // MARK: - Favorites Persistence

    private static func loadFavorites() -> UserFavorites {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.userFavoritesKey),
              let decoded = try? JSONDecoder().decode(UserFavorites.self, from: data) else {
            return UserFavorites()
        }
        return decoded
    }

    private static func saveFavorites(_ favorites: UserFavorites) {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.userFavoritesKey)
    }

    // MARK: - Collections Persistence

    static func loadCollections() -> [SlangCollection] {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.userCollectionsKey),
              let decoded = try? JSONDecoder().decode([SlangCollection].self, from: data) else {
            // Return empty — "Want to Learn" is created on first save, not upfront.
            return []
        }
        return decoded
    }

    static func saveCollections(_ collections: [SlangCollection]) {
        guard let data = try? JSONEncoder().encode(collections) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.userCollectionsKey)
    }

    // MARK: - Lexicon Observer

    private func startLexiconObserver() {
        lexiconObserverTask?.cancel()
        lexiconObserverTask = Task {
            for await updatedLexicon in repository.lexiconStream {
                guard !Task.isCancelled else { break }
                lexicon = updatedLexicon
            }
        }
    }
}
