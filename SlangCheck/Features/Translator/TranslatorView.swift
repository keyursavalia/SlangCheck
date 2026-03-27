// Features/Translator/TranslatorView.swift
// SlangCheck
//
// Chill & Cozy split-screen translator.
// Panels use the same warm card surface as SlangCardView.
// Title style matches the SwiperView principal toolbar item.

import SwiftUI

// MARK: - TranslatorView

/// Entry point for the Translator tab.
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

    /// Card surface — warm parchment in light mode, warm near-black in dark mode.
    private var cardBackground: Color { SlangColor.cardSurface }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SlangSpacing.lg) {
                    inputPanel
                    swapButtonRow
                    outputPanel
                    if let result = viewModel.result, result.hasSubstitutions {
                        substitutionsSection(result.substitutions)
                        exampleSentencesSection(result.substitutions)
                    }
                }
                .padding(.horizontal, SlangSpacing.md)
                .padding(.top, SlangSpacing.md)
                .padding(.bottom, SlangSpacing.xl)
            }
            .background(SlangColor.background)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { isInputFocused = false }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(SlangColor.secondary)
                        Text(String(localized: "translator.title.full", defaultValue: "Translate GenZ Lingo").uppercased())
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .tracking(2.5)
                            .foregroundStyle(.primary)
                        Image(systemName: "waveform")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(SlangColor.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Input Panel

    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: SlangSpacing.sm) {
            languageLabel(viewModel.direction.inputLanguageLabel, icon: "pencil.line")

            ZStack(alignment: .topLeading) {
                if viewModel.inputText.isEmpty {
                    Text(viewModel.direction.inputPlaceholder)
                        .font(.montserrat(size: 16))
                        .foregroundStyle(.primary.opacity(0.35))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 9)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.inputText)
                    .font(.montserrat(size: 16))
                    .foregroundStyle(.primary)
                    .frame(minHeight: 90)
                    .scrollContentBackground(.hidden)
                    .focused($isInputFocused)
                    .accessibilityLabel(viewModel.direction.inputLanguageLabel)
            }

            if !viewModel.inputText.isEmpty {
                HStack {
                    Spacer()
                    Button(String(localized: "translator.clear", defaultValue: "Clear")) {
                        viewModel.clear()
                    }
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(SlangColor.accent.opacity(0.8))
                }
            }
        }
        .padding(SlangSpacing.md)
        .background(RoundedRectangle(cornerRadius: SlangCornerRadius.card).fill(cardBackground))
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .strokeBorder(SlangColor.secondary.opacity(0.35), lineWidth: 1.5)
        )
        .shadow(color: SlangColor.secondary.opacity(0.12), radius: 12, x: 0, y: 0)
    }

    // MARK: - Swap Button

    private var swapButtonRow: some View {
        HStack {
            Spacer()
            Button {
                swapRotation += 180
                viewModel.swapDirection()
            } label: {
                ZStack {
                    Circle()
                        .fill(SlangColor.secondary.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(SlangColor.secondary)
                        .rotation3DEffect(.degrees(swapRotation), axis: (x: 0, y: 1, z: 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: swapRotation)
                }
            }
            .shadow(color: SlangColor.secondary.opacity(0.35), radius: 10, x: 0, y: 0)
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
                .frame(minHeight: 90, alignment: .topLeading)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.slang(.caption))
                    .foregroundStyle(SlangColor.errorRed)
            }
        }
        .padding(SlangSpacing.md)
        .background(RoundedRectangle(cornerRadius: SlangCornerRadius.card).fill(cardBackground))
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .strokeBorder(
                    viewModel.result != nil ? SlangColor.secondary.opacity(0.55) : SlangColor.secondary.opacity(0.20),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: SlangColor.secondary.opacity(viewModel.result != nil ? 0.30 : 0.08),
            radius: 16, x: 0, y: 0
        )
    }

    @ViewBuilder
    private var outputContent: some View {
        if viewModel.isTranslating {
            HStack(spacing: SlangSpacing.sm) {
                ProgressView().tint(SlangColor.secondary)
                Text(String(localized: "translator.translating", defaultValue: "Translating…"))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.primary.opacity(0.50))
            }
        } else if let result = viewModel.result {
            Text(result.translatedText)
                .font(.montserrat(size: 16))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        } else {
            Text(String(localized: "translator.output.placeholder", defaultValue: "Translation will appear here…"))
                .font(.montserrat(size: 16))
                .foregroundStyle(.primary.opacity(0.30))
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
            HStack(spacing: 4) {
                Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                Text(didCopy
                     ? String(localized: "translator.copied", defaultValue: "Copied!")
                     : String(localized: "translator.copy", defaultValue: "Copy"))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
            .foregroundStyle(SlangColor.secondary)
            .padding(.horizontal, SlangSpacing.sm)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(SlangColor.secondary.opacity(0.12))
            )
        }
        .accessibilityLabel(
            String(localized: "translator.copy.accessibility", defaultValue: "Copy translation to clipboard")
        )
    }

    // MARK: - Substitutions Section

    @ViewBuilder
    private func substitutionsSection(_ substitutions: [TranslationResult.Substitution]) -> some View {
        VStack(alignment: .leading, spacing: SlangSpacing.sm) {
            sectionHeader(
                String(localized: "translator.substitutions.title", defaultValue: "Terms Translated"),
                icon: "arrow.left.arrow.right"
            )

            ForEach(substitutions) { sub in
                HStack(spacing: SlangSpacing.sm) {
                    substitutionChip(sub.originalToken, color: SlangColor.accent)
                    Image(systemName: "arrow.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.primary.opacity(0.35))
                    substitutionChip(sub.translatedToken, color: SlangColor.secondary)
                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(sub.originalToken) translates to \(sub.translatedToken)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SlangSpacing.md)
        .background(RoundedRectangle(cornerRadius: SlangCornerRadius.card).fill(cardBackground))
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .strokeBorder(SlangColor.accent.opacity(0.30), lineWidth: 1.5)
        )
    }

    // MARK: - Example Sentences Section

    @ViewBuilder
    private func exampleSentencesSection(_ substitutions: [TranslationResult.Substitution]) -> some View {
        VStack(alignment: .leading, spacing: SlangSpacing.md) {
            sectionHeader(
                String(localized: "translator.examples.title", defaultValue: "How to use this in a sentence?"),
                icon: "text.quote"
            )

            ForEach(substitutions) { sub in
                VStack(alignment: .leading, spacing: SlangSpacing.xs) {
                    Text(sub.term.term)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(SlangColor.accent)
                        .padding(.horizontal, SlangSpacing.sm)
                        .padding(.vertical, SlangSpacing.xs)
                        .overlay(
                            RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                                .strokeBorder(SlangColor.accent.opacity(0.55), lineWidth: 1)
                        )

                    highlightedExample(sentence: sub.term.exampleSentence, slangTerm: sub.term.term)
                        .font(.montserrat(size: 15))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SlangSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                        .fill(SlangColor.secondary.opacity(0.06))
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(sub.term.term): \(sub.term.exampleSentence)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SlangSpacing.md)
        .background(RoundedRectangle(cornerRadius: SlangCornerRadius.card).fill(cardBackground))
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .strokeBorder(SlangColor.secondary.opacity(0.25), lineWidth: 1.5)
        )
    }

    /// Renders the example sentence with the slang term bolded and tinted.
    private func highlightedExample(sentence: String, slangTerm: String) -> Text {
        let lower     = sentence.lowercased()
        let termLower = slangTerm.lowercased()

        guard let range = lower.range(of: termLower) else {
            return Text(sentence).foregroundColor(Color.primary.opacity(0.80))
        }

        let before  = String(sentence[sentence.startIndex ..< range.lowerBound])
        let matched = String(sentence[range.lowerBound ..< range.upperBound])
        let after   = String(sentence[range.upperBound...])

        return Text(before).foregroundColor(Color.primary.opacity(0.80))
             + Text(matched).bold().foregroundColor(SlangColor.secondary)
             + Text(after).foregroundColor(Color.primary.opacity(0.80))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: SlangSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(SlangColor.secondary)
                .accessibilityHidden(true)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(.primary.opacity(0.50))
        }
    }

    private func languageLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(SlangColor.secondary)
                .accessibilityHidden(true)
            Text(text.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(.primary.opacity(0.55))
        }
    }

    private func substitutionChip(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, SlangSpacing.sm)
            .padding(.vertical, SlangSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                    .fill(color.opacity(0.12))
            )
    }
}

// MARK: - Preview

#Preview("Translator") {
    TranslatorView()
        .environment(\.appEnvironment, .preview())
}
