// Features/Translator/TranslatorView.swift
// SlangCheck
//
// Split-screen Translator UI (Iteration 2, Step 2.3).
// Top panel: text input with language label.
// Middle: direction swap button with .rotation3DEffect animation.
// Bottom: translated output with copy-to-clipboard button.
// Below output: substitutions breakdown (visible when terms were matched).

import SwiftUI

// MARK: - TranslatorView

/// Entry point for the Translator tab.
/// Defers ViewModel creation until the SwiftUI environment is available,
/// matching the lazy-init pattern used in GlossaryView.
struct TranslatorView: View {

    @Environment(\.appEnvironment) private var env
    @State private var viewModel: TranslatorViewModel?

    var body: some View {
        Group {
            if let viewModel {
                TranslatorContentView(viewModel: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(SlangColor.background)
            }
        }
        .task {
            guard viewModel == nil else { return }
            let service = LocalTranslationService(
                repository: env.slangTermRepository,
                aiService:  env.aiTranslationService
            )
            viewModel = TranslatorViewModel(
                translationService: service,
                hapticService: env.hapticService
            )
        }
    }
}

// MARK: - TranslatorContentView

@MainActor
struct TranslatorContentView: View {

    @Bindable var viewModel: TranslatorViewModel
    @Environment(\.appEnvironment) private var env

    /// Cumulative rotation of the swap button — increments by 180° each tap.
    @State private var swapRotation: Double = 0

    /// Temporarily `true` after the user taps Copy, driving the checkmark state.
    @State private var didCopy: Bool = false

