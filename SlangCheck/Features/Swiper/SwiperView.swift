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
    /// Persisted swipe count — swipe hint hides permanently after 3 swipes.
    @AppStorage("swiperSwipeCount") private var swiperSwipeCount: Int = 0

    /// 0→1 as the user drags 160pt upward; drives next-term preview opacity/position.
    private var swipeProgress: Double {
        min(1.0, max(0, -dragY / 160))
    }

    /// True until the user has swiped 3 times — then permanently false.
    private var showSwipeHint: Bool { swiperSwipeCount < 3 }

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
                        // Track swipes so the hint auto-hides after 3
                        if swiperSwipeCount < 10 { swiperSwipeCount += 1 }
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                            viewModel.swipeUp()
                        }
                    }
                }
        )
    }

    // MARK: - Term View

    private func termView(_ term: SlangTerm) -> some View {
        let (posTag, cleanDefinition) = extractPOS(term.definition)

        return VStack(spacing: 0) {

            // Fixed top anchor — every term starts at the same Y regardless of length
            Spacer().frame(height: 100)

            // ── Term ──────────────────────────────────────
            Text(term.term.lowercased())
                .font(.slangTerm(size: 52))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.xl)

            // ── Definition with inline bold POS tag ────────
            // "(adj.) Some text" — the abbreviation is bold, rest is regular weight.
            definitionText(posTag: posTag, definition: cleanDefinition)
                .font(.slangDefinition(size: 22))
                .foregroundStyle(.primary.opacity(0.82))
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.xl)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, SlangSpacing.xl)

            // ── Example sentence ──────────────────────────
            if !term.exampleSentence.isEmpty {
                Text("\u{201C}\(term.exampleSentence)\u{201D}")
                    .font(.slangDefinition(size: 18))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary.opacity(0.42))
                    .multilineTextAlignment(.center)
                    .italic()
                    .padding(.horizontal, SlangSpacing.xl + SlangSpacing.md)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, SlangSpacing.lg)
            }

            Spacer()

            // ── Bottom action row ─────────────────────────
            actionButtons(term: term)
                .padding(.bottom, SlangSpacing.sm)

            // ── Swipe hint — fades permanently after 3 swipes ─
            swipeHintView
                .padding(.bottom, SlangSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(term.term). \(cleanDefinition)")
        .accessibilityAction(named: String(localized: "swiper.accessibility.next",
                                          defaultValue: "Next card")) {
            viewModel.swipeUp()
        }
        .accessibilityAction(named: String(localized: "swiper.accessibility.save",
                                          defaultValue: "Save term")) {
            viewModel.saveCurrentCard()
        }
    }

    // MARK: - POS Helpers

    /// Splits `"(adj.) Some definition"` into `("adj.", "Some definition")`.
    /// Returns `(nil, original)` if no POS prefix is present.
    private func extractPOS(_ definition: String) -> (String?, String) {
        guard definition.hasPrefix("("),
              let endIdx = definition.firstIndex(of: ")") else {
            return (nil, definition)
        }
        let tag = String(definition[definition.index(after: definition.startIndex)..<endIdx])
        let rest = String(definition[definition.index(after: endIdx)...])
            .trimmingCharacters(in: .whitespaces)
        return (tag, rest)
    }

    /// Builds an inline `Text` where the POS abbreviation is bold and the
    /// definition body follows in regular weight: **(adj.)** Some text…
    private func definitionText(posTag: String?, definition: String) -> Text {
        guard let tag = posTag else {
            return Text(definition)
        }
        return Text("(\(tag)) ").bold() + Text(definition)
    }

    // MARK: - Action Buttons

    private func actionButtons(term: SlangTerm) -> some View {
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

    /// Reserves layout space even when invisible so the action bar never shifts.
    private var swipeHintView: some View {
        Text(String(localized: "swiper.hint.swipe", defaultValue: "swipe up for next"))
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(Color(.tertiaryLabel))
            .opacity(showSwipeHint ? 1 : 0)
            .animation(.easeOut(duration: 0.6), value: showSwipeHint)
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
