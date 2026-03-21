// SlangCheckTests/QuizViewModelTests.swift
// SlangCheck
//
// Unit tests for QuizViewModel: phase transitions, answer submission,
// hint mechanic, progress computation, and result finalization.
//
// All tests run on @MainActor because QuizViewModel is @MainActor.

import XCTest
@testable import SlangCheck

// MARK: - Term Factory

private func makeTerms(count: Int) -> [SlangTerm] {
    (0..<count).map { i in
        SlangTerm(
            id: UUID(),
            term: "Word\(i)",
            definition: "Def\(i)",
            standardEnglish: "Equivalent\(i)",
            exampleSentence: "Word\(i) used in context.",
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

// MARK: - MockAuraRepository

private actor MockAuraRepository: AuraRepository {
    private var profile: AuraProfile?

    func fetchProfile()                         async throws(AuraRepositoryError) -> AuraProfile? { profile }
    func saveProfile(_ p: AuraProfile)          async throws(AuraRepositoryError) { profile = p }
    func saveQuizResult(_ r: QuizResult)        async throws(AuraRepositoryError) {}
    func fetchQuizHistory()                     async throws(AuraRepositoryError) -> [QuizResult] { [] }
}

// MARK: - MockAuraSyncService

private struct MockAuraSyncService: AuraSyncService {
    func syncProfile(_ local: AuraProfile) async throws(AuraSyncError) -> AuraProfile { local }
    func syncQuizResult(_ result: QuizResult)   async throws(AuraSyncError) {}
}

// MARK: - MockHapticService

private struct MockHapticService: HapticServiceProtocol {
    func swipeCompleted()    {}
    func answerCorrect()     {}
    func answerIncorrect()   {}
    func copySucceeded()     {}
    func tierPromotion()     {}
    func swipeButtonTapped() {}
}

// MARK: - QuizViewModelTests

@MainActor
final class QuizViewModelTests: XCTestCase {

    // MARK: - Factory

    private func makeViewModel(termCount: Int = 10) -> QuizViewModel {
        let termRepo    = MockSlangTermRepository(terms: makeTerms(count: termCount))
        let auraRepo    = MockAuraRepository()
        let syncUseCase = SyncAuraProfileUseCase(auraRepository: auraRepo, syncService: MockAuraSyncService())
        return QuizViewModel(
            generateQuizUseCase: GenerateQuizUseCase(repository: termRepo),
            syncUseCase:         syncUseCase,
            auraRepository:      auraRepo,
            hapticService:       MockHapticService()
        )
    }

    private func startedViewModel(termCount: Int = 10) async -> QuizViewModel {
        let vm = makeViewModel(termCount: termCount)
        await vm.startQuiz()
        return vm
    }

    // MARK: - Initial State

    func testInitialPhaseIsIdle() async {
        XCTAssertEqual(makeViewModel().phase, .idle)
    }

    func testInitialQuestionsIsEmpty() async {
        XCTAssertTrue(makeViewModel().questions.isEmpty)
    }

    func testInitialCorrectCountIsZero() async {
        XCTAssertEqual(makeViewModel().correctCount, 0)
    }

    func testInitialHintsUsedIsZero() async {
        XCTAssertEqual(makeViewModel().hintsUsed, 0)
    }

    func testInitialCurrentIndexIsZero() async {
        XCTAssertEqual(makeViewModel().currentIndex, 0)
    }

    // MARK: - startQuiz Phase Transitions

    func testStartQuizTransitionsToActive() async {
        let vm = await startedViewModel()
        XCTAssertEqual(vm.phase, .active)
    }

    func testStartQuizPopulatesDefaultQuestionCount() async {
        let vm = await startedViewModel()
        XCTAssertEqual(vm.questions.count, GenerateQuizUseCase.defaultQuestionCount)
    }

    func testStartQuizSetsCurrentIndexToZero() async {
        let vm = await startedViewModel()
        XCTAssertEqual(vm.currentIndex, 0)
    }

    func testRestartResetsSessionCounters() async {
        let vm = await startedViewModel()
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        vm.submitAnswer(q.correctAnswer)
        await vm.restartQuiz()
        XCTAssertEqual(vm.correctCount, 0)
        XCTAssertEqual(vm.hintsUsed, 0)
        XCTAssertEqual(vm.currentIndex, 0)
    }

    // MARK: - Submit Answer

    func testSubmitCorrectAnswerIncrementsCorrectCount() async {
        let vm = await startedViewModel()
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        vm.submitAnswer(q.correctAnswer)
        XCTAssertEqual(vm.correctCount, 1)
    }

    func testSubmitWrongAnswerDoesNotIncrementCorrectCount() async {
        let vm = await startedViewModel()
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        let wrong = q.allChoices.first { $0 != q.correctAnswer } ?? "X"
        vm.submitAnswer(wrong)
        XCTAssertEqual(vm.correctCount, 0)
    }

    func testSubmitAnswerSetsIsAnswerRevealed() async {
        let vm = await startedViewModel()
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        vm.submitAnswer(q.correctAnswer)
        XCTAssertTrue(vm.isAnswerRevealed)
    }

    func testSubmitAnswerSetsSelectedAnswer() async {
        let vm = await startedViewModel()
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        vm.submitAnswer(q.correctAnswer)
        XCTAssertEqual(vm.selectedAnswer, q.correctAnswer)
    }

    func testSecondSubmitIsIgnoredAfterReveal() async {
        let vm = await startedViewModel()
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        vm.submitAnswer(q.correctAnswer)
        let wrong = q.allChoices.first { $0 != q.correctAnswer } ?? "X"
        vm.submitAnswer(wrong)
        XCTAssertEqual(vm.selectedAnswer, q.correctAnswer)
        XCTAssertEqual(vm.correctCount, 1)
    }

    // MARK: - Hint Mechanic

    func testCanUseHintTrueBeforeAnyAction() async {
        let vm = await startedViewModel()
        XCTAssertTrue(vm.canUseHint)
    }

    func testUseHintEliminatesOneWrongChoice() async {
        let vm = await startedViewModel()
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        vm.useHint()
        guard let eliminated = vm.eliminatedChoice else {
            return XCTFail("eliminatedChoice should be non-nil after useHint()")
        }
        XCTAssertNotEqual(eliminated, q.correctAnswer,
                          "Eliminated choice must not be the correct answer.")
        XCTAssertTrue(q.allChoices.contains(eliminated),
                      "Eliminated choice must be one of the question's choices.")
    }

    func testUseHintIncrementsHintsUsed() async {
        let vm = await startedViewModel()
        vm.useHint()
        XCTAssertEqual(vm.hintsUsed, 1)
    }

    func testCanUseHintFalseAfterHintConsumed() async {
        let vm = await startedViewModel()
        vm.useHint()
        XCTAssertFalse(vm.canUseHint)
    }

    func testCanUseHintFalseAfterAnswerRevealed() async {
        let vm = await startedViewModel()
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        vm.submitAnswer(q.correctAnswer)
        XCTAssertFalse(vm.canUseHint)
    }

    func testSecondUseHintIsNoOp() async {
        let vm = await startedViewModel()
        vm.useHint()
        let first = vm.eliminatedChoice
        vm.useHint()
        XCTAssertEqual(vm.eliminatedChoice, first,
                       "Second useHint must not change eliminatedChoice.")
        XCTAssertEqual(vm.hintsUsed, 1,
                       "hintsUsed must not increment on a second useHint call.")
    }

    // MARK: - Advance

    func testAdvanceToNextQuestionIncrementsCurrentIndex() async {
        let vm = await startedViewModel()
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        vm.submitAnswer(q.correctAnswer)
        vm.advanceToNextQuestion()
        XCTAssertEqual(vm.currentIndex, 1)
    }

    func testAdvanceResetsAnswerState() async {
        let vm = await startedViewModel()
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        vm.submitAnswer(q.correctAnswer)
        vm.advanceToNextQuestion()
        XCTAssertFalse(vm.isAnswerRevealed)
        XCTAssertNil(vm.selectedAnswer)
        XCTAssertNil(vm.eliminatedChoice)
    }

    func testAdvanceResetsCanUseHintForNextQuestion() async {
        let vm = await startedViewModel()
        vm.useHint()
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        vm.submitAnswer(q.correctAnswer)
        vm.advanceToNextQuestion()
        XCTAssertNil(vm.eliminatedChoice)
        XCTAssertTrue(vm.canUseHint)
    }

    // MARK: - Session Progress

    func testSessionProgressIsZeroAtStart() async {
        let vm = await startedViewModel()
        XCTAssertEqual(vm.sessionProgress, 0.0, accuracy: 0.001)
    }

    func testSessionProgressIncreasesAfterOneAdvance() async {
        let vm = await startedViewModel()
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        vm.submitAnswer(q.correctAnswer)
        vm.advanceToNextQuestion()
        XCTAssertGreaterThan(vm.sessionProgress, 0.0)
    }

    func testSessionProgressIsOneOverTotalQuestionsAfterOneAdvance() async {
        let vm    = await startedViewModel()
        let total = Double(vm.totalQuestions)
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        vm.submitAnswer(q.correctAnswer)
        vm.advanceToNextQuestion()
        XCTAssertEqual(vm.sessionProgress, 1.0 / total, accuracy: 0.001)
    }

    // MARK: - Question Number / Total

    func testQuestionNumberStartsAtOne() async {
        let vm = await startedViewModel()
        XCTAssertEqual(vm.questionNumber, 1)
    }

    func testTotalQuestionsMatchesDefaultCount() async {
        let vm = await startedViewModel()
        XCTAssertEqual(vm.totalQuestions, GenerateQuizUseCase.defaultQuestionCount)
    }

    func testQuestionNumberIncrementsWithIndex() async {
        let vm = await startedViewModel()
        guard let q = vm.currentQuestion else { return XCTFail("No current question") }
        vm.submitAnswer(q.correctAnswer)
        vm.advanceToNextQuestion()
        XCTAssertEqual(vm.questionNumber, 2)
    }

    // MARK: - Finish Session → Result Phase

    func testFinishingLastQuestionTransitionsToResult() async {
        let vm    = await startedViewModel(termCount: 10)
        let total = GenerateQuizUseCase.defaultQuestionCount

        for _ in 0..<(total - 1) {
            guard let q = vm.currentQuestion else { break }
            vm.submitAnswer(q.correctAnswer)
            vm.advanceToNextQuestion()
        }
        guard let last = vm.currentQuestion else { return XCTFail("Missing last question") }
        vm.submitAnswer(last.correctAnswer)
        vm.advanceToNextQuestion()

        if case .result = vm.phase { } else {
            XCTFail("Expected .result phase after last question, got \(vm.phase)")
        }
    }

    func testResultContainsAllCorrectAnswers() async {
        let vm    = await startedViewModel(termCount: 10)
        let total = GenerateQuizUseCase.defaultQuestionCount

        for _ in 0..<total {
            guard let q = vm.currentQuestion else { break }
            vm.submitAnswer(q.correctAnswer)
            vm.advanceToNextQuestion()
        }

        if case .result(let result) = vm.phase {
            XCTAssertEqual(result.correctCount, total)
            XCTAssertEqual(result.totalCount,   total)
            XCTAssertTrue(result.isPerfect)
            XCTAssertGreaterThan(result.auraPointsEarned, 0)
        } else {
            XCTFail("Phase is not .result")
        }
    }

    func testResultTracksHintsUsed() async {
        let vm    = await startedViewModel(termCount: 10)
        let total = GenerateQuizUseCase.defaultQuestionCount

        // Use a hint on the first question.
        vm.useHint()
        for _ in 0..<total {
            guard let q = vm.currentQuestion else { break }
            vm.submitAnswer(q.correctAnswer)
            vm.advanceToNextQuestion()
        }

        if case .result(let result) = vm.phase {
            XCTAssertEqual(result.hintsUsed, 1)
        } else {
            XCTFail("Phase is not .result")
        }
    }

    // MARK: - dismissResult

    func testDismissResultResetsPhaseToIdle() async {
        let vm    = await startedViewModel(termCount: 10)
        for _ in 0..<GenerateQuizUseCase.defaultQuestionCount {
            guard let q = vm.currentQuestion else { break }
            vm.submitAnswer(q.correctAnswer)
            vm.advanceToNextQuestion()
        }
        vm.dismissResult()
        XCTAssertEqual(vm.phase, .idle)
    }

    func testDismissResultClearsAllSessionState() async {
        let vm    = await startedViewModel(termCount: 10)
        for _ in 0..<GenerateQuizUseCase.defaultQuestionCount {
            guard let q = vm.currentQuestion else { break }
            vm.submitAnswer(q.correctAnswer)
            vm.advanceToNextQuestion()
        }
        vm.dismissResult()
        XCTAssertTrue(vm.questions.isEmpty)
        XCTAssertEqual(vm.currentIndex, 0)
        XCTAssertEqual(vm.correctCount, 0)
        XCTAssertEqual(vm.hintsUsed, 0)
        XCTAssertNil(vm.selectedAnswer)
        XCTAssertFalse(vm.isAnswerRevealed)
    }
}
