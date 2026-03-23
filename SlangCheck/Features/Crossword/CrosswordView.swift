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
    @FocusState private var isKeyboardActive: Bool

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
                    CrosswordCompletionView(result: result, viewModel: vm)
                }
            } else {
                loadingView
            }
        }
        .navigationTitle(String(localized: "crossword.title", defaultValue: "Daily Crossword"))
        .navigationBarTitleDisplayMode(.inline)
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
                // Bottom padding so content isn't hidden under keyboard
                .padding(.bottom, 320)
                // Tapping empty/blocked space outside the grid dismisses the keyboard.
                // Child views (grid cells, buttons) handle their own taps with higher priority.
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.deselectCell()
                }
            }
            // Swipe-down on the scroll view dismisses the keyboard interactively.
            .scrollDismissesKeyboard(.interactively)

            // Hidden TextField that drives the system keyboard.
            // Focused whenever a cell is selected.
            TextField("", text: $keyboardInput)
                .frame(width: 0, height: 0)
                .opacity(0)
                .focused($isKeyboardActive)
                // Dismiss keyboard when no cell is selected.
                .onChange(of: vm.selectedCellID) { _, newID in
                    isKeyboardActive = (newID != nil)
                }
                // Route each typed character to the ViewModel.
                .onChange(of: keyboardInput) { _, newValue in
                    guard !newValue.isEmpty else { return }
                    for ch in newValue where ch.isLetter {
                        vm.enterLetter(String(ch))
                    }
                    keyboardInput = ""
                }
        }
        // Delete key via toolbar
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    vm.deleteLetter()
                } label: {
                    Image(systemName: "delete.backward")
                }
                .accessibilityLabel(String(localized: "crossword.key.delete", defaultValue: "Delete letter"))

                Spacer()

                // Reveal button in keyboard toolbar — disabled when no credits remain
                // or the selected cell is already revealed.
                Button {
                    vm.revealCurrentCell()
                } label: {
                    HStack(spacing: 4) {
                        Text(String(localized: "crossword.key.reveal", defaultValue: "Reveal"))
                            .font(.slang(.label))
                        Text("(\(vm.revealCreditsRemaining))")
                            .font(.slang(.caption))
                    }
                    .foregroundStyle(vm.canReveal ? SlangColor.accent : SlangColor.labelSecondary)
                }
                .disabled(!vm.canReveal)
                .accessibilityLabel(
                    String(localized: "crossword.key.reveal.accessibility",
                           defaultValue: "Reveal the correct letter for the selected cell")
                )
            }
        }
    }

    // MARK: - Action Row

    private func actionRow(vm: CrosswordViewModel) -> some View {
        HStack(spacing: SlangSpacing.md) {
            // Reveal cell button — remaining credits shown in the keyboard toolbar.
            Button {
                vm.revealCurrentCell()
            } label: {
                Label(String(localized: "crossword.reveal", defaultValue: "Reveal"),
                      systemImage: "eye")
                    .font(.slang(.label))
                    .foregroundStyle(vm.canReveal ? SlangColor.accent : SlangColor.labelSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SlangSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: SlangCornerRadius.button)
                            .strokeBorder(
                                vm.canReveal ? SlangColor.accent : SlangColor.separator,
                                lineWidth: 1
                            )
                    )
            }
            .disabled(!vm.canReveal)
            .accessibilityLabel(
                String(localized: "crossword.reveal.accessibility",
                       defaultValue: "Reveal correct letter for selected cell")
            )
            .accessibilityValue("\(vm.revealCreditsRemaining) credits remaining")

            // Submit button (primary action)
            Button {
                isKeyboardActive = false
                vm.submitPuzzle()
            } label: {
                Text(String(localized: "crossword.submit", defaultValue: "Submit"))
                    .font(.slang(.label))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SlangSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: SlangCornerRadius.button)
                            .fill(vm.canSubmit ? SlangColor.primary : SlangColor.separator)
                    )
            }
            .disabled(!vm.canSubmit)
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
