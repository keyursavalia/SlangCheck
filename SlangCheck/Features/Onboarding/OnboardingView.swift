// Features/Onboarding/OnboardingView.swift
// SlangCheck
//
// Root onboarding container: step routing and shared UI components
// (OnboardingOptionRow, OnboardingCTAButton).

import SwiftUI

// MARK: - OnboardingView

/// Entry point for the onboarding flow. Routes to each step and calls onComplete when done.
struct OnboardingView: View {

    @State private var viewModel = OnboardingViewModel()
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            SlangColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                skipRow
                    .frame(height: 44)
                    .padding(.top, SlangSpacing.sm)

                stepContent
                    .id(viewModel.currentStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: viewModel.isComplete) { _, done in
            if done { onComplete() }
        }
    }

    // MARK: - Skip Row

    private var skipRow: some View {
        HStack {
            Spacer()
            if viewModel.currentStep.isSkippable {
                Button(action: viewModel.skip) {
                    Text(String(localized: "onboarding.skip", defaultValue: "Skip"))
                        .font(.slang(.label))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, SlangSpacing.md)
                .accessibilityLabel(
                    String(localized: "onboarding.skip.accessibility",
                           defaultValue: "Skip this step")
                )
            }
        }
    }

    // MARK: - Step Routing

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {

        case .splash:
            SplashStep(onStart: viewModel.advance)

        case .displayName:
            DisplayNameStep(name: $viewModel.displayName, onContinue: viewModel.advance)

        case .gender:
            SingleSelectStep(
                question: String(localized: "onboarding.gender.question",
                                 defaultValue: "Which option represents you best?"),
                options: OnboardingGender.allCases.map(\.rawValue),
                selected: Binding(
                    get: { viewModel.selectedGender?.rawValue },
                    set: { v in viewModel.selectedGender = v.flatMap(OnboardingGender.init(rawValue:)) }
                ),
                onContinue: viewModel.advance
            )

        case .learningGoal:
            SingleSelectStep(
                question: String(localized: "onboarding.goal.question",
                                 defaultValue: "Do you have a specific goal in mind?"),
                options: OnboardingGoal.allCases.map(\.rawValue),
                selected: Binding(
                    get: { viewModel.selectedGoal?.rawValue },
                    set: { v in viewModel.selectedGoal = v.flatMap(OnboardingGoal.init(rawValue:)) }
                ),
                onContinue: viewModel.advance
            )

        case .slangLevel:
            SingleSelectStep(
                question: String(localized: "onboarding.level.question",
                                 defaultValue: "What's your slang level?"),
                options: OnboardingSlangLevel.allCases.map(\.rawValue),
                selected: Binding(
                    get: { viewModel.selectedSlangLevel?.rawValue },
                    set: { v in viewModel.selectedSlangLevel = v.flatMap(OnboardingSlangLevel.init(rawValue:)) }
                ),
                onContinue: viewModel.advance
            )

        case .wordFrequency:
            SingleSelectStep(
                question: String(localized: "onboarding.frequency.question",
                                 defaultValue: "Do you often encounter slang you don't know?"),
                options: OnboardingWordFrequency.allCases.map(\.rawValue),
                selected: Binding(
                    get: { viewModel.selectedFrequency?.rawValue },
                    set: { v in viewModel.selectedFrequency = v.flatMap(OnboardingWordFrequency.init(rawValue:)) }
                ),
                onContinue: viewModel.advance
            )

        case .vocabDescription:
            SingleSelectStep(
                question: String(localized: "onboarding.vocabdesc.question",
                                 defaultValue: "How would you describe your slang knowledge?"),
                options: OnboardingVocabDescription.allCases.map(\.rawValue),
                selected: Binding(
                    get: { viewModel.selectedVocabDescription?.rawValue },
                    set: { v in viewModel.selectedVocabDescription = v.flatMap(OnboardingVocabDescription.init(rawValue:)) }
                ),
                onContinue: viewModel.advance
            )

        case .weeklyGoal:
            SingleSelectStep(
                question: String(localized: "onboarding.weekly.question",
                                 defaultValue: "How many slang terms do you want to learn per week?"),
                options: OnboardingWeeklyGoal.allCases.map(\.rawValue),
                selected: Binding(
                    get: { viewModel.selectedWeeklyGoal?.rawValue },
                    set: { v in viewModel.selectedWeeklyGoal = v.flatMap(OnboardingWeeklyGoal.init(rawValue:)) }
                ),
                onContinue: viewModel.advance
            )

        case .categorySelection:
            CategorySelectionStep(
                selectedCategories: $viewModel.selectedCategories,
                onContinue: viewModel.advance
            )

        case .testIntro:
            TestIntroStep(onContinue: viewModel.advance)

        case .testBeginner:
            WordTestStep(
                level: String(localized: "onboarding.test.beginner", defaultValue: "Beginner slang"),
                words: OnboardingWordBank.beginner,
                knownWords: $viewModel.knownBeginnerTerms,
                onContinue: viewModel.advance
            )

        case .testIntermediate:
            WordTestStep(
                level: String(localized: "onboarding.test.intermediate", defaultValue: "Intermediate slang"),
                words: OnboardingWordBank.intermediate,
                knownWords: $viewModel.knownIntermediateTerms,
                onContinue: viewModel.advance
            )

        case .testAdvanced:
            WordTestStep(
                level: String(localized: "onboarding.test.advanced", defaultValue: "Advanced slang"),
                words: OnboardingWordBank.advanced,
                knownWords: $viewModel.knownAdvancedTerms,
                onContinue: viewModel.advance
            )

        case .notificationConsent:
            NotificationConsentStep(
                onAllow: viewModel.proceedToNotificationSchedule,
                onSkip: viewModel.skipToWelcome
            )

        case .notificationSchedule:
            NotificationScheduleStep(
                count: $viewModel.notificationCount,
                startTime: $viewModel.notificationStartTime,
                endTime: $viewModel.notificationEndTime,
                onSave: viewModel.requestNotifications
            )

        case .notificationPermission:
            NotificationPermissionStep(
                onGoToSettings: {
                    // SAFE: openSettingsURLString is a compile-time constant known-valid URL.
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    viewModel.advance()
                },
                onSkip: viewModel.advance
            )

        case .welcomeSplash:
            WelcomeSplashStep(onContinue: viewModel.advance)
        }
    }
}

