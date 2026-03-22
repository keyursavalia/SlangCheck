// Core/Services/AnswerKeyService.swift
// SlangCheck
//
// Protocol for decrypting the daily crossword answer key.
// Concrete implementation lives in Data/ and uses CryptoKit.
// Zero UIKit/SwiftUI/CoreData imports — platform-agnostic contract.

import Foundation

// MARK: - AnswerKeyError

/// Errors thrown by `AnswerKeyService` implementations.
public enum AnswerKeyError: LocalizedError, Sendable {
    /// The decryption key, nonce, or ciphertext is malformed.
    case invalidData
    /// AES-GCM authentication tag verification failed (data tampered or wrong key).
    case decryptionFailed(underlying: Error)
    /// The decrypted bytes could not be decoded as a `[String: String]` JSON object.
    case decodingFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return String(localized: "error.answerKey.invalidData",
                          defaultValue: "The answer key data is malformed.")
        case .decryptionFailed(let err):
            return String(localized: "error.answerKey.decryptionFailed",
                          defaultValue: "Could not decrypt the answer key: \(err.localizedDescription)")
        case .decodingFailed(let err):
            return String(localized: "error.answerKey.decodingFailed",
                          defaultValue: "Could not read the answer key: \(err.localizedDescription)")
        }
    }
}

// MARK: - AnswerKeyService Protocol

/// Decrypts the AES-GCM encrypted answer key embedded in a `CrosswordPuzzle`.
///
/// The concrete implementation (`CryptoKitAnswerKeyService`) uses
/// `CryptoKit.AES.GCM`. The protocol exists so tests can supply a
/// `MockAnswerKeyService` without importing CryptoKit.
///
/// ## Usage
/// ```swift
/// let key  = try await repository.fetchDecryptionKey(for: puzzle.id)
/// let answers = try answerKeyService.decrypt(using: key, puzzle: puzzle)
/// // answers["0-0"] == "N", answers["0-1"] == "O", …
/// ```
public protocol AnswerKeyService: Sendable {

    /// Decrypts the answer key embedded in `puzzle` using `symmetricKey`.
    ///
    /// - Parameters:
    ///   - symmetricKey: 32-byte AES-256 key issued by the server Cloud Function.
    ///   - puzzle: The `CrosswordPuzzle` whose `encryptedAnswerKey` and `encryptionNonce`
    ///     will be used for decryption.
    /// - Returns: A dictionary mapping cell IDs (`"row-col"`) to uppercase letters.
    /// - Throws: `AnswerKeyError` on any decryption or decoding failure.
    func decrypt(using symmetricKey: Data, puzzle: CrosswordPuzzle) throws(AnswerKeyError) -> [String: String]
}
