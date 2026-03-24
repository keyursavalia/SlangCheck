// Features/Swiper/SwiperViewModel.swift
// SlangCheck
//
// ViewModel for the Swiper (flashcard stack) screen.
// Interaction model: swipe-up advances; tap flips; Save button persists to Lexicon.

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

    /// True while the initial queue is being loaded.
    private(set) var isLoading = true

    /// A user-facing error message, or nil.
    private(set) var errorMessage: String? = nil

    /// Total number of terms in the session queue (set once on first load, resets on reshuffle).
    private(set) var totalTermCount: Int = 0

    // MARK: - Private

    private let fetchTermsUseCase: FetchSlangTermsUseCase
    private let saveToLexiconUseCase: SaveTermToLexiconUseCase
    private let repository: any SlangTermRepository
    let hapticService: any HapticServiceProtocol

    private var lexiconObserverTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        repository: any SlangTermRepository,
        hapticService: any HapticServiceProtocol
    ) {
        self.repository           = repository
        self.hapticService        = hapticService
        self.fetchTermsUseCase    = FetchSlangTermsUseCase(repository: repository)
        self.saveToLexiconUseCase = SaveTermToLexiconUseCase(repository: repository)
    }

    // MARK: - Lifecycle

    func onAppear() {
        Task { await loadQueue() }
        startLexiconObserver()
    }

    func onDisappear() {
        lexiconObserverTask?.cancel()
    }

    // MARK: - Queue Loading

    private func loadQueue() async {
        isLoading = true
        errorMessage = nil

        do {
            let currentLexicon = try await repository.fetchLexicon()
            lexicon = currentLexicon
            cardQueue = try await fetchTermsUseCase.fetchSwiperQueue(lexicon: currentLexicon)
            historyStack = []
            totalTermCount = cardQueue.count
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

    /// Saves the current top card to the Lexicon — triggered by the Save button.
    /// No-ops silently if the card is already saved.
    func saveCurrentCard() {
        guard let top = cardQueue.first,
              !lexicon.savedTermIDs.contains(top.id) else { return }
        hapticService.swipeCompleted()
        Task {
            do {
                try await saveToLexiconUseCase.execute(termID: top.id)
            } catch {
                Logger.swiper.error("Save to lexicon failed: \(error.localizedDescription)")
            }
        }
    }

    // flipCard() commented out — full-screen layout shows all content directly.
    // func flipCard() { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isCardFlipped.toggle() } }

    /// Reshuffles all terms back into the queue.
    func reshuffleAll() {
        Task { await loadQueue() }
    }

    /// Whether the current top card is already saved in the user's Lexicon.
    var isTopCardSaved: Bool {
        guard let top = cardQueue.first else { return false }
        return lexicon.savedTermIDs.contains(top.id)
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
