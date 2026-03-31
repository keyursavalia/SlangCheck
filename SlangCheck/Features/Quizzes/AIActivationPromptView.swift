// Features/Quizzes/AIActivationPromptView.swift
// SlangCheck
//
// Shown once to iOS 26+ users who haven't activated Apple Intelligence.
// Explains the benefit and offers a shortcut to Settings. If declined,
// the app falls back to Gemini API silently.

import SwiftUI

// MARK: - AIActivationPromptView

/// Prompts the user to enable Apple Intelligence for the best games experience.
/// Dismisses itself after the user taps either "Open Settings" or "Not Now".
struct AIActivationPromptView: View {

    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenAIPrompt") private var hasSeenPrompt = false

    /// Called when the user makes a choice so the parent can proceed.
    var onDismissed: () -> Void

    var body: some View {
        VStack(spacing: SlangSpacing.xl) {
            Spacer()

            // Icon
            Image(systemName: "cpu")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(SlangColor.primary)
                .accessibilityHidden(true)

            // Title
            Text(String(localized: "ai.prompt.title",
                        defaultValue: "Unlock smarter games"))
                .font(.slang(.title))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            // Body
            Text(String(localized: "ai.prompt.body",
                        defaultValue: "Turn on Apple Intelligence for unique AI-generated quiz questions and crossword puzzles — all processed on-device for your privacy."))
                .font(.slang(.body))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.lg)

            Spacer()

            // Primary CTA — open Settings
            // SAFE: openSettingsURLString is a compile-time constant known-valid URL.
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                Link(destination: settingsURL) {
                    Text(String(localized: "ai.prompt.openSettings",
                                defaultValue: "Open Settings"))
                        .font(.custom("Montserrat-Bold", size: 18))
                        .foregroundStyle(Color(.label))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(SlangColor.onboardingTeal)
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(SlangColor.hardShadow)
                                .offset(y: 4)
                        }
                }
                .simultaneousGesture(TapGesture().onEnded {
                    hasSeenPrompt = true
                    onDismissed()
                })
                .padding(.horizontal, SlangSpacing.md)
            }

            // Secondary — skip
            Button {
                hasSeenPrompt = true
                onDismissed()
                dismiss()
            } label: {
                Text(String(localized: "ai.prompt.skip",
                            defaultValue: "Not now — use cloud AI instead"))
                    .font(.montserrat(size: 15))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, SlangSpacing.xl)
        }
        .background(SlangColor.background.ignoresSafeArea())
    }
}
