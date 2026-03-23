// Features/Crossword/CrosswordViewModel.swift
// SlangCheck
//
// ViewModel for the daily crossword feature.
// Manages the full puzzle lifecycle: loading → active → submitting → completed,
// plus cursor navigation, letter entry, reveal hints, and scoring.

import Foundation
import OSLog
import SwiftUI

// MARK: - CrosswordPhase

/// The lifecycle phase of the crossword session.
enum CrosswordPhase: Equatable {
    case loading
    case active
    case submitting
    case completed(CrosswordResult)
    case error(String)

    static func == (lhs: CrosswordPhase, rhs: CrosswordPhase) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.active, .active), (.submitting, .submitting): return true
        case (.completed(let l), .completed(let r)):                               return l.id == r.id
        case (.error(let l), .error(let r)):                                       return l == r
        default:                                                                    return false
        }
    }
}

// MARK: - CrosswordViewModel

/// Owns all crossword puzzle state and business logic.
///
/// Created and owned by `CrosswordView`. Uses `@Observable` (iOS 17+).
/// All mutations happen on `@MainActor` to keep published state thread-safe.
@Observable
@MainActor
final class CrosswordViewModel {

    // MARK: - Observable State

    private(set) var phase: CrosswordPhase = .loading
    private(set) var puzzle: CrosswordPuzzle?
    private(set) var userState: CrosswordUserState?

    /// The cell ID currently selected by the cursor. `nil` when no cell is active.
    private(set) var selectedCellID: String?

    /// The direction the cursor is moving. Tapping the active cell toggles this.
    private(set) var selectedDirection: ClueDirection = .across

    /// The decrypted answer dictionary — only populated after the puzzle is validated.
    private(set) var answerMap: [String: String]?

    /// Aura profile for scoring display.
    private(set) var auraProfile: AuraProfile?

    /// Non-nil when a recoverable error message should be shown.
    private(set) var errorMessage: String?

    // MARK: - Computed

    /// The clue currently highlighted, determined by the selected cell and direction.
    var activeClue: CrosswordClue? {
        guard let puzzle, let cellID = selectedCellID else { return nil }
        return puzzle.clues.first { $0.direction == selectedDirection && $0.cellIDs.contains(cellID) }
            ?? puzzle.clues.first { $0.cellIDs.contains(cellID) }
    }

    /// All cells the cursor highlight should extend through (cells in `activeClue`).
    var highlightedCellIDs: Set<String> {
        Set(activeClue?.cellIDs ?? [])
    }

    /// `true` when the current puzzle is finished (all letter cells filled in).
    var canSubmit: Bool {
        guard let puzzle, let state = userState else { return false }
        return state.filledCount >= puzzle.totalLetterCount
    }

    /// Number of reveal-hint credits remaining this session (0–5).
    var revealCreditsRemaining: Int {
        userState?.revealCreditsRemaining ?? CrosswordConstants.revealCreditCount
    }

    /// `true` when the reveal button should be active: a cell is selected, credits remain,
    /// the cell has not already been revealed, and the puzzle is in progress.
    var canReveal: Bool {
        guard phase == .active,
              let cellID = selectedCellID,
              revealCreditsRemaining > 0 else { return false }
        return !(userState?.revealedCellIDs.contains(cellID) ?? false)
    }

    /// Letter the user has entered in `cellID`, or `nil`.
    func enteredLetter(for cellID: String) -> String? {
        userState?.entries[cellID]
    }

    /// Whether `cellID` was revealed via hint.
    func isRevealed(_ cellID: String) -> Bool {
        userState?.revealedCellIDs.contains(cellID) ?? false
    }

    /// Whether `cellID` is correct (only valid after submission in `.completed`).
    func isCorrect(_ cellID: String) -> Bool {
        guard let answer = answerMap else { return false }
        return userState?.entries[cellID] == answer[cellID]
    }

    // MARK: - Dependencies

    private let crosswordRepository: any CrosswordRepository
    private let answerKeyService: any AnswerKeyService
    private let scoringUseCase: CrosswordScoringUseCase
    private let auraRepository: any AuraRepository
    private let syncUseCase: SyncAuraProfileUseCase
    private let notificationService: any CrosswordNotificationService
    let hapticService: any HapticServiceProtocol

    // MARK: - Private

    private var puzzleOpenDate: Date?

    // MARK: - Initialization

