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

        /// Authentication service (Firebase Auth in production, NoOp in previews/tests).
    public let authService: any AuthenticationService

    /// Firestore-backed user profile repository (Firebase in production, NoOp in previews/tests).
    public let userProfileRepository: any UserProfileRepository

    /// Daily crossword puzzle repository. Uses AI generation when available; falls back
    /// to `SampleCrosswordRepository` automatically (see `AIGeneratedCrosswordRepository`).
    public let crosswordRepository: any CrosswordRepository

    /// CoreData persistence stack. Needed by ViewModels that spawn their own FRC.
    public let persistence: PersistenceController

    /// Platform haptic feedback service.
    public let hapticService: any HapticServiceProtocol

    /// Translation augmentation service (Apple Intelligence on iOS 26+, no-op below).
    public let aiTranslationService: any AITranslationService

    /// Quiz enhancement service (Apple Intelligence on iOS 26+, no-op below).
    public let aiQuizService: (any AIQuizGenerationService)?

    // MARK: Initialization

    public init(
        slangTermRepository:    any SlangTermRepository,
        auraRepository:         any AuraRepository,
        syncAuraProfileUseCase: SyncAuraProfileUseCase,
        authService:            any AuthenticationService,
        userProfileRepository:  any UserProfileRepository,
        crosswordRepository:    any CrosswordRepository,
        persistence:            PersistenceController,
        hapticService:          any HapticServiceProtocol,
        aiTranslationService:   any AITranslationService,
        aiQuizService:          (any AIQuizGenerationService)?
    ) {
        self.slangTermRepository   = slangTermRepository
        self.auraRepository        = auraRepository
        self.syncAuraProfileUseCase = syncAuraProfileUseCase
        self.authService           = authService
        self.userProfileRepository = userProfileRepository
        self.crosswordRepository   = crosswordRepository
        self.persistence           = persistence
        self.hapticService         = hapticService
        self.aiTranslationService  = aiTranslationService
        self.aiQuizService         = aiQuizService
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

        // Select Firebase-backed or no-op services depending on whether the SDK is linked.
        #if canImport(FirebaseFirestore) && canImport(FirebaseAuth) && canImport(FirebaseStorage)
        let syncService:    any AuraSyncService         = FirebaseAuraSyncService()
        let authSvc:        any AuthenticationService   = FirebaseAuthenticationService()
        let profileRepo:    any UserProfileRepository   = FirebaseUserProfileRepository()
        #else
        let syncService:    any AuraSyncService         = NoOpAuraSyncService()
        let authSvc:        any AuthenticationService   = NoOpAuthenticationService()
        let profileRepo:    any UserProfileRepository   = NoOpUserProfileRepository()
        #endif

        let syncUseCase = SyncAuraProfileUseCase(
            auraRepository: auraRepo,
            syncService:    syncService
        )

        // Build AI services — FoundationModels on iOS 26+, no-ops on older OS.
        let (aiTranslation, aiQuiz, aiCrossword) = makeAIServices()

        // AIGeneratedCrosswordRepository handles graceful fallback to SampleCrosswordRepository
        // internally, so we always use it as the production crossword repository.
        let crosswordRepo = AIGeneratedCrosswordRepository(
            slangRepository: slangRepo,
            aiService:       aiCrossword
        )

        return AppEnvironment(
            slangTermRepository:    slangRepo,
            auraRepository:         auraRepo,
            syncAuraProfileUseCase: syncUseCase,
            authService:            authSvc,
            userProfileRepository:  profileRepo,
            crosswordRepository:    crosswordRepo,
            persistence:            persistence,
            hapticService:          haptics,
            aiTranslationService:   aiTranslation,
            aiQuizService:          aiQuiz
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
        let crosswordRepo   = SampleCrosswordRepository(defaults: previewDefaults)
        return AppEnvironment(
            slangTermRepository:    slangRepo,
            auraRepository:         auraRepo,
            syncAuraProfileUseCase: syncUseCase,
            authService:            NoOpAuthenticationService(),
            userProfileRepository:  NoOpUserProfileRepository(),
            crosswordRepository:    crosswordRepo,
            persistence:            persistence,
            hapticService:          haptics,
            aiTranslationService:   NoOpAITranslationService(),
            aiQuizService:          nil
        )
    }

    // MARK: Private — AI Service Factory

    /// Returns the three AI service implementations appropriate for the current runtime.
    ///
    /// **Fallback chain** (quiz & crossword):
    /// 1. Apple Intelligence (`FoundationModels*` on iOS 26+) — best quality, on-device.
    /// 2. Gemini REST API (`Gemini*Service`) — remote, requires `Secrets.plist` key.
    /// 3. Static content (no-op) — deterministic pool-based fallback.
    ///
    /// The `Fallback*Service` composites try step 1 first; if it returns `nil`
    /// (AI unavailable or disabled), they automatically delegate to step 2.
    /// If step 2 also returns `nil` (no API key / network error), callers
    /// fall back to static content (step 3) as they already do today.
    private static func makeAIServices() -> (
        translation: any AITranslationService,
        quiz:        any AIQuizGenerationService,
        crossword:   any AICrosswordGenerationService
    ) {
        let geminiQuiz      = GeminiQuizService()
        let geminiCrossword = GeminiCrosswordService()

        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let appleQuiz      = FoundationModelsQuizService()
            let appleCrossword = FoundationModelsCrosswordService()
            return (
                FoundationModelsTranslationService(),
                FallbackQuizService(primary: appleQuiz, fallback: geminiQuiz),
                FallbackCrosswordService(primary: appleCrossword, fallback: geminiCrossword)
            )
        }
        #endif

        // iOS < 26: Gemini is the only AI option. Translation stays no-op
        // (dictionary-based local translation is sufficient).
        return (
            NoOpAITranslationService(),
            geminiQuiz,
            geminiCrossword
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
