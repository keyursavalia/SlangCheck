// Core/UseCases/GenerateQuizUseCase.swift
// SlangCheck
//
// Generates a QuizSession by sampling random terms from the local dictionary
// and constructing four-choice questions with the correct answer plus three
// distractors drawn from other terms.

import Foundation
import OSLog

// MARK: - GenerateQuizError

/// Errors thrown by `GenerateQuizUseCase`.
public enum GenerateQuizError: LocalizedError, Sendable {
    /// The dictionary has fewer than 4 terms — distractors cannot be generated.
    case notEnoughTerms

    public var errorDescription: String? {
        String(localized: "quiz.error.notEnoughTerms",
               defaultValue: "Not enough terms to generate a quiz. Try again later.")
    }
}

// MARK: - GenerateQuizUseCase

/// Builds a shuffled `QuizSession` from the local slang dictionary.
///
/// Each question is one of three types (randomly assigned):
/// - `.definitionPick` — given the term, choose the correct definition.
/// - `.termPick`       — given the definition, choose the correct term.
/// - `.fillInBlank`    — complete the example sentence with the correct term.
///
/// Distractors are sampled from other terms in the dictionary and are unique
/// per question. Choices inside each `QuizQuestion` are in deterministic order
/// (`allChoices`); the ViewModel shuffles them before display.
public struct GenerateQuizUseCase: Sendable {

    // MARK: - Configuration

    /// Default number of questions per session.
    public static let defaultQuestionCount: Int = 10

    /// Minimum dictionary size required to generate distractors.
    static let minimumTermCount: Int = 4

    // MARK: - Dependencies

    private let repository: any SlangTermRepository

    // MARK: - Initialization

    public init(repository: any SlangTermRepository) {
        self.repository = repository
    }

    // MARK: - Execute

    /// Generates and returns a `QuizSession` containing `questionCount` questions.
    ///
    /// - Parameter questionCount: Number of questions to generate. Clamped to the
    ///   dictionary size when the dictionary is smaller than the requested count.
    /// - Throws: `GenerateQuizError.notEnoughTerms` if the dictionary has fewer
    ///   than `minimumTermCount` entries.
    public func execute(
        questionCount: Int = GenerateQuizUseCase.defaultQuestionCount
    ) async throws -> QuizSession {
        let allTerms = try await repository.fetchAllTerms()

        guard allTerms.count >= Self.minimumTermCount else {
            Logger.quizzes.error("GenerateQuizUseCase: only \(allTerms.count) terms available.")
            throw GenerateQuizError.notEnoughTerms
        }

        let count    = Swift.min(questionCount, allTerms.count)
        let selected = Array(allTerms.shuffled().prefix(count))
        let questions = selected.map { term in
            makeQuestion(for: term, pool: allTerms)
        }

        Logger.quizzes.debug("GenerateQuizUseCase: generated \(questions.count) questions.")
        return QuizSession(questions: questions)
    }

    // MARK: - Private

    private func makeQuestion(for term: SlangTerm, pool: [SlangTerm]) -> QuizQuestion {
        let type = QuestionType.allCases.randomElement() ?? .definitionPick

        // Pick 3 unique distractor terms that are not the current term.
        let distractorTerms = pool
            .filter { $0.id != term.id }
            .shuffled()
            .prefix(3)

        let distractors: [String]
        switch type {
        case .definitionPick:
            distractors = distractorTerms.map(\.definition)
        case .termPick, .fillInBlank:
            distractors = distractorTerms.map(\.term)
        }

        return QuizQuestion(
            termID:            term.id,
            term:              term.term,
            correctDefinition: term.definition,
            exampleSentence:   term.exampleSentence,
            distractors:       Array(distractors),
            type:              type
        )
    }
}
