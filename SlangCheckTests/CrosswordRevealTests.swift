// SlangCheckTests/CrosswordRevealTests.swift
// SlangCheck
//
// Unit tests for crossword reveal timing logic and answer key
// encryption / decryption via CryptoKitAnswerKeyService.
// Covers timezone-invariant isRevealable semantics and round-trip correctness.

import CryptoKit
import XCTest
@testable import SlangCheck

// MARK: - CrosswordRevealTests

final class CrosswordRevealTests: XCTestCase {

    // MARK: - isRevealable Timing

    func testIsRevealableTrueWhenRevealAtIsInThePast() {
        let puzzle = makePuzzle(revealAt: Date(timeIntervalSinceNow: -60))
        XCTAssertTrue(puzzle.isRevealable)
    }

    func testIsRevealableFalseWhenRevealAtIsInTheFuture() {
        let puzzle = makePuzzle(revealAt: Date(timeIntervalSinceNow: 3600))
        XCTAssertFalse(puzzle.isRevealable)
    }

    func testIsRevealableFalseExactlyAtRevealAt() throws {
        // Computed date is always at least an epsilon ahead of "now" at the time
        // the guard is evaluated, so a future date guarantees false.
        let futureDate = Date(timeIntervalSinceNow: 3600)
        let puzzle     = makePuzzle(revealAt: futureDate)
        XCTAssertFalse(puzzle.isRevealable, "Puzzle should not be revealable before its revealAt time.")
    }

    // MARK: - AES-GCM Round-Trip

    func testDecryptProducesCorrectAnswerMap() throws {
        let answers: [String: String] = ["0-0": "N", "0-1": "O", "0-2": "C"]
        let key                       = generateKey()
        let puzzle                    = makePuzzle(answers: answers, key: key)
        let service                   = CryptoKitAnswerKeyService()

        let decoded = try service.decrypt(using: key, puzzle: puzzle)
        XCTAssertEqual(decoded, answers)
    }

    func testDecryptAllSamplePuzzleCells() throws {
        let answers: [String: String] = [
            "0-0": "N", "0-1": "O", "0-2": "C", "0-3": "A", "0-4": "P",
            "1-0": "O", "2-0": "O", "3-0": "B", "4-0": "S",
            "1-2": "A", "2-2": "P",
            "4-1": "L", "4-2": "A", "4-3": "Y"
        ]
        let key     = generateKey()
        let puzzle  = makePuzzle(answers: answers, key: key)
        let service = CryptoKitAnswerKeyService()

        let decoded = try service.decrypt(using: key, puzzle: puzzle)
        XCTAssertEqual(decoded.count, answers.count)
        for (cellID, letter) in answers {
            XCTAssertEqual(decoded[cellID], letter, "Mismatch at cell \(cellID)")
        }
    }

    func testDecryptWithWrongKeyThrowsDecryptionFailed() {
        let answers: [String: String] = ["0-0": "X"]
        let correctKey = generateKey()
        let wrongKey   = generateKey()   // Different random key
        let puzzle     = makePuzzle(answers: answers, key: correctKey)
        let service    = CryptoKitAnswerKeyService()

        XCTAssertThrowsError(try service.decrypt(using: wrongKey, puzzle: puzzle)) { error in
            guard case AnswerKeyError.decryptionFailed = error else {
                return XCTFail("Expected .decryptionFailed, got \(error)")
            }
        }
    }

    func testDecryptWithShortKeyThrowsInvalidData() {
        let puzzle  = makePuzzle(answers: ["0-0": "A"], key: Data(repeating: 0, count: 32))
        let service = CryptoKitAnswerKeyService()
        let shortKey = Data(repeating: 0, count: 16)  // 16 bytes instead of 32

        XCTAssertThrowsError(try service.decrypt(using: shortKey, puzzle: puzzle)) { error in
            guard case AnswerKeyError.invalidData = error else {
                return XCTFail("Expected .invalidData, got \(error)")
            }
        }
    }

