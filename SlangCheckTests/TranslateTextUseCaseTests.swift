// SlangCheckTests/TranslateTextUseCaseTests.swift
// SlangCheck
//
// Unit tests for TranslateTextUseCase: genZ→standard and standard→genZ
// translation, multi-term sentences, edge cases, and error propagation.

import XCTest
@testable import SlangCheck

final class TranslateTextUseCaseTests: XCTestCase {

    private var repository: MockSlangTermRepository!
    private var useCase: TranslateTextUseCase!

    override func setUp() {
        super.setUp()
        repository = MockSlangTermRepository()
        useCase    = TranslateTextUseCase(repository: repository)
    }

    override func tearDown() {
        useCase    = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Edge Cases

    func testEmptyInputReturnsEmptyResult() async throws {
        let result = try await useCase.translate(text: "", direction: .genZToStandard)
        XCTAssertTrue(result.substitutions.isEmpty)
        XCTAssertEqual(result.translatedText, "")
    }

    func testWhitespaceOnlyInputPassesThroughUnchanged() async throws {
        let result = try await useCase.translate(text: "   ", direction: .genZToStandard)
        XCTAssertTrue(result.substitutions.isEmpty)
        XCTAssertEqual(result.translatedText, "   ")
    }

    func testUnknownTermPassesThroughUnchanged() async throws {
        let input  = "This phrase contains no known slang terms whatsoever."
        let result = try await useCase.translate(text: input, direction: .genZToStandard)
        XCTAssertEqual(result.translatedText, input)
        XCTAssertTrue(result.substitutions.isEmpty)
    }

    // MARK: - GenZ → Standard

    func testGenZToStandardReplacesSingleKnownTerm() async throws {
        // "Mid" → "Average"
        let result = try await useCase.translate(text: "That movie was so mid.", direction: .genZToStandard)
        XCTAssertTrue(
            result.translatedText.localizedCaseInsensitiveContains("Average"),
            "Expected 'Average' in output, got: \(result.translatedText)"
        )
        XCTAssertEqual(result.substitutions.count, 1)
    }

    func testGenZToStandardIsCaseInsensitive() async throws {
        let lower = try await useCase.translate(text: "mid", direction: .genZToStandard)
        let upper = try await useCase.translate(text: "MID", direction: .genZToStandard)
        XCTAssertEqual(
            lower.translatedText.lowercased(),
            upper.translatedText.lowercased(),
            "Translation should be case-insensitive."
        )
    }

    func testGenZToStandardTranslatesMultipleTermsInOneSentence() async throws {
        // "No Cap" → "Honestly", "mid" → "Average"
        let result = try await useCase.translate(
            text: "No cap, that film was mid.",
            direction: .genZToStandard
        )
        XCTAssertTrue(
            result.translatedText.localizedCaseInsensitiveContains("Honestly"),
            "Expected 'Honestly' from 'No cap'. Output: \(result.translatedText)"
        )
        XCTAssertTrue(
            result.translatedText.localizedCaseInsensitiveContains("Average"),
            "Expected 'Average' from 'mid'. Output: \(result.translatedText)"
        )
        XCTAssertEqual(result.substitutions.count, 2)
    }

    func testRepeatedTermCountsAsOneSubstitutionRecord() async throws {
        // "mid" appears twice — one substitution record, both occurrences replaced.
        let result = try await useCase.translate(
            text: "That was mid and I mean mid.",
            direction: .genZToStandard
        )
        XCTAssertEqual(result.substitutions.count, 1)

        let avgCount = result.translatedText
            .components(separatedBy: " ")
            .filter { $0.localizedCaseInsensitiveContains("Average") }
            .count
        XCTAssertEqual(avgCount, 2, "Both occurrences of 'mid' should be translated.")
    }

    func testWordBoundaryPreventesPartialMatches() async throws {
        // "midterm" contains "mid" but should NOT be matched — \b enforces word boundary.
        let result = try await useCase.translate(text: "I have a midterm exam.", direction: .genZToStandard)
        XCTAssertTrue(
            result.translatedText.contains("midterm"),
            "Word boundary regex must not match 'mid' inside 'midterm'."
        )
        XCTAssertTrue(result.substitutions.isEmpty)
    }

    // MARK: - Standard → GenZ

    func testStandardToGenZReplacesSingleKnownMeaning() async throws {
        // "Charisma" → "Rizz"
        let result = try await useCase.translate(text: "He has a lot of Charisma.", direction: .standardToGenZ)
        XCTAssertTrue(
            result.translatedText.localizedCaseInsensitiveContains("Rizz"),
            "Expected 'Rizz' in output, got: \(result.translatedText)"
        )
        XCTAssertEqual(result.substitutions.count, 1)
    }

    func testStandardToGenZIsCaseInsensitive() async throws {
        let result = try await useCase.translate(text: "average performance", direction: .standardToGenZ)
        XCTAssertTrue(
            result.translatedText.localizedCaseInsensitiveContains("Mid"),
            "Expected 'Mid' from 'average'. Output: \(result.translatedText)"
        )
    }

    // MARK: - Result Metadata

    func testResultDirectionMatchesInput() async throws {
        let result = try await useCase.translate(text: "rizz", direction: .genZToStandard)
        XCTAssertEqual(result.direction, .genZToStandard)
    }

    func testResultOriginalTextIsPreserved() async throws {
        let input  = "No cap that party was bussin'."
        let result = try await useCase.translate(text: input, direction: .genZToStandard)
        XCTAssertEqual(result.originalText, input)
    }

    // MARK: - Error Propagation

    func testRepositoryFetchErrorPropagates() async {
        repository.shouldThrowOnFetch = true
        do {
            _ = try await useCase.translate(text: "rizz", direction: .genZToStandard)
            XCTFail("Expected throw from failing repository.")
        } catch {
            // Expected — test passes.
        }
    }
}
