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
    @State private var showingLexicon = false
    @State private var showingFavorites = false
    @State private var showingGlossary = false
    @State private var glossaryCategory: SlangCategory? = nil

    private let columns = [
        GridItem(.flexible(), spacing: SlangSpacing.md),
        GridItem(.flexible(), spacing: SlangSpacing.md)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SlangSpacing.lg) {
                    profileHeader
                    categoryGrid
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
        }
        .fullScreenCover(isPresented: $showingFavorites) {
            FavoritesView()
        }
        .sheet(isPresented: $showingLexicon, onDismiss: {
            Task { await refreshCounts() }
        }) {
            LexiconView()
        }
        .fullScreenCover(isPresented: $showingGlossary) {
            NavigationStack {
                GlossaryView(initialCategory: glossaryCategory)
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

    // MARK: - Category Grid

    /// 2-column grid of slang categories. Tapping each opens the Glossary filtered to that category.
    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: SlangSpacing.sm) {
            Text(String(localized: "profile.section.browse", defaultValue: "BROWSE BY VIBE"))
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .tracking(2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            LazyVGrid(columns: columns, spacing: SlangSpacing.md) {
                ForEach(featuredCategories, id: \.self) { category in
                    CategoryCard(category: category) {
                        glossaryCategory = category
                        showingGlossary = true
                    }
                }
            }
        }
    }

    private let featuredCategories: [SlangCategory] = [
        .foundationalDescriptor,
        .brainrot,
        .socialArchetype,
        .reaction,
        .gamingInternet,
        .aesthetic,
        .relationship,
        .emerging2026
    ]

    // MARK: - Quick Access Section

    private var quickAccessSection: some View {
        VStack(spacing: SlangSpacing.sm) {
            QuickAccessRow(
                symbolName: "heart.fill",
                title: String(localized: "profile.nav.favorites", defaultValue: "Favorites"),
                badge: favoritesCount > 0 ? "\(favoritesCount)" : nil,
                color: .red.opacity(0.75),
                action: { showingFavorites = true }
            )
            QuickAccessRow(
                symbolName: "bookmark.fill",
                title: String(localized: "profile.nav.lexicon", defaultValue: "My Lexicon"),
                badge: lexiconCount > 0 ? "\(lexiconCount)" : nil,
                color: SlangColor.primary,
                action: { showingLexicon = true }
            )
            QuickAccessRow(
                symbolName: "books.vertical.fill",
                title: String(localized: "profile.nav.glossary", defaultValue: "All Slang"),
                badge: nil,
                color: SlangColor.secondary,
                action: {
                    glossaryCategory = nil
                    showingGlossary = true
                }
            )
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

// MARK: - CategoryCard

private struct CategoryCard: View {
    let category: SlangCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: SlangSpacing.xs) {
                Image(systemName: categoryIcon(category))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(SlangColor.primary)
                    .accessibilityHidden(true)

                Spacer()

                Text(category.displayName)
                    .font(.slang(.label))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(categoryTagline(category))
                    .font(.slang(.caption))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(SlangSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
            .profileCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.displayName)
    }

    private func categoryIcon(_ cat: SlangCategory) -> String {
        switch cat {
        case .foundationalDescriptor: return "book.fill"
        case .brainrot:               return "brain.fill"
        case .socialArchetype:        return "person.2.fill"
        case .reaction:               return "bubble.left.fill"
        case .gamingInternet:         return "gamecontroller.fill"
        case .aesthetic:              return "paintbrush.fill"
        case .relationship:           return "heart.fill"
        case .emerging2026:           return "arrow.up.right.circle.fill"
        case .emojiDescriptor:        return "face.smiling.fill"
        case .emojiReaction:          return "ellipsis.bubble.fill"
        case .emojiTone:              return "theatermasks.fill"
        case .regionalNorCal:         return "map.fill"
        case .regionalSoCal:          return "sun.max.fill"
        case .techSiliconValley:      return "laptopcomputer"
        }
    }

    private func categoryTagline(_ cat: SlangCategory) -> String {
        switch cat {
        case .foundationalDescriptor: return "Core slang"
        case .brainrot:               return "Gen Alpha coded"
        case .socialArchetype:        return "Who are you?"
        case .reaction:               return "Express yourself"
        case .gamingInternet:         return "For the gamers"
        case .aesthetic:              return "Vibes only"
        case .relationship:           return "Ship or skip"
        case .emerging2026:           return "Just dropped"
        case .emojiDescriptor:        return "Say it in emoji"
        case .emojiReaction:          return "React differently"
        case .emojiTone:              return "Tone check"
        case .regionalNorCal:         return "Bay Area speak"
        case .regionalSoCal:          return "SoCal vibes"
        case .techSiliconValley:      return "Tech bro lingo"
        }
    }
}

// MARK: - QuickAccessRow

private struct QuickAccessRow: View {
    let symbolName: String
    let title: String
    var badge: String? = nil
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SlangSpacing.md) {
                Image(systemName: symbolName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.slang(.subheading))
                    .foregroundStyle(.primary)

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.slang(.caption))
                        .foregroundStyle(.white)
                        .padding(.horizontal, SlangSpacing.sm)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(color.opacity(0.85)))
                        .accessibilityLabel("\(badge) items")
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, SlangSpacing.md)
            .padding(.vertical, SlangSpacing.md)
            .profileCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
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
