// Features/Profile/ProfileView.swift
// SlangCheck
//
// Profile sheet: avatar header, category browsing grid, and quick-access vocabulary rows.
// Presented as a full-screen cover from SwiperView's profile avatar button.

import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {

    @Environment(\.appEnvironment) private var env
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss

    @State private var lexiconCount: Int = 0
    @State private var favoritesCount: Int = 0
    @State private var showingGlossary = false
    @State private var navigateToFavorites = false
    @State private var navigateToCollections = false

    private let columns = [
        GridItem(.flexible(), spacing: SlangSpacing.md),
        GridItem(.flexible(), spacing: SlangSpacing.md)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SlangSpacing.lg) {
                    profileHeader
                    quickAccessSection
                }
                .padding(.horizontal, SlangSpacing.lg)
                .padding(.top, SlangSpacing.md)
                .padding(.bottom, SlangSpacing.xxl)
            }
            .background(SlangColor.background.ignoresSafeArea())
            .navigationTitle(String(localized: "profile.title", defaultValue: "Profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(String(localized: "profile.close", defaultValue: "Close"))
                }
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(String(localized: "profile.settings", defaultValue: "Settings"))
                }
            }
            .navigationDestination(isPresented: $navigateToFavorites) {
                FavoritesView().environment(\.appEnvironment, env)
            }
            .navigationDestination(isPresented: $navigateToCollections) {
                LexiconView().environment(\.appEnvironment, env)
            }
        }
        .fullScreenCover(isPresented: $showingGlossary) {
            NavigationStack {
                GlossaryView(initialCategory: nil)
            }
            .environment(\.appEnvironment, env)
        }
        .task { await refreshCounts() }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: SlangSpacing.md) {
            avatarView
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(authState.currentProfile?.displayName
                     ?? String(localized: "profile.guest", defaultValue: "Guest User"))
                    .font(.slang(.heading))
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .padding(SlangSpacing.md)
        .frame(maxWidth: .infinity)
        .profileCard()
    }

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            Circle().fill(SlangColor.primary.opacity(0.1))
            if let url = authState.currentProfile?.photoURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        avatarFallback
                    }
                }
            } else {
                avatarFallback
            }
        }
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(SlangColor.primary.opacity(0.25), lineWidth: 1.5))
    }

    private var avatarFallback: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 22, weight: .light))
            .foregroundStyle(SlangColor.primary.opacity(0.6))
    }

    // MARK: - Quick Access Section

    private var quickAccessSection: some View {
        VStack(spacing: SlangSpacing.md) {
            HStack(spacing: SlangSpacing.md) {
                Button { navigateToFavorites = true } label: {
                    CategoryCardContent(
                        symbolName: "heart.fill",
                        title: String(localized: "profile.nav.favorites", defaultValue: "Favorites"),
                        subtitle: String(localized: "profile.nav.favorites.sub",
                                        defaultValue: "Your liked terms")
                    )
                }
                .buttonStyle(.plain)

                Button { navigateToCollections = true } label: {
                    CategoryCardContent(
                        symbolName: "bookmark.fill",
                        title: String(localized: "profile.nav.lexicon", defaultValue: "Collections"),
                        subtitle: String(localized: "profile.nav.lexicon.sub",
                                        defaultValue: "Saved words")
                    )
                }
                .buttonStyle(.plain)
            }

            Button { showingGlossary = true } label: {
                CategoryCardContent(
                    symbolName: "books.vertical.fill",
                    title: String(localized: "profile.nav.glossary", defaultValue: "All Slang"),
                    subtitle: String(localized: "profile.nav.glossary.sub",
                                    defaultValue: "Full dictionary")
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func refreshCounts() async {
        if let lexicon = try? await env.slangTermRepository.fetchLexicon() {
            lexiconCount = lexicon.count
        }
        if let data = UserDefaults.standard.data(forKey: AppConstants.userFavoritesKey),
           let fav = try? JSONDecoder().decode(UserFavorites.self, from: data) {
            favoritesCount = fav.count
        }
    }
}

// MARK: - Preview

#Preview("ProfileView") {
    Color.clear.sheet(isPresented: .constant(true)) {
        ProfileView()
            .environment(\.appEnvironment, .preview())
            .environment(AuthState(
                authService: NoOpAuthenticationService(),
                profileRepository: NoOpUserProfileRepository()
            ))
    }
}
