// Data/UserDefaults/SampleCrosswordRepository.swift
// SlangCheck
//
// Offline CrosswordRepository used for development, Xcode Previews, and
// the simulator before Firebase is wired up (developer action A-007).
//
// Puzzle layout (5×5):
//
//   Col:  0    1    2    3    4
// Row 0:  N    O    C    A    P      ← Across 1: NOCAP
// Row 1:  O    ■    A    ■    ■
// Row 2:  O    ■    P    ■    ■
// Row 3:  B    ■    ■    ■    ■
// Row 4:  S    L    A    Y    ■      ← Across 3: SLAY
//
//   Down 1: NOOBS (col 0, rows 0–4)
//   Down 2: CAP   (col 2, rows 0–2)
//
// The answer key is AES-GCM encrypted with a hardcoded 32-byte key
// (development only). `fetchDecryptionKey(for:)` returns the same key,
// simulating the Cloud Function behaviour.

import CryptoKit
import Foundation
import OSLog

// MARK: - SampleCrosswordRepository

/// An in-memory / UserDefaults `CrosswordRepository` backed by a single
/// hardcoded sample puzzle. Suitable for development and Xcode Previews.
///
/// - Important: The hardcoded symmetric key is development-only and must
///   never be used in production. The production repository
///   (`FirebaseCrosswordRepository`) fetches the key from the server.
public actor SampleCrosswordRepository: CrosswordRepository {

    // MARK: - Constants

    /// 32-byte AES-256 development key. **Never ship to production.**
    // SAFE: hardcoded only for the sample/preview repository; production
    // key is issued by the server Cloud Function at revealAt.
    private static let devSymmetricKey: Data = Data([
        0x53, 0x6C, 0x61, 0x6E, 0x67, 0x43, 0x68, 0x65,
        0x63, 0x6B, 0x44, 0x65, 0x76, 0x4B, 0x65, 0x79,
        0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38,
        0x39, 0x30, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46
    ])

    private static let log = Logger(subsystem: "com.slangcheck", category: "SampleCrosswordRepository")

    // MARK: - State

    private let defaults: UserDefaults
    private let userStateKey = "crossword.userState.v1"
    private let resultsKey   = "crossword.results.v1"

    // The puzzle is generated once and cached.
    private var cachedPuzzle: CrosswordPuzzle?

    // MARK: - Initialization

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - CrosswordRepository

    public func fetchTodaysPuzzle() async throws(CrosswordRepositoryError) -> CrosswordPuzzle {
        if let cached = cachedPuzzle { return cached }
        let puzzle = buildSamplePuzzle()
        cachedPuzzle = puzzle
        return puzzle
    }

    public func fetchUserState(for puzzleID: UUID) async throws(CrosswordRepositoryError) -> CrosswordUserState? {
        guard let data = defaults.data(forKey: userStateKey) else { return nil }
        do {
            let state = try JSONDecoder().decode(CrosswordUserState.self, from: data)
            guard state.puzzleID == puzzleID else { return nil }
            return state
        } catch {
            SampleCrosswordRepository.log.error("fetchUserState decode failed: \(error)")
            return nil
        }
    }

    public func saveUserState(_ state: CrosswordUserState) async throws(CrosswordRepositoryError) {
        do {
            let data = try JSONEncoder().encode(state)
            defaults.set(data, forKey: userStateKey)
        } catch {
            throw CrosswordRepositoryError.saveFailed(underlying: error)
        }
    }

    public func saveResult(_ result: CrosswordResult) async throws(CrosswordRepositoryError) {
        var all = loadResultsFromDefaults()
        all.append(result)
        all.sort { $0.completedAt > $1.completedAt }
        do {
            let data = try JSONEncoder().encode(all)
            defaults.set(data, forKey: resultsKey)
        } catch {
            throw CrosswordRepositoryError.saveFailed(underlying: error)
        }
    }

    public func fetchResults() async throws(CrosswordRepositoryError) -> [CrosswordResult] {
        loadResultsFromDefaults()
    }

    public func fetchDecryptionKey(for puzzleID: UUID) async throws(CrosswordRepositoryError) -> Data {
        // In the sample repository the key is always available (simulates post-revealAt).
        return SampleCrosswordRepository.devSymmetricKey
    }

    // MARK: - Helpers

    private func loadResultsFromDefaults() -> [CrosswordResult] {
        guard let data = defaults.data(forKey: resultsKey),
              let results = try? JSONDecoder().decode([CrosswordResult].self, from: data)
        else { return [] }
        return results
    }

    // MARK: - Puzzle Construction

    private func buildSamplePuzzle() -> CrosswordPuzzle {
        let rows = 5, cols = 5

        // Answer key (plaintext): cell ID → uppercase letter.
        let answers: [String: String] = [
            // Across 1 / Down 1 intersection: NOCAP across (row 0)
            "0-0": "N", "0-1": "O", "0-2": "C", "0-3": "A", "0-4": "P",
            // Down 1: NOOBS (col 0, rows 1–4)
            "1-0": "O", "2-0": "O", "3-0": "B", "4-0": "S",
            // Down 2: CAP (col 2, rows 1–2) — C at row 0 already above
            "1-2": "A", "2-2": "P",
            // Across 3: SLAY (row 4, cols 0–3) — S at col 0 already above
            "4-1": "L", "4-2": "A", "4-3": "Y"
        ]

        // Black cells: all cells NOT in answers.
        let answerCellIDs = Set(answers.keys)
        var cells: [CrosswordCell] = []
        for r in 0..<rows {
            for c in 0..<cols {
                let cid = "\(r)-\(c)"
                let isLetter = answerCellIDs.contains(cid)
                let clueNum: Int? = clueNumber(row: r, col: c)
                cells.append(CrosswordCell(
                    row: r,
                    col: c,
                    kind: isLetter ? .letter : .black,
                    clueNumber: clueNum
                ))
            }
        }

        // Clues
        let clues: [CrosswordClue] = [
            CrosswordClue(
                number: 1,
                direction: .across,
                text: "Truthfully; for real (no ___)",
                cellIDs: ["0-0", "0-1", "0-2", "0-3", "0-4"]
            ),
            CrosswordClue(
                number: 3,
                direction: .across,
                text: "To do something exceptionally well",
                cellIDs: ["4-0", "4-1", "4-2", "4-3"]
            ),
            CrosswordClue(
                number: 1,
                direction: .down,
                text: "Beginners; internet rookies (pl.)",
                cellIDs: ["0-0", "1-0", "2-0", "3-0", "4-0"]
            ),
            CrosswordClue(
                number: 2,
                direction: .down,
                text: "A lie or exaggeration",
                cellIDs: ["0-2", "1-2", "2-2"]
            )
        ]

        // Encrypt the answer key.
        let (encrypted, nonce) = encryptAnswers(answers)

        // revealAt: 24 hours from now in the sample (puzzle is always "in reveal" for dev).
        // Set far in the past so isRevealable == true immediately.
        let revealAt = Date(timeIntervalSinceNow: -3600)

        return CrosswordPuzzle(
            id: UUID(uuidString: "DEADBEEF-0000-0000-0000-000000000001")!,
            date: Calendar.current.startOfDay(for: Date()),
            rows: rows,
            cols: cols,
            cells: cells,
            clues: clues,
            encryptedAnswerKey: encrypted,
            encryptionNonce: nonce,
            revealAt: revealAt
        )
    }

    /// Assigns clue numbers to cells that begin an Across or Down entry.
    /// Matches standard crossword numbering rules:
    /// a cell gets a number if it starts an Across entry (left edge or left neighbour is black)
    /// OR starts a Down entry (top edge or upper neighbour is black).
    private func clueNumber(row: Int, col: Int) -> Int? {
        // Black cells never get numbers.
        let answers: Set<String> = [
            "0-0", "0-1", "0-2", "0-3", "0-4",
            "1-0", "2-0", "3-0", "4-0",
            "1-2", "2-2",
            "4-1", "4-2", "4-3"
        ]
        guard answers.contains("\(row)-\(col)") else { return nil }

        // Using the pre-assigned clue number map derived from the layout.
        let numberMap: [String: Int] = [
            "0-0": 1,   // Across 1 + Down 1
            "0-2": 2,   // Down 2
            "4-0": 3    // Across 3 (S is shared with Down 1)
        ]
        return numberMap["\(row)-\(col)"]
    }

    private func encryptAnswers(_ answers: [String: String]) -> (ciphertext: Data, nonce: Data) {
        // SAFE: This is the sample/preview repository only. The dev key is not secret.
        do {
            let plaintext = try JSONEncoder().encode(answers)
            let key       = SymmetricKey(data: SampleCrosswordRepository.devSymmetricKey)
            let sealed    = try AES.GCM.seal(plaintext, using: key)
            // Store nonce (12 bytes) + ciphertext + tag (16 bytes) separately.
            let cipherAndTag = sealed.ciphertext + sealed.tag
            return (cipherAndTag, Data(sealed.nonce))
        } catch {
            // SAFE: This only fails if the system CSPRNG is unavailable — unrecoverable.
            fatalError("SampleCrosswordRepository: AES-GCM encryption failed: \(error)")
        }
    }
}