    init(
        crosswordRepository: any CrosswordRepository,
        answerKeyService: any AnswerKeyService,
        scoringUseCase: CrosswordScoringUseCase = CrosswordScoringUseCase(),
        auraRepository: any AuraRepository,
        syncUseCase: SyncAuraProfileUseCase,
        notificationService: any CrosswordNotificationService,
        hapticService: any HapticServiceProtocol
    ) {
        self.crosswordRepository = crosswordRepository
        self.answerKeyService    = answerKeyService
        self.scoringUseCase      = scoringUseCase
        self.auraRepository      = auraRepository
        self.syncUseCase         = syncUseCase
        self.notificationService = notificationService
        self.hapticService       = hapticService
    }

    // MARK: - Public Actions

    /// Loads today's puzzle and the user's saved progress. Call from `.task`.
    func loadPuzzle() async {
        phase = .loading
        do {
            let p     = try await crosswordRepository.fetchTodaysPuzzle()
            let state = (try? await crosswordRepository.fetchUserState(for: p.id))
                ?? CrosswordUserState(puzzleID: p.id)
            puzzle        = p
            userState     = state
            puzzleOpenDate = Date()
            if state.isCompleted {
                await finaliseCompleted(puzzle: p, state: state)
            } else {
                phase = .active
            }
            // Schedule next-day reminder (fire-and-forget; errors are non-fatal).
            Task { [weak self] in await self?.scheduleTomorrowReminder(after: p) }
        } catch {
            phase        = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            Logger.crossword.error("loadPuzzle failed: \(error.localizedDescription)")
        }
    }

    /// Loads the user's current Aura profile from the local cache.
    func loadProfile() async {
        auraProfile = try? await auraRepository.fetchProfile()
    }

    // MARK: - Cursor Navigation

    /// Selects the given cell. Tapping the already-selected cell toggles direction.
    func selectCell(_ cellID: String) {
        guard let puzzle else { return }
        guard let cell = puzzle.cells.first(where: { $0.id == cellID }),
              cell.isLetter else { return }

        if cellID == selectedCellID {
            // Toggle between across and down if both directions have a clue through this cell.
            let hasAcross = puzzle.clues.contains { $0.direction == .across && $0.cellIDs.contains(cellID) }
            let hasDown   = puzzle.clues.contains { $0.direction == .down   && $0.cellIDs.contains(cellID) }
            if hasAcross && hasDown {
                selectedDirection = (selectedDirection == .across) ? .down : .across
            }
        } else {
            selectedCellID = cellID
            // If the new cell has no clue in the current direction, switch direction.
            let hasCurrent = puzzle.clues.contains { $0.direction == selectedDirection && $0.cellIDs.contains(cellID) }
            if !hasCurrent {
                selectedDirection = (selectedDirection == .across) ? .down : .across
            }
        }
    }

    /// Selects a clue from the clue list (scrollable panel interaction).
    func selectClue(_ clue: CrosswordClue) {
        selectedDirection = clue.direction
        selectedCellID    = clue.cellIDs.first
    }

    /// Clears the cursor selection, dismissing the keyboard.
    func deselectCell() {
        selectedCellID = nil
    }

    // MARK: - Letter Entry

    /// Enters a single uppercase letter at the current cursor position and advances the cursor.
    func enterLetter(_ letter: String) {
        guard phase == .active,
              let cellID = selectedCellID,
              let ch = letter.first, ch.isLetter else { return }

        let upper = String(ch).uppercased()
        userState = userState?.entering(upper, at: cellID)
        persistUserState()
        advanceCursor()
        hapticService.swipeButtonTapped()
    }

    /// Deletes the letter at the current cursor position (or retreats the cursor if empty).
    func deleteLetter() {
        guard phase == .active, let cellID = selectedCellID else { return }
        if userState?.entries[cellID] != nil {
            userState = userState?.clearing(cellID)
            persistUserState()
        } else {
            retreatCursor()
        }
    }

