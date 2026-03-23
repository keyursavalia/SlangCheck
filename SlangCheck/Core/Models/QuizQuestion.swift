// Core/Models/QuizQuestion.swift
// SlangCheck
//
// Models for the Quiz feature (Iteration 3).
// Zero UIKit/SwiftUI/CoreData imports — platform-agnostic.

import Foundation

// MARK: - QuestionType

/// The format of a quiz question. Controls how the question stem and answers are rendered.
public enum QuestionType: String, Codable, CaseIterable, Sendable {

    /// Given the slang term, choose the correct definition from four options.
    case definitionPick = "definition_pick"

    /// Given the definition, choose the correct slang term from four options.
    case termPick       = "term_pick"

    /// Given an example sentence with the slang term redacted, choose the correct term.
    case fillInBlank    = "fill_in_blank"
}

// MARK: - QuizQuestion

/// A single multiple-choice question in a quiz session.
///
/// Each question has exactly one correct answer and three distractors, always
/// presented together as `allChoices` in a shuffled order.  The caller is
/// responsible for the shuffle so the order is deterministic during testing.
public struct QuizQuestion: Codable, Identifiable, Hashable, Sendable {

    // MARK: Properties

    /// Stable UUID for this question. Unique per generated quiz session.
    public let id: UUID

    /// The `SlangTerm.id` that this question is testing.
    public let termID: UUID

    /// The slang term string (e.g., "No Cap").
    public let term: String

    /// The correct definition for this question.
    public let correctDefinition: String

    /// The example sentence for this term, used in `.fillInBlank` questions.
    /// The term itself should be replaced with a placeholder before display.
    public let exampleSentence: String

    /// Three plausible-but-incorrect answer strings.
    /// For `.definitionPick`: incorrect definitions.
    /// For `.termPick`: incorrect term strings.
    /// For `.fillInBlank`: incorrect term strings to fill the blank.
    public let distractors: [String]

    /// The format of this question.
    public let type: QuestionType

    /// The thematic category of the term being tested.
    /// Used by `AuraScoringEngine` to award category bonus points for premium categories.
    public let category: SlangCategory

    // MARK: Initialization

    public init(
        id: UUID = UUID(),
        termID: UUID,
        term: String,
        correctDefinition: String,
        exampleSentence: String,
        distractors: [String],
        type: QuestionType,
        category: SlangCategory
    ) {
        precondition(distractors.count == 3, "QuizQuestion must have exactly 3 distractors.")
        self.id                = id
        self.termID            = termID
        self.term              = term
        self.correctDefinition = correctDefinition
        self.exampleSentence   = exampleSentence
        self.distractors       = distractors
        self.type              = type
        self.category          = category
    }

    // MARK: Derived

    /// All four answer choices: the correct answer plus the three distractors.
    /// The order is deterministic — callers must shuffle for display.
    public var allChoices: [String] {
        switch type {
        case .definitionPick:
            return [correctDefinition] + distractors
        case .termPick, .fillInBlank:
            return [term] + distractors
        }
    }

    /// The correct answer string for validation against a user's selection.
    public var correctAnswer: String {
        switch type {
        case .definitionPick:
            return correctDefinition
        case .termPick, .fillInBlank:
            return term
        }
    }

    /// The example sentence with the slang term replaced by a blank placeholder.
    /// Used as the question stem for `.fillInBlank` questions.
    public var sentenceWithBlank: String {
        exampleSentence.replacingOccurrences(
            of: term,
            with: String(repeating: "_", count: term.count),
            options: .caseInsensitive
        )
    }
}

// MARK: - QuizSession

/// A complete set of questions generated for a single quiz session.
///
/// `QuizSession` is a lightweight value type that holds the ordered question list
/// and tracks session-level metadata. Per-question answer state is managed by
/// `QuizViewModel` so this model remains free of mutable state.
public struct QuizSession: Codable, Identifiable, Sendable {

    // MARK: Properties

    /// Stable UUID for this session. Used as the Firestore document key for `QuizResult`.
    public let id: UUID

    /// The ordered list of questions the user will answer.
    public let questions: [QuizQuestion]

    /// UTC timestamp when the session was generated.
    public let startedAt: Date

    // MARK: Initialization

    public init(
        id: UUID = UUID(),
        questions: [QuizQuestion],
        startedAt: Date = Date()
    ) {
        precondition(!questions.isEmpty, "QuizSession must contain at least one question.")
        self.id         = id
        self.questions  = questions
        self.startedAt  = startedAt
    }

    /// Total number of questions in this session.
    public var questionCount: Int { questions.count }
}
