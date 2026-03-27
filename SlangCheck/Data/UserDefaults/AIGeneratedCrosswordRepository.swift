// Data/UserDefaults/AIGeneratedCrosswordRepository.swift
// SlangCheck
//
// CrosswordRepository that generates a fresh puzzle daily via Apple Intelligence.
// Falls back to SampleCrosswordRepository when the AI service returns nil.
// User state and results are persisted in UserDefaults.

import CryptoKit
import Foundation
import OSLog

// MARK: - AIGeneratedCrosswordRepository

/// Produces a fresh daily crossword from the slang glossary using Apple Intelligence.
///
/// ## Puzzle lifecycle
/// 1. On `fetchTodaysPuzzle()`, generate (or load from cache) today's puzzle.
/// 2. AI selects terms and writes clues → `CrosswordLayoutBuilder` builds the grid.
/// 3. Answer map is AES-GCM encrypted using a fresh nonce and the bundled dev key
///    (same key used by `SampleCrosswordRepository`; key rotation is A-008).
/// 4. Puzzle is cached in UserDefaults keyed by today's date so subsequent calls
///    within the same day return instantly without re-running the AI.
/// 5. When AI is unavailable, `SampleCrosswordRepository.fetchTodaysPuzzle()` is called.
///
/// - Important: The dev key is acceptable for this iteration because the puzzle answer
///   is also visible in the `CrosswordUserState` entries once the user fills cells.
///   Full key rotation via Cloud Function is tracked as A-008.
public actor AIGeneratedCrosswordRepository: CrosswordRepository {

    // MARK: - Constants

    /// 32-byte AES-256 dev key (same as SampleCrosswordRepository; see A-008 for rotation).
    // SAFE: dev-only symmetric key. Production key issuance tracked in A-008.
    private static let devSymmetricKey: Data = Data([
        0x53, 0x6C, 0x61, 0x6E, 0x67, 0x43, 0x68, 0x65,
        0x63, 0x6B, 0x44, 0x65, 0x76, 0x4B, 0x65, 0x79,
        0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38,
        0x39, 0x30, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46
    ])

    private static let log = Logger(subsystem: "com.slangcheck", category: "AIGeneratedCrosswordRepository")

    // MARK: - Dependencies

    private let slangRepository:  any SlangTermRepository
    private let aiService:        any AICrosswordGenerationService
    private let layoutBuilder:    CrosswordLayoutBuilder
    private let sampleFallback:   SampleCrosswordRepository
    private let defaults:         UserDefaults

    // MARK: - State

    private var cachedPuzzle: CrosswordPuzzle?
    private let puzzleKey    = "crossword.aiPuzzle.v2"
    private let userStateKey = "crossword.userState.v1"
    private let resultsKey   = "crossword.results.v1"

    // MARK: - Initialization

    public init(
        slangRepository: any SlangTermRepository,
        aiService: any AICrosswordGenerationService,
        defaults: UserDefaults = .standard
    ) {
        self.slangRepository = slangRepository
        self.aiService       = aiService
        self.layoutBuilder   = CrosswordLayoutBuilder()
        self.sampleFallback  = SampleCrosswordRepository(defaults: defaults)
        self.defaults        = defaults
    }

    // MARK: - CrosswordRepository

    public func fetchTodaysPuzzle() async throws(CrosswordRepositoryError) -> CrosswordPuzzle {
        // Return in-memory cached puzzle if already generated this session.
        if let cached = cachedPuzzle { return cached }

        // Try to load a cached AI puzzle from UserDefaults (avoids re-running AI within same day).
        if let stored = loadCachedPuzzle() {
            cachedPuzzle = stored
            return stored
        }

        // Attempt AI generation. Only cache if AI succeeds — sample fallbacks are
        // not cached so the next launch retries AI (user may enable Apple Intelligence
        // or configure Gemini between sessions).
        if let aiPuzzle = await generateAIPuzzle() {
            cachedPuzzle = aiPuzzle
            storeCachedPuzzle(aiPuzzle)
            return aiPuzzle
        }

        // AI unavailable — serve the sample puzzle without caching it.
        AIGeneratedCrosswordRepository.log.info("AI unavailable; serving sample puzzle (not cached).")
        let sample = (try? await sampleFallback.fetchTodaysPuzzle()) ?? buildEmergencyPuzzle()
        cachedPuzzle = sample
        return sample
    }

    public func fetchUserState(for puzzleID: UUID) async throws(CrosswordRepositoryError) -> CrosswordUserState? {
        guard let data  = defaults.data(forKey: userStateKey),
              let state = try? JSONDecoder().decode(CrosswordUserState.self, from: data),
              state.puzzleID == puzzleID else { return nil }
        return state
    }

    public func saveUserState(_ state: CrosswordUserState) async throws(CrosswordRepositoryError) {
        do {
            defaults.set(try JSONEncoder().encode(state), forKey: userStateKey)
        } catch {
            throw CrosswordRepositoryError.saveFailed(underlying: error)
        }
    }

    public func saveResult(_ result: CrosswordResult) async throws(CrosswordRepositoryError) {
        var all = loadResultsFromDefaults()
        all.append(result)
        all.sort { $0.completedAt > $1.completedAt }
        do {
            defaults.set(try JSONEncoder().encode(all), forKey: resultsKey)
        } catch {
            throw CrosswordRepositoryError.saveFailed(underlying: error)
        }
    }

    public func fetchResults() async throws(CrosswordRepositoryError) -> [CrosswordResult] {
        loadResultsFromDefaults()
    }

    public func fetchDecryptionKey(for puzzleID: UUID) async throws(CrosswordRepositoryError) -> Data {
        AIGeneratedCrosswordRepository.devSymmetricKey
    }

    // MARK: - Private: Generation

    /// Attempts to generate a crossword via AI (Apple Intelligence → Gemini fallback chain).
    /// Returns `nil` when AI is entirely unavailable so the caller can serve a sample puzzle.
    private func generateAIPuzzle() async -> CrosswordPuzzle? {
        // Fetch glossary.
        guard let allTerms = try? await slangRepository.fetchAllTerms(), !allTerms.isEmpty else {
            AIGeneratedCrosswordRepository.log.warning("Glossary unavailable; cannot generate AI puzzle.")
            return nil
        }

        // Ask AI for layout.
        guard let aiLayout = await aiService.generateLayout(from: allTerms) else {
            AIGeneratedCrosswordRepository.log.info("AI layout generation returned nil.")
            return nil
        }

        // Build grid deterministically.
        guard let layout = layoutBuilder.build(entries: aiLayout.entries) else {
            AIGeneratedCrosswordRepository.log.warning("Layout builder failed for AI entries.")
            return nil
        }

        // Encrypt answer map and return puzzle.
        let (ciphertext, nonce) = encrypt(layout.answerMap)
        AIGeneratedCrosswordRepository.log.info("AI crossword built: \(layout.rows)×\(layout.cols) grid.")
        return CrosswordPuzzle(
            date: Calendar.current.startOfDay(for: Date()),
            rows: layout.rows,
            cols: layout.cols,
            cells: layout.cells,
            clues: layout.clues,
            encryptedAnswerKey: ciphertext,
            encryptionNonce: nonce,
            revealAt: Date(timeIntervalSinceNow: -3600)  // Immediately revealable for AI-generated puzzles.
        )
    }

    // MARK: - Private: Caching

    private func loadCachedPuzzle() -> CrosswordPuzzle? {
        guard let data   = defaults.data(forKey: puzzleKey),
              let puzzle = try? JSONDecoder().decode(CrosswordPuzzle.self, from: data) else { return nil }
        // Invalidate if the cached puzzle is from a different calendar day.
        let today = Calendar.current.startOfDay(for: Date())
        guard Calendar.current.isDate(puzzle.date, inSameDayAs: today) else { return nil }
        return puzzle
    }

    private func storeCachedPuzzle(_ puzzle: CrosswordPuzzle) {
        if let data = try? JSONEncoder().encode(puzzle) {
            defaults.set(data, forKey: puzzleKey)
        }
    }

    private func loadResultsFromDefaults() -> [CrosswordResult] {
        guard let data    = defaults.data(forKey: resultsKey),
              let results = try? JSONDecoder().decode([CrosswordResult].self, from: data)
        else { return [] }
        return results
    }

    // MARK: - Private: Encryption

    private func encrypt(_ answers: [String: String]) -> (ciphertext: Data, nonce: Data) {
        // SAFE: dev-only key — acceptable until A-008 (server key rotation) is implemented.
        do {
            let plaintext = try JSONEncoder().encode(answers)
            let key       = SymmetricKey(data: AIGeneratedCrosswordRepository.devSymmetricKey)
            let sealed    = try AES.GCM.seal(plaintext, using: key)
            return (sealed.ciphertext + sealed.tag, Data(sealed.nonce))
        } catch {
            fatalError("AIGeneratedCrosswordRepository: AES-GCM encryption failed: \(error)")
        }
    }

    private func buildEmergencyPuzzle() -> CrosswordPuzzle {
        // Last-resort 1×1 placeholder — should never be reached in practice.
        let cell = CrosswordCell(row: 0, col: 0, kind: .letter, clueNumber: 1)
        let (ct, nonce) = encrypt(["0-0": "A"])
        return CrosswordPuzzle(date: Date(), rows: 1, cols: 1, cells: [cell], clues: [],
                               encryptedAnswerKey: ct, encryptionNonce: nonce,
                               revealAt: Date(timeIntervalSinceNow: -1))
    }
}
