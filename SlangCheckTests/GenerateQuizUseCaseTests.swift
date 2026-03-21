// SlangCheckTests/GenerateQuizUseCaseTests.swift
// SlangCheck
//
// Unit tests for GenerateQuizUseCase: session structure, distractor uniqueness,
// question type correctness, notEnoughTerms guard, and question count clamping.

import XCTest
@testable import SlangCheck

// MARK: - Helpers

private func makeTerms(count: Int) -> [SlangTerm] {
    (0..<count).map { i in
        SlangTerm(
            id: UUID(),
            term: "Term\(i)",
            definition: "Definition\(i)",
            standardEnglish: "Word\(i)",
            exampleSentence: "Term\(i) is used here.",
            category: .brainrot,
            origin: "Internet",
            usageFrequency: .high,
            generationTags: [.genZ],
            addedDate: Date(),
            isBrainrot: false,
            isEmojiTerm: false
        )
    }
}

// MARK: - GenerateQuizUseCaseTests

final class GenerateQuizUseCaseTests: XCTestCase {

    // MARK: - Not Enough Terms

    func testThrowsNotEnoughTermsWhenFewerThanMinimum() async {
        let repo    = MockSlangTermRepository(terms: makeTerms(count: 3))
        let useCase = GenerateQuizUseCase(repository: repo)

        do {
            _ = try await useCase.execute()
            XCTFail("Expected GenerateQuizError.notEnoughTerms to be thrown.")
        } catch GenerateQuizError.notEnoughTerms {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSucceedsWithExactlyMinimumTermCount() async throws {
        let repo    = MockSlangTermRepository(terms: makeTerms(count: GenerateQuizUseCase.minimumTermCount))
        let useCase = GenerateQuizUseCase(repository: repo)
        let session = try await useCase.execute(questionCount: 1)
        XCTAssertEqual(session.questions.count, 1)
    }

    // MARK: - Question Count

    func testDefaultQuestionCountConstantIs10() {
        XCTAssertEqual(GenerateQuizUseCase.defaultQuestionCount, 10)
    }

    func testGeneratesRequestedQuestionCount() async throws {
        let repo    = MockSlangTermRepository(terms: makeTerms(count: 20))
        let useCase = GenerateQuizUseCase(repository: repo)
        let session = try await useCase.execute(questionCount: 5)
        XCTAssertEqual(session.questions.count, 5)
    }

    func testClampsQuestionCountToDictionarySize() async throws {
        let termCount = 6
        let repo      = MockSlangTermRepository(terms: makeTerms(count: termCount))
        let useCase   = GenerateQuizUseCase(repository: repo)
        let session   = try await useCase.execute(questionCount: 100)
        XCTAssertEqual(session.questions.count, termCount)
    }

    // MARK: - Distractor Uniqueness

    func testEachQuestionHasFourUniqueChoices() async throws {
        let repo    = MockSlangTermRepository(terms: makeTerms(count: 10))
        let useCase = GenerateQuizUseCase(repository: repo)
        let session = try await useCase.execute(questionCount: 10)

        for question in session.questions {
            let choices = question.allChoices
            XCTAssertEqual(choices.count, 4, "Expected 4 choices per question.")
            XCTAssertEqual(Set(choices).count, 4, "All choices must be unique.")
        }
    }

    func testCorrectAnswerAppearsInChoices() async throws {
        let repo    = MockSlangTermRepository(terms: makeTerms(count: 10))
        let useCase = GenerateQuizUseCase(repository: repo)
        let session = try await useCase.execute(questionCount: 10)

        for question in session.questions {
            XCTAssertTrue(
                question.allChoices.contains(question.correctAnswer),
                "Correct answer '\(question.correctAnswer)' not found in choices."
            )
        }
    }

    func testDistractorsDoNotEqualCorrectAnswer() async throws {
        let repo    = MockSlangTermRepository(terms: makeTerms(count: 10))
        let useCase = GenerateQuizUseCase(repository: repo)
        let session = try await useCase.execute(questionCount: 10)

        for question in session.questions {
            let distractors = question.allChoices.filter { $0 != question.correctAnswer }
            XCTAssertEqual(distractors.count, 3, "Expected exactly 3 distractors.")
            for d in distractors {
                XCTAssertNotEqual(d, question.correctAnswer,
                                  "Distractor must not equal the correct answer.")
            }
        }
    }

    // MARK: - Session Structure

    func testSessionHasNonNilID() async throws {
        let repo    = MockSlangTermRepository(terms: makeTerms(count: 10))
        let useCase = GenerateQuizUseCase(repository: repo)
        let session = try await useCase.execute()
        XCTAssertNotNil(session.id)
    }

    func testSessionStartedAtIsRecentlySet() async throws {
        let before  = Date()
        let repo    = MockSlangTermRepository(terms: makeTerms(count: 10))
        let useCase = GenerateQuizUseCase(repository: repo)
        let session = try await useCase.execute()
        XCTAssertGreaterThanOrEqual(session.startedAt, before)
        XCTAssertLessThanOrEqual(session.startedAt, Date())
    }

    // MARK: - Question Type Correctness

    func testDefinitionPickCorrectAnswerIsDefinition() async throws {
        let repo    = MockSlangTermRepository(terms: makeTerms(count: 10))
        let useCase = GenerateQuizUseCase(repository: repo)

        var found = false
        for _ in 0..<20 {
            let session = try await useCase.execute(questionCount: 10)
            for q in session.questions where q.type == .definitionPick {
                XCTAssertEqual(q.correctAnswer, q.correctDefinition)
                found = true
            }
        }
        XCTAssertTrue(found, "Should have generated at least one .definitionPick question.")
    }

    func testTermPickCorrectAnswerIsTerm() async throws {
        let repo    = MockSlangTermRepository(terms: makeTerms(count: 10))
        let useCase = GenerateQuizUseCase(repository: repo)

        var found = false
        for _ in 0..<20 {
            let session = try await useCase.execute(questionCount: 10)
            for q in session.questions where q.type == .termPick {
                XCTAssertEqual(q.correctAnswer, q.term)
                found = true
            }
        }
        XCTAssertTrue(found, "Should have generated at least one .termPick question.")
    }

    func testFillInBlankCorrectAnswerIsTerm() async throws {
        let repo    = MockSlangTermRepository(terms: makeTerms(count: 10))
        let useCase = GenerateQuizUseCase(repository: repo)

        var found = false
        for _ in 0..<20 {
            let session = try await useCase.execute(questionCount: 10)
            for q in session.questions where q.type == .fillInBlank {
                XCTAssertEqual(q.correctAnswer, q.term)
                found = true
            }
        }
        XCTAssertTrue(found, "Should have generated at least one .fillInBlank question.")
    }
}
