// SlangCheckTests/QuizQuestionTests.swift
// SlangCheck
//
// Unit tests for QuizQuestion: allChoices, correctAnswer, sentenceWithBlank,
// and QuizSession invariants.

import XCTest
@testable import SlangCheck

final class QuizQuestionTests: XCTestCase {

    // MARK: - Helpers

    private func makeQuestion(type: QuestionType = .definitionPick) -> QuizQuestion {
        QuizQuestion(
            termID: UUID(),
            term: "No Cap",
            correctDefinition: "Truthful; no lie.",
            exampleSentence: "No Cap, that was the best meal I've ever had.",
            distractors: ["Cool; excellent.", "Sad; disappointed.", "Very tired or worn out."],
            type: type
        )
    }

    // MARK: - allChoices

    func testDefinitionPickAllChoicesContainsCorrectDefinition() {
        let q = makeQuestion(type: .definitionPick)
        XCTAssertTrue(q.allChoices.contains("Truthful; no lie."))
    }

    func testDefinitionPickAllChoicesCountIsFour() {
        let q = makeQuestion(type: .definitionPick)
        XCTAssertEqual(q.allChoices.count, 4)
    }

    func testTermPickAllChoicesContainsTerm() {
        let q = makeQuestion(type: .termPick)
        XCTAssertTrue(q.allChoices.contains("No Cap"))
    }

    func testFillInBlankAllChoicesContainsTerm() {
        let q = makeQuestion(type: .fillInBlank)
        XCTAssertTrue(q.allChoices.contains("No Cap"))
    }

    // MARK: - correctAnswer

    func testCorrectAnswerForDefinitionPickIsDefinition() {
        let q = makeQuestion(type: .definitionPick)
        XCTAssertEqual(q.correctAnswer, "Truthful; no lie.")
    }

    func testCorrectAnswerForTermPickIsTerm() {
        let q = makeQuestion(type: .termPick)
        XCTAssertEqual(q.correctAnswer, "No Cap")
    }

    func testCorrectAnswerForFillInBlankIsTerm() {
        let q = makeQuestion(type: .fillInBlank)
        XCTAssertEqual(q.correctAnswer, "No Cap")
    }

    // MARK: - sentenceWithBlank

    func testSentenceWithBlankReplacesTermWithUnderscores() {
        let q = makeQuestion(type: .fillInBlank)
        let blanked = q.sentenceWithBlank
        XCTAssertFalse(blanked.lowercased().contains("no cap"),
                       "Term should be replaced by underscores.")
        XCTAssertTrue(blanked.contains("______"),
                      "Expected 6-character blank for 'No Cap'.")
    }

    func testSentenceWithBlankPreservesRestOfSentence() {
        let q = makeQuestion(type: .fillInBlank)
        let blanked = q.sentenceWithBlank
        XCTAssertTrue(blanked.contains("that was the best meal"))
    }

    // MARK: - QuizSession

    func testQuizSessionQuestionCount() {
        let questions = (0..<5).map { _ in makeQuestion() }
        let session = QuizSession(questions: questions)
        XCTAssertEqual(session.questionCount, 5)
    }

    func testQuizSessionHasStableID() {
        let id = UUID()
        let session = QuizSession(id: id, questions: [makeQuestion()])
        XCTAssertEqual(session.id, id)
    }
}
