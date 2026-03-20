// SlangCheckTests/SearchSlangTermsUseCaseTests.swift
// SlangCheck
//
// Unit tests for SearchSlangTermsUseCase (FR-SR-001 through FR-SR-006).

import XCTest
@testable import SlangCheck

final class SearchSlangTermsUseCaseTests: XCTestCase {

    private var useCase: SearchSlangTermsUseCase!
    private var terms: [SlangTerm]!

    override func setUp() {
        super.setUp()
        useCase = SearchSlangTermsUseCase()
        terms   = MockSlangTermRepository.sampleTerms()
    }

    override func tearDown() {
        useCase = nil
        terms   = nil
        super.tearDown()
    }

    // MARK: - Empty Query

    func testEmptyQueryReturnsAllTerms() {
        let result = useCase.execute(terms: terms, query: "")
        XCTAssertEqual(result.count, terms.count, "Empty query should return all terms unchanged.")
    }

    func testWhitespaceOnlyQueryReturnsAllTerms() {
        let result = useCase.execute(terms: terms, query: "   ")
        XCTAssertEqual(result.count, terms.count, "Whitespace-only query should return all terms.")
    }

    // MARK: - Term Match

    func testExactTermMatchReturnsCorrectResult() {
        let result = useCase.execute(terms: terms, query: "Rizz")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.term, "Rizz")
    }

    func testCaseInsensitiveMatchOnTerm() {
        let result = useCase.execute(terms: terms, query: "rizz")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.term, "Rizz")
    }

    func testPartialTermMatchReturnsResults() {
        // "No Cap" contains "cap", "Cap" is a separate term that also contains "cap"
        let result = useCase.execute(terms: terms, query: "cap")
        XCTAssert(result.contains(where: { $0.term == "No Cap" }), "Partial match should find 'No Cap'.")
    }

    // MARK: - Definition Match (FR-SR-002)

    func testDefinitionMatchReturnsResult() {
        // "Rizz" definition contains "charisma"
        let result = useCase.execute(terms: terms, query: "charisma")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.term, "Rizz")
    }

    func testDefinitionMatchIsCaseInsensitive() {
        let result = useCase.execute(terms: terms, query: "CHARISMA")
        XCTAssertEqual(result.count, 1)
    }

    // MARK: - No Match

    func testNoMatchReturnsEmptyArray() {
        let result = useCase.execute(terms: terms, query: "xyzzy_nonexistent")
        XCTAssertTrue(result.isEmpty, "No match should return an empty array.")
    }

    // MARK: - Multiple Matches

    func testQueryMatchingMultipleTerms() {
        // "mid" appears in definition of "Mid" — search for "mediocre" returns just "Mid"
        let result = useCase.execute(terms: terms, query: "mediocre")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.term, "Mid")
    }

    // MARK: - Empty Input List

    func testEmptyTermsListReturnsEmpty() {
        let result = useCase.execute(terms: [], query: "rizz")
        XCTAssertTrue(result.isEmpty)
    }
}
