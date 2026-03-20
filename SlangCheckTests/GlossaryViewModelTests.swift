// SlangCheckTests/GlossaryViewModelTests.swift
// SlangCheck
//
// Unit tests for GlossaryViewModel: search filtering, category filter, sort order.

import XCTest
@testable import SlangCheck

@MainActor
final class GlossaryViewModelTests: XCTestCase {

    private var repository: MockSlangTermRepository!
    private var viewModel: GlossaryViewModel!

    override func setUp() async throws {
        try await super.setUp()
        repository = MockSlangTermRepository()
        viewModel  = GlossaryViewModel(repository: repository)
    }

    override func tearDown() async throws {
        viewModel  = nil
        repository = nil
        try await super.tearDown()
    }

    // MARK: - Initial Load

    func testOnAppearLoadsTerms() async throws {
        viewModel.onAppear()
        // Give the Task a moment to complete.
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(viewModel.allTerms.isEmpty, "Terms should be loaded after onAppear.")
    }

    func testTermsAreSortedAlphabetically() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        let termNames = viewModel.allTerms.map(\.term)
        let sorted    = termNames.sorted()
        XCTAssertEqual(termNames, sorted, "Terms should be sorted alphabetically.")
    }

    // MARK: - Search (FR-SR-001 through FR-SR-006)

    func testEmptySearchShowsAllTerms() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        viewModel.searchQuery = ""
        // Allow debounce to settle.
        try await Task.sleep(for: .milliseconds(400))

        XCTAssertEqual(viewModel.displayedTerms.count, viewModel.allTerms.count)
    }

    func testSearchFiltersCorrectly() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        viewModel.searchQuery = "charisma"
        try await Task.sleep(for: .milliseconds(400))

        XCTAssertEqual(viewModel.displayedTerms.count, 1)
        XCTAssertEqual(viewModel.displayedTerms.first?.term, "Rizz")
    }

    func testSearchIsCaseInsensitive() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        viewModel.searchQuery = "RIZZ"
        try await Task.sleep(for: .milliseconds(400))

        XCTAssertFalse(viewModel.displayedTerms.isEmpty)
        XCTAssertTrue(viewModel.displayedTerms.contains(where: { $0.term == "Rizz" }))
    }

    func testNoSearchResultsShowsEmptyDisplayedTerms() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        viewModel.searchQuery = "xyzzy_nonexistent_12345"
        try await Task.sleep(for: .milliseconds(400))

        XCTAssertTrue(viewModel.displayedTerms.isEmpty)
    }

    // MARK: - Category Filter (FR-GL-007, FR-GL-008)

    func testCategoryFilterShowsOnlyMatchingTerms() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        viewModel.selectedCategory = .brainrot
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(
            viewModel.allTerms.allSatisfy { $0.category == .brainrot },
            "All displayed terms should be in the selected category."
        )
    }

    func testNilCategoryShowsAllTerms() async throws {
        viewModel.selectedCategory = .brainrot
        try await Task.sleep(for: .milliseconds(100))

        viewModel.selectedCategory = nil
        try await Task.sleep(for: .milliseconds(100))

        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(200))

        // After resetting to nil, all terms should be present.
        XCTAssertEqual(viewModel.allTerms.count, repository.terms.count)
    }

    // MARK: - Section Headers

    func testSectionHeadersAreAlphabeticallySorted() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        let sorted = viewModel.sectionHeaders.sorted()
        XCTAssertEqual(viewModel.sectionHeaders, sorted, "Section headers should be sorted A-Z.")
    }

    func testGroupedTermsMatchSectionHeaders() async throws {
        viewModel.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        for header in viewModel.sectionHeaders {
            XCTAssertNotNil(viewModel.groupedTerms[header], "Each header should have a corresponding group.")
        }
    }
}
