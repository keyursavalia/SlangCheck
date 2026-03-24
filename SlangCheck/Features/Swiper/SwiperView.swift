// Features/Swiper/SwiperView.swift
// SlangCheck
//
// Full-screen term layout — term + definition always visible, no tap-to-flip.
// Swipe up to advance to the next term. Save button at bottom.
// The 3D flip card design is preserved (commented out) in SlangCardView.swift.

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
    /// Live vertical drag offset from the gesture — resets on release.
    @GestureState private var dragY: CGFloat = 0

    /// 0→1 as the user drags 160pt upward; drives next-term preview opacity/position.
    private var swipeProgress: Double {
        min(1.0, max(0, -dragY / 160))
    }

    var body: some View {
        ZStack {
            SlangColor.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView().tint(SlangColor.secondary)
            } else if viewModel.isQueueEmpty {
                emptyQueueState
            } else {
                termStack
            }
        }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: - Term Stack

    /// Two layers: current term (draggable) + next term fading up from behind.
    private var termStack: some View {
        ZStack {
            // Next term — fades and rises into view as swipe progresses
            if viewModel.cardQueue.count > 1 {
                termView(viewModel.cardQueue[1])
                    .opacity(swipeProgress * 0.95)
                    .offset(y: 48 * (1.0 - swipeProgress))
                    .allowsHitTesting(false)
            }

            // Current term — follows the drag upward
            termView(viewModel.cardQueue[0])
                .offset(y: dragY < 0 ? dragY : dragY * 0.12)
                .opacity(1.0 - swipeProgress * 0.70)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20)
                .updating($dragY) { value, state, _ in
                    state = value.translation.height
                }
                .onEnded { value in
                    if value.translation.height < -AppConstants.swiperSwipeThreshold {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                            viewModel.swipeUp()
                        }
                    }
                }
        )
    }

    // MARK: - Term View

    private func termView(_ term: SlangTerm) -> some View {
        VStack(spacing: 0) {

            Spacer()

            // ── Term ──────────────────────────────────────
            Text(term.term.lowercased())
                .font(.slangTerm(size: 52))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.xl)

            // Category pill — sits just below the term like a subtle label
            Text(term.category.displayName.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(SlangColor.accent)
                .padding(.horizontal, SlangSpacing.sm)
                .padding(.vertical, 5)
                .background(Capsule().fill(SlangColor.accent.opacity(0.14)))
                .padding(.top, SlangSpacing.sm)

            Spacer().frame(height: 32)

            // ── Definition ────────────────────────────────
            Text(term.definition)
                .font(.slangDefinition(size: 18))
                .foregroundStyle(.primary.opacity(0.78))
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.xl + SlangSpacing.sm)
                .fixedSize(horizontal: false, vertical: true)

            // ── Example sentence (muted, italic) ──────────
            if !term.exampleSentence.isEmpty {
                Text("\u{201C}\(term.exampleSentence)\u{201D}")
                    .font(.slangDefinition(size: 14))
                    .foregroundStyle(.primary.opacity(0.38))
                    .multilineTextAlignment(.center)
                    .italic()
                    .padding(.horizontal, SlangSpacing.xl + SlangSpacing.md)
                    .padding(.top, SlangSpacing.sm)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // ── Bottom action row ─────────────────────────
            saveButton(term: term)
                .padding(.bottom, SlangSpacing.sm)

            // ── Swipe hint ────────────────────────────────
            swipeHint
                .padding(.bottom, SlangSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(term.term). \(term.definition)")
        .accessibilityAction(named: String(localized: "swiper.accessibility.next", defaultValue: "Next card")) {
            viewModel.swipeUp()
        }
        .accessibilityAction(named: String(localized: "swiper.accessibility.save", defaultValue: "Save term")) {
            viewModel.saveCurrentCard()
        }
    }

    // MARK: - Action Buttons

    private func saveButton(term: SlangTerm) -> some View {
        HStack(spacing: SlangSpacing.xl) {
            // Info — placeholder; detail view coming later
            Button { } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color(.label).opacity(0.40))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Term info")

            // Save to Lexicon
            Button {
                viewModel.saveCurrentCard()
            } label: {
                Image(systemName: viewModel.isTopCardSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(
                        viewModel.isTopCardSaved ? SlangColor.primary : Color(.label).opacity(0.40)
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isTopCardSaved)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isTopCardSaved)
            .accessibilityLabel(
                viewModel.isTopCardSaved
                    ? String(localized: "swiper.save.saved", defaultValue: "Saved")
                    : String(localized: "swiper.save.button.accessibility",
                             defaultValue: "Save this term to your Lexicon")
            )

            // Share — placeholder; share sheet coming later
            Button { } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color(.label).opacity(0.40))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share term")
        }
    }

    // MARK: - Swipe Hint

    private var swipeHint: some View {
        Text(String(localized: "swiper.hint.swipe", defaultValue: "swipe up for next"))
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(Color(.tertiaryLabel))
    }

    // MARK: - Empty Queue State

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
}

// MARK: - Preview

#Preview("SwiperView") {
    SwiperView()
        .environment(\.appEnvironment, .preview())
}
