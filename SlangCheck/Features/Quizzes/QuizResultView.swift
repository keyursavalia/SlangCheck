// Features/Quizzes/QuizResultView.swift
// SlangCheck
//
// Post-session summary: Aura Points earned, score breakdown,
// accuracy, tier progress, and session actions.

import SwiftUI

// MARK: - QuizResultView

/// Displayed after the final question is answered.
/// Owned inside `QuizView` — the ViewModel manages the result state.
struct QuizResultView: View {

    let result: QuizResult
    let auraProfile: AuraProfile?
    let onPlayAgain: () async -> Void
    let onDone: () -> Void

    @State private var displayedPoints: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: SlangSpacing.xl) {
                headerSection
                auraSection
                breakdownSection
                if let profile = auraProfile {
                    tierSection(profile: profile)
                }
                actionButtons
            }
            .padding(SlangSpacing.md)
            .padding(.top, SlangSpacing.xl)
        }
        .background(SlangColor.background.ignoresSafeArea())
        .onAppear { animatePointsCount() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: SlangSpacing.sm) {
            Image(systemName: result.isPerfect ? "star.fill" : "checkmark.seal.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(result.isPerfect ? SlangColor.accent : SlangColor.secondary)
                .accessibilityHidden(true)

            Text(String(localized: "quizResult.title", defaultValue: "Session Complete"))
                .font(.slang(.title))
                .foregroundStyle(.primary)

            Text(
                String(
                    localized: "quizResult.correct \(result.correctCount) \(result.totalCount)",
                    defaultValue: "\(result.correctCount)/\(result.totalCount) Correct"
                )
            )
            .font(.slang(.subheading))
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Aura Points Earned

    private var auraSection: some View {
        VStack(spacing: SlangSpacing.xs) {
            Text(
                String(
                    localized: "quizResult.auraEarned \(displayedPoints)",
                    defaultValue: "+\(displayedPoints) Aura"
                )
            )
            .font(.slang(.display))
            .foregroundStyle(SlangColor.primary)
            .contentTransition(.numericText(countsDown: false))
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: displayedPoints)

            Text(
                String(
                    localized: "quizResult.accuracy \(Int(result.accuracy * 100))%",
                    defaultValue: "\(Int(result.accuracy * 100))% Accuracy"
                )
            )
            .font(.slang(.caption))
            .foregroundStyle(.secondary)
        }
        .padding(SlangSpacing.xl)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Score Breakdown

    private var breakdownSection: some View {
        let engine = AuraScoringEngine()
        let input  = ScoringInput(
            correctCount:   result.correctCount,
            totalCount:     result.totalCount,
            hintsUsed:      result.hintsUsed,
            elapsedSeconds: result.elapsedSeconds
        )
        let bd = engine.breakdown(for: input)

        return VStack(spacing: SlangSpacing.sm) {
            breakdownRow(
                label: String(localized: "quizResult.breakdown.base",
                              defaultValue: "Base Score"),
                value: "+\(bd.basePoints)",
                color: SlangColor.secondary
            )
            if result.hintsUsed > 0 {
                breakdownRow(
                    label: String(localized: "quizResult.breakdown.hints",
                                  defaultValue: "Hint Penalty"),
                    value: "−\(bd.basePoints - bd.afterHintPenalty)",
                    color: SlangColor.errorRed
                )
            }
            if bd.timePenalty > 0 {
                breakdownRow(
                    label: String(localized: "quizResult.breakdown.time",
                                  defaultValue: "Time Penalty"),
                    value: "−\(bd.timePenalty)",
                    color: SlangColor.accent
                )
            }
            Divider().background(SlangColor.separator)
            breakdownRow(
                label: String(localized: "quizResult.breakdown.total",
                              defaultValue: "Total Earned"),
                value: "+\(bd.finalScore)",
                color: SlangColor.primary
            )
        }
        .padding(SlangSpacing.md)
        .frame(maxWidth: .infinity)
        .neumorphicSurface()
    }

    private func breakdownRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.slang(.body))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.slang(.label))
                .foregroundStyle(color)
        }
    }

    // MARK: - Tier Progress

    private func tierSection(profile: AuraProfile) -> some View {
        VStack(spacing: SlangSpacing.sm) {
            Text(profile.currentTier.displayName)
                .font(.slang(.subheading))
                .foregroundStyle(.primary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                        .fill(SlangColor.separator)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                        .fill(SlangColor.primary)
                        .frame(width: geo.size.width * profile.tierProgress, height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.75),
                                   value: profile.tierProgress)
                }
            }
            .frame(height: 8)

            if let pts = profile.pointsToNextTier {
                Text(
                    String(
                        localized: "aura.profile.nextTier \(pts)",
                        defaultValue: "\(pts) pts to next tier"
                    )
                )
                .font(.slang(.caption))
                .foregroundStyle(.secondary)
            }
        }
        .padding(SlangSpacing.md)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: SlangSpacing.sm) {
            Button {
                Task { await onPlayAgain() }
            } label: {
                Text(String(localized: "quizResult.playAgain", defaultValue: "Play Again"))
                    .font(.slang(.label))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SlangSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: SlangCornerRadius.button)
                            .fill(SlangColor.primary)
                    )
            }

            Button {
                onDone()
            } label: {
                Text(String(localized: "quizResult.done", defaultValue: "Done"))
                    .font(.slang(.label))
                    .foregroundStyle(SlangColor.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SlangSpacing.md)
            }
        }
    }

    // MARK: - Animation

    private func animatePointsCount() {
        let target   = result.auraPointsEarned
        let steps    = 20
        let interval = 0.6 / Double(steps)
        for i in 1...steps {
            let delay = interval * Double(i)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                displayedPoints = (target * i) / steps
            }
        }
    }
}
