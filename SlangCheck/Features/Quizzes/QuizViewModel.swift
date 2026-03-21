// Features/Quizzes/QuizViewModel.swift
// SlangCheck
//
// ViewModel for the Quiz feature. Manages the full quiz lifecycle:
// idle → loading → active → result, plus Aura profile updates and sync.

import Foundation
import OSLog
import SwiftUI

// MARK: - QuizPhase

/// The current state of the quiz session.
enum QuizPhase: Equatable {
    case idle
    case loading
    case active
    case result(QuizResult)

    static func == (lhs: QuizPhase, rhs: QuizPhase) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.active, .active): return true
        case (.result(let l), .result(let r)):                         return l.id == r.id
        default:                                                        return false
        }
    }
}

// MARK: - QuizViewModel

/// Owns all quiz state and business logic.
///
/// Created and owned by `QuizzesView`. Child views receive it via `@Bindable`
/// or direct reference. Never passed as `@ObservedObject` — this project uses
/// the `@Observable` macro throughout (iOS 17+).
@Observable
@MainActor
final class QuizViewModel {

    // MARK: - Observable State

    private(set) var phase: QuizPhase = .idle

    /// Questions for the current session.
    private(set) var questions: [QuizQuestion] = []

    /// Choices for `currentQuestion`, pre-shuffled for display.
    private(set) var shuffledChoices: [String] = []

    /// Index of the question currently on screen.
    private(set) var currentIndex: Int = 0

    /// The answer string the user most recently tapped.
    private(set) var selectedAnswer: String? = nil

    /// `true` after the user taps a choice — reveals correct/wrong feedback.
    private(set) var isAnswerRevealed: Bool = false

    /// One wrong choice eliminated by the hint for the current question.
    private(set) var eliminatedChoice: String? = nil

    /// Running correct answer count for the current session.
    private(set) var correctCount: Int = 0

    /// Total hints consumed across the session.
    private(set) var hintsUsed: Int = 0

    /// The user's Aura Economy snapshot, loaded on appear.
    private(set) var auraProfile: AuraProfile? = nil

    /// Non-nil when quiz generation fails.
    private(set) var errorMessage: String? = nil

    // MARK: - Computed

    var currentQuestion: QuizQuestion? {
        currentIndex < questions.count ? questions[currentIndex] : nil
    }

    /// 1-based question number for display ("Question 3 of 10").
    var questionNumber: Int { currentIndex + 1 }
    var totalQuestions: Int { questions.count }

    /// Fraction of questions answered (0–1), used for the progress bar.
    var sessionProgress: Double {
        questions.isEmpty ? 0 : Double(currentIndex) / Double(questions.count)
    }

    /// `true` when the user may still use the hint for the current question.
    var canUseHint: Bool {
        !isAnswerRevealed && eliminatedChoice == nil && currentQuestion != nil
    }

    // MARK: - Dependencies

    private let generateQuizUseCase: GenerateQuizUseCase
    private let scoringEngine: AuraScoringEngine
    private let syncUseCase: SyncAuraProfileUseCase
    private let auraRepository: any AuraRepository

    /// Exposed `internal` (not `private`) so views can trigger haptics for copy / UI events.
    let hapticService: any HapticServiceProtocol

    // MARK: - Private

    private var sessionStartDate: Date? = nil

    // MARK: - Initialization

    init(
        generateQuizUseCase: GenerateQuizUseCase,
        syncUseCase: SyncAuraProfileUseCase,
        auraRepository: any AuraRepository,
        hapticService: any HapticServiceProtocol,
        scoringEngine: AuraScoringEngine = AuraScoringEngine()
    ) {
        self.generateQuizUseCase = generateQuizUseCase
        self.syncUseCase         = syncUseCase
        self.auraRepository      = auraRepository
        self.hapticService       = hapticService
        self.scoringEngine       = scoringEngine
    }

    // MARK: - Public Actions

    /// Loads the user's current Aura profile from the local cache.
    func loadProfile() async {
        auraProfile = try? await auraRepository.fetchProfile()
    }

    /// Generates a new quiz session and transitions to `.active`.
    func startQuiz() async {
        phase         = .loading
        errorMessage  = nil
        hintsUsed     = 0
        correctCount  = 0
        currentIndex  = 0
        selectedAnswer   = nil
        isAnswerRevealed = false
        eliminatedChoice = nil

        do {
            let session = try await generateQuizUseCase.execute()
            questions   = session.questions
            sessionStartDate = Date()
            refreshShuffledChoices()
            phase = .active
        } catch {
            errorMessage = error.localizedDescription
            phase        = .idle
            Logger.quizzes.error("Quiz generation failed: \(error.localizedDescription)")
        }
    }

    /// Records the user's choice and reveals answer feedback.
    func submitAnswer(_ choice: String) {
        guard !isAnswerRevealed, let question = currentQuestion else { return }
        selectedAnswer   = choice
        isAnswerRevealed = true

        if choice == question.correctAnswer {
            correctCount += 1
            hapticService.answerCorrect()
        } else {
            hapticService.answerIncorrect()
        }
    }

    /// Eliminates one wrong answer from `shuffledChoices` for the current question.
    func useHint() {
        guard canUseHint, let question = currentQuestion else { return }
        let wrongChoices = shuffledChoices.filter { $0 != question.correctAnswer }
        if let toEliminate = wrongChoices.randomElement() {
            eliminatedChoice = toEliminate
            hintsUsed       += 1
        }
    }

    /// Moves to the next question, or finalises the session if on the last question.
    func advanceToNextQuestion() {
        if currentIndex + 1 < questions.count {
            currentIndex    += 1
            selectedAnswer   = nil
            isAnswerRevealed = false
            eliminatedChoice = nil
            refreshShuffledChoices()
        } else {
            finishSession()
        }
    }

    /// Resets all session state and starts a fresh quiz.
    func restartQuiz() async {
        await startQuiz()
    }

    /// Resets to `.idle` without starting a new session.
    func dismissResult() {
        questions        = []
        shuffledChoices  = []
        currentIndex     = 0
        selectedAnswer   = nil
        isAnswerRevealed = false
        eliminatedChoice = nil
        hintsUsed        = 0
        correctCount     = 0
        sessionStartDate = nil
        phase            = .idle
    }

    // MARK: - Private

    private func refreshShuffledChoices() {
        shuffledChoices = currentQuestion?.allChoices.shuffled() ?? []
    }

    private func finishSession() {
        guard let startDate = sessionStartDate else { return }
        let elapsed = Date().timeIntervalSince(startDate)
        let input   = ScoringInput(
            correctCount:   correctCount,
            totalCount:     questions.count,
            hintsUsed:      hintsUsed,
            elapsedSeconds: elapsed
        )
        let result = scoringEngine.result(sessionID: UUID(), input: input)
        phase = .result(result)
        Task { [weak self] in await self?.applyResult(result) }
    }

    private func applyResult(_ result: QuizResult) async {
        let current = (try? await auraRepository.fetchProfile())
            ?? AuraProfile(id: UUID(), totalPoints: 0, streak: 0, lastActivityDate: nil, displayName: "You")
        let updated = current.adding(points: result.auraPointsEarned)
        do {
            try await syncUseCase.execute(updatedProfile: updated)
            try await syncUseCase.saveAndSyncResult(result)
            if updated.currentTier > current.currentTier {
                hapticService.tierPromotion()
            }
            auraProfile = updated
        } catch {
            Logger.quizzes.error("applyResult failed: \(error.localizedDescription)")
        }
    }
}
