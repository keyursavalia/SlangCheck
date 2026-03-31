// Features/Crossword/CrosswordView.swift
// SlangCheck
//
// Root view for the daily crossword feature. Hosts the grid, clue bar,
// keyboard input layer, and submit / completion states.

import SwiftUI

// MARK: - CrosswordView

/// The main view for the daily crossword puzzle.
///
/// Owns `CrosswordViewModel` via `@State`. All child views receive the
/// ViewModel by reference (value semantics with `@Observable`).
struct CrosswordView: View {

    // MARK: - Environment

    @Environment(\.appEnvironment) private var env

    // MARK: - State

    @State private var viewModel: CrosswordViewModel?
    @State private var keyboardInput: String = ""
    @State private var showCancelAlert = false
    @FocusState private var isKeyboardActive: Bool

    /// Callback invoked when the crossword session ends (submit or cancel).
    /// The parent uses this to dismiss the fullScreenCover.
    var onSessionEnd: (() -> Void)?

    // MARK: - Body

    var body: some View {
        // No NavigationStack here — CrosswordView is pushed inside QuizzesView's
        // NavigationStack via .navigationDestination(isPresented:). A nested stack
        // would prevent the swipe-back gesture and produce a double navigation bar.
        Group {
            if let vm = viewModel {
                switch vm.phase {
                case .loading, .submitting:
                    loadingView
                case .error(let msg):
                    errorView(msg)
                case .active:
                    puzzleActiveView(vm: vm)
                case .completed(let result):
                    CrosswordCompletionView(result: result, viewModel: vm, onSessionEnd: onSessionEnd)
                }
            } else {
                loadingView
            }
        }
        .navigationTitle(String(localized: "crossword.title", defaultValue: "Daily Crossword"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(viewModel?.phase == .active)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                switch viewModel?.phase {
                case .active:
                    Button {
                        showCancelAlert = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(SlangColor.primary)
                    }
                    .buttonStyle(.plain)
                case .completed:
                    Button {
                        onSessionEnd?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(SlangColor.primary)
                    }
                    .buttonStyle(.plain)
                case .error:
                    Button {
                        onSessionEnd?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(SlangColor.primary)
                    }
                    .buttonStyle(.plain)
                default:
                    EmptyView()
                }
            }
        }
        .alert(
            String(localized: "crossword.cancel.title", defaultValue: "Cancel Crossword?"),
            isPresented: $showCancelAlert
        ) {
            Button(String(localized: "crossword.cancel.confirm", defaultValue: "Cancel Crossword"),
                   role: .destructive) {
                viewModel?.cancelPuzzle()
                onSessionEnd?()
            }
            Button(String(localized: "crossword.cancel.keep", defaultValue: "Keep Playing"),
                   role: .cancel) { }
        } message: {
            Text(String(localized: "crossword.cancel.message",
                        defaultValue: "You won't be able to attempt today's crossword again and will not earn any Aura points."))
        }
        .background(SlangColor.background.ignoresSafeArea())
        .task {
            let vm = makeViewModel()
            viewModel = vm
            await vm.loadPuzzle()
            await vm.loadProfile()
        }
    }

    // MARK: - Active Puzzle Layout

