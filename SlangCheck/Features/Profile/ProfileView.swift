// Features/Profile/ProfileView.swift
// SlangCheck
//
// Profile sheet. 2-column feature card grid + "YOUR VOCABULARY" section.
// Presented as a full-screen cover from SwiperView's avatar button.

import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {

    @Environment(\.appEnvironment) private var env
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss

    @State private var lexiconCount: Int = 0
    @State private var favoritesCount: Int = 0
    @State private var auraProfile: AuraProfile? = nil
    @State private var showingLexicon = false
    @State private var showingFavorites = false

    private let columns = [
        GridItem(.flexible(), spacing: SlangSpacing.md),
        GridItem(.flexible(), spacing: SlangSpacing.md)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SlangSpacing.lg) {
                    profileHeader
                    featureGrid
                    vocabularySection
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

                if let profile = auraProfile {
                    Text(profile.currentTier.displayName)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(SlangColor.primary)
                        .padding(.horizontal, SlangSpacing.sm)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(SlangColor.primary.opacity(0.12)))
                }
            }

            Spacer()
        }
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

    // MARK: - Feature Grid

    private var featureGrid: some View {
        LazyVGrid(columns: columns, spacing: SlangSpacing.md) {
            FeatureCard(
                symbolName: "heart.fill",
                title: String(localized: "profile.feature.favorites", defaultValue: "Favorites"),
                badge: favoritesCount > 0 ? "\(favoritesCount)" : nil,
                color: .red.opacity(0.75),
                action: { showingFavorites = true }
            )
            FeatureCard(
                symbolName: "bookmark.fill",
                title: String(localized: "profile.feature.lexicon", defaultValue: "My Lexicon"),
                badge: lexiconCount > 0 ? "\(lexiconCount)" : nil,
                color: SlangColor.primary,
                action: { showingLexicon = true }
            )
            FeatureCard(
                symbolName: "puzzlepiece.fill",
                title: String(localized: "profile.feature.crossword", defaultValue: "Daily Crossword"),
                badge: nil,
                color: SlangColor.secondary,
                isLocked: true,
                action: {}
            )
            FeatureCard(
                symbolName: "questionmark.circle.fill",
                title: String(localized: "profile.feature.quizzes", defaultValue: "Quizzes"),
                badge: nil,
                color: SlangColor.accent,
                isLocked: true,
                action: {}
            )
            FeatureCard(
                symbolName: "character.book.closed.fill",
                title: String(localized: "profile.feature.translator", defaultValue: "Translator"),
                badge: nil,
                color: SlangColor.onboardingTeal,
                isLocked: true,
                action: {}
            )
            FeatureCard(
                symbolName: "chart.bar.fill",
                title: String(localized: "profile.feature.stats", defaultValue: "Stats"),
                badge: auraProfile.map { "\($0.totalPoints) pts" },
                color: SlangColor.secondary,
                action: {}
            )
        }
    }

    // MARK: - YOUR VOCABULARY Section

    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: SlangSpacing.sm) {
            Text(String(localized: "profile.section.vocabulary", defaultValue: "YOUR VOCABULARY"))
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .tracking(2)
                .foregroundStyle(.secondary)

            VStack(spacing: 1) {
                ProfileNavRow(
                    symbolName: "heart.fill",
                    title: String(localized: "profile.nav.favorites", defaultValue: "Favorites"),
                    badge: favoritesCount > 0 ? "\(favoritesCount)" : nil,
                    action: { showingFavorites = true }
                )
                Divider().padding(.leading, 52)
                ProfileNavRow(
                    symbolName: "bookmark.fill",
                    title: String(localized: "profile.nav.lexicon", defaultValue: "My Lexicon"),
                    badge: lexiconCount > 0 ? "\(lexiconCount)" : nil,
                    action: { showingLexicon = true }
                )
                Divider().padding(.leading, 52)
                ProfileNavRow(
                    symbolName: "square.stack.fill",
                    title: String(localized: "profile.nav.collections", defaultValue: "Collections"),
                    badge: nil,
                    isLocked: true,
                    action: {}
                )
                Divider().padding(.leading, 52)
                ProfileNavRow(
                    symbolName: "clock.fill",
                    title: String(localized: "profile.nav.history", defaultValue: "History"),
                    badge: nil,
                    isLocked: true,
                    action: {}
                )
            }
            .background(SlangColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.cell))
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
        auraProfile = try? await env.auraRepository.fetchProfile()
    }
}

// MARK: - FeatureCard

private struct FeatureCard: View {
    let symbolName: String
    let title: String
    let badge: String?
    let color: Color
    var isLocked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: isLocked ? {} : action) {
            VStack(alignment: .leading, spacing: SlangSpacing.sm) {
                HStack(alignment: .top) {
                    Image(systemName: symbolName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isLocked ? Color(.tertiaryLabel) : color)
                        .accessibilityHidden(true)
                    Spacer()
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(.tertiaryLabel))
                            .accessibilityHidden(true)
                    } else if let badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(color.opacity(0.85)))
                    }
                }

                Spacer()

                Text(title)
                    .font(.slang(.label))
                    .foregroundStyle(isLocked ? Color(.secondaryLabel) : .primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding(SlangSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .background(SlangColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.cell))
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .accessibilityLabel(isLocked ? "\(title), locked" : title)
    }
}

// MARK: - ProfileNavRow

private struct ProfileNavRow: View {
    let symbolName: String
    let title: String
    let badge: String?
    var isLocked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: isLocked ? {} : action) {
            HStack(spacing: SlangSpacing.md) {
                Image(systemName: symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isLocked ? Color(.tertiaryLabel) : SlangColor.primary)
                    .frame(width: 22)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.slang(.subheading))
                    .foregroundStyle(isLocked ? Color(.secondaryLabel) : .primary)

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.slang(.caption))
                        .foregroundStyle(.white)
                        .padding(.horizontal, SlangSpacing.sm)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(SlangColor.primary))
                        .accessibilityLabel("\(badge) items")
                }

                Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, SlangSpacing.md)
            .padding(.vertical, SlangSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .accessibilityLabel(isLocked ? "\(title), locked" : title)
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
