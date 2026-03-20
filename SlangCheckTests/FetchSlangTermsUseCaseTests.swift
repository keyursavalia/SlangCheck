// SlangCheckTests/FetchSlangTermsUseCaseTests.swift
// SlangCheck
//
// Unit tests for FetchSlangTermsUseCase: category filtering, swiper queue building.

import XCTest
@testable import SlangCheck

final class FetchSlangTermsUseCaseTests: XCTestCase {

    private var repository: MockSlangTermRepository!
    private var useCase: FetchSlangTermsUseCase!

    override func setUp() {
        super.setUp()
        repository = MockSlangTermRepository()
        useCase    = FetchSlangTermsUseCase(repository: repository)
    }

    override func tearDown() {
        useCase    = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - fetchAllGrouped

    func testFetchAllGroupedReturnsGroupedByFirstLetter() async throws {
        let grouped = try await useCase.fetchAllGrouped()
        XCTAssertFalse(grouped.isEmpty)
        // Each group key should be a single letter matching the first character of its terms.
        for (letter, terms) in grouped {
            for term in terms {
                XCTAssertEqual(term.firstLetter, letter, "Term '\(term.term)' grouped under wrong letter.")
            }
        }
    }

    // MARK: - fetchByCategory

    func testFetchByCategoryNilReturnsAllTerms() async throws {
        let result = try await useCase.fetchByCategory(nil)
        XCTAssertEqual(result.count, repository.terms.count)
    }

    func testFetchByCategoryFiltersCorrectly() async throws {
        let result = try await useCase.fetchByCategory(.brainrot)
        XCTAssertTrue(result.allSatisfy { $0.category == .brainrot })
    }

    func testFetchByCategoryIsSortedAlphabetically() async throws {
        let result = try await useCase.fetchByCategory(nil)
        let names  = result.map(\.term)
        XCTAssertEqual(names, names.sorted())
    }

    // MARK: - fetchSwiperQueue

    func testSwiperQueueExcludesSavedTerms() async throws {
        let allTerms  = MockSlangTermRepository.sampleTerms()
        let savedTerm = allTerms[0]
        let lexicon   = UserLexicon(entries: [LexiconEntry(termID: savedTerm.id, savedDate: Date())])

        let queue = try await useCase.fetchSwiperQueue(lexicon: lexicon)

        XCTAssertFalse(queue.contains(where: { $0.id == savedTerm.id }),
                       "Swiper queue must not contain already-saved terms (FR-S-007).")
    }

    func testSwiperQueueHighFrequencyTermsAppearFirst() async throws {
        let queue = try await useCase.fetchSwiperQueue(lexicon: UserLexicon())

        // Find the first medium or low frequency term.
        let firstNonHigh = queue.firstIndex(where: { $0.usageFrequency != .high })
        let lastHigh     = queue.lastIndex(where: { $0.usageFrequency == .high })

        if let firstNonHigh, let lastHigh {
            XCTAssertGreaterThan(
                firstNonHigh, lastHigh,
                "High-frequency terms should all appear before medium/low/emerging terms."
            )
        }
    }

    func testSwiperQueueIsNonEmptyWhenTermsExist() async throws {
        let queue = try await useCase.fetchSwiperQueue(lexicon: UserLexicon())
        XCTAssertFalse(queue.isEmpty)
    }
}
