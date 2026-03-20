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

    /// The CoreData persistence stack. Needed by ViewModels that spawn their own FRC.
    public let persistence: PersistenceController

    /// Platform haptic feedback service.
    public let hapticService: any HapticServiceProtocol

    // MARK: Initialization

    public init(
        slangTermRepository: any SlangTermRepository,
        persistence: PersistenceController,
        hapticService: any HapticServiceProtocol
    ) {
        self.slangTermRepository = slangTermRepository
        self.persistence         = persistence
        self.hapticService       = hapticService
    }

    // MARK: Factory — Production

    /// Builds the production dependency graph.
    public static func production() -> AppEnvironment {
        let persistence = PersistenceController()
        let repository  = CoreDataSlangTermRepository(persistence: persistence)
        let haptics     = HapticService()
        return AppEnvironment(
            slangTermRepository: repository,
            persistence:         persistence,
            hapticService:       haptics
        )
    }

    // MARK: Factory — Preview / Test

    /// Builds an in-memory environment suitable for SwiftUI Previews and unit tests.
    public static func preview() -> AppEnvironment {
        let persistence = PersistenceController(inMemory: true)
        let repository  = CoreDataSlangTermRepository(persistence: persistence)
        let haptics     = HapticService()
        return AppEnvironment(
            slangTermRepository: repository,
            persistence:         persistence,
            hapticService:       haptics
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
