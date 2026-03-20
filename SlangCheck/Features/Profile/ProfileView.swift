// Features/Profile/ProfileView.swift
// SlangCheck
//
// Profile tab: displays lexicon count badge, and links to the Personal Lexicon.
// Iteration 1 scope: lexicon access + basic user info. Aura/tier display is Iteration 3.

import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {

    @Environment(\.appEnvironment) private var env
    @AppStorage(AppConstants.userSegmentKey) private var userSegmentRaw = UserSegment.languageEnthusiast.rawValue
    @State private var lexiconCount: Int = 0
    @State private var showingLexicon = false

    private var userSegment: UserSegment {
        UserSegment(rawValue: userSegmentRaw) ?? .languageEnthusiast
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SlangSpacing.lg) {
                    profileHeader
                    statsSection
                    navigationSection
                }
                .padding(SlangSpacing.md)
            }
            .background(SlangColor.background.ignoresSafeArea())
            .navigationTitle(String(localized: "profile.title", defaultValue: "Profile"))
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await refreshLexiconCount()
        }
        .sheet(isPresented: $showingLexicon, onDismiss: {
            Task { await refreshLexiconCount() }
        }) {
            LexiconView()
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: SlangSpacing.md) {
            Circle()
                .fill(SlangColor.primary.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: userSegment.symbolName)
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(SlangColor.primary)
                        .accessibilityHidden(true)
                )

            VStack(spacing: SlangSpacing.xs) {
                Text(userSegment.displayName)
                    .font(.slang(.heading))
                    .foregroundStyle(.primary)

                Text(String(localized: "profile.guest", defaultValue: "Guest User"))
                    .font(.slang(.caption))
                    .foregroundStyle(.secondary)
            }

            // Iteration 3: Aura tier badge will appear here.
            Text(String(localized: "profile.auraComingSoon",
                        defaultValue: "Aura System — Coming in the Quizzes Update"))
                .font(.slang(.caption))
                .foregroundStyle(SlangColor.primary.opacity(0.7))
                .padding(.horizontal, SlangSpacing.md)
                .padding(.vertical, SlangSpacing.xs)
                .background(Capsule().fill(SlangColor.primary.opacity(0.10)))
        }
        .padding(SlangSpacing.md)
        .frame(maxWidth: .infinity)
        .glassCard()
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
                value: String(localized: "profile.stat.streakPlaceholder", defaultValue: "--"),
                label: String(localized: "profile.stat.streak", defaultValue: "Day Streak"),
                symbolName: "flame.fill",
                color: SlangColor.accent
            )
            StatTile(
                value: String(localized: "profile.stat.auraPlaceholder", defaultValue: "--"),
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
                symbolName: "chart.bar.fill",
                title: String(localized: "profile.nav.quizHistory",
                              defaultValue: "Quiz History"),
                badge: nil,
                isLocked: true,
                action: {}
            )
            ProfileNavRow(
                symbolName: "gearshape.fill",
                title: String(localized: "profile.nav.settings", defaultValue: "Settings"),
                badge: nil,
                action: {}
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
                        .accessibilityLabel(
                            String(localized: "profile.badge.count \(badge)",
                                   defaultValue: "\(badge) items")
                        )
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
        .accessibilityLabel(
            isLocked
                ? String(localized: "profile.nav.locked \(title)", defaultValue: "\(title), locked")
                : title
        )
    }
}

// MARK: - Preview

#Preview("ProfileView") {
    ProfileView()
        .environment(\.appEnvironment, .preview())
}
