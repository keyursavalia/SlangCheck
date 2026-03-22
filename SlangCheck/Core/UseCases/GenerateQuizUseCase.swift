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
/// When an ``AIQuizGenerationService`` is provided, each question is enhanced
/// with a freshly generated example sentence and AI-authored definition distractors
/// (for `.definitionPick` only). Term-pool distractors remain glossary-sourced for
/// `.termPick` and `.fillInBlank` — real slang exposure is more pedagogically useful
/// than AI-invented fake term names.
///
/// Choices inside each `QuizQuestion` are in deterministic order (`allChoices`);
/// the ViewModel shuffles them before display.
public struct GenerateQuizUseCase: Sendable {

    // MARK: - Configuration

    /// Default number of questions per session.
    public static let defaultQuestionCount: Int = 10

    /// Minimum dictionary size required to generate distractors.
    static let minimumTermCount: Int = 4

    // MARK: - Dependencies

    private let repository: any SlangTermRepository

    /// Optional Apple Intelligence service. `nil` on iOS < 26 or when AI is disabled.
    private let aiService: (any AIQuizGenerationService)?

    // MARK: - Initialization

    /// - Parameters:
    ///   - repository: Slang term data source.
    ///   - aiService:  Apple Intelligence quiz enhancer. Pass `nil` for static-only generation.
    public init(repository: any SlangTermRepository, aiService: (any AIQuizGenerationService)? = nil) {
        self.repository = repository
        self.aiService  = aiService
    }

    // MARK: - Execute

    /// Generates and returns a `QuizSession` containing `questionCount` questions.
    ///
    /// When `aiService` is set, questions are built in parallel using `withTaskGroup`.
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

        // Build questions in parallel so AI calls don't run serially.
        let questions = await withTaskGroup(of: QuizQuestion.self, returning: [QuizQuestion].self) { group in
            for term in selected {
                group.addTask { await makeQuestion(for: term, pool: allTerms) }
            }
            var results: [QuizQuestion] = []
            for await q in group { results.append(q) }
            return results
        }

        Logger.quizzes.debug("GenerateQuizUseCase: generated \(questions.count) questions.")
        return QuizSession(questions: questions)
    }

    // MARK: - Private

    private func makeQuestion(for term: SlangTerm, pool: [SlangTerm]) async -> QuizQuestion {
        let type = QuestionType.allCases.randomElement() ?? .definitionPick

        // Pick 3 unique distractor terms that are not the current term (static pool).
        let distractorTerms = pool
            .filter { $0.id != term.id }
            .shuffled()
            .prefix(3)

        // Attempt AI enhancement (fresh sentence + AI distractors for definitionPick).
        let enhancement = await aiService?.enhance(term: term, allTerms: pool, questionType: type)

        let exampleSentence = enhancement?.exampleSentence ?? term.exampleSentence

        let distractors: [String]
        switch type {
        case .definitionPick:
            // Prefer AI-generated wrong definitions; fall back to pool definitions.
            distractors = enhancement?.definitionDistractors ?? distractorTerms.map(\.definition)
        case .termPick, .fillInBlank:
            // Always use real glossary term names — AI-invented fake terms are less useful.
            distractors = distractorTerms.map(\.term)
        }

        return QuizQuestion(
            termID:            term.id,
            term:              term.term,
            correctDefinition: term.definition,
            exampleSentence:   exampleSentence,
            distractors:       Array(distractors),
            type:              type
        )
    }
}
