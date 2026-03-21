// Data/CoreData/CoreDataAuraRepository.swift
// SlangCheck
//
// Concrete CoreData implementation of AuraRepository.
// All writes use a private background context. View context is read-only.

import CoreData
import Foundation
import OSLog

// MARK: - CoreDataAuraRepository

/// Production `AuraRepository` backed by CoreData.
///
/// Follows the same patterns as `CoreDataSlangTermRepository`:
/// - `actor` isolation for all mutable state.
/// - Background context for every write.
/// - View context for reads (main thread, via `perform`).
public actor CoreDataAuraRepository: AuraRepository {

    // MARK: - Properties

    private let persistence: PersistenceController

    // MARK: - Initialization

    public init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    // MARK: - AuraRepository: Profile

    public func fetchProfile() async throws(AuraRepositoryError) -> AuraProfile? {
        let context = persistence.viewContext
        let request = CDAuraProfile.fetchRequest()
        request.fetchLimit = 1

        do {
            let result: AuraProfile? = try await context.perform {
                let managed = try context.fetch(request)
                return managed.first?.toDomainModel()
            }
            return result
        } catch {
            Logger.quizzes.error("fetchProfile failed: \(error.localizedDescription)")
            throw AuraRepositoryError.fetchFailed(underlying: error)
        }
    }

    public func saveProfile(_ profile: AuraProfile) async throws(AuraRepositoryError) {
        let context = persistence.newBackgroundContext()

        do {
            try await context.perform {
                // Find existing record by id, or create a new one.
                let request = CDAuraProfile.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", profile.id as CVarArg)
                request.fetchLimit = 1

                let existing = try context.fetch(request)
                let entity   = existing.first ?? CDAuraProfile(context: context)
                entity.populate(from: profile)
                try context.save()
            }
            Logger.quizzes.debug("AuraProfile saved. id=\(profile.id.uuidString) points=\(profile.totalPoints)")
        } catch {
            Logger.quizzes.error("saveProfile failed: \(error.localizedDescription)")
            throw AuraRepositoryError.saveFailed(underlying: error)
        }
    }

    // MARK: - AuraRepository: Quiz History

    public func saveQuizResult(_ result: QuizResult) async throws(AuraRepositoryError) {
        let context = persistence.newBackgroundContext()

        do {
            try await context.perform {
                // Guard against duplicate inserts (idempotent).
                let check = CDQuizResult.fetchRequest()
                check.predicate = NSPredicate(format: "id == %@", result.id as CVarArg)
                check.fetchLimit = 1
                let existing = (try? context.fetch(check)) ?? []
                guard existing.isEmpty else { return }

                let entity = CDQuizResult(context: context)
                entity.populate(from: result)
                try context.save()
            }
            Logger.quizzes.debug("QuizResult saved. id=\(result.id.uuidString)")
        } catch {
            Logger.quizzes.error("saveQuizResult failed: \(error.localizedDescription)")
            throw AuraRepositoryError.saveFailed(underlying: error)
        }
    }

    public func fetchQuizHistory() async throws(AuraRepositoryError) -> [QuizResult] {
        let context = persistence.viewContext
        let request = CDQuizResult.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]
        request.fetchBatchSize  = 20

        do {
            let results: [QuizResult] = try await context.perform {
                let managed = try context.fetch(request)
                return managed.compactMap { $0.toDomainModel() }
            }
            return results
        } catch {
            Logger.quizzes.error("fetchQuizHistory failed: \(error.localizedDescription)")
            throw AuraRepositoryError.fetchFailed(underlying: error)
        }
    }
}