    private func puzzleActiveView(vm: CrosswordViewModel) -> some View {
        ZStack {
            ScrollView {
                VStack(spacing: SlangSpacing.md) {
                    if let puzzle = vm.puzzle {
                        // Clue bar + expandable list — shown above the grid so the
                        // user reads the clue before looking at the letter cells.
                        CrosswordClueView(puzzle: puzzle, viewModel: vm)
                            .padding(.horizontal, SlangSpacing.md)

                        // Grid
                        CrosswordGridView(puzzle: puzzle, viewModel: vm)
                            .padding(.horizontal, SlangSpacing.md)

                        // Action row: Reveal (with credits) + Submit
                        actionRow(vm: vm)
                            .padding(.horizontal, SlangSpacing.md)
                    }
                }
                .padding(.vertical, SlangSpacing.md)
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.deselectCell()
                }
            }
            // Swipe-down on the scroll view dismisses the keyboard interactively.
            .scrollDismissesKeyboard(.interactively)

            // Hidden TextField that drives the system keyboard.
            // Focused whenever a cell is selected. Starts with a sentinel
            // space so iOS can detect backspace key presses.
            TextField("", text: $keyboardInput)
                .frame(width: 0, height: 0)
                .opacity(0)
                .focused($isKeyboardActive)
                .onChange(of: vm.selectedCellID) { _, newID in
                    isKeyboardActive = (newID != nil)
                    if newID != nil { keyboardInput = " " }
                }
                .onChange(of: keyboardInput) { oldValue, newValue in
                    if newValue.isEmpty {
                        vm.deleteLetter()
                        keyboardInput = " "
                        return
                    }
                    let letters = newValue.filter { $0.isLetter }
                    guard !letters.isEmpty else { return }
                    for ch in letters {
                        vm.enterLetter(String(ch))
                    }
                    keyboardInput = " "
                }
        }
    }

    // MARK: - Action Row

    private func actionRow(vm: CrosswordViewModel) -> some View {
        HStack(spacing: SlangSpacing.md) {
            // Reveal cell button — onboarding-style outlined pill
            Button {
                vm.revealCurrentCell()
            } label: {
                Label(String(localized: "crossword.reveal", defaultValue: "Reveal"),
                      systemImage: "eye")
                    .font(.custom("Montserrat-SemiBold", size: 16))
                    .foregroundStyle(vm.canReveal ? Color(.label) : Color(.label).opacity(0.35))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color(.systemBackground))
                    }
                    .background {
                        if vm.canReveal {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(SlangColor.hardShadow)
                                .offset(y: 4)
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(!vm.canReveal)
            .accessibilityLabel(
                String(localized: "crossword.reveal.accessibility",
                       defaultValue: "Reveal correct letter for selected cell")
            )
            .accessibilityValue("\(vm.revealCreditsRemaining) credits remaining")

            Button {
                isKeyboardActive = false
                vm.submitPuzzle()
            } label: {
                Text(String(localized: "crossword.submit", defaultValue: "Submit"))
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
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "crossword.submit.accessibility",
                                        defaultValue: "Submit your answers"))
        }
    }

    // MARK: - Reveal Credits Indicator

    /// Five dots showing how many reveal credits remain.
    /// Filled dots = remaining credits; empty dots = used.
    private func revealCreditsIndicator(remaining: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<CrosswordConstants.revealCreditCount, id: \.self) { index in
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundStyle(index < remaining ? SlangColor.accent : SlangColor.separator)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: SlangSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(SlangColor.primary)
            Text(String(localized: "crossword.loading", defaultValue: "Loading today's puzzle…"))
                .font(.slang(.body))
                .foregroundStyle(SlangColor.labelSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: SlangSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(SlangColor.accent)
            Text(message)
                .font(.slang(.body))
                .foregroundStyle(SlangColor.labelSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.xl)

            if !CrosswordViewModel.hasAttemptedToday() {
                Button {
                    Task { await viewModel?.loadPuzzle() }
                } label: {
                    Text(String(localized: "crossword.retry", defaultValue: "Try Again"))
                        .font(.slang(.label))
                        .foregroundStyle(.white)
                        .padding(.horizontal, SlangSpacing.xl)
                        .padding(.vertical, SlangSpacing.md)
                        .background(RoundedRectangle(cornerRadius: SlangCornerRadius.button).fill(SlangColor.primary))
                }
            } else {
                Button {
                    onSessionEnd?()
                } label: {
                    Text(String(localized: "crossword.backToGames", defaultValue: "Back to Games"))
                        .font(.slang(.label))
                        .foregroundStyle(.white)
                        .padding(.horizontal, SlangSpacing.xl)
                        .padding(.vertical, SlangSpacing.md)
                        .background(RoundedRectangle(cornerRadius: SlangCornerRadius.button).fill(SlangColor.primary))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - ViewModel Factory

    private func makeViewModel() -> CrosswordViewModel {
        CrosswordViewModel(
            crosswordRepository: env.crosswordRepository,
            answerKeyService:    CryptoKitAnswerKeyService(),
            auraRepository:      env.auraRepository,
            syncUseCase:         env.syncAuraProfileUseCase,
            notificationService: LocalCrosswordNotificationService(),
            hapticService:       env.hapticService
        )
    }
}

// MARK: - Preview

#Preview("CrosswordView") {
    NavigationStack {
        CrosswordView()
    }
    .environment(\.appEnvironment, .preview())
}
