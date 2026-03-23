// Features/Swiper/SwiperView.swift
// SlangCheck
//
// Chill & Cozy swiper. NavigationStack with "Learn" title.
// Single gesture: swipe up to advance. Tap to flip. Save button below card.
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
                        Text(String(localized: "swiper.title.full", defaultValue: "Learn GenZ Lingo").uppercased())
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .tracking(2.5)
                            .foregroundStyle(.primary)
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

                    saveButton
                        .padding(.bottom, SlangSpacing.sm)

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
                    named: String(localized: "swiper.accessibility.next", defaultValue: "Next card")
                ) { viewModel.swipeUp() }
                .accessibilityAction(
                    named: String(localized: "swiper.accessibility.save", defaultValue: "Save term")
                ) { viewModel.saveCurrentCard() }
                .accessibilityAction(
                    named: String(localized: "swiper.accessibility.flip", defaultValue: "Flip card")
                ) { viewModel.flipCard() }
            }
        }
    }

    // MARK: - Swipe Gesture (upward only)

    private var swipeGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                if value.translation.height < -AppConstants.swiperSwipeThreshold {
                    viewModel.swipeUp()
                }
                // Under threshold or downward drag → card snaps back via GestureState reset
            }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            viewModel.saveCurrentCard()
        } label: {
            HStack(spacing: SlangSpacing.sm) {
                Image(systemName: viewModel.isTopCardSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 15, weight: .semibold))
                Text(viewModel.isTopCardSaved
                     ? String(localized: "swiper.save.saved", defaultValue: "Saved")
                     : String(localized: "swiper.save.button", defaultValue: "Save"))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
            }
            .foregroundStyle(
                viewModel.isTopCardSaved ? SlangColor.primary : SlangColor.secondary
            )
            .padding(.horizontal, SlangSpacing.lg)
            .padding(.vertical, SlangSpacing.sm)
            .background(
                Capsule().fill(
                    viewModel.isTopCardSaved
                        ? SlangColor.primary.opacity(0.12)
                        : SlangColor.secondary.opacity(0.12)
                )
            )
        }
        .disabled(viewModel.isTopCardSaved)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isTopCardSaved)
        .accessibilityLabel(
            viewModel.isTopCardSaved
                ? String(localized: "swiper.save.saved", defaultValue: "Saved")
                : String(localized: "swiper.save.button.accessibility", defaultValue: "Save this term to your Lexicon")
        )
    }

    // MARK: - Swipe Hint

    private var swipeHint: some View {
        HStack(spacing: SlangSpacing.xs) {
            Image(systemName: "arrow.up")
                .font(.system(size: 11, weight: .medium))
                .accessibilityHidden(true)
            Text(String(localized: "swiper.hint.swipe", defaultValue: "swipe up for next"))
                .font(.system(size: 12, design: .monospaced))
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
