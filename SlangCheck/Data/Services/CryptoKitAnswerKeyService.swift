// Data/Services/CryptoKitAnswerKeyService.swift
// SlangCheck
//
// Concrete AES-GCM answer key decryption using Apple's CryptoKit.
// Import is unconditional — CryptoKit ships with iOS 13+ and requires no SPM dep.

import CryptoKit
import Foundation

// MARK: - CryptoKitAnswerKeyService

/// Decrypts a `CrosswordPuzzle`'s encrypted answer key using `CryptoKit.AES.GCM`.
///
/// The encrypted blob stored in `CrosswordPuzzle.encryptedAnswerKey` is the
/// raw AES-GCM ciphertext + 16-byte authentication tag (CryptoKit's combined
/// representation minus the nonce, which is stored separately in
/// `encryptionNonce`). The 32-byte symmetric key is issued by the server's
/// Cloud Function at or after `revealAt`.
public struct CryptoKitAnswerKeyService: AnswerKeyService {

    public init() {}

    // MARK: - AnswerKeyService

    public func decrypt(using symmetricKey: Data, puzzle: CrosswordPuzzle) throws(AnswerKeyError) -> [String: String] {
        // Build the CryptoKit key — must be exactly 32 bytes (AES-256).
        guard symmetricKey.count == 32 else { throw AnswerKeyError.invalidData }

        let key: SymmetricKey
        key = SymmetricKey(data: symmetricKey)

        // Build the AES-GCM nonce — must be exactly 12 bytes.
        guard puzzle.encryptionNonce.count == 12 else { throw AnswerKeyError.invalidData }

        let nonce: AES.GCM.Nonce
        do {
            nonce = try AES.GCM.Nonce(data: puzzle.encryptionNonce)
        } catch {
            throw AnswerKeyError.invalidData
        }

        // The stored ciphertext includes the 16-byte GCM authentication tag
        // appended by CryptoKit at the end of the ciphertext bytes.
        guard puzzle.encryptedAnswerKey.count > 16 else { throw AnswerKeyError.invalidData }
        let ciphertextBody = puzzle.encryptedAnswerKey.dropLast(16)
        let tag            = puzzle.encryptedAnswerKey.suffix(16)

        let sealedBox: AES.GCM.SealedBox
        do {
            sealedBox = try AES.GCM.SealedBox(nonce: nonce,
                                               ciphertext: ciphertextBody,
                                               tag: tag)
        } catch {
            throw AnswerKeyError.invalidData
        }

        // Decrypt and authenticate.
        let plaintext: Data
        do {
            plaintext = try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw AnswerKeyError.decryptionFailed(underlying: error)
        }

        // Decode the JSON answer dictionary.
        do {
            let answers = try JSONDecoder().decode([String: String].self, from: plaintext)
            return answers
        } catch {
            throw AnswerKeyError.decodingFailed(underlying: error)
        }
    }
}