    /// Reveals the correct letter at the current cursor position, consuming one reveal credit
    /// and deducting `CrosswordConstants.auraDeductionPerReveal` Aura points immediately.
    ///
    /// No-ops if: the puzzle is not active, no cell is selected, the cell was already
    /// revealed, or the user has no credits remaining.
    func revealCurrentCell() {
        guard canReveal, let cellID = selectedCellID else { return }
        Task { [weak self] in
            guard let self, let puzzle = self.puzzle else { return }
            do {
                let key     = try await crosswordRepository.fetchDecryptionKey(for: puzzle.id)
                let answers = try answerKeyService.decrypt(using: key, puzzle: puzzle)
                guard let letter = answers[cellID] else { return }
                userState = userState?.revealing(cellID, letter: letter)
                persistUserState()
                hapticService.copySucceeded()
                advanceCursor()
                // Deduct Aura immediately so the user feels the cost of the hint.
                await deductRevealAura()
            } catch {
                Logger.crossword.error("revealCurrentCell failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Submission

    /// Validates the user's entries against the decrypted answer key and finalises the session.
    func submitPuzzle() {
        guard phase == .active, let puzzle, let state = userState else { return }
        phase = .submitting

        Task { [weak self] in
            guard let self else { return }
            do {
                let key     = try await crosswordRepository.fetchDecryptionKey(for: puzzle.id)
                let answers = try answerKeyService.decrypt(using: key, puzzle: puzzle)
                answerMap   = answers

                let correctCount = puzzle.letterCells.filter { cell in
                    state.entries[cell.id] == answers[cell.id]
                }.count
                let elapsed = puzzleOpenDate.map { Date().timeIntervalSince($0) } ?? 0

                let input = CrosswordScoringInput(
                    correctCells:   correctCount,
                    totalCells:     puzzle.totalLetterCount,
                    revealsUsed:    state.revealCount,
                    elapsedSeconds: elapsed
                )
                let result = scoringUseCase.result(
                    puzzleID:   puzzle.id,
                    puzzleDate: puzzle.date,
                    input:      input
                )
                let completed = state.completing()
                userState = completed
                persistUserState()

                try? await crosswordRepository.saveResult(result)
                await applyAuraPoints(result.auraPointsEarned)

                phase = .completed(result)
                Logger.crossword.info("Crossword submitted: \(correctCount)/\(puzzle.totalLetterCount) correct, \(result.auraPointsEarned) Aura pts.")
            } catch {
                phase        = .active
                errorMessage = error.localizedDescription
                Logger.crossword.error("submitPuzzle failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private Helpers

    private func persistUserState() {
        guard let state = userState else { return }
        Task { [weak self] in
            guard let self else { return }
            try? await crosswordRepository.saveUserState(state)
        }
    }

    private func advanceCursor() {
        guard let clue = activeClue, let cellID = selectedCellID else { return }
        guard let idx = clue.cellIDs.firstIndex(of: cellID),
              idx + 1 < clue.cellIDs.count else { return }
        selectedCellID = clue.cellIDs[idx + 1]
    }

    private func retreatCursor() {
        guard let clue = activeClue, let cellID = selectedCellID else { return }
        guard let idx = clue.cellIDs.firstIndex(of: cellID), idx > 0 else { return }
        selectedCellID = clue.cellIDs[idx - 1]
    }

    private func finaliseCompleted(puzzle: CrosswordPuzzle, state: CrosswordUserState) async {
        // Re-fetch result for display without re-scoring.
        let results = (try? await crosswordRepository.fetchResults()) ?? []
        if let result = results.first(where: { $0.puzzleID == puzzle.id }) {
            phase = .completed(result)
        } else {
            // Puzzle marked complete but result missing — show active so user can re-submit.
            phase = .active
        }
    }

    /// Immediately deducts `CrosswordConstants.auraDeductionPerReveal` from the user's
    /// Aura balance when they use a reveal hint.
    private func deductRevealAura() async {
        await applyAuraPoints(-CrosswordConstants.auraDeductionPerReveal)
        Logger.crossword.debug("Reveal used: -\(CrosswordConstants.auraDeductionPerReveal) Aura deducted.")
    }

    private func applyAuraPoints(_ points: Int) async {
        let current = (try? await auraRepository.fetchProfile())
            ?? AuraProfile(id: UUID(), totalPoints: 0, streak: 0, lastActivityDate: nil, displayName: "You")
        let updated = current.adding(points: points)
        do {
            try await syncUseCase.execute(updatedProfile: updated)
            if updated.currentTier > current.currentTier { hapticService.tierPromotion() }
            auraProfile = updated
        } catch {
            Logger.crossword.error("applyAuraPoints sync failed: \(error.localizedDescription)")
        }
    }

    private func scheduleTomorrowReminder(after puzzle: CrosswordPuzzle) async {
        // Schedule next day's puzzle reminder (current date + 1 day at midnight UTC).
        var components  = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: puzzle.date)
        components.day  = (components.day ?? 0) + 1
        components.hour = 0
        guard let tomorrow = Calendar(identifier: .gregorian).date(from: components) else { return }
        try? await notificationService.scheduleDailyReminder(for: tomorrow)
    }
}
