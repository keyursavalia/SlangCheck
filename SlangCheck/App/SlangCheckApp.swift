// App/SlangCheckApp.swift
// SlangCheck
//
// Application entry point. Constructs the production AppEnvironment and injects it
// into the SwiftUI view hierarchy. Seeds the local CoreData store on first launch.

import SwiftUI
import OSLog

// MARK: - SlangCheckApp

@main
struct SlangCheckApp: App {

    // MARK: - Properties

    /// The root dependency container, built once at launch.
    private let environment: AppEnvironment

    // MARK: - Initialization

    init() {
        environment = AppEnvironment.production()
        Logger.app.info("SlangCheckApp initialized. Environment: production.")
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.appEnvironment, environment)
                .task {
                    await seedDatabaseIfNeeded()
                }
        }
    }

    // MARK: - Seed

    /// Seeds the local dictionary from the bundled JSON on first launch (Step 1.3).
    /// This is a no-op if the store already contains data.
    private func seedDatabaseIfNeeded() async {
        do {
            try await environment.slangTermRepository.seedIfNeeded()
        } catch {
            Logger.app.error("Database seed failed: \(error.localizedDescription)")
            // Non-fatal: app can still function; the dictionary will be empty.
        }
    }
}

// MARK: - AppRootView

/// Decides whether to show onboarding or the main tab shell based on UserDefaults flag.
struct AppRootView: View {

    @AppStorage(AppConstants.hasCompletedOnboardingKey) private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }
}
