// Data/UserDefaults/UserDefaultsAuraRepository.swift
// SlangCheck
//
// UserDefaults-backed AuraRepository implementation.
//
// Used instead of CoreDataAuraRepository until the developer adds
// CDAuraProfile / CDQuizResult entities to SlangCheckData.xcdatamodeld (A-006).
// AuraProfile and QuizResult are not sensitive data — no credentials or PII —
// so UserDefaults is an appropriate store for this game-progress payload.

import Foundation
import OSLog

// MARK: - UserDefaultsAuraRepository

/// An `AuraRepository` that persists the user's Aura Profile and quiz history
/// as JSON blobs in `UserDefaults`. Each stored value is keyed by a versioned
/// string so a future migration can be detected and run cleanly.
///
/// All writes are performed on the calling actor's executor (no background
/// context needed — `UserDefaults.set(_:forKey:)` is thread-safe).
public actor UserDefaultsAuraRepository: AuraRepository {

    // MARK: - Keys

    private static let profileKey = "aura.profile.v1"
    private static let historyKey = "aura.quizHistory.v1"

    // MARK: - Dependencies

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    /// - Parameter defaults: The `UserDefaults` suite to read/write.
    ///   Pass `UserDefaults(suiteName: UUID().uuidString)!` for test isolation.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - AuraRepository: Profile

    public func fetchProfile() async throws(AuraRepositoryError) -> AuraProfile? {
        guard let data = defaults.data(forKey: Self.profileKey) else { return nil }
        do {
            return try decoder.decode(AuraProfile.self, from: data)
        } catch {
            Logger.quizzes.error("UserDefaultsAuraRepository.fetchProfile decode error: \(error.localizedDescription)")
            throw AuraRepositoryError.fetchFailed(underlying: error)
        }
    }

    public func saveProfile(_ profile: AuraProfile) async throws(AuraRepositoryError) {
        do {
            let data = try encoder.encode(profile)
            defaults.set(data, forKey: Self.profileKey)
            Logger.quizzes.debug("UserDefaultsAuraRepository: profile saved. points=\(profile.totalPoints)")
        } catch {
            Logger.quizzes.error("UserDefaultsAuraRepository.saveProfile encode error: \(error.localizedDescription)")
            throw AuraRepositoryError.saveFailed(underlying: error)
        }
    }

    // MARK: - AuraRepository: Quiz History

    public func saveQuizResult(_ result: QuizResult) async throws(AuraRepositoryError) {
        var history = loadHistoryFromDefaults()
        // Idempotent — skip if already stored.
        guard !history.contains(where: { $0.id == result.id }) else { return }
        history.insert(result, at: 0)
        // Cap history at 100 entries to bound storage growth.
        if history.count > 100 { history = Array(history.prefix(100)) }
        do {
            let data = try encoder.encode(history)
            defaults.set(data, forKey: Self.historyKey)
            Logger.quizzes.debug("UserDefaultsAuraRepository: quiz result saved. id=\(result.id.uuidString)")
        } catch {
            Logger.quizzes.error("UserDefaultsAuraRepository.saveQuizResult encode error: \(error.localizedDescription)")
            throw AuraRepositoryError.saveFailed(underlying: error)
        }
    }

    public func fetchQuizHistory() async throws(AuraRepositoryError) -> [QuizResult] {
        loadHistoryFromDefaults()
    }

    // MARK: - Private

    /// Synchronous read — avoids actor suspension when called from `saveQuizResult`.
    private func loadHistoryFromDefaults() -> [QuizResult] {
        guard let data = defaults.data(forKey: Self.historyKey),
              let history = try? decoder.decode([QuizResult].self, from: data)
        else { return [] }
        return history
    }
}
