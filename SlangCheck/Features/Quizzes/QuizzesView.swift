// Features/Quizzes/QuizzesView.swift
// SlangCheck
//
// Root view for the Games tab. Shows the user's compact Aura summary
// and two large game-mode cards — Quiz and Daily Crossword.

import SwiftUI

// MARK: - QuizzesView

/// Entry point for the Games tab.
/// Owns the `QuizViewModel` and surfaces both game modes in a premium card layout.
struct QuizzesView: View {

    @Environment(\.appEnvironment) private var env
    @Environment(AuthState.self) private var authState
    @State private var viewModel: QuizViewModel? = nil
    @State private var showingQuiz       = false
    @State private var showingCrossword  = false
    @State private var showingAuthGate   = false
    @State private var pendingGame: PendingGame? = nil
    @State private var auraCardImage: AuraCardImage? = nil

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
            CrosswordView()
        }
        .sheet(isPresented: $showingAuthGate) {
            AuthGateView {
                // Auth succeeded — now launch whatever game was requested.
                launchPendingGame()
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
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(SlangSpacing.md)
        .glassCard()
    }

    // MARK: - Game Mode Section

    private var gameModeSection: some View {
        VStack(spacing: SlangSpacing.md) {
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
                iconColor: SlangColor.secondary,
                title: String(localized: "games.crossword.title", defaultValue: "Daily Crossword"),
                subtitle: String(localized: "games.crossword.subtitle",
                                 defaultValue: "A new puzzle every morning at 7 AM"),
                isLoading: false
            ) {
                requireAuth(for: .crossword)
            }
        }
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
            showingCrossword = true
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

/// A compact horizontal Aura summary shown at the top of the Games tab.
private struct CompactAuraBannerView: View {

    let profile: AuraProfile

    var body: some View {
        HStack(spacing: SlangSpacing.md) {
            // Tier badge circle
            ZStack {
                Circle()
                    .fill(tierColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: tierSymbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tierColor)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.currentTier.displayName)
                    .font(.slang(.label))
                    .foregroundStyle(.primary)
                Text(profile.currentTier.subtitle)
                    .font(.slang(.caption))
                    .foregroundStyle(.secondary)
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
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.currentTier.displayName), \(profile.totalPoints) points, \(profile.streak) day streak")
    }

    private var tierColor: Color {
        switch profile.currentTier {
        case .unc:        return .secondary
        case .lurk:       return SlangColor.accent
        case .auraFarmer: return SlangColor.secondary
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
}

// MARK: - GameModeCard

/// A large, tappable game-mode entry card.
private struct GameModeCard: View {

    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: SlangSpacing.lg) {
                // Icon
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

                // Text
                VStack(alignment: .leading, spacing: SlangSpacing.xs) {
                    Text(title)
                        .font(.slang(.heading))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.slang(.caption))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                    .accessibilityHidden(true)
            }
            .padding(SlangSpacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                    .fill(SlangColor.surface)
                    .shadow(
                        color: iconColor.opacity(isPressed ? 0.05 : 0.12),
                        radius: isPressed ? 4 : 12,
                        x: 0,
                        y: isPressed ? 2 : 6
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                    .strokeBorder(iconColor.opacity(0.18), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
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
