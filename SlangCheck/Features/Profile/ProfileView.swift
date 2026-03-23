// Features/Profile/ProfileView.swift
// SlangCheck
//
// Profile tab: user info, Aura Economy standing, lexicon count, and nav links.

import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {

    @Environment(\.appEnvironment) private var env
    @Environment(AuthState.self) private var authState
    @AppStorage(AppConstants.userSegmentKey) private var userSegmentRaw = UserSegment.languageEnthusiast.rawValue
    @State private var lexiconCount: Int = 0
    @State private var auraProfile: AuraProfile? = nil
    @State private var showingLexicon  = false
    @State private var showingSettings = false

    private var userSegment: UserSegment {
        UserSegment(rawValue: userSegmentRaw) ?? .languageEnthusiast
    }

    var body: some View {
        // No NavigationStack here — ProfileView is always pushed inside MoreMenuView's
        // NavigationStack via a value-based NavigationLink. A nested stack would produce
        // a double navigation bar. .navigationTitle propagates to the outer stack.
        ScrollView {
            VStack(spacing: SlangSpacing.lg) {
                profileHeader
                statsSection
                if auraProfile != nil {
                    auraStatusSection
                }
                navigationSection
            }
            .padding(SlangSpacing.md)
        }
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "profile.title", defaultValue: "Profile"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            await refreshLexiconCount()
            auraProfile = try? await env.auraRepository.fetchProfile()
        }
        .sheet(isPresented: $showingLexicon, onDismiss: {
            Task { await refreshLexiconCount() }
        }) {
            LexiconView()
        }
        .sheet(isPresented: $showingSettings) {
            ProfileSettingsView()
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: SlangSpacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(SlangColor.primary.opacity(0.12))
                    .frame(width: 88, height: 88)

                if let url = authState.currentProfile?.photoURL {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 88, height: 88)
                                .clipShape(Circle())
                        } else {
                            avatarFallback
                        }
                    }
                } else {
                    avatarFallback
                }
            }
            .overlay(Circle().strokeBorder(SlangColor.primary.opacity(0.2), lineWidth: 2))

            VStack(spacing: SlangSpacing.xs) {
                Text(authState.currentProfile?.displayName
                     ?? String(localized: "profile.guest", defaultValue: "Guest User"))
                    .font(.slang(.heading))
                    .foregroundStyle(.primary)

                if let username = authState.currentProfile?.username {
                    Text("@\(username)")
                        .font(.slang(.caption))
                        .foregroundStyle(.secondary)
                }
            }

            if let profile = auraProfile {
                Text(profile.currentTier.displayName)
                    .font(.slang(.caption))
                    .foregroundStyle(SlangColor.primary)
                    .padding(.horizontal, SlangSpacing.md)
                    .padding(.vertical, SlangSpacing.xs)
                    .background(Capsule().fill(SlangColor.primary.opacity(0.12)))
            }
        }
        .padding(SlangSpacing.md)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private var avatarFallback: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 36, weight: .light))
            .foregroundStyle(SlangColor.primary.opacity(0.6))
    }

    // MARK: - Aura Status Section

    /// Full Aura tier progress card shown between the stats tiles and nav rows.
    @ViewBuilder
    private var auraStatusSection: some View {
        if let profile = auraProfile {
            VStack(alignment: .leading, spacing: SlangSpacing.md) {
                HStack {
                    Text(profile.currentTier.displayName)
                        .font(.slang(.label))
                        .foregroundStyle(.primary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(profile.currentTier.subtitle)
                        .font(.slang(.caption))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(profile.totalPoints) pts")
                        .font(.slang(.label))
                        .foregroundStyle(auraColor(for: profile.currentTier))
                        .contentTransition(.numericText())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                            .fill(SlangColor.separator)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                            .fill(auraColor(for: profile.currentTier))
                            .frame(width: geo.size.width * profile.tierProgress, height: 8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.75),
                                       value: profile.tierProgress)
                    }
                }
                .frame(height: 8)

                if let ptsNeeded = profile.pointsToNextTier {
                    Text(
                        String(
                            format: String(localized: "aura.profile.nextTier %d",
                                           defaultValue: "%d pts to next tier"),
                            ptsNeeded
                        )
                    )
                    .font(.slang(.caption))
                    .foregroundStyle(.secondary)
                } else {
                    Text(String(localized: "aura.profile.topTier",
                                defaultValue: "You've reached the top!"))
                        .font(.slang(.caption))
                        .foregroundStyle(SlangColor.primary)
                }
            }
            .padding(SlangSpacing.md)
            .frame(maxWidth: .infinity)
            .glassCard()
        }
    }

    private func auraColor(for tier: AuraTier) -> Color {
        switch tier {
        case .unc:        return .secondary
        case .lurk:       return SlangColor.accent
        case .auraFarmer: return SlangColor.secondary
        case .rizzler:    return SlangColor.primary
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: SlangSpacing.md) {
            StatTile(
                value: "\(lexiconCount)",
                label: String(localized: "profile.stat.lexicon", defaultValue: "Words Saved"),
                symbolName: "bookmark.fill",
                color: SlangColor.primary
            )
            StatTile(
                value: auraProfile.map { "\($0.streak)" }
                    ?? String(localized: "profile.stat.streakPlaceholder", defaultValue: "--"),
                label: String(localized: "profile.stat.streak", defaultValue: "Day Streak"),
                symbolName: "flame.fill",
                color: SlangColor.accent
            )
            StatTile(
                value: auraProfile.map { "\($0.totalPoints)" }
                    ?? String(localized: "profile.stat.auraPlaceholder", defaultValue: "--"),
                label: String(localized: "profile.stat.aura", defaultValue: "Aura Points"),
                symbolName: "sparkles",
                color: SlangColor.secondary
            )
        }
    }

    // MARK: - Navigation Section

    private var navigationSection: some View {
        VStack(spacing: SlangSpacing.xs) {
            ProfileNavRow(
                symbolName: "bookmark.fill",
                title: String(localized: "profile.nav.lexicon", defaultValue: "My Lexicon"),
                badge: lexiconCount > 0 ? "\(lexiconCount)" : nil,
                action: { showingLexicon = true }
            )
            ProfileNavRow(
                symbolName: "gearshape.fill",
                title: String(localized: "profile.nav.settings", defaultValue: "Settings"),
                badge: nil,
                action: { showingSettings = true }
            )
        }
        .background(SlangColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.cell))
    }

    // MARK: - Helpers

    private func refreshLexiconCount() async {
        if let lexicon = try? await env.slangTermRepository.fetchLexicon() {
            lexiconCount = lexicon.count
        }
    }
}

// MARK: - StatTile

private struct StatTile: View {
    let value: String
    let label: String
    let symbolName: String
    let color: Color

    var body: some View {
        VStack(spacing: SlangSpacing.xs) {
            Image(systemName: symbolName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(.slang(.heading))
                .foregroundStyle(.primary)
            Text(label)
                .font(.slang(.caption))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(SlangSpacing.md)
        .background(SlangColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.cell))
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isLocked ? Color(.tertiaryLabel) : SlangColor.primary)
                    .frame(width: 24)
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
    NavigationStack {
        ProfileView()
    }
    .environment(\.appEnvironment, .preview())
    .environment(AuthState(
        authService:       NoOpAuthenticationService(),
        profileRepository: NoOpUserProfileRepository()
    ))
}
