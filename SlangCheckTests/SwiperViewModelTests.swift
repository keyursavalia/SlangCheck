// SlangCheckTests/SwiperViewModelTests.swift
// SlangCheck
//
// Unit tests for SwiperViewModel: swipe actions, undo, lexicon state.

import XCTest
@testable import SlangCheck

@MainActor
final class SwiperViewModelTests: XCTestCase {

    private var repository: MockSlangTermRepository!
    private var viewModel: SwiperViewModel!

    override func setUp() async throws {
        try await super.setUp()
        repository = MockSlangTermRepository()
        viewModel  = SwiperViewModel(
            repository: repository,
            hapticService: MockHapticService()
        )
    }

    override func tearDown() async throws {
        viewModel  = nil
        repository = nil
        try await super.tearDown()
    }

    // MARK: - Queue Loading

    func testOnAppearLoadsQueue() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(viewModel.cardQueue.isEmpty, "Queue should be populated after onAppear.")
    }

    func testQueueExcludesSavedTerms() async throws {
        // Pre-save the first term.
        let firstTerm = MockSlangTermRepository.sampleTerms().first!
        repository.lexiconEntries = [LexiconEntry(termID: firstTerm.id, savedDate: Date())]

        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertFalse(
            viewModel.cardQueue.contains(where: { $0.id == firstTerm.id }),
            "Saved terms should be excluded from the Swiper queue (FR-S-007)."
        )
    }

    // MARK: - Swipe Right (Save) — FR-S-002

    func testSwipeRightSavesTermToLexicon() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        let topTerm = viewModel.cardQueue.first!
        viewModel.swipeRight()

        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(
            repository.lexiconEntries.contains(where: { $0.termID == topTerm.id }),
            "Swipe right should add the term to the lexicon."
        )
    }

    func testSwipeRightRemovesCardFromQueue() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        let initialCount = viewModel.cardQueue.count
        viewModel.swipeRight()

        XCTAssertEqual(viewModel.cardQueue.count, initialCount - 1,
                       "Swipe right should remove one card from the queue.")
    }

    // MARK: - Swipe Left (Dismiss) — FR-S-003

    func testSwipeLeftDoesNotSaveToLexicon() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        let topTerm = viewModel.cardQueue.first!
        viewModel.swipeLeft()

        try await Task.sleep(for: .milliseconds(100))

        XCTAssertFalse(
            repository.lexiconEntries.contains(where: { $0.termID == topTerm.id }),
            "Swipe left should NOT save the term to the lexicon."
        )
    }

    func testSwipeLeftRemovesCardFromQueue() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        let initialCount = viewModel.cardQueue.count
        viewModel.swipeLeft()

        XCTAssertEqual(viewModel.cardQueue.count, initialCount - 1)
    }

    // MARK: - Undo — FR-S-009

    func testUndoAfterSwipeRightRestoresCard() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        let topTerm = viewModel.cardQueue.first!
        viewModel.swipeRight()

        XCTAssertTrue(viewModel.showUndoButton, "Undo button should be visible after swipe.")

        viewModel.undo()

        XCTAssertEqual(viewModel.cardQueue.first?.id, topTerm.id,
                       "Undo should restore the top card to the front of the queue.")
    }

    func testUndoAfterSwipeRightRemovesFromLexicon() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        let topTerm = viewModel.cardQueue.first!
        viewModel.swipeRight()
        try await Task.sleep(for: .milliseconds(100))

        viewModel.undo()
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertFalse(
            repository.lexiconEntries.contains(where: { $0.termID == topTerm.id }),
            "Undo after swipe-right should remove the term from the lexicon."
        )
    }

    func testUndoAfterSwipeLeftRestoresCard() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        let topTerm = viewModel.cardQueue.first!
        viewModel.swipeLeft()
        viewModel.undo()

        XCTAssertEqual(viewModel.cardQueue.first?.id, topTerm.id)
    }

    // MARK: - Empty Queue — FR-S-008

    func testEmptyQueueFlagSetWhenQueueExhausted() async throws {
        // Create a viewModel with only one term.
        let singleTermRepo = MockSlangTermRepository(terms: [MockSlangTermRepository.sampleTerms().first!])
        let vm = SwiperViewModel(repository: singleTermRepo, hapticService: MockHapticService())
        vm.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        vm.swipeLeft()

        XCTAssertTrue(vm.isQueueEmpty, "isQueueEmpty should be true when the queue is exhausted.")
    }

    // MARK: - Card Flip — FR-S-004

    func testFlipCardTogglesState() {
        XCTAssertFalse(viewModel.isCardFlipped)
        viewModel.flipCard()
        XCTAssertTrue(viewModel.isCardFlipped)
        viewModel.flipCard()
        XCTAssertFalse(viewModel.isCardFlipped)
    }

    func testSwipeResetsFlipState() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        viewModel.flipCard()
        XCTAssertTrue(viewModel.isCardFlipped)

        viewModel.swipeLeft()
        XCTAssertFalse(viewModel.isCardFlipped, "Swipe should reset flip state.")
    }
}

// MARK: - MockHapticService

private struct MockHapticService: HapticServiceProtocol {
    func swipeCompleted() {}
    func answerCorrect() {}
    func answerIncorrect() {}
    func copySucceeded() {}
    func tierPromotion() {}
    func swipeButtonTapped() {}
}