    /// Tracks focus on the input TextEditor for programmatic keyboard dismissal.
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SlangSpacing.md) {
                    inputPanel
                    swapButtonRow
                    outputPanel
                    if let result = viewModel.result, result.hasSubstitutions {
                        substitutionsSection(result.substitutions)
                        exampleSentencesSection(result.substitutions)
                    }
                }
                .padding(.horizontal, SlangSpacing.md)
                .padding(.top, SlangSpacing.sm)
                .padding(.bottom, SlangSpacing.xl)
            }
            .background(SlangColor.background)
            // Dismiss keyboard by tapping outside the TextEditor or by swiping the
            // scroll view down. The explicit "Done" toolbar button has been removed
            // — interactive dismiss is more natural and less cluttered.
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { isInputFocused = false }
            .navigationTitle(String(localized: "tab.translator", defaultValue: "Translator"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Input Panel

    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: SlangSpacing.sm) {
            languageLabel(viewModel.direction.inputLanguageLabel, icon: "pencil")

            ZStack(alignment: .topLeading) {
                if viewModel.inputText.isEmpty {
                    Text(viewModel.direction.inputPlaceholder)
                        .font(.slang(.body))
                        .foregroundStyle(Color(.placeholderText))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 9)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.inputText)
                    .font(.slang(.body))
                    .foregroundStyle(.primary)
                    .frame(height: 80)
                    .scrollContentBackground(.hidden)
                    .focused($isInputFocused)
                    .accessibilityLabel(viewModel.direction.inputLanguageLabel)
            }

            HStack {
                Spacer()
                if !viewModel.inputText.isEmpty {
                    Button(String(localized: "translator.clear", defaultValue: "Clear")) {
                        viewModel.clear()
                    }
                    .font(.slang(.caption))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(
                        String(localized: "translator.clear.accessibility", defaultValue: "Clear input text")
                    )
                }
            }
        }
        .padding(SlangSpacing.md)
        .glassCard()
    }

    // MARK: - Swap Button

    private var swapButtonRow: some View {
        HStack {
            Spacer()
            Button {
                swapRotation += 180
                viewModel.swapDirection()
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(SlangColor.primary)
                    .rotation3DEffect(.degrees(swapRotation), axis: (x: 0, y: 1, z: 0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.65), value: swapRotation)
            }
            .accessibilityLabel(
                String(localized: "translator.swap.accessibility", defaultValue: "Swap translation direction")
            )
            Spacer()
        }
    }

    // MARK: - Output Panel

    private var outputPanel: some View {
        VStack(alignment: .leading, spacing: SlangSpacing.sm) {
            HStack {
                languageLabel(viewModel.direction.outputLanguageLabel, icon: "text.bubble")
                Spacer()
                if let result = viewModel.result, !result.translatedText.isEmpty {
                    copyButton(text: result.translatedText)
                }
            }

            outputContent
                .frame(height: 80, alignment: .topLeading)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.slang(.caption))
                    .foregroundStyle(SlangColor.errorRed)
            }
        }
        .padding(SlangSpacing.md)
        .glassCard()
    }

    @ViewBuilder
    private var outputContent: some View {
        if viewModel.isTranslating {
            HStack(spacing: SlangSpacing.sm) {
                ProgressView()
                    .tint(SlangColor.primary)
                Text(String(localized: "translator.translating", defaultValue: "Translating…"))
                    .font(.slang(.caption))
                    .foregroundStyle(.secondary)
            }
        } else if let result = viewModel.result {
            Text(result.translatedText)
                .font(.slang(.body))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        } else {
            Text(String(localized: "translator.output.placeholder", defaultValue: "Translation will appear here…"))
                .font(.slang(.body))
                .foregroundStyle(Color(.placeholderText))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Copy Button

    private func copyButton(text: String) -> some View {
        Button {
            UIPasteboard.general.string = text
            viewModel.hapticService.copySucceeded()
            didCopy = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                didCopy = false
            }
        } label: {
            Label(
                didCopy
                    ? String(localized: "translator.copied", defaultValue: "Copied!")
                    : String(localized: "translator.copy", defaultValue: "Copy"),
                systemImage: didCopy ? "checkmark" : "doc.on.doc"
            )
            .font(.slang(.caption))
            .foregroundStyle(SlangColor.primary)
            .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(
            String(localized: "translator.copy.accessibility", defaultValue: "Copy translation to clipboard")
        )
    }

    // MARK: - Substitutions Section

    @ViewBuilder
    private func substitutionsSection(_ substitutions: [TranslationResult.Substitution]) -> some View {
        VStack(alignment: .leading, spacing: SlangSpacing.sm) {
            Text(String(localized: "translator.substitutions.title", defaultValue: "Terms Translated"))
                .font(.slang(.subheading))
                .foregroundStyle(SlangColor.primary)

            ForEach(substitutions) { sub in
                HStack(spacing: SlangSpacing.sm) {
                    substitutionChip(sub.originalToken, color: SlangColor.primary)
                    Image(systemName: "arrow.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    substitutionChip(sub.translatedToken, color: SlangColor.secondary)
                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(sub.originalToken) translates to \(sub.translatedToken)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SlangSpacing.md)
        .glassCard()
    }

    // MARK: - Example Sentences Section

    @ViewBuilder
    private func exampleSentencesSection(_ substitutions: [TranslationResult.Substitution]) -> some View {
        VStack(alignment: .leading, spacing: SlangSpacing.md) {
            Text(String(localized: "translator.examples.title", defaultValue: "How to use this in a sentence?"))
                .font(.slang(.subheading))
                .foregroundStyle(SlangColor.primary)

            ForEach(substitutions) { sub in
                VStack(alignment: .leading, spacing: SlangSpacing.xs) {
                    // Term name badge
                    Text(sub.term.term)
                        .font(.slang(.label))
                        .foregroundStyle(SlangColor.secondary)

                    // Example sentence with the slang term highlighted
                    highlightedExample(sentence: sub.term.exampleSentence, slangTerm: sub.term.term)
                        .font(.slang(.body))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SlangSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                        .fill(SlangColor.secondary.opacity(0.08))
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(sub.term.term): \(sub.term.exampleSentence)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SlangSpacing.md)
        .glassCard()
    }

    /// Renders the example sentence with the slang term bolded and tinted.
    private func highlightedExample(sentence: String, slangTerm: String) -> Text {
        let lower     = sentence.lowercased()
        let termLower = slangTerm.lowercased()

        guard let range = lower.range(of: termLower) else {
            return Text(sentence).foregroundColor(.primary)
        }

        let before  = String(sentence[sentence.startIndex ..< range.lowerBound])
        let matched = String(sentence[range.lowerBound ..< range.upperBound])
        let after   = String(sentence[range.upperBound...])

        return Text(before).foregroundColor(.primary)
             + Text(matched).bold().foregroundColor(SlangColor.secondary)
             + Text(after).foregroundColor(.primary)
    }

    private func substitutionChip(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.slang(.caption))
            .foregroundStyle(color)
            .padding(.horizontal, SlangSpacing.sm)
            .padding(.vertical, SlangSpacing.xs)
            .background(Capsule().fill(color.opacity(0.15)))
    }

    // MARK: - Helpers

    private func languageLabel(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.slang(.caption))
            .foregroundStyle(SlangColor.primary)
    }
}

// MARK: - Preview

#Preview("Translator") {
    TranslatorView()
        .environment(\.appEnvironment, .preview())
}
