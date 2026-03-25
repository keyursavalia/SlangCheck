// App/SlangCheckApp.swift
// SlangCheck
//
// Application entry point. Constructs the production AppEnvironment and injects it
// into the SwiftUI view hierarchy. Seeds the local CoreData store on first launch.

import SwiftUI
import OSLog
import CoreText
import FirebaseCore

// MARK: - SlangCheckApp

@main
struct SlangCheckApp: App {

    // MARK: - Properties

    /// The root dependency container, built once at launch.
    private let environment: AppEnvironment

    /// Global authentication state. Restored from the persisted Firebase session on launch.
    @State private var authState: AuthState

    // MARK: - Initialization

    init() {
        FirebaseApp.configure()
        let env = AppEnvironment.production()
        environment = env
        // AuthState is created here so it exists before the first view body evaluation.
        // `reload()` is called in the root `.task` to restore any persisted session.
        _authState = State(initialValue: AuthState(
            authService:       env.authService,
            profileRepository: env.userProfileRepository
        ))
        SlangCheckApp.registerBundledFonts()
        SlangCheckApp.configureNavigationBarAppearance()
        Logger.app.info("SlangCheckApp initialized. Environment: production.")
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(\.appEnvironment, environment)
                .environment(authState)
                .task {
                    await seedDatabaseIfNeeded()
                    // Restore persisted Firebase session (if any) before the first render.
                    await authState.reload()
                }
        }
    }

    // MARK: - Navigation Bar Appearance

    /// Configures UINavigationBarAppearance app-wide so all NavigationStacks use
    /// NoticiaText-Bold for titles and the correct blurry-vs-transparent background.
    ///   • scrollEdgeAppearance (large title at top)  → transparent background
    ///   • standardAppearance   (scrolled, inline)    → system default material (blur)
    private static func configureNavigationBarAppearance() {
        let bold17 = UIFont(name: "NoticiaText-Bold", size: 17) ?? UIFont.boldSystemFont(ofSize: 17)
        let bold34 = UIFont(name: "NoticiaText-Bold", size: 34) ?? UIFont.boldSystemFont(ofSize: 34)

        // Scrolled state — blurry material background, centered inline title
        let standard = UINavigationBarAppearance()
        standard.configureWithDefaultBackground()
        standard.titleTextAttributes     = [.font: bold17]
        standard.largeTitleTextAttributes = [.font: bold34]

        // Top-of-scroll state — transparent, large title visible
        let scrollEdge = UINavigationBarAppearance()
        scrollEdge.configureWithTransparentBackground()
        scrollEdge.largeTitleTextAttributes = [.font: bold34]
        scrollEdge.titleTextAttributes      = [.font: bold17]

        UINavigationBar.appearance().standardAppearance   = standard
        UINavigationBar.appearance().compactAppearance    = standard
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdge
    }

    // MARK: - Font Registration

    /// Registers bundled custom fonts with CoreText at launch.
    /// This is the reliable alternative to UIAppFonts in Info.plist when the
    /// project uses a generated Info.plist (GENERATE_INFOPLIST_FILE = YES).
    private static func registerBundledFonts() {
        let fontFiles = [
            "NoticiaText-Regular",
            "NoticiaText-Bold",
            "NoticiaText-Italic",
            "NoticiaText-BoldItalic"
        ]
        for name in fontFiles {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                Logger.app.error("Font file missing from bundle: \(name).ttf")
                continue
            }
            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            if !success, let err = error?.takeRetainedValue() {
                Logger.app.error("Failed to register font \(name): \(err.localizedDescription)")
            } else {
                Logger.app.debug("Registered font: \(name)")
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
