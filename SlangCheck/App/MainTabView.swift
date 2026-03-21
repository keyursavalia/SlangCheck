// App/MainTabView.swift
// SlangCheck
//
// The root tab bar container. Hosts 5 tabs per FR-G-001:
//   0 — Swiper, 1 — Glossary, 2 — Translator, 3 — Quizzes (placeholder), 4 — Profile
// Tab state is preserved across tab switches (FR-G-004).

import SwiftUI

// MARK: - MainTabView

/// Root navigation container for the entire app after onboarding.
struct MainTabView: View {

    @State private var selectedTab = AppConstants.TabIndex.swiper
    @Environment(\.appEnvironment) private var env

    // Lexicon count badge for the Profile tab (FR-L-005).
    @State private var lexiconCount: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: Swiper
            SwiperView()
                .tabItem {
                    Label(
                        String(localized: "tab.swiper", defaultValue: "Swiper"),
                        systemImage: selectedTab == AppConstants.TabIndex.swiper
                            ? "rectangle.stack.fill"
                            : "rectangle.stack"
                    )
                }
                .tag(AppConstants.TabIndex.swiper)

            // MARK: Glossary
            GlossaryView()
                .tabItem {
                    Label(
                        String(localized: "tab.glossary", defaultValue: "Glossary"),
                        systemImage: selectedTab == AppConstants.TabIndex.glossary
                            ? "books.vertical.fill"
                            : "books.vertical"
                    )
                }
                .tag(AppConstants.TabIndex.glossary)

            // MARK: Translator
            TranslatorView()
                .tabItem {
                    Label(
                        String(localized: "tab.translator", defaultValue: "Translator"),
                        systemImage: selectedTab == AppConstants.TabIndex.translator
                            ? "character.bubble.fill"
                            : "character.bubble"
                    )
                }
                .tag(AppConstants.TabIndex.translator)

            // MARK: Quizzes
            QuizzesView()
                .tabItem {
                    Label(
                        String(localized: "tab.quizzes", defaultValue: "Quizzes"),
                        systemImage: selectedTab == AppConstants.TabIndex.quizzes
                            ? "trophy.fill"
                            : "trophy"
                    )
                }
                .tag(AppConstants.TabIndex.quizzes)

            // MARK: Profile
            ProfileView()
                .tabItem {
                    Label(
                        String(localized: "tab.profile", defaultValue: "Profile"),
                        systemImage: selectedTab == AppConstants.TabIndex.profile
                            ? "person.fill"
                            : "person"
                    )
                }
                .badge(lexiconCount > 0 ? lexiconCount : 0)
                .tag(AppConstants.TabIndex.profile)
        }
        .tint(SlangColor.primary)
        .task {
            await refreshLexiconBadge()
        }
        .onChange(of: selectedTab) { _, _ in
            // Refresh badge when switching to Profile tab.
            Task { await refreshLexiconBadge() }
        }
    }

    // MARK: - Lexicon Badge (FR-L-005)

    private func refreshLexiconBadge() async {
        if let lexicon = try? await env.slangTermRepository.fetchLexicon() {
            lexiconCount = lexicon.count
        }
    }
}

// MARK: - Preview

#Preview("MainTabView") {
    MainTabView()
        .environment(\.appEnvironment, .preview())
}
