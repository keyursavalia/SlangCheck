// Features/Swiper/SwiperView.swift
// SlangCheck
//
// Full-screen term layout — term + definition always visible, no tap-to-flip.
// Swipe up to advance, swipe down to revisit the previous term.

import SwiftUI
import UIKit

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
    /// Live vertical drag offset from the gesture. Using @State (not @GestureState) so we
    /// can control exactly when and how it resets — preventing the flicker caused by
    /// @GestureState's implicit reset racing against the withAnimation model update.
    @State private var dragY: CGFloat = 0
    /// Persisted swipe count — swipe hint hides permanently after 3 swipes.
    @AppStorage("swiperSwipeCount") private var swiperSwipeCount: Int = 0
    /// Term whose info sheet is currently open; nil when the sheet is dismissed.
    @State private var infoTerm: SlangTerm? = nil

    /// 0→1 as the user drags 160pt upward; drives next-term preview opacity/position.
    private var swipeProgress: Double {
        min(1.0, max(0, -dragY / 160))
    }

    /// 0→1 as the user drags 160pt downward; drives previous-term preview from above.
    private var swipeDownProgress: Double {
        min(1.0, max(0, dragY / 160))
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
        .sheet(item: $infoTerm) { term in
            TermInfoSheet(term: term)
        }
    }

    // MARK: - Term Stack

    /// Three layers: previous term (above), current term (draggable), next term (below).
    ///
    /// Preview cards are always kept in the view hierarchy (no conditional insertion) to
    /// prevent SwiftUI from triggering its default fade transition when they cross zero.
    /// The model (swipeUp/swipeDown) is updated inside the withAnimation completion handler,
    /// so it fires only AFTER the exit animation finishes. dragY then resets to 0 without
    /// animation, giving the new card a clean snap into place with no cross-fade conflict.
    private var termStack: some View {
        ZStack {
            // Previous term — always in hierarchy; visible only while swiping down
            if viewModel.canGoBack, let previous = viewModel.historyStack.last {
                termView(previous)
                    .opacity(swipeDownProgress * 0.95)
                    .offset(y: -48 * (1.0 - swipeDownProgress))
                    .allowsHitTesting(false)
            }

            // Next term — always in hierarchy; visible only while swiping up
            if viewModel.cardQueue.count > 1 {
                termView(viewModel.cardQueue[1])
                    .opacity(swipeProgress * 0.95)
                    .offset(y: 48 * (1.0 - swipeProgress))
                    .allowsHitTesting(false)
            }

            // Current term — follows the drag in either direction
            termView(viewModel.cardQueue[0])
                .offset(y: dragY < 0 ? dragY : dragY * 0.12)
                .opacity(dragY < 0
                         ? 1.0 - swipeProgress * 0.70
                         : 1.0 - swipeDownProgress * 0.70)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    dragY = value.translation.height
                }
                .onEnded { value in
                    let dy = value.translation.height
                    if dy < -AppConstants.swiperSwipeThreshold {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            dragY = -1000
                        } completion: {
                            if swiperSwipeCount < 10 { swiperSwipeCount += 1 }
                            viewModel.swipeUp()
                            dragY = 0
                        }
                    } else if dy > AppConstants.swiperSwipeThreshold, viewModel.canGoBack {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            dragY = 1000
                        } completion: {
                            viewModel.swipeDown()
                            dragY = 0
                        }
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            dragY = 0
                        }
                    }
                }
        )
    }

    // MARK: - Term View

    private func termView(_ term: SlangTerm) -> some View {
        let (posTag, cleanDefinition) = extractPOS(term.definition)

        return VStack(spacing: 0) {

            // Equal top spacer — centers the content block vertically
            Spacer()

            // ── Term ──────────────────────────────────────
            Text(term.term.lowercased())
                .font(.slangTerm(size: 52))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.xl)

            // ── Definition with inline bold POS tag ────────
            // "(adj.) Some text" — the abbreviation is bold, rest is regular weight.
            definitionText(posTag: posTag, definition: cleanDefinition)
                .font(.slangDefinition(size: 24))
                .foregroundStyle(.primary.opacity(0.82))
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.xl)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, SlangSpacing.xl)

            // ── Example sentence ──────────────────────────
            if !term.exampleSentence.isEmpty {
                Text("\u{201C}\(term.exampleSentence)\u{201D}")
                    .font(.slangDefinition(size: 20))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .italic()
                    .padding(.horizontal, SlangSpacing.xl + SlangSpacing.md)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, SlangSpacing.lg)
            }

            // Equal bottom spacer — mirrors the top spacer to vertically center content
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
            // Info — opens the term detail bottom sheet
            Button {
                infoTerm = term
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color(.label).opacity(0.40))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "swiper.info.accessibility", defaultValue: "Term info"))

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

            // Share — renders a share card image and presents the iOS share sheet
            Button {
                SlangShareCard.share(term: term)
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color(.label).opacity(0.40))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "swiper.share.accessibility", defaultValue: "Share term"))
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
        VStack(spacing: SlangSpacing.lg) {
            Text("💀")
                .font(.system(size: 72))

            VStack(spacing: SlangSpacing.sm) {
                Text(String(localized: "swiper.empty.title", defaultValue: "stack cleared."))
                    .font(.slangTerm(size: 38))
                    .foregroundStyle(.primary)

                Text(String(localized: "swiper.empty.message",
                            defaultValue: "you've seen every banger in the deck.\nlowkey impressive fr fr 🤌"))
                    .font(.slangDefinition(size: 18))
                    .foregroundStyle(.primary.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SlangSpacing.xl)
            }

            Button {
                viewModel.reshuffleAll()
            } label: {
                Text(String(localized: "swiper.empty.reshuffle", defaultValue: "run it back"))
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(SlangColor.background)
                    .padding(.horizontal, SlangSpacing.xl)
                    .padding(.vertical, SlangSpacing.md)
                    .background(SlangColor.primary,
                                in: RoundedRectangle(cornerRadius: SlangCornerRadius.button))
            }
            .padding(.top, SlangSpacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SlangColor.background.ignoresSafeArea())
    }
}

// MARK: - Preview

#Preview("SwiperView") {
    SwiperView()
        .environment(\.appEnvironment, .preview())
}
