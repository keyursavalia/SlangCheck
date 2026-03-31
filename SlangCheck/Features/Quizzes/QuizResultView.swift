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
    @State private var auraCardImage: AuraCardImage? = nil

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: SlangSpacing.md) {
                headerSection
                auraSection
                breakdownSection
                if let profile = auraProfile {
                    tierSection(profile: profile)
                }
                if let cardImage = auraCardImage {
                    shareButton(cardImage: cardImage)
                }
            }
            .padding(.horizontal, SlangSpacing.md)

            Spacer(minLength: SlangSpacing.sm)

            actionButtons
                .padding(.horizontal, SlangSpacing.md)
                .padding(.bottom, SlangSpacing.md)
        }
        .padding(.top, SlangSpacing.lg)
        .background(SlangColor.background.ignoresSafeArea())
        .onAppear {
            animatePointsCount()
            renderAuraCard()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: SlangSpacing.xs) {
            Image(systemName: result.isPerfect ? "star.fill" : "checkmark.seal.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(result.isPerfect ? SlangColor.accent : SlangColor.secondary)
                .accessibilityHidden(true)

            Text(String(localized: "quizResult.title", defaultValue: "Session Complete"))
                .font(.slang(.heading))
                .foregroundStyle(.primary)

            Text("\(result.correctCount)/\(result.totalCount) Correct")
                .font(.slang(.caption))
                .foregroundStyle(.primary.opacity(0.6))
        }
    }

    // MARK: - Aura Points Earned

    private var auraSection: some View {
        VStack(spacing: SlangSpacing.xs) {
            Text("+\(displayedPoints) Aura")
                .font(.slang(.title))
                .foregroundStyle(SlangColor.primary)
                .contentTransition(.numericText(countsDown: false))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: displayedPoints)

            Text("\(Int(result.accuracy * 100))% Accuracy")
                .font(.slang(.caption))
                .foregroundStyle(.primary.opacity(0.6))
        }
        .padding(.vertical, SlangSpacing.md)
        .padding(.horizontal, SlangSpacing.md)
        .frame(maxWidth: .infinity)
        .profileCard()
    }

    // MARK: - Score Breakdown

    private var breakdownSection: some View {
        let engine = AuraScoringEngine()
        let input  = ScoringInput(
            correctCount:        result.correctCount,
            totalCount:          result.totalCount,
            hintsUsed:           result.hintsUsed,
            elapsedSeconds:      result.elapsedSeconds,
            unansweredCount:     result.unansweredCount,
            categoryBonusPoints: result.categoryBonusPoints
        )
        let bd = engine.breakdown(for: input)

        return VStack(spacing: SlangSpacing.sm) {
            breakdownRow(
                label: String(localized: "quizResult.breakdown.base",
                              defaultValue: "Base Score"),
                value: "+\(bd.basePoints)",
                color: SlangColor.secondary
            )
            if bd.categoryBonus > 0 {
                breakdownRow(
                    label: String(localized: "quizResult.breakdown.categoryBonus",
                                  defaultValue: "Category Bonus"),
                    value: "+\(bd.categoryBonus)",
                    color: SlangColor.secondary
                )
            }
            if result.hintsUsed > 0 {
                breakdownRow(
                    label: String(localized: "quizResult.breakdown.hints",
                                  defaultValue: "Hint Penalty"),
                    value: "−\(bd.basePoints + bd.categoryBonus - bd.afterHintPenalty)",
                    color: SlangColor.errorRed
                )
            }
            if bd.wrongAnswerPenalty > 0 {
                breakdownRow(
                    label: String(localized: "quizResult.breakdown.wrong",
                                  defaultValue: "Wrong Answers"),
                    value: "−\(bd.wrongAnswerPenalty)",
                    color: SlangColor.errorRed
                )
            }
            if bd.unansweredPenalty > 0 {
                breakdownRow(
                    label: String(localized: "quizResult.breakdown.unanswered",
                                  defaultValue: "Unanswered"),
                    value: "−\(bd.unansweredPenalty)",
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
        .profileCard()
    }

    private func breakdownRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.slang(.body))
                .foregroundStyle(.primary.opacity(0.6))
            Spacer()
            Text(value)
                .font(.slang(.label))
                .foregroundStyle(color)
        }
    }

    // MARK: - Tier Progress

    private func tierSection(profile: AuraProfile) -> some View {
        VStack(spacing: SlangSpacing.xs) {
            Text(profile.currentTier.displayName)
                .font(.slang(.label))
                .foregroundStyle(.primary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                        .fill(SlangColor.separator)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                        .fill(SlangColor.primary)
                        .frame(width: geo.size.width * profile.tierProgress, height: 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.75),
                                   value: profile.tierProgress)
                }
            }
            .frame(height: 6)

            if let pts = profile.pointsToNextTier {
                Text("\(pts) pts to next tier")
                    .font(.slang(.caption))
                    .foregroundStyle(.primary.opacity(0.6))
            }
        }
        .padding(.vertical, SlangSpacing.sm)
        .padding(.horizontal, SlangSpacing.md)
        .frame(maxWidth: .infinity)
        .profileCard()
    }

    // MARK: - Share

    private func shareButton(cardImage: AuraCardImage) -> some View {
        ShareLink(
            item: cardImage,
            preview: SharePreview(
                "My Aura Card",
                image: Image(uiImage: cardImage.uiImage)
            )
        ) {
            Label("Share Aura Card", systemImage: "square.and.arrow.up")
                .font(.slang(.label))
                .foregroundStyle(SlangColor.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, SlangSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SlangCornerRadius.button)
                        .strokeBorder(SlangColor.primary, lineWidth: 1)
                )
        }
        .accessibilityLabel("Share your Aura Card")
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: SlangSpacing.sm) {
            Button {
                Task { await onPlayAgain() }
            } label: {
                Text(String(localized: "quizResult.playAgain", defaultValue: "Play Again"))
                    .font(.custom("Montserrat-Bold", size: 17))
                    .foregroundStyle(Color(.label))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(SlangColor.onboardingTeal)
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                    .fill(SlangColor.hardShadow)
                    .offset(y: 4)
                    }
            }
            .buttonStyle(.plain)

            Button {
                onDone()
            } label: {
                Text(String(localized: "quizResult.done", defaultValue: "Done"))
                    .font(.custom("Montserrat-SemiBold", size: 15))
                    .foregroundStyle(Color(.label))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(.systemBackground))
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                    .fill(SlangColor.hardShadow)
                    .offset(y: 4)
                    }
            }
            .buttonStyle(.plain)
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

    private func renderAuraCard() {
        guard let profile = auraProfile else { return }
        Task { @MainActor in
            if let image = AuraCardView.render(for: profile) {
                auraCardImage = AuraCardImage(uiImage: image)
            }
        }
    }
}