    func testDecryptWithTamperedCiphertextThrowsDecryptionFailed() {
        let answers  = ["0-0": "Z"]
        let key      = generateKey()
        var puzzle   = makePuzzle(answers: answers, key: key)

        // Flip one bit in the ciphertext to simulate tampering.
        var tampered                = puzzle.encryptedAnswerKey
        tampered[0]                 = tampered[0] ^ 0xFF
        puzzle = CrosswordPuzzle(
            id: puzzle.id,
            date: puzzle.date,
            rows: puzzle.rows,
            cols: puzzle.cols,
            cells: puzzle.cells,
            clues: puzzle.clues,
            encryptedAnswerKey: tampered,
            encryptionNonce: puzzle.encryptionNonce,
            revealAt: puzzle.revealAt
        )

        let service = CryptoKitAnswerKeyService()
        XCTAssertThrowsError(try service.decrypt(using: key, puzzle: puzzle)) { error in
            guard case AnswerKeyError.decryptionFailed = error else {
                return XCTFail("Expected .decryptionFailed, got \(error)")
            }
        }
    }

    // MARK: - CrosswordPuzzle Derived Helpers

    func testTotalLetterCountMatchesAnswerMapSize() {
        let answers: [String: String] = [
            "0-0": "N", "0-1": "O", "0-2": "C", "0-3": "A", "0-4": "P"
        ]
        let puzzle = makePuzzle(answers: answers, key: generateKey())
        XCTAssertEqual(puzzle.totalLetterCount, answers.count)
    }

    func testLetterCellsCountMatchesNonBlackCells() {
        let answers: [String: String] = ["0-0": "A", "0-2": "B"]
        let puzzle = makePuzzle(answers: answers, key: generateKey())
        let expectedLetterCount = puzzle.cells.filter(\.isLetter).count
        XCTAssertEqual(puzzle.letterCells.count, expectedLetterCount)
    }

    func testCellLookupByRowAndCol() {
        let puzzle = makePuzzle(answers: ["0-0": "A"], key: generateKey())
        let cell   = puzzle.cell(row: 0, col: 0)
        XCTAssertNotNil(cell)
        XCTAssertEqual(cell?.id, "0-0")
    }

    func testCellLookupOutOfBoundsReturnsNil() {
        let puzzle = makePuzzle(answers: ["0-0": "A"], key: generateKey())
        XCTAssertNil(puzzle.cell(row: 99, col: 99))
    }

    // MARK: - Helpers

    /// Generates a fresh 32-byte random symmetric key.
    private func generateKey() -> Data {
        Data(SymmetricKey(size: .bits256).withUnsafeBytes { Array($0) })
    }

    /// Builds a minimal `CrosswordPuzzle` from an answer map and symmetric key.
    /// The grid is 1×N where N is the answer count, all cells are letter cells.
    private func makePuzzle(
        answers: [String: String] = ["0-0": "A"],
        key: Data,
        revealAt: Date = Date(timeIntervalSinceNow: -3600)
    ) -> CrosswordPuzzle {
        let answerIDs = Set(answers.keys)
        let maxCol    = answers.keys.compactMap { Int($0.split(separator: "-").last ?? "") }.max() ?? 0
        let cols      = maxCol + 1
        let rows      = 1

        var cells: [CrosswordCell] = []
        for c in 0..<cols {
            let id = "0-\(c)"
            cells.append(CrosswordCell(
                row: 0, col: c,
                kind: answerIDs.contains(id) ? .letter : .black
            ))
        }

        let (ciphertext, nonce) = encrypt(answers, using: key)
        return CrosswordPuzzle(
            date: Date(),
            rows: rows,
            cols: cols,
            cells: cells,
            clues: [],
            encryptedAnswerKey: ciphertext,
            encryptionNonce: nonce,
            revealAt: revealAt
        )
    }

    private func makePuzzle(revealAt: Date) -> CrosswordPuzzle {
        makePuzzle(answers: ["0-0": "A"], key: generateKey(), revealAt: revealAt)
    }

    private func encrypt(_ answers: [String: String], using keyData: Data) -> (Data, Data) {
        let plaintext  = try! JSONEncoder().encode(answers)
        let key        = SymmetricKey(data: keyData)
        let sealed     = try! AES.GCM.seal(plaintext, using: key)
        let ciphertext = sealed.ciphertext + sealed.tag
        return (ciphertext, Data(sealed.nonce))
    }
}
