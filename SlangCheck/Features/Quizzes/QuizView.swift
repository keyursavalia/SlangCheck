// Features/Quizzes/QuizView.swift
// SlangCheck
//
// Active quiz screen: question card, four answer choices (onboarding-style pills),
// hint button, progress indicator, exit button. Correct → green pulse. Wrong → red shake.

import SwiftUI

// MARK: - QuizView

/// The full-screen quiz experience. Presented as a `.fullScreenCover` from `QuizzesView`.
/// Transitions to `QuizResultView` inline once the session finishes.
struct QuizView: View {

    @Bindable var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false

    var body: some View {
        Group {
            switch viewModel.phase {
            case .active:
                activeContent
            case .result(let result):
                QuizResultView(
                    result: result,
                    auraProfile: viewModel.auraProfile,
                    onPlayAgain: { await viewModel.restartQuiz() },
                    onDone: {
                        viewModel.dismissResult()
                        dismiss()
                    }
                )
            default:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(SlangColor.background.ignoresSafeArea())
            }
        }
        .alert(
            String(localized: "quiz.exit.title", defaultValue: "End Quiz?"),
            isPresented: $showExitConfirmation
        ) {
            Button(String(localized: "quiz.exit.confirm", defaultValue: "End & See Results"),
                   role: .destructive) {
                viewModel.endQuizEarly()
            }
            Button(String(localized: "quiz.exit.cancel", defaultValue: "Keep Going"),
                   role: .cancel) {}
        } message: {
            Text(String(localized: "quiz.exit.message",
                        defaultValue: "You'll still earn points for your correct answers so far."))
        }
    }

    // MARK: - Active Quiz Layout

    private var activeContent: some View {
        VStack(spacing: 0) {
            quizHeader
                .padding(.horizontal, SlangSpacing.md)
                .padding(.top, SlangSpacing.md)

            Spacer(minLength: SlangSpacing.lg)

            if let question = viewModel.currentQuestion {
                QuizQuestionCard(question: question)
                    .padding(.horizontal, SlangSpacing.md)
                    .id(viewModel.currentIndex)
                    .transition(.asymmetric(
                        insertion:  .move(edge: .trailing).combined(with: .opacity),
                        removal:    .move(edge: .leading).combined(with: .opacity)
                    ))
            }

            Spacer(minLength: SlangSpacing.lg)

            choicesGrid
                .padding(.horizontal, SlangSpacing.md)

            Spacer(minLength: SlangSpacing.sm)

            nextButton
                .padding(.horizontal, SlangSpacing.md)
                .padding(.bottom, SlangSpacing.xl)
        }
        .background(SlangColor.background.ignoresSafeArea())
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.currentIndex)
    }

    // MARK: - Header (Exit + Progress + Timer + Hint)

    private var quizHeader: some View {
        VStack(spacing: SlangSpacing.sm) {
            HStack {
                // Exit button
                Button { showExitConfirmation = true } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(.label).opacity(0.55))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "quiz.exit.accessibility",
                                          defaultValue: "End quiz"))

                Spacer()

                Text("Question \(viewModel.questionNumber) of \(viewModel.totalQuestions)")
                    .font(.slang(.caption))
                    .foregroundStyle(.primary.opacity(0.6))

                Spacer()

                // 30-second countdown ring
                TimerRingView(
                    timeRemaining: viewModel.timeRemaining,
                    total: QuizViewModel.questionTimeLimit
                )
                .frame(width: 36, height: 36)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                        .fill(SlangColor.separator)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                        .fill(SlangColor.primary)
                        .frame(width: geo.size.width * viewModel.sessionProgress, height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8),
                                   value: viewModel.sessionProgress)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Answer Choices (Onboarding-style pills)

    private var choicesGrid: some View {
        VStack(spacing: SlangSpacing.sm) {
            ForEach(viewModel.shuffledChoices, id: \.self) { choice in
                QuizChoiceRow(
                    choice: choice,
                    correctAnswer: viewModel.currentQuestion?.correctAnswer ?? "",
                    selectedAnswer: viewModel.selectedAnswer,
                    isRevealed: viewModel.isAnswerRevealed,
                    isEliminated: viewModel.eliminatedChoice == choice
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.submitAnswer(choice)
                    }
                }
            }

            // Hint button
            if viewModel.canUseHint {
                Button(action: { viewModel.useHint() }) {
                    Label(
                        String(localized: "quiz.hint", defaultValue: "Hint"),
                        systemImage: "lightbulb"
                    )
                    .font(.montserrat(size: 14))
                    .foregroundStyle(SlangColor.accent)
                }
                .padding(.top, SlangSpacing.xs)
            }
        }
    }

    // MARK: - Next / Finish Button

    private var nextButton: some View {
        let isLast  = viewModel.currentIndex + 1 >= viewModel.totalQuestions
        let label   = isLast
            ? String(localized: "quiz.finish", defaultValue: "See Results")
            : String(localized: "quiz.next",   defaultValue: "Next")

        return Button {
            withAnimation {
                viewModel.advanceToNextQuestion()
            }
        } label: {
            Text(label)
                .font(.custom("Montserrat-Bold", size: 18))
                .foregroundStyle(Color(.label))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(viewModel.isAnswerRevealed
                              ? SlangColor.onboardingTeal
                              : SlangColor.onboardingTeal.opacity(0.4))
                }
                .background {
                    if viewModel.isAnswerRevealed {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.black)
                            .offset(y: 4)
                    }
                }
        }
        .disabled(!viewModel.isAnswerRevealed)
        .opacity(viewModel.isAnswerRevealed ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isAnswerRevealed)
        .accessibilityLabel(label)
    }
}

