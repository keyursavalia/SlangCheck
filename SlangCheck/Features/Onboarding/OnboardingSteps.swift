// Features/Onboarding/OnboardingSteps.swift
// SlangCheck
//
// Step views: Splash, DisplayName, SingleSelect, TestIntro, WordTest.
// Notification and welcome steps live in OnboardingNotificationSteps.swift.

import SwiftUI

// MARK: - SplashStep

/// Opening screen: app value proposition and "Get started" CTA.
struct SplashStep: View {

    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero illustration
            ZStack {
                Circle()
                    .fill(SlangColor.onboardingTeal.opacity(0.1))
                    .frame(width: 220, height: 220)
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 88, weight: .light))
                    .foregroundStyle(SlangColor.onboardingTeal)
            }
            .accessibilityHidden(true)
            .padding(.bottom, SlangSpacing.xl)

            VStack(spacing: SlangSpacing.md) {
                Text(String(localized: "onboarding.splash.title",
                            defaultValue: "Level up your slang\nin minutes a day"))
                    .font(.custom("Montserrat-Bold", size: 32))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(String(localized: "onboarding.splash.subtitle",
                            defaultValue: "Master Gen Z slang, internet culture, and modern expressions with daily flashcards."))
                    .font(.custom("Montserrat-Regular", size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, SlangSpacing.lg)
            }

            Spacer()

            OnboardingCTAButton(
                title: String(localized: "onboarding.splash.cta", defaultValue: "Get started"),
                action: onStart
            )
            .padding(.horizontal, SlangSpacing.md)
            .padding(.bottom, SlangSpacing.xl)
        }
    }
}

// MARK: - DisplayNameStep

/// Text-field step: captures the user's preferred display name.
struct DisplayNameStep: View {

    @Binding var name: String
    let onContinue: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "onboarding.name.question",
                        defaultValue: "What do you want to\nbe called?"))
                .font(.custom("Montserrat-Bold", size: 30))
                .foregroundStyle(.primary)
                .padding(.horizontal, SlangSpacing.md)
                .padding(.top, SlangSpacing.xl)

            Spacer().frame(height: SlangSpacing.xl)

            TextField(
                String(localized: "onboarding.name.placeholder", defaultValue: "Your name"),
                text: $name
            )
            .font(.custom("Montserrat-Regular", size: 17))
            .focused($isFocused)
            .padding(.horizontal, SlangSpacing.md)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.systemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28)
                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1.5)
                    }
                    .shadow(color: .black.opacity(0.45), radius: 0, x: 0, y: 3)
            }
            .padding(.horizontal, SlangSpacing.md)

            Spacer()

            OnboardingCTAButton(
                title: String(localized: "onboarding.continue", defaultValue: "Continue"),
                action: onContinue
            )
            .padding(.horizontal, SlangSpacing.md)
            .padding(.bottom, SlangSpacing.xl)
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - SingleSelectStep

/// Generic radio-select step. Continue enables when an option is selected.
/// Used for gender, learning goal, slang level, frequency, self-description, weekly goal.
struct SingleSelectStep: View {

    let question: String
    let options: [String]
    @Binding var selected: String?
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(question)
                .font(.custom("Montserrat-Bold", size: 30))
                .foregroundStyle(.primary)
                .padding(.horizontal, SlangSpacing.md)
                .padding(.top, SlangSpacing.xl)

            Spacer().frame(height: SlangSpacing.xl)

            VStack(spacing: SlangSpacing.sm) {
                ForEach(options, id: \.self) { option in
                    OnboardingOptionRow(
                        label: option,
                        isSelected: selected == option,
                        action: { selected = option }
                    )
                }
            }
            .padding(.horizontal, SlangSpacing.md)

            Spacer()

            OnboardingCTAButton(
                title: String(localized: "onboarding.continue", defaultValue: "Continue"),
                isEnabled: selected != nil,
                action: onContinue
            )
            .padding(.horizontal, SlangSpacing.md)
            .padding(.bottom, SlangSpacing.xl)
        }
    }
}

// MARK: - TestIntroStep

/// Transition screen before the vocabulary knowledge test.
struct TestIntroStep: View {

    let onContinue: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Text(String(localized: "onboarding.testintro.message",
                        defaultValue: "Amazing!\nLet's test how many\nslang terms you know..."))
                .font(.custom("Montserrat-Bold", size: 34))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.xl)
            Spacer()
            OnboardingCTAButton(
                title: String(localized: "onboarding.continue", defaultValue: "Continue"),
                action: onContinue
            )
            .padding(.horizontal, SlangSpacing.md)
            .padding(.bottom, SlangSpacing.xl)
        }
    }
}

// MARK: - WordTestStep

/// Multi-select step: user taps every slang term they already know.
/// Used for beginner, intermediate, and advanced level tests.
struct WordTestStep: View {

    let level: String
    let words: [String]
    @Binding var knownWords: Set<String>
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(level)
                .font(.custom("Montserrat-Bold", size: 30))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, SlangSpacing.xl)

            Text(String(localized: "onboarding.test.subtitle",
                        defaultValue: "Select all the ones you know"))
                .font(.custom("Montserrat-Regular", size: 15))
                .foregroundStyle(.secondary)
                .padding(.top, SlangSpacing.xs)

            Spacer().frame(height: SlangSpacing.xl)

            VStack(spacing: SlangSpacing.sm) {
                ForEach(words, id: \.self) { word in
                    OnboardingOptionRow(
                        label: word,
                        isSelected: knownWords.contains(word),
                        action: {
                            if knownWords.contains(word) {
                                knownWords.remove(word)
                            } else {
                                knownWords.insert(word)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, SlangSpacing.md)

            Spacer()

            OnboardingCTAButton(
                title: String(localized: "onboarding.continue", defaultValue: "Continue"),
                action: onContinue
            )
            .padding(.horizontal, SlangSpacing.md)
            .padding(.bottom, SlangSpacing.xl)
        }
    }
}
