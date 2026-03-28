// Features/Quizzes/QuizzesView.swift
// SlangCheck
//
// Root view for the Games screen. Shows the user's compact Aura summary
// and two large game-mode cards — Quiz and Daily Crossword.
// Presented as a fullScreenCover from SwiperView.

import SwiftUI

// MARK: - QuizzesView

/// Entry point for the Games screen.
/// Owns the `QuizViewModel` and surfaces both game modes in a premium card layout.
struct QuizzesView: View {

    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthState.self) private var authState
    @State private var viewModel: QuizViewModel? = nil
    @State private var showingQuiz       = false
    @State private var showingCrossword  = false
    @State private var showingAuthGate   = false
    @State private var showingAIPrompt   = false
    @State private var showAlreadyAttemptedAlert = false
    @State private var pendingGame: PendingGame? = nil
    @State private var auraCardImage: AuraCardImage? = nil
    @AppStorage("hasSeenAIPrompt") private var hasSeenAIPrompt = false

    /// Which game the user tried to launch before auth was required.
    private enum PendingGame { case quiz, crossword }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SlangSpacing.lg) {
                    auraSection
                    gameModeSection
                }
                .padding(.horizontal, SlangSpacing.md)
                .padding(.top, SlangSpacing.sm)
                .padding(.bottom, SlangSpacing.xl)
            }
            .background(SlangColor.background.ignoresSafeArea())
            .navigationTitle(String(localized: "quizzes.title", defaultValue: "Games"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(SlangColor.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
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
        .fullScreenCover(isPresented: $showingCrossword) {
            NavigationStack {
                CrosswordView(onSessionEnd: { showingCrossword = false })
                    .environment(\.appEnvironment, env)
            }
        }
        .sheet(isPresented: $showingAuthGate) {
            AuthGateView {
                // Auth succeeded — now launch whatever game was requested.
                launchPendingGame()
            }
        }
        .sheet(isPresented: $showingAIPrompt) {
            AIActivationPromptView {
                showingAIPrompt = false
            }
            .presentationDetents([.medium])
        }
        .alert(
            String(localized: "crossword.alreadyAttempted.title",
                   defaultValue: "Already Attempted"),
            isPresented: $showAlreadyAttemptedAlert
        ) {
            Button(String(localized: "general.ok", defaultValue: "OK"), role: .cancel) { }
        } message: {
            Text(String(localized: "crossword.alreadyAttempted.message",
                        defaultValue: "You've already attempted today's crossword. Come back tomorrow for a new puzzle!"))
        }
        .onAppear {
            if !hasSeenAIPrompt, AIAvailabilityChecker.canPromptForAppleIntelligence() {
                showingAIPrompt = true
            }
        }
    }

    // MARK: - Aura Section

    @ViewBuilder
    private var auraSection: some View {
        if let profile = viewModel?.auraProfile {
            VStack(spacing: SlangSpacing.sm) {
                CompactAuraBannerView(profile: profile)
                if let cardImage = auraCardImage {
                    ShareLink(
                        item: cardImage,
                        preview: SharePreview(
                            String(localized: "auraCard.share.preview", defaultValue: "My Aura Card"),
                            image: Image(uiImage: cardImage.uiImage)
                        )
                    ) {
                        Label(
                            String(localized: "auraCard.share", defaultValue: "Share Aura Card"),
                            systemImage: "square.and.arrow.up"
                        )
                        .font(.slang(.caption))
                        .foregroundStyle(SlangColor.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SlangSpacing.xs)
                    }
                    .accessibilityLabel(
                        String(localized: "auraCard.share.accessibility",
                               defaultValue: "Share your Aura Card")
                    )
                }
            }
        } else {
            auraPlaceholderBanner
        }
    }

    private var auraPlaceholderBanner: some View {
        HStack(spacing: SlangSpacing.md) {
            Image(systemName: "trophy")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(SlangColor.primary.opacity(0.6))
                .accessibilityHidden(true)
            Text(String(localized: "aura.profile.noHistory",
                        defaultValue: "Complete a quiz to earn Aura Points!"))
                .font(.slang(.body))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(SlangSpacing.md)
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

    // MARK: - Game Mode Section

    private var gameModeSection: some View {
        VStack(spacing: SlangSpacing.md) {
            aiProviderBadge
            GameModeCard(
                icon: "trophy.fill",
                iconColor: SlangColor.primary,
                title: String(localized: "games.quiz.title", defaultValue: "Quiz"),
                subtitle: String(localized: "games.quiz.subtitle",
                                 defaultValue: "Test your slang knowledge"),
                isLoading: viewModel?.phase == .loading
            ) {
                requireAuth(for: .quiz)
            }

            GameModeCard(
                icon: "squareshape.split.3x3",
                iconColor: SlangColor.primary,
                title: String(localized: "games.crossword.title", defaultValue: "Daily Crossword"),
                subtitle: String(localized: "games.crossword.subtitle",
                                 defaultValue: "A new puzzle every morning at 7 AM"),
                isLoading: false
            ) {
                requireAuth(for: .crossword)
            }
        }
    }

    // MARK: - AI Provider Badge

    @ViewBuilder
    private var aiProviderBadge: some View {
        let provider = AIAvailabilityChecker.currentProvider()
        HStack(spacing: SlangSpacing.xs) {
            Image(systemName: provider == .appleIntelligence ? "cpu" : "cloud")
                .font(.system(size: 11, weight: .semibold))
            Text(provider == .appleIntelligence
                 ? String(localized: "games.ai.apple", defaultValue: "Apple Intelligence")
                 : provider == .gemini
                    ? String(localized: "games.ai.gemini", defaultValue: "Gemini AI")
                    : String(localized: "games.ai.static", defaultValue: "Classic Mode"))
                .font(.slang(.caption))
        }
        .foregroundStyle(SlangColor.primary.opacity(0.7))
        .padding(.horizontal, SlangSpacing.md)
        .padding(.vertical, SlangSpacing.xs)
        .background(Capsule().fill(SlangColor.primary.opacity(0.08)))
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Auth-Gated Launch

    /// If the user is authenticated, launch the game immediately.
    /// Otherwise, store the intent and present the auth gate sheet.
    private func requireAuth(for game: PendingGame) {
        if authState.isAuthenticated {
            launch(game)
        } else {
            pendingGame = game
            showingAuthGate = true
        }
    }

    private func launchPendingGame() {
        guard let game = pendingGame else { return }
        pendingGame = nil
        launch(game)
    }

    private func launch(_ game: PendingGame) {
        switch game {
        case .quiz:
            Task {
                await viewModel?.startQuiz()
                if viewModel?.phase == .active {
                    showingQuiz = true
                }
            }
        case .crossword:
            if CrosswordViewModel.hasAttemptedToday() {
                showAlreadyAttemptedAlert = true
            } else {
                showingCrossword = true
            }
        }
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
            generateQuizUseCase: GenerateQuizUseCase(
                repository: env.slangTermRepository,
                aiService:  env.aiQuizService
            ),
            syncUseCase:     env.syncAuraProfileUseCase,
            auraRepository:  env.auraRepository,
            hapticService:   env.hapticService
        )
    }
}

// MARK: - CompactAuraBannerView

/// A compact horizontal Aura summary shown at the top of the Games screen.
private struct CompactAuraBannerView: View {

    let profile: AuraProfile
    @Environment(AuthState.self) private var authState

    var body: some View {
        HStack(spacing: SlangSpacing.md) {
            ZStack {
                Circle()
                    .fill(tierColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                if let url = authState.currentProfile?.photoURL {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                        } else {
                            tierIconView
                        }
                    }
                } else {
                    tierIconView
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.currentTier.displayName)
                    .font(.slang(.label))
                    .foregroundStyle(.primary)
                Text(profile.currentTier.subtitle)
                    .font(.slang(.caption))
                    .foregroundStyle(.primary.opacity(0.6))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(profile.totalPoints) pts")
                    .font(.slang(.label))
                    .foregroundStyle(tierColor)
                    .contentTransition(.numericText())
                if profile.streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(SlangColor.accent)
                            .accessibilityHidden(true)
                        Text("\(profile.streak)d")
                            .font(.slang(.caption))
                            .foregroundStyle(SlangColor.accent)
                    }
                }
            }
        }
        .padding(SlangSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .fill(Color(.systemBackground))
        }
        .background {
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .fill(.black)
                .offset(y: 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.currentTier.displayName), \(profile.totalPoints) points, \(profile.streak) day streak")
    }

    private var tierColor: Color {
        switch profile.currentTier {
        case .unc:        return SlangColor.primary
        case .lurk:       return SlangColor.accent
        case .auraFarmer: return SlangColor.primary
        case .rizzler:    return SlangColor.primary
        }
    }

    private var tierSymbol: String {
        switch profile.currentTier {
        case .unc:        return "figure.stand"
        case .lurk:       return "eye.fill"
        case .auraFarmer: return "flame.fill"
        case .rizzler:    return "crown.fill"
        }
    }

    private var tierIconView: some View {
        Image(systemName: tierSymbol)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(tierColor)
            .accessibilityHidden(true)
    }
}

// MARK: - GameModeCard

/// A large, tappable game-mode entry card with onboarding-style drop shadow.
private struct GameModeCard: View {

    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: SlangSpacing.lg) {
                ZStack {
                    RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 64, height: 64)
                    if isLoading {
                        ProgressView()
                            .tint(iconColor)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(iconColor)
                            .accessibilityHidden(true)
                    }
                }

                VStack(alignment: .leading, spacing: SlangSpacing.xs) {
                    Text(title)
                        .font(.slang(.heading))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.slang(.caption))
                        .foregroundStyle(.primary.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.35))
                    .accessibilityHidden(true)
            }
            .padding(SlangSpacing.lg)
            .frame(maxWidth: .infinity)
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
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

// MARK: - Preview

#Preview("QuizzesView") {
    QuizzesView()
        .environment(\.appEnvironment, .preview())
        .environment(AuthState(
            authService:       NoOpAuthenticationService(),
            profileRepository: NoOpUserProfileRepository()
        ))
}
