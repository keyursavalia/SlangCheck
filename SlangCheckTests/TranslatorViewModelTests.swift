// SlangCheckTests/TranslatorViewModelTests.swift
// SlangCheck
//
// Unit tests for TranslatorViewModel: initial state, debounce, direction swap,
// clear, and error state.

import XCTest
@testable import SlangCheck

// MARK: - MockHapticService

private final class MockHapticService: HapticServiceProtocol, @unchecked Sendable {
    func swipeCompleted()   {}
    func answerCorrect()    {}
    func answerIncorrect()  {}
    func copySucceeded()    {}
    func tierPromotion()    {}
    func swipeButtonTapped() {}
}

// MARK: - TranslatorViewModelTests

@MainActor
final class TranslatorViewModelTests: XCTestCase {

    private var repository: MockSlangTermRepository!
    private var viewModel: TranslatorViewModel!

    override func setUp() {
        super.setUp()
        repository = MockSlangTermRepository()
        let service = LocalTranslationService(repository: repository, aiService: NoOpAITranslationService())
        viewModel   = TranslatorViewModel(translationService: service, hapticService: MockHapticService())
    }

    override func tearDown() {
        viewModel   = nil
        repository  = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialStateIsEmpty() {
        XCTAssertTrue(viewModel.inputText.isEmpty)
        XCTAssertNil(viewModel.result)
        XCTAssertFalse(viewModel.isTranslating)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.direction, .genZToStandard)
    }

    // MARK: - Clear

    func testClearResetsAllState() async throws {
        viewModel.inputText = "mid"
        try await Task.sleep(for: .milliseconds(600))   // wait for debounce
        viewModel.clear()
        XCTAssertTrue(viewModel.inputText.isEmpty)
        XCTAssertNil(viewModel.result)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testEmptyInputAfterClearYieldsNilResult() {
        viewModel.inputText = ""
        XCTAssertNil(viewModel.result)
    }

    // MARK: - Debounce & Translation

    func testTranslationProducesResultAfterDebounce() async throws {
        viewModel.inputText = "mid"
        // 400ms debounce + generous buffer for async translation.
        try await Task.sleep(for: .milliseconds(700))
        XCTAssertNotNil(viewModel.result, "Result should be populated after debounce + translation.")
    }

    func testRapidInputChangesProduceOnlyOneTranslation() async throws {
        // Simulates fast typing — only the last value should be translated.
        viewModel.inputText = "r"
        viewModel.inputText = "ri"
        viewModel.inputText = "riz"
        viewModel.inputText = "rizz"
        try await Task.sleep(for: .milliseconds(700))
        // Result should be for "rizz", not intermediate states.
        XCTAssertNotNil(viewModel.result)
    }

    // MARK: - Direction

    func testSwapDirectionTogglesDirection() {
        XCTAssertEqual(viewModel.direction, .genZToStandard)
        viewModel.swapDirection()
        XCTAssertEqual(viewModel.direction, .standardToGenZ)
        viewModel.swapDirection()
        XCTAssertEqual(viewModel.direction, .genZToStandard)
    }

    func testSwapDirectionLoadsOutputAsInput() async throws {
        viewModel.inputText = "mid"
        try await Task.sleep(for: .milliseconds(700))
        let outputText = viewModel.result?.translatedText ?? ""
        XCTAssertFalse(outputText.isEmpty, "Must have a translation before swap.")
        viewModel.swapDirection()
        XCTAssertEqual(viewModel.inputText, outputText, "Input after swap should equal previous output.")
    }

    func testSwapWithNoResultOnlyTogglesDirection() {
        XCTAssertNil(viewModel.result)
        viewModel.swapDirection()
        XCTAssertEqual(viewModel.direction, .standardToGenZ)
        XCTAssertTrue(viewModel.inputText.isEmpty, "Input must not change when there is no result.")
    }

    // MARK: - Error State

    func testFetchFailureSetsErrorMessage() async throws {
        repository.shouldThrowOnFetch = true
        viewModel.inputText = "rizz"
        try await Task.sleep(for: .milliseconds(700))
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set on repository failure.")
        XCTAssertNil(viewModel.result, "Result should remain nil on failure.")
    }
}
