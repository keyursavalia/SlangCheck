// Features/Swiper/SwiperView.swift
// SlangCheck
//
// Main learning view. No tab bar — navigation is provided by the inline chrome:
//   Top:    profile avatar (left) · session progress (center) · crown (right)
//   Bottom: glossary grid (left) · Practice capsule (center) · stats chart (right)

import SwiftUI
import UIKit

// MARK: - SwiperView

struct SwiperView: View {

    @Environment(\.appEnvironment) private var env
    @Environment(AuthState.self) private var authState
    @State private var viewModel: SwiperViewModel?
    @State private var showProfile  = false
    // @State private var showPractice = false  // practice removed for now
    // @State private var showGlossary = false  // glossary grid removed — accessible via Profile

    var body: some View {
        ZStack {
            SlangColor.background.ignoresSafeArea()

            if let vm = viewModel {
                SwiperContentView(viewModel: vm)
            } else {
                ProgressView()
                    .tint(SlangColor.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // safeAreaInset pushes the swiper content inward so cards never hide behind chrome.
        .safeAreaInset(edge: .top, spacing: 0) { topChrome }
        // .safeAreaInset(edge: .bottom, spacing: 0) { bottomChrome }  // bottom chrome removed
        .task {
            guard viewModel == nil else { return }
            let vm = SwiperViewModel(
                repository: env.slangTermRepository,
                hapticService: env.hapticService
            )
            viewModel = vm
            vm.onAppear()
        }
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView()
        }
        // .sheet(isPresented: $showPractice) { QuizzesView() }  // practice removed for now
        // .fullScreenCover(isPresented: $showGlossary) { NavigationStack { GlossaryView() } }  // removed
    }

    // MARK: - Top Chrome

    private var topChrome: some View {
        HStack(spacing: 0) {
            // Profile avatar — taps open ProfileView sheet
            Button { showProfile = true } label: {
                profileAvatar
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "swiper.chrome.profile",
                                       defaultValue: "Open profile"))

            Spacer()

            sessionProgress

            Spacer()

            // Crown removed for now
            // Button { } label: {
            //     Image(systemName: "crown")
            //         .font(.system(size: 24, weight: .light))
            //         .foregroundStyle(Color(.label).opacity(0.40))
            //         .frame(width: 44, height: 44)
            // }
            // .buttonStyle(.plain)
            // .accessibilityLabel(String(localized: "swiper.chrome.achievements",
            //                            defaultValue: "Achievements"))
        }
        .padding(.horizontal, SlangSpacing.md)
        .padding(.vertical, SlangSpacing.xs)
        .background(SlangColor.background)
    }

    // MARK: - Bottom Chrome (removed — all navigation now via Profile sheet)
    //
    // private var bottomChrome: some View {
    //     HStack(spacing: 0) {
    //         // Glossary grid button removed
    //         // Button { showGlossary = true } label: { Image(systemName: "square.grid.2x2") ... }
    //
    //         Spacer()
    //
    //         // Practice button removed
    //         // Button { showPractice = true } label: { ... "Practice" ... }
    //
    //         Spacer()
    //
    //         // Stats button removed
    //         // Button { } label: { Image(systemName: "chart.bar") ... }
    //     }
    //     .padding(.horizontal, SlangSpacing.md)
    //     .padding(.bottom, SlangSpacing.sm)
    //     .background(SlangColor.background)
    // }

    // MARK: - Profile Avatar

    @ViewBuilder
    private var profileAvatar: some View {
        if let url = authState.currentProfile?.photoURL {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Color(.label).opacity(0.15), lineWidth: 1))
                } else {
                    avatarFallbackIcon
                }
            }
        } else {
            avatarFallbackIcon
        }
    }

    private var avatarFallbackIcon: some View {
        Image(systemName: "person.circle")
            .font(.system(size: 26, weight: .light))
            .foregroundStyle(Color(.label).opacity(0.40))
    }

    // MARK: - Session Progress

    private var sessionProgress: some View {
        let swiped = viewModel?.historyStack.count ?? 0
        let total  = viewModel?.totalTermCount ?? 0
        let ratio  = total > 0 ? Double(swiped) / Double(total) : 0.0

        return HStack(spacing: SlangSpacing.sm) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(.primary.opacity(0.35))
                .accessibilityHidden(true)

            Text("\(swiped)/\(total)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.55))
                .monospacedDigit()

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(SlangColor.primary.opacity(0.15))
                    .frame(width: 72, height: 3)
                RoundedRectangle(cornerRadius: 2)
                    .fill(SlangColor.primary.opacity(0.60))
                    .frame(width: max(0, 72 * ratio), height: 3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: ratio)
            }
            .accessibilityLabel(String(format: "%d of %d words reviewed", swiped, total))
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

    /// Pure offset-based vertical card stack — no opacity changes, no fading.
    ///
    /// Cards behave like a physical vertical scroll:
    ///   • The previous card parks exactly one viewport-height above the current card.
    ///   • The next card parks exactly one viewport-height below the current card.
    ///   • Dragging translates all cards together so adjacent cards slide in/out in sync.
    ///   • No opacity is altered — the transition is purely positional.
    ///
    /// GeometryReader measures the available height so the exit/entry distance is always
    /// exactly one screen's worth, making the animation feel physically grounded.
    private var termStack: some View {
        GeometryReader { geo in
            let height = geo.size.height

            ZStack {
                // Previous card — parked one full height above; slides down with drag.
                if viewModel.canGoBack, let previous = viewModel.historyStack.last {
                    termView(previous)
                        .offset(y: dragY > 0 ? -height + dragY : -height)
                        .allowsHitTesting(false)
                }

                // Next card — parked one full height below; slides up with drag.
                if viewModel.cardQueue.count > 1 {
                    termView(viewModel.cardQueue[1])
                        .offset(y: dragY < 0 ? height + dragY : height)
                        .allowsHitTesting(false)
                }

                // Current card — tracks the drag directly.
                // Slight resistance (×0.15) when dragging down and there's no history.
                termView(viewModel.cardQueue[0])
                    .offset(y: dragY > 0 && !viewModel.canGoBack
                            ? dragY * 0.15
                            : dragY)
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
                                dragY = -height
                            } completion: {
                                if swiperSwipeCount < 10 { swiperSwipeCount += 1 }
                                viewModel.swipeUp()
                                dragY = 0
                            }
                        } else if dy > AppConstants.swiperSwipeThreshold, viewModel.canGoBack {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                dragY = height
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

            // Like — toggles the term in the user's favorites
            Button {
                viewModel.toggleFavoriteCurrentCard()
            } label: {
                Image(systemName: viewModel.isTopCardLiked ? "heart.fill" : "heart")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(
                        viewModel.isTopCardLiked ? Color.red.opacity(0.75) : Color(.label).opacity(0.40)
                    )
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isTopCardLiked)
            .accessibilityLabel(
                viewModel.isTopCardLiked
                    ? String(localized: "swiper.like.liked", defaultValue: "Unlike this term")
                    : String(localized: "swiper.like.button.accessibility",
                             defaultValue: "Like this term")
            )

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
        .environment(AuthState(
            authService: NoOpAuthenticationService(),
            profileRepository: NoOpUserProfileRepository()
        ))
}
