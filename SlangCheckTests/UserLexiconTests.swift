// SlangCheckTests/UserLexiconTests.swift
// SlangCheck
//
// Unit tests for the UserLexicon value type and LexiconEntry model.

import XCTest
@testable import SlangCheck

final class UserLexiconTests: XCTestCase {

    private let termA = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    private let termB = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!

    // MARK: - Initialization

    func testEmptyLexiconHasZeroCount() {
        let lexicon = UserLexicon()
        XCTAssertEqual(lexicon.count, 0)
    }

    func testInitWithEntriesSortsMostRecentFirst() {
        let older = LexiconEntry(termID: termA, savedDate: Date().addingTimeInterval(-100))
        let newer = LexiconEntry(termID: termB, savedDate: Date())
        let lexicon = UserLexicon(entries: [older, newer])

        XCTAssertEqual(lexicon.entries.first?.termID, termB, "Most recent entry should be first.")
    }

    // MARK: - Saving

    func testSavingTermAddsToLexicon() {
        let lexicon = UserLexicon().saving(termID: termA)
        XCTAssertTrue(lexicon.contains(termID: termA))
        XCTAssertEqual(lexicon.count, 1)
    }

    func testSavingAlreadySavedTermIsNoOp() {
        let once  = UserLexicon().saving(termID: termA)
        let twice = once.saving(termID: termA)
        XCTAssertEqual(twice.count, 1, "Saving a duplicate term should not increase count.")
    }

    func testSavingMultipleTermsIncrementsCount() {
        let lexicon = UserLexicon()
            .saving(termID: termA)
            .saving(termID: termB)
        XCTAssertEqual(lexicon.count, 2)
    }

    // MARK: - Removing

    func testRemovingTermDecreasesCount() {
        let lexicon = UserLexicon()
            .saving(termID: termA)
            .removing(termID: termA)
        XCTAssertEqual(lexicon.count, 0)
        XCTAssertFalse(lexicon.contains(termID: termA))
    }

    func testRemovingNonExistentTermIsNoOp() {
        let lexicon = UserLexicon().saving(termID: termA).removing(termID: termB)
        XCTAssertEqual(lexicon.count, 1)
    }

    // MARK: - Contains

    func testContainsReturnsFalseForUnsavedTerm() {
        let lexicon = UserLexicon()
        XCTAssertFalse(lexicon.contains(termID: termA))
    }

    func testContainsReturnsTrueForSavedTerm() {
        let lexicon = UserLexicon().saving(termID: termA)
        XCTAssertTrue(lexicon.contains(termID: termA))
    }

    // MARK: - savedTermIDs

    func testSavedTermIDsContainsAllSavedIDs() {
        let lexicon = UserLexicon()
            .saving(termID: termA)
            .saving(termID: termB)
        XCTAssertTrue(lexicon.savedTermIDs.contains(termA))
        XCTAssertTrue(lexicon.savedTermIDs.contains(termB))
    }

    // MARK: - Immutability (value semantics)

    func testSavingProducesNewValueWithoutMutatingOriginal() {
        let original = UserLexicon()
        let modified = original.saving(termID: termA)
        XCTAssertEqual(original.count, 0, "Original should be unchanged.")
        XCTAssertEqual(modified.count, 1)
    }
}
