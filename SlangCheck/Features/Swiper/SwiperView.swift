// Features/Swiper/SwiperView.swift
// SlangCheck
//
// Neon Tokyo-themed swiper. NavigationStack with "Learn" title.
// Two-button bottom row: SKIP (×) and SAVE (✓) with dynamic glow on drag.
// Buttons only glow when the user drags in their respective direction.
// Per FR-S-001 through FR-S-009. Pure SwiftUI gesture implementation.

import SwiftUI

// MARK: - SwiperView

struct SwiperView: View {

    @Environment(\.appEnvironment) private var env
    @State private var viewModel: SwiperViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    SwiperContentView(viewModel: viewModel)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(SlangColor.background.ignoresSafeArea())
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(SlangColor.accent)
                        Text(String(localized: "swiper.title.full", defaultValue: "Learn GenZ Lingo").uppercased())
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .tracking(2.5)
                            .foregroundStyle(.primary)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(SlangColor.accent)
                    }
                }
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
    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            SlangColor.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView().tint(SlangColor.secondary)
            } else if viewModel.isQueueEmpty {
                emptyQueueState
            } else {
                VStack(spacing: 0) {
                    Spacer(minLength: SlangSpacing.md)

                    cardStack
                        .padding(.horizontal, SlangSpacing.xl)

                    Spacer(minLength: SlangSpacing.md)

                    swipeHint
                        .padding(.bottom, SlangSpacing.lg)
                }
            }

        }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        let cardHeight = min(520, UIScreen.main.bounds.height * 0.58)

        return ZStack {
            ForEach(
                Array(viewModel.cardQueue.prefix(2).enumerated().reversed()),
                id: \.element.id
            ) { index, term in
                let isTop = index == 0
                SlangCardView(
                    term: term,
                    isFlipped: isTop ? viewModel.isCardFlipped : false,
                    dragOffset: isTop ? dragOffset : .zero,
                    isTopCard: isTop
                )
                .frame(maxWidth: .infinity)
                .frame(height: cardHeight)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isTop { viewModel.flipCard() }
                }
                .gesture(isTop ? swipeGesture : nil)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel(for: term, isFlipped: isTop && viewModel.isCardFlipped))
                .accessibilityAction(
                    named: String(localized: "swiper.accessibility.save", defaultValue: "Save term")
                ) { viewModel.swipeRight() }
                .accessibilityAction(
                    named: String(localized: "swiper.accessibility.skip", defaultValue: "Skip term")
                ) { viewModel.swipeLeft() }
                .accessibilityAction(
                    named: String(localized: "swiper.accessibility.flip", defaultValue: "Flip card")
                ) { viewModel.flipCard() }
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
                // Under threshold → card snaps back via GestureState reset
            }
    }

    // MARK: - Swipe Hint

    /// Subtle instruction nudge sitting between the card stack and the tab bar.
    private var swipeHint: some View {
        HStack(spacing: SlangSpacing.sm) {
            Image(systemName: "arrow.left")
                .font(.system(size: 11, weight: .medium))
                .accessibilityHidden(true)
            Text(String(localized: "swiper.hint.swipe", defaultValue: "swipe to skip or save"))
                .font(.system(size: 12, design: .monospaced))
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .medium))
                .accessibilityHidden(true)
        }
        .foregroundStyle(Color(.tertiaryLabel))
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
            return String(
                format: String(
                    localized: "swiper.accessibility.card %@",
                    defaultValue: "Flashcard: %@. Double tap to reveal definition."
                ),
                term.term
            )
        }
    }
}

// MARK: - Preview

#Preview("SwiperView") {
    SwiperView()
        .environment(\.appEnvironment, .preview())
}
