// App/AppEnvironment.swift
// SlangCheck
//
// Root dependency injection container. Value type injected via SwiftUI .environment().
// All concrete service instances are created once at app launch in SlangCheckApp.swift.
// Never use a global singleton or service locator — always go through AppEnvironment.

import SwiftUI

// MARK: - AppEnvironment

/// The root container for all app-wide dependencies.
/// Passed down the SwiftUI view hierarchy via `.environment(\.appEnvironment, env)`.
public struct AppEnvironment {

    // MARK: Dependencies

    /// The data access layer for slang terms and the user's lexicon.
    public let slangTermRepository: any SlangTermRepository

    /// The data access layer for the Aura Economy (local cache).
    public let auraRepository: any AuraRepository

    /// The use case that saves an `AuraProfile` locally and syncs it to Firestore.
    public let syncAuraProfileUseCase: SyncAuraProfileUseCase

    /// The CoreData persistence stack. Needed by ViewModels that spawn their own FRC.
    public let persistence: PersistenceController

    /// Platform haptic feedback service.
    public let hapticService: any HapticServiceProtocol

    // MARK: Initialization

    public init(
        slangTermRepository: any SlangTermRepository,
        auraRepository: any AuraRepository,
        syncAuraProfileUseCase: SyncAuraProfileUseCase,
        persistence: PersistenceController,
        hapticService: any HapticServiceProtocol
    ) {
        self.slangTermRepository    = slangTermRepository
        self.auraRepository         = auraRepository
        self.syncAuraProfileUseCase = syncAuraProfileUseCase
        self.persistence            = persistence
        self.hapticService          = hapticService
    }

    // MARK: Factory — Production

    /// Builds the production dependency graph.
    public static func production() -> AppEnvironment {
        let persistence  = PersistenceController()
        let slangRepo    = CoreDataSlangTermRepository(persistence: persistence)
        // UserDefaultsAuraRepository is used until CDAuraProfile / CDQuizResult
        // entities are added to SlangCheckData.xcdatamodeld (A-006). Swap back to
        // CoreDataAuraRepository(persistence: persistence) after that migration.
        let auraRepo     = UserDefaultsAuraRepository()
        let haptics      = HapticService()

        // Use FirebaseAuraSyncService when the Firebase SDK is present (added via SPM).
        // Falls back to NoOpAuraSyncService until Firebase is configured.
        #if canImport(FirebaseFirestore) && canImport(FirebaseAuth)
        let syncService: any AuraSyncService = FirebaseAuraSyncService()
        #else
        let syncService: any AuraSyncService = NoOpAuraSyncService()
        #endif

        let syncUseCase = SyncAuraProfileUseCase(
            auraRepository: auraRepo,
            syncService:    syncService
        )

        return AppEnvironment(
            slangTermRepository:    slangRepo,
            auraRepository:         auraRepo,
            syncAuraProfileUseCase: syncUseCase,
            persistence:            persistence,
            hapticService:          haptics
        )
    }

    // MARK: Factory — Preview / Test

    /// Builds an in-memory environment suitable for SwiftUI Previews and unit tests.
    public static func preview() -> AppEnvironment {
        // Fresh UserDefaults suite per preview so runs don't share persisted state.
        let previewDefaults = UserDefaults(suiteName: "preview-\(UUID().uuidString)")!
        let persistence     = PersistenceController(inMemory: true)
        let slangRepo       = CoreDataSlangTermRepository(persistence: persistence)
        let auraRepo        = UserDefaultsAuraRepository(defaults: previewDefaults)
        let haptics         = HapticService()
        let syncUseCase     = SyncAuraProfileUseCase(
            auraRepository: auraRepo,
            syncService:    NoOpAuraSyncService()
        )
        return AppEnvironment(
            slangTermRepository:    slangRepo,
            auraRepository:         auraRepo,
            syncAuraProfileUseCase: syncUseCase,
            persistence:            persistence,
            hapticService:          haptics
        )
    }
}

// MARK: - EnvironmentKey

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment = .preview()
}

extension EnvironmentValues {
    /// Access the injected `AppEnvironment` from any SwiftUI view.
    public var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