// MARK: - QuizQuestionCard

/// The glassmorphic card that displays the current question stem.
private struct QuizQuestionCard: View {

    let question: QuizQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: SlangSpacing.md) {
            Text(questionTypeBadge)
                .font(.slang(.caption))
                .foregroundStyle(SlangColor.primary)
                .padding(.horizontal, SlangSpacing.sm)
                .padding(.vertical, SlangSpacing.xs)
                .background(Capsule().fill(SlangColor.primary.opacity(0.12)))

            Text(questionStem)
                .font(.slang(.subheading))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .slangBodySpacing()
        }
        .padding(SlangSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .fill(Color(.systemBackground))
        }
        .background {
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .fill(.black)
                .offset(y: 4)
        }
    }

    private var questionTypeBadge: String {
        switch question.type {
        case .definitionPick: return String(localized: "quiz.badge.definitionPick", defaultValue: "What Does It Mean?")
        case .termPick:       return String(localized: "quiz.badge.termPick",       defaultValue: "Name That Slang")
        case .fillInBlank:    return String(localized: "quiz.badge.fillInBlank",    defaultValue: "Fill in the Blank")
        }
    }

    private var questionStem: String {
        switch question.type {
        case .definitionPick:
            return "What does \"\(question.term)\" mean?"
        case .termPick:
            return question.correctDefinition
        case .fillInBlank:
            return question.sentenceWithBlank
        }
    }
}

// MARK: - QuizChoiceRow (Onboarding-Style Pill)

/// An answer-choice pill matching the onboarding `OnboardingOptionRow` style.
/// Neutral → white pill with black drop shadow. Selected → teal (correct) or red (wrong).
private struct QuizChoiceRow: View {

    let choice: String
    let correctAnswer: String
    let selectedAnswer: String?
    let isRevealed: Bool
    let isEliminated: Bool
    let action: () -> Void

    @State private var shakeTrigger: CGFloat = 0

    private var choiceState: ChoiceState {
        guard isRevealed else { return isEliminated ? .eliminated : .neutral }
        if choice == correctAnswer  { return .correct }
        if choice == selectedAnswer { return .wrong }
        return .dimmed
    }

    var body: some View {
        Button(action: triggerAction) {
            HStack {
                Text(choice)
                    .font(.custom("Montserrat-Regular", size: 17))
                    .foregroundStyle(foregroundColor)
                    .multilineTextAlignment(.leading)
                Spacer()
                indicator
            }
            .padding(.horizontal, SlangSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(backgroundColor)
            }
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.black)
                    .offset(y: 4)
            }
        }
        .buttonStyle(.plain)
        .disabled(isRevealed || isEliminated)
        .modifier(ShakeEffect(trigger: shakeTrigger))
        .opacity(choiceState == .dimmed || choiceState == .eliminated ? 0.40 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: choiceState)
        .accessibilityLabel(choice)
        .accessibilityAddTraits(choiceState == .correct ? .isSelected : [])
    }

    // MARK: - Indicator

    @ViewBuilder
    private var indicator: some View {
        switch choiceState {
        case .correct:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
        case .wrong:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.white)
        default:
            EmptyView()
        }
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        switch choiceState {
        case .correct:    return SlangColor.onboardingTeal
        case .wrong:      return SlangColor.errorRed
        default:          return Color(.systemBackground)
        }
    }

    private var foregroundColor: Color {
        switch choiceState {
        case .correct, .wrong: return .white
        default:               return .primary
        }
    }

    // MARK: - Action

    private func triggerAction() {
        action()
        if choice != correctAnswer {
            withAnimation(.linear(duration: 0.5)) { shakeTrigger = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shakeTrigger = 0 }
        }
    }
}

// MARK: - ChoiceState

private enum ChoiceState: Equatable { case neutral, correct, wrong, dimmed, eliminated }

// MARK: - TimerRingView

/// Circular countdown ring shown in the quiz header.
private struct TimerRingView: View {

    let timeRemaining: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(timeRemaining) / Double(total)
    }

    private var ringColor: Color {
        if timeRemaining > 10 { return SlangColor.onboardingTeal }
        if timeRemaining >  5 { return SlangColor.accent }
        return SlangColor.errorRed
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(SlangColor.separator, lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            Text("\(timeRemaining)")
                .font(.slang(.caption))
                .foregroundStyle(ringColor)
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .animation(.linear(duration: 1), value: timeRemaining)
        }
        .accessibilityLabel("\(timeRemaining) seconds remaining")
    }
}
