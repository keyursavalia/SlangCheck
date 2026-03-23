// Data/CoreData/CoreDataSlangTermRepository.swift
// SlangCheck
//
// Concrete implementation of SlangTermRepository backed by CoreData.
// All writes use a private background context (TECH_STACK.md §3.1).
// The view context is never written to directly.
// An AsyncStream bridges CoreData changes to the lexiconStream consumer.

import CoreData
import Foundation
import OSLog

// MARK: - CoreDataSlangTermRepository

/// The production repository implementation. Translates between CoreData managed objects
/// and the domain model types defined in `Core/Models/`.
public actor CoreDataSlangTermRepository: SlangTermRepository {

    // MARK: - Properties

    private let persistence: PersistenceController

    /// Continuation for the lexicon AsyncStream. Notified on every lexicon change.
    private var lexiconContinuation: AsyncStream<UserLexicon>.Continuation?

    // MARK: - Initialization

    public init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    // MARK: - SlangTermRepository: Seed

    public func seedIfNeeded() async throws(SlangRepositoryError) {
        let storedVersion = UserDefaults.standard.integer(forKey: AppConstants.seedVersionKey)
        guard storedVersion < AppConstants.seedVersion else {
            Logger.repository.info("Seed is up to date (v\(AppConstants.seedVersion)). Skipping.")
            return
        }

        Logger.repository.info("Seed version mismatch (stored: \(storedVersion) → current: \(AppConstants.seedVersion)). Re-seeding dictionary.")
        let terms = try loadSeedData()
        let context = persistence.newBackgroundContext()

        await context.perform {
            // Remove all existing dictionary terms; CDLexiconEntry rows are a separate
            // entity and are intentionally preserved across reseeds.
            if let existing = try? context.fetch(CDSlangTerm.fetchRequest()) {
                existing.forEach { context.delete($0) }
            }
            for term in terms {
                let entity = CDSlangTerm(context: context)
                entity.populate(from: term)
            }
            do {
                try context.save()
                Logger.repository.info("Seed complete: \(terms.count) terms written (v\(AppConstants.seedVersion)).")
            } catch {
                Logger.repository.error("Seed save failed: \(error.localizedDescription)")
            }
        }

        UserDefaults.standard.set(AppConstants.seedVersion, forKey: AppConstants.seedVersionKey)
    }

    // MARK: - SlangTermRepository: Dictionary

    public func fetchAllTerms() async throws(SlangRepositoryError) -> [SlangTerm] {
        let request = CDSlangTerm.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "term", ascending: true)]
        request.fetchBatchSize = 20 // NF-P-003
        return try await performFetch(request: request)
    }

    public func fetchTerms(in category: SlangCategory) async throws(SlangRepositoryError) -> [SlangTerm] {
        let request = CDSlangTerm.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "term", ascending: true)]
        request.fetchBatchSize = 20
        return try await performFetch(request: request)
    }

    public func fetchTerm(id: UUID) async throws(SlangRepositoryError) -> SlangTerm {
        let request = CDSlangTerm.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let results = try await performFetch(request: request)
        guard let term = results.first else {
            throw SlangRepositoryError.termNotFound(id: id)
        }
        return term
    }

    // MARK: - SlangTermRepository: Lexicon

    public func fetchLexicon() async throws(SlangRepositoryError) -> UserLexicon {
        let context = persistence.viewContext
        let request = CDLexiconEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: false)]

        do {
            let entries: [LexiconEntry] = try await context.perform {
                let managed = try context.fetch(request)
                return managed.compactMap { $0.toDomainModel() }
            }
            return UserLexicon(entries: entries)
        } catch {
            throw SlangRepositoryError.fetchFailed(underlying: error)
        }
    }

    public func addToLexicon(termID: UUID) async throws(SlangRepositoryError) {
        let context = persistence.newBackgroundContext()

        do {
            try await context.perform {
                // Check for duplicates before inserting.
                let check = CDLexiconEntry.fetchRequest()
                check.predicate = NSPredicate(format: "termID == %@", termID as CVarArg)
                check.fetchLimit = 1
                let existing = (try? context.fetch(check)) ?? []
                guard existing.isEmpty else { return }

                let entry = CDLexiconEntry(context: context)
                entry.termID    = termID
                entry.savedDate = Date()
                try context.save()
            }
            Logger.repository.info("Term \(termID.uuidString) added to lexicon.")
            await notifyLexiconChanged()
        } catch {
            throw SlangRepositoryError.saveFailed(underlying: error)
        }
    }

    public func removeFromLexicon(termID: UUID) async throws(SlangRepositoryError) {
        let context = persistence.newBackgroundContext()

        do {
            try await context.perform {
                let request = CDLexiconEntry.fetchRequest()
                request.predicate = NSPredicate(format: "termID == %@", termID as CVarArg)
                let entries = try context.fetch(request)
                entries.forEach { context.delete($0) }
                if context.hasChanges { try context.save() }
            }
            Logger.repository.info("Term \(termID.uuidString) removed from lexicon.")
            await notifyLexiconChanged()
        } catch {
            throw SlangRepositoryError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Lexicon Stream

    /// An `AsyncStream` that emits the current `UserLexicon` whenever the lexicon changes.
    /// Callers must hold a reference to keep the stream alive.
    public var lexiconStream: AsyncStream<UserLexicon> {
        AsyncStream { continuation in
            self.lexiconContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.clearLexiconContinuation() }
            }
        }
    }

    // MARK: - Private Helpers

    private func clearLexiconContinuation() {
        lexiconContinuation = nil
    }

    private func notifyLexiconChanged() async {
        guard let continuation = lexiconContinuation else { return }
        do {
            let lexicon = try await fetchLexicon()
            continuation.yield(lexicon)
        } catch {
            Logger.repository.error("Failed to fetch lexicon for stream update: \(error.localizedDescription)")
        }
    }

    private func performFetch(request: NSFetchRequest<CDSlangTerm>) async throws(SlangRepositoryError) -> [SlangTerm] {
        let context = persistence.viewContext
        do {
            let results: [SlangTerm] = try await context.perform {
                let managed = try context.fetch(request)
                return managed.compactMap { $0.toDomainModel() }
            }
            return results
        } catch {
            throw SlangRepositoryError.fetchFailed(underlying: error)
        }
    }

    // MARK: - Seed Data Loading

    private func loadSeedData() throws(SlangRepositoryError) -> [SlangTerm] {
        guard let url = Bundle.main.url(
            forResource: AppConstants.seedDataFilename,
            withExtension: AppConstants.seedDataExtension
        ) else {
            Logger.repository.error("Seed file not found in bundle: \(AppConstants.seedDataFilename).\(AppConstants.seedDataExtension)")
            throw SlangRepositoryError.seedFileNotFound
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode([SlangTerm].self, from: data)
        } catch {
            Logger.repository.error("Seed data decode failed: \(error.localizedDescription)")
            throw SlangRepositoryError.seedDataCorrupted(underlying: error)
        }
    }
}