// MARK: - OnboardingOptionRow

/// Full-width pill-shaped option row with radio indicator and hard drop shadow.
/// Used for single-select (radio behaviour) and multi-select (toggle behaviour).
struct OnboardingOptionRow: View {

    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.custom("Montserrat-Regular", size: 17))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                Spacer()
                // Radio / check indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.white.opacity(0.5) : Color.primary.opacity(0.3),
                            lineWidth: 1.5
                        )
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 13, height: 13)
                    }
                }
            }
            .padding(.horizontal, SlangSpacing.md)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(isSelected ? SlangColor.onboardingTeal : Color(.systemBackground))
            }
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.black)
                    .offset(y: 4)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - OnboardingCTAButton

/// Full-width pill CTA button (teal fill, hard shadow). Primary action on every step.
struct OnboardingCTAButton: View {

    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Montserrat-Bold", size: 18))
                .foregroundStyle(isEnabled ? Color(.label) : Color(.label).opacity(0.4))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(isEnabled
                              ? SlangColor.onboardingTeal
                              : SlangColor.onboardingTeal.opacity(0.4))
                    // Hard shadow is placed behind the fill. When disabled the fill is
                    // semi-transparent so we hide the shadow entirely to avoid a
                    // double-line artifact.
                }
                .background {
                    if isEnabled {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.black)
                            .offset(y: 4)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.easeOut(duration: 0.15), value: isEnabled)
    }
}

// MARK: - Preview

#Preview("OnboardingView") {
    OnboardingView(onComplete: {})
}
