// Features/Quizzes/QuizzesView.swift
// SlangCheck
//
// Root view for the Quizzes tab. Shows the user's Aura profile and
// launches the quiz session as a full-screen cover.

import SwiftUI

// MARK: - QuizzesView

/// Entry point for the Quizzes tab. Owns the `QuizViewModel`.
struct QuizzesView: View {

    @Environment(\.appEnvironment) private var env
    @State private var viewModel: QuizViewModel? = nil
    @State private var showingQuiz = false
    @State private var auraCardImage: AuraCardImage? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SlangSpacing.lg) {
                    profileCard
                    startButton
                    if let vm = viewModel, case .result(let result) = vm.phase {
                        recentResultBanner(result: result)
                    }
                }
                .padding(SlangSpacing.md)
            }
            .background(SlangColor.background.ignoresSafeArea())
            .navigationTitle(String(localized: "quizzes.title", defaultValue: "Quizzes"))
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            guard viewModel == nil else { return }
            viewModel = makeViewModel()
            await viewModel?.loadProfile()
            renderAuraCard()
        }
        .fullScreenCover(isPresented: $showingQuiz, onDismiss: handleQuizDismiss) {
            if let vm = viewModel {
                QuizView(viewModel: vm)
            }
        }
    }

    // MARK: - Profile Card

    @ViewBuilder
    private var profileCard: some View {
        if let profile = viewModel?.auraProfile {
            VStack(spacing: SlangSpacing.sm) {
                AuraProfileView(profile: profile)
                if let cardImage = auraCardImage {
                    ShareLink(
                        item: cardImage,
                        preview: SharePreview(
                            "My Aura Card",
                            image: Image(uiImage: cardImage.uiImage)
                        )
                    ) {
                        Label("Share Aura Card", systemImage: "square.and.arrow.up")
                            .font(.slang(.caption))
                            .foregroundStyle(SlangColor.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, SlangSpacing.sm)
                    }
                    .accessibilityLabel("Share your Aura Card")
                }
            }
        } else {
            auraPlaceholderCard
        }
    }

    private var auraPlaceholderCard: some View {
        VStack(spacing: SlangSpacing.sm) {
            Image(systemName: "trophy")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(SlangColor.primary.opacity(0.6))
                .accessibilityHidden(true)
            Text(String(localized: "aura.profile.noHistory",
                        defaultValue: "Complete a quiz to earn Aura Points!"))
                .font(.slang(.body))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(SlangSpacing.xl)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            Task {
                await viewModel?.startQuiz()
                if viewModel?.phase == .active {
                    showingQuiz = true
                }
            }
        } label: {
            HStack(spacing: SlangSpacing.sm) {
                if viewModel?.phase == .loading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "play.fill")
                        .accessibilityHidden(true)
                    Text(String(localized: "aura.profile.startQuiz", defaultValue: "Start Quiz"))
                }
            }
            .font(.slang(.label))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, SlangSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: SlangCornerRadius.button)
                    .fill(SlangColor.primary)
            )
        }
        .disabled(viewModel?.phase == .loading)
        .accessibilityLabel(
            String(localized: "aura.profile.startQuiz", defaultValue: "Start Quiz")
        )
    }

    // MARK: - Recent Result Banner

    private func recentResultBanner(result: QuizResult) -> some View {
        HStack(spacing: SlangSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(SlangColor.secondary)
                .font(.title2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: SlangSpacing.xs) {
                Text("\(result.correctCount)/\(result.totalCount) Correct")
                    .font(.slang(.label))
                    .foregroundStyle(.primary)

                Text("+\(result.auraPointsEarned) Aura")
                    .font(.slang(.caption))
                    .foregroundStyle(SlangColor.primary)
            }
            Spacer()
        }
        .padding(SlangSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: SlangCornerRadius.cell)
                .fill(SlangColor.surface)
        )
    }

    // MARK: - Helpers

    private func handleQuizDismiss() {
        Task {
            await viewModel?.loadProfile()
            renderAuraCard()
        }
    }

    private func renderAuraCard() {
        guard let profile = viewModel?.auraProfile else { return }
        Task { @MainActor in
            if let image = AuraCardView.render(for: profile) {
                auraCardImage = AuraCardImage(uiImage: image)
            }
        }
    }

    private func makeViewModel() -> QuizViewModel {
        QuizViewModel(
            generateQuizUseCase: GenerateQuizUseCase(repository: env.slangTermRepository),
            syncUseCase:         env.syncAuraProfileUseCase,
            auraRepository:      env.auraRepository,
            hapticService:       env.hapticService
        )
    }
}

// MARK: - Preview

#Preview("QuizzesView") {
    QuizzesView()
        .environment(\.appEnvironment, .preview())
}
