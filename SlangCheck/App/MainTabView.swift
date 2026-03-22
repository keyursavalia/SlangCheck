// App/MainTabView.swift
// SlangCheck
//
// Root tab bar — 4 tabs: Learn · Translator · Quizzes · More.
// Glossary and Profile are accessed via the "More" menu.
// Crossword is removed from the tab bar.
// Tab state is preserved across tab switches (FR-G-004).

import SwiftUI

// MARK: - MainTabView

/// Root navigation container for the entire app after onboarding.
///
/// Tab layout:
///   0 — Learn (Swiper)
///   1 — Translator
///   2 — Quizzes
///   3 — More  →  Glossary, Profile
struct MainTabView: View {

    @State private var selectedTab = AppConstants.TabIndex.swiper
    @Environment(\.appEnvironment) private var env

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: 0 — Learn
            SwiperView()
                .tabItem {
                    Label(
                        String(localized: "tab.swiper", defaultValue: "Learn"),
                        systemImage: selectedTab == AppConstants.TabIndex.swiper
                            ? "rectangle.stack.fill"
                            : "rectangle.stack"
                    )
                }
                .tag(AppConstants.TabIndex.swiper)

            // MARK: 1 — Translator
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

            // MARK: 2 — Games
            QuizzesView()
                .tabItem {
                    Label(
                        String(localized: "tab.quizzes", defaultValue: "Games"),
                        systemImage: selectedTab == AppConstants.TabIndex.quizzes
                            ? "gamecontroller.fill"
                            : "gamecontroller"
                    )
                }
                .tag(AppConstants.TabIndex.quizzes)

            // MARK: 3 — More (Glossary + Profile)
            MoreMenuView()
                .tabItem {
                    Label(
                        String(localized: "tab.more", defaultValue: "More"),
                        systemImage: selectedTab == AppConstants.TabIndex.more
                            ? "ellipsis.circle.fill"
                            : "ellipsis.circle"
                    )
                }
                .tag(AppConstants.TabIndex.more)
        }
        .tint(SlangColor.primary)
    }
}

// MARK: - MoreMenuView

/// Presents Glossary and Profile as navigation destinations from a simple menu list.
/// Keeps the tab bar at 4 items (iOS HIG recommends ≤5) while decluttering the bar.
private struct MoreMenuView: View {

    @Environment(\.appEnvironment) private var env
    @State private var lexiconCount: Int = 0

    var body: some View {
        NavigationStack {
            List {
                // Glossary
                NavigationLink {
                    GlossaryView()
                        .toolbarRole(.navigationStack)
                } label: {
                    moreRow(
                        icon: "books.vertical.fill",
                        iconColor: SlangColor.primary,
                        title: String(localized: "tab.glossary", defaultValue: "Glossary"),
                        subtitle: String(localized: "more.glossary.subtitle",
                                         defaultValue: "Browse all Gen Z slang")
                    )
                }

                // Profile
                NavigationLink {
                    ProfileView()
                        .toolbarRole(.navigationStack)
                } label: {
                    moreRow(
                        icon: "person.fill",
                        iconColor: SlangColor.secondary,
                        title: String(localized: "tab.profile", defaultValue: "Profile"),
                        subtitle: lexiconCount > 0
                            ? "\(lexiconCount) \(String(localized: "more.profile.savedCount", defaultValue: "terms saved"))"
                            : String(localized: "more.profile.subtitle", defaultValue: "Your Aura rank & saved terms")
                    )
                }
            }
            .listStyle(.insetGrouped)
            .background(SlangColor.background.ignoresSafeArea())
            .navigationTitle(String(localized: "tab.more", defaultValue: "More"))
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await refreshLexiconBadge() }
    }

    private func moreRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: SlangSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.slang(.label))
                    .foregroundStyle(SlangColor.labelPrimary)
                Text(subtitle)
                    .font(.slang(.caption))
                    .foregroundStyle(SlangColor.labelSecondary)
            }
        }
        .padding(.vertical, SlangSpacing.xs)
    }

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
        .environment(AuthState(
            authService:       NoOpAuthenticationService(),
            profileRepository: NoOpUserProfileRepository()
        ))
}
