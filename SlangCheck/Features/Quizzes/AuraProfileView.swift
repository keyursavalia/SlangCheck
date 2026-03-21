// Features/Quizzes/AuraProfileView.swift
// SlangCheck
//
// Displays the user's Aura Economy standing: tier badge, total points,
// progress bar to the next tier, and day streak.

import SwiftUI

// MARK: - AuraProfileView

/// A self-contained card showing the user's current Aura Economy state.
/// Embedded in `QuizzesView` and `ProfileView`.
struct AuraProfileView: View {

    let profile: AuraProfile

    var body: some View {
        VStack(spacing: SlangSpacing.md) {
            tierBadge
            pointsRow
            tierProgressBar
            streakRow
        }
        .padding(SlangSpacing.lg)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Tier Badge

    private var tierBadge: some View {
        VStack(spacing: SlangSpacing.sm) {
            ZStack {
                Circle()
                    .fill(tierColor(profile.currentTier).opacity(0.15))
                    .frame(width: 72, height: 72)
                Image(systemName: tierSymbol(profile.currentTier))
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(tierColor(profile.currentTier))
                    .accessibilityHidden(true)
            }

            VStack(spacing: SlangSpacing.xs) {
                Text(profile.currentTier.displayName)
                    .font(.slang(.heading))
                    .foregroundStyle(.primary)

                Text(profile.currentTier.subtitle)
                    .font(.slang(.caption))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Points

    private var pointsRow: some View {
        Text(
            String(
                localized: "aura.profile.points \(profile.totalPoints)",
                defaultValue: "\(profile.totalPoints) pts"
            )
        )
        .font(.slang(.title))
        .foregroundStyle(tierColor(profile.currentTier))
        .contentTransition(.numericText())
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: profile.totalPoints)
    }

    // MARK: - Tier Progress Bar

    private var tierProgressBar: some View {
        VStack(spacing: SlangSpacing.xs) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                        .fill(SlangColor.separator)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                        .fill(tierColor(profile.currentTier))
                        .frame(
                            width: geo.size.width * profile.tierProgress,
                            height: 8
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.75),
                                   value: profile.tierProgress)
                }
            }
            .frame(height: 8)

            if let pointsLeft = profile.pointsToNextTier {
                Text(
                    String(
                        localized: "aura.profile.nextTier \(pointsLeft)",
                        defaultValue: "\(pointsLeft) pts to next tier"
                    )
                )
                .font(.slang(.caption))
                .foregroundStyle(.secondary)
            } else {
                Text(
                    String(localized: "aura.profile.topTier",
                           defaultValue: "You've reached the top!")
                )
                .font(.slang(.caption))
                .foregroundStyle(SlangColor.primary)
            }
        }
    }

    // MARK: - Streak

    private var streakRow: some View {
        HStack(spacing: SlangSpacing.xs) {
            Image(systemName: "flame.fill")
                .foregroundStyle(profile.streak > 0 ? SlangColor.accent : Color.secondary)
                .accessibilityHidden(true)
            Text(
                String(
                    localized: "aura.profile.streak \(profile.streak)",
                    defaultValue: "\(profile.streak) day streak"
                )
            )
            .font(.slang(.label))
            .foregroundStyle(profile.streak > 0 ? SlangColor.accent : Color.secondary)
        }
        .padding(.horizontal, SlangSpacing.md)
        .padding(.vertical, SlangSpacing.xs)
        .background(
            Capsule()
                .fill((profile.streak > 0 ? SlangColor.accent : Color.secondary).opacity(0.12))
        )
    }

    // MARK: - Tier Helpers

    private func tierColor(_ tier: AuraTier) -> Color {
        switch tier {
        case .unc:        return .secondary
        case .lurk:       return SlangColor.accent
        case .auraFarmer: return SlangColor.secondary
        case .rizzler:    return SlangColor.primary
        }
    }

    private func tierSymbol(_ tier: AuraTier) -> String {
        switch tier {
        case .unc:        return "figure.stand"
        case .lurk:       return "eye.fill"
        case .auraFarmer: return "flame.fill"
        case .rizzler:    return "crown.fill"
        }
    }
}

// MARK: - Preview

#Preview("AuraProfileView — Rizzler") {
    AuraProfileView(
        profile: AuraProfile(
            id: UUID(),
            totalPoints: 18_400,
            streak: 7,
            lastActivityDate: Date(),
            displayName: "Keyur"
        )
    )
    .padding(SlangSpacing.md)
    .background(SlangColor.background.ignoresSafeArea())
}

#Preview("AuraProfileView — Unc") {
    AuraProfileView(
        profile: AuraProfile(
            id: UUID(),
            totalPoints: 0,
            streak: 0,
            lastActivityDate: nil,
            displayName: "Guest"
        )
    )
    .padding(SlangSpacing.md)
    .background(SlangColor.background.ignoresSafeArea())
}
