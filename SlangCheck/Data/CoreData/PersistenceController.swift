// Data/CoreData/PersistenceController.swift
// SlangCheck
//
// Manages the CoreData stack lifecycle.
// Stack configured per TECH_STACK.md §3.1:
//   - NSPersistentContainer in Application Support directory (NF-S-002)
//   - Lightweight migration enabled from day one (NF-R-004)
//   - Background context for all writes; view context (main thread) for reads only

import CoreData
import OSLog

// MARK: - PersistenceController

/// Owns and manages the app's CoreData `NSPersistentContainer`.
/// Shared across the app via `AppEnvironment`.
public final class PersistenceController: Sendable {

    // MARK: - Shared Instance (for SwiftUI previews only)
    // Production code uses the instance injected via AppEnvironment.

    /// In-memory container for SwiftUI Previews. Never used in production.
    public static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()

    // MARK: - Properties

    /// The underlying `NSPersistentContainer`.
    public let container: NSPersistentContainer

    /// The view context — read-only, main thread only.
    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Initialization

    /// - Parameter inMemory: When `true`, uses an in-memory store (for tests and previews).
    public init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SlangCheckData")

        if inMemory {
            // SAFE: force-unwrap on a constant URL constructed from a known valid path component.
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure for Application Support directory (NF-S-002: excluded from user-accessible backups).
            if let description = container.persistentStoreDescriptions.first {
                // Lightweight migration enabled (NF-R-004).
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true
            }
        }

        container.loadPersistentStores { storeDescription, error in
            if let error {
                // Fatal error on store load failure. This is intentional per Apple's recommendation:
                // if the store cannot be loaded, the app cannot function. The error will surface
                // clearly in Xcode/Crashlytics with the description below.
                Logger.persistence.critical("CoreData store load failed: \(error.localizedDescription)")
                fatalError("CoreData store failed to load: \(error.localizedDescription)")
            }
            Logger.persistence.info("CoreData store loaded: \(storeDescription.url?.lastPathComponent ?? "unknown")")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Background Context Factory

    /// Creates a new private background context for write operations.
    /// All CoreData writes MUST happen on a background context, never the view context.
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: - Save Helper

    /// Saves a background context and propagates any errors.
    /// - Parameter context: The background context to save.
    /// - Throws: Core Data save error if the save fails.
    public func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
            Logger.persistence.debug("Background context saved successfully.")
        } catch {
            Logger.persistence.error("Background context save failed: \(error.localizedDescription)")
            throw error
        }
    }
}
