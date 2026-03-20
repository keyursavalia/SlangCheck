// Features/Swiper/SwiperViewModel.swift
// SlangCheck
//
// ViewModel for the Swiper (flashcard stack) screen.
// Manages the card queue, swipe actions, undo, and card-flip state.

import Foundation
import OSLog
import SwiftUI

// MARK: - SwiperViewModel

/// Owns the state and business logic for the Swiper tab.
@Observable
@MainActor
final class SwiperViewModel {

    // MARK: - Published State

    /// The current card stack. Index 0 is the top card.
    private(set) var cardQueue: [SlangTerm] = []

    /// Whether the current top card is showing its definition (flipped state, FR-S-004).
    var isCardFlipped = false

    /// The term that was last dismissed/saved, available for 1-level undo (FR-S-009).
    private(set) var lastUndoneCard: (term: SlangTerm, wasSaved: Bool)? = nil

    /// Whether the undo button is visible (shown for 3 seconds after each swipe).
    private(set) var showUndoButton = false

    /// True when the queue is exhausted (FR-S-008).
    private(set) var isQueueEmpty = false

    /// The user's lexicon, observed reactively.
    private(set) var lexicon: UserLexicon = UserLexicon()

    /// True while the initial queue is being loaded.
    private(set) var isLoading = true

    /// A user-facing error message, or nil.
    private(set) var errorMessage: String? = nil

    // MARK: - Private

    private let fetchTermsUseCase: FetchSlangTermsUseCase
    private let saveToLexiconUseCase: SaveTermToLexiconUseCase
    private let removeFromLexiconUseCase: RemoveTermFromLexiconUseCase
    private let repository: any SlangTermRepository
    let hapticService: any HapticServiceProtocol

    private var undoTimerTask: Task<Void, Never>?
    private var lexiconObserverTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        repository: any SlangTermRepository,
        hapticService: any HapticServiceProtocol
    ) {
        self.repository              = repository
        self.hapticService           = hapticService
        self.fetchTermsUseCase       = FetchSlangTermsUseCase(repository: repository)
        self.saveToLexiconUseCase    = SaveTermToLexiconUseCase(repository: repository)
        self.removeFromLexiconUseCase = RemoveTermFromLexiconUseCase(repository: repository)
    }

    // MARK: - Lifecycle

    func onAppear() {
        Task { await loadQueue() }
        startLexiconObserver()
    }

    func onDisappear() {
        lexiconObserverTask?.cancel()
        undoTimerTask?.cancel()
    }

    // MARK: - Queue Loading

    private func loadQueue() async {
        isLoading = true
        errorMessage = nil

        do {
            let currentLexicon = try await repository.fetchLexicon()
            lexicon = currentLexicon
            cardQueue = try await fetchTermsUseCase.fetchSwiperQueue(lexicon: currentLexicon)
            isQueueEmpty = cardQueue.isEmpty
        } catch {
            Logger.swiper.error("Failed to load swiper queue: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Card Actions

    /// Called when the user right-swipes (save to Lexicon) — FR-S-002.
    func swipeRight() {
        guard let top = cardQueue.first else { return }
        hapticService.swipeCompleted()
        lastUndoneCard = (term: top, wasSaved: true)
        cardQueue.removeFirst()
        isCardFlipped = false
        isQueueEmpty = cardQueue.isEmpty
        showUndoButtonBriefly()

        Task {
            do {
                try await saveToLexiconUseCase.execute(termID: top.id)
            } catch {
                Logger.swiper.error("Save to lexicon failed: \(error.localizedDescription)")
            }
        }
    }

    /// Called when the user left-swipes (dismiss/skip) — FR-S-003.
    func swipeLeft() {
        guard let top = cardQueue.first else { return }
        hapticService.swipeCompleted()
        lastUndoneCard = (term: top, wasSaved: false)
        cardQueue.removeFirst()
        isCardFlipped = false
        isQueueEmpty = cardQueue.isEmpty
        showUndoButtonBriefly()
        Logger.swiper.debug("Dismissed term: \(top.term)")
    }

    /// Flips the current card to show/hide the definition — FR-S-004.
    func flipCard() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isCardFlipped.toggle()
        }
    }

    /// Undoes the last swipe action — FR-S-009.
    func undo() {
        guard let last = lastUndoneCard else { return }

        // Re-insert the card at the front.
        cardQueue.insert(last.term, at: 0)
        isQueueEmpty = false
        isCardFlipped = false

        // If it was saved, remove it from the lexicon.
        if last.wasSaved {
            Task {
                do {
                    try await removeFromLexiconUseCase.execute(termID: last.term.id)
                } catch {
                    Logger.swiper.error("Undo remove from lexicon failed: \(error.localizedDescription)")
                }
            }
        }

        lastUndoneCard = nil
        showUndoButton = false
        undoTimerTask?.cancel()
        Logger.swiper.info("Undo: restored \(last.term.term) to queue.")
    }

    /// Reshuffles all terms back into the queue — FR-S-008.
    func reshuffleAll() {
        Task { await loadQueue() }
    }

    // MARK: - Private: Undo Timer (FR-S-009: visible for 3 seconds)

    private func showUndoButtonBriefly() {
        undoTimerTask?.cancel()
        showUndoButton = true
        undoTimerTask = Task {
            do {
                try await Task.sleep(for: .seconds(AppConstants.swiperUndoVisibilitySeconds))
                guard !Task.isCancelled else { return }
                showUndoButton = false
                lastUndoneCard = nil
            } catch {
                // Task cancelled — undo was used or view disappeared.
            }
        }
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
