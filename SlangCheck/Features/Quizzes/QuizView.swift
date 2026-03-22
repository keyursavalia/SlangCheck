// Features/Quizzes/QuizView.swift
// SlangCheck
//
// Active quiz screen: question card, four answer choices, hint button,
// progress indicator. Correct → green pulse. Wrong → red shake.

import SwiftUI

// MARK: - QuizView

/// The full-screen quiz experience. Presented as a `.fullScreenCover` from `QuizzesView`.
/// Transitions to `QuizResultView` inline once the session finishes.
struct QuizView: View {

    @Bindable var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss

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
                        // Reset state then close the fullScreenCover.
                        // Calling only dismissResult() leaves the cover open
                        // showing the default-case spinner.
                        viewModel.dismissResult()
                        dismiss()
                    }
                )
            default:
                // Loading / idle — should not appear during an active quiz session.
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(SlangColor.background.ignoresSafeArea())
            }
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
                    .id(viewModel.currentIndex)   // triggers slide-in transition
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

    // MARK: - Header (Progress + Hint)

    private var quizHeader: some View {
        VStack(spacing: SlangSpacing.sm) {
            HStack {
                Text("Question \(viewModel.questionNumber) of \(viewModel.totalQuestions)")
                .font(.slang(.caption))
                .foregroundStyle(.secondary)

                Spacer()

                Button(action: { viewModel.useHint() }) {
                    Label(
                        viewModel.canUseHint
                            ? String(localized: "quiz.hint", defaultValue: "Hint")
                            : String(localized: "quiz.hint.used", defaultValue: "Hint Used"),
                        systemImage: "lightbulb"
                    )
                    .font(.slang(.caption))
                    .foregroundStyle(viewModel.canUseHint ? SlangColor.accent : .secondary)
                }
                .disabled(!viewModel.canUseHint)
                .accessibilityLabel(
                    viewModel.canUseHint
                        ? String(localized: "quiz.hint.accessibility", defaultValue: "Use hint to eliminate one wrong answer")
                        : String(localized: "quiz.hint.used.accessibility", defaultValue: "Hint already used")
                )
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

    // MARK: - Answer Choices

    private var choicesGrid: some View {
        let isLast = viewModel.currentIndex + 1 >= viewModel.totalQuestions
        _ = isLast  // suppress unused warning; used in nextButton

        return VStack(spacing: SlangSpacing.sm) {
            ForEach(viewModel.shuffledChoices, id: \.self) { choice in
                QuizChoiceButton(
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
                .font(.slang(.label))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, SlangSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SlangCornerRadius.button)
                        .fill(viewModel.isAnswerRevealed ? SlangColor.primary : SlangColor.separator)
                )
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
        .glassCard()
    }

    private var questionTypeBadge: String {
        switch question.type {
        case .definitionPick: return String(localized: "quiz.badge.definitionPick", defaultValue: "Definition")
        case .termPick:       return String(localized: "quiz.badge.termPick",       defaultValue: "Term")
        case .fillInBlank:    return String(localized: "quiz.badge.fillInBlank",    defaultValue: "Fill in the Blank")
        }
    }

    private var questionStem: String {
        switch question.type {
        case .definitionPick:
            return "What does \"\(question.term)\" mean?"
        case .termPick:
            return "Which term means: \"\(question.correctDefinition)\"?"
        case .fillInBlank:
            return question.sentenceWithBlank
        }
    }
}

// MARK: - QuizChoiceButton

/// A single answer-choice button. Renders neutral, correct, wrong, or eliminated states.
private struct QuizChoiceButton: View {

    let choice: String
    let correctAnswer: String
    let selectedAnswer: String?
    let isRevealed: Bool
    let isEliminated: Bool
    let action: () -> Void

    @State private var shakeTrigger: CGFloat = 0

    private var choiceState: ChoiceState {
        guard isRevealed else { return isEliminated ? .eliminated : .neutral }
        if choice == correctAnswer        { return .correct }
        if choice == selectedAnswer       { return .wrong }
        return .dimmed
    }

    var body: some View {
        Button(action: triggerAction) {
            Text(choice)
                .font(.slang(.body))
                .foregroundStyle(foregroundColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SlangSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SlangCornerRadius.cell)
                        .fill(backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SlangCornerRadius.cell)
                        .strokeBorder(borderColor, lineWidth: choiceState == .correct ? 2 : 0)
                )
        }
        .disabled(isRevealed || isEliminated)
        .modifier(ShakeEffect(trigger: shakeTrigger))
        .opacity(choiceState == .dimmed || choiceState == .eliminated ? 0.40 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: choiceState)
        .accessibilityLabel(choice)
        .accessibilityAddTraits(choiceState == .correct ? .isSelected : [])
    }

    // MARK: - State → Colors

    private var backgroundColor: Color {
        switch choiceState {
        case .neutral:    return SlangColor.surface
        case .correct:    return SlangColor.secondary.opacity(0.20)
        case .wrong:      return SlangColor.errorRed.opacity(0.20)
        case .dimmed, .eliminated: return SlangColor.surface
        }
    }

    private var foregroundColor: Color {
        switch choiceState {
        case .correct:    return SlangColor.secondary
        case .wrong:      return SlangColor.errorRed
        default:          return .primary
        }
    }

    private var borderColor: Color {
        switch choiceState {
        case .correct: return SlangColor.secondary
        case .wrong:   return SlangColor.errorRed
        default:       return .clear
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

private enum ChoiceState { case neutral, correct, wrong, dimmed, eliminated }
extension ChoiceState: Equatable {}
