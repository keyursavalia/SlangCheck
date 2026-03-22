// Features/Swiper/SwiperView.swift
// SlangCheck
//
// The Swiper tab screen. Gesture-driven card stack with tap-to-flip,
// right/left swipe to save/dismiss, button alternatives, and undo.
// Per FR-S-001 through FR-S-009. Pure SwiftUI gesture implementation.

import SwiftUI

// MARK: - SwiperView

struct SwiperView: View {

    @Environment(\.appEnvironment) private var env
    @State private var viewModel: SwiperViewModel?

    var body: some View {
        Group {
            if let viewModel {
                SwiperContentView(viewModel: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(SlangColor.background.ignoresSafeArea())
            }
        }
        .task {
            guard viewModel == nil else { return }
            let vm = SwiperViewModel(
                repository: env.slangTermRepository,
                hapticService: env.hapticService
            )
            viewModel = vm
            vm.onAppear()
        }
    }
}

// MARK: - SwiperContentView

private struct SwiperContentView: View {

    @Bindable var viewModel: SwiperViewModel

    /// Current drag offset for the top card.
    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            ZStack {
                SlangColor.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(SlangColor.primary)
                } else if viewModel.isQueueEmpty {
                    emptyQueueState
                } else {
                    VStack(spacing: SlangSpacing.lg) {
                        cardStack
                        controlButtons
                    }
                }

                // Undo button (FR-S-009)
                if viewModel.showUndoButton {
                    VStack {
                        Spacer()
                        undoButton
                            .padding(.bottom, SlangSpacing.xl)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.showUndoButton)
            .navigationTitle(String(localized: "swiper.title", defaultValue: "Learn"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        ZStack {
            // Show up to 2 cards (top + one below for depth effect)
            ForEach(Array(viewModel.cardQueue.prefix(2).enumerated().reversed()), id: \.element.id) { index, term in
                let isTop = index == 0
                SlangCardView(
                    term: term,
                    isFlipped: isTop ? viewModel.isCardFlipped : false,
                    dragOffset: isTop ? dragOffset : .zero,
                    isTopCard: isTop
                )
                .frame(width: UIScreen.main.bounds.width - SlangSpacing.xl * 2,
                       height: 480)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isTop { viewModel.flipCard() }
                }
                .gesture(isTop ? swipeGesture : nil)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel(for: term, isFlipped: isTop && viewModel.isCardFlipped))
                .accessibilityAction(named: String(localized: "swiper.accessibility.save", defaultValue: "Save term")) {
                    viewModel.swipeRight()
                }
                .accessibilityAction(named: String(localized: "swiper.accessibility.skip", defaultValue: "Skip term")) {
                    viewModel.swipeLeft()
                }
                .accessibilityAction(named: String(localized: "swiper.accessibility.flip", defaultValue: "Flip card")) {
                    viewModel.flipCard()
                }
            }
        }
    }

    // MARK: - Swipe Gesture (FR-S-002, FR-S-003, FR-S-005)

    private var swipeGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let threshold = AppConstants.swiperSwipeThreshold
                if value.translation.width > threshold {
                    viewModel.swipeRight()
                } else if value.translation.width < -threshold {
                    viewModel.swipeLeft()
                }
                // If under threshold, card snaps back (dragOffset returns to .zero via GestureState)
            }
    }

    // MARK: - Control Buttons (FR-S-006)

    private var controlButtons: some View {
        HStack(spacing: SlangSpacing.xxl) {
            // Dismiss / Skip button
            CircleActionButton(
                symbolName: "xmark",
                color: SlangColor.accent,
                accessibilityLabel: String(localized: "swiper.button.skip", defaultValue: "Skip")
            ) {
                viewModel.hapticService.swipeButtonTapped()
                viewModel.swipeLeft()
            }

            // Save button
            CircleActionButton(
                symbolName: "checkmark",
                color: SlangColor.secondary,
                accessibilityLabel: String(localized: "swiper.button.save", defaultValue: "Save to Lexicon")
            ) {
                viewModel.hapticService.swipeButtonTapped()
                viewModel.swipeRight()
            }
        }
    }

    // MARK: - Undo Button (FR-S-009)

    private var undoButton: some View {
        Button {
            viewModel.undo()
        } label: {
            HStack(spacing: SlangSpacing.xs) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14, weight: .semibold))
                    .accessibilityHidden(true)
                Text(String(localized: "swiper.undo", defaultValue: "Undo"))
                    .font(.slang(.label))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, SlangSpacing.lg)
            .padding(.vertical, SlangSpacing.sm + 2)
            .background(Capsule().fill(Color(.systemGray)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "swiper.undo", defaultValue: "Undo last swipe"))
    }

    // MARK: - Empty Queue State (FR-S-008)

    private var emptyQueueState: some View {
        EmptyStateView(
            symbolName: "checkmark.circle",
            title: String(localized: "swiper.empty.title", defaultValue: "You've seen them all!"),
            message: String(localized: "swiper.empty.message",
                            defaultValue: "Your slang knowledge is growing. What's next?"),
            actionTitle: String(localized: "swiper.empty.reshuffle",
                                defaultValue: "Reshuffle All Terms"),
            action: { viewModel.reshuffleAll() }
        )
    }

    // MARK: - Accessibility

    private func accessibilityLabel(for term: SlangTerm, isFlipped: Bool) -> String {
        if isFlipped {
            return "\(term.term). \(term.definition)"
        } else {
            return "Flashcard: \(term.term). Double tap to reveal definition."
        }
    }
}

// MARK: - CircleActionButton

private struct CircleActionButton: View {
    let symbolName: String
    let color: Color
    let accessibilityLabel: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
                .frame(width: SlangTapTarget.minimum + 16,
                       height: SlangTapTarget.minimum + 16)
                .background(
                    Circle()
                        .fill(color.opacity(0.12))
                        .overlay(Circle().stroke(color.opacity(0.3), lineWidth: 1.5))
                )
        }
        .buttonStyle(.plain)
        .pressedState(isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Preview

#Preview("SwiperView") {
    SwiperView()
        .environment(\.appEnvironment, .preview())
}
