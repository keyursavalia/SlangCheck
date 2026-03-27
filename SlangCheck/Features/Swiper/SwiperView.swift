// Features/Swiper/SwiperView.swift
// SlangCheck
//
// Main learning view. When filterTermIDs/presentedTitle are set, operates as a
// filtered feed (pushed in a NavigationStack by FavoritesView or CollectionDetailView).

import SwiftUI
import UIKit

// MARK: - SwiperView

struct SwiperView: View {

    @Environment(\.appEnvironment) private var env
    @Environment(AuthState.self) private var authState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var viewModel: SwiperViewModel?
    @State private var showProfile = false
    @State private var showCollectionPicker = false
    @State private var showBrowseByVibe = false
    @State private var showGames = false
    @State private var keyboardHeight: CGFloat = 0

    /// Drives the full-screen filtered feed launched from Browse by Vibe.
    @State private var vibeFeed: VibeFeedSelection? = nil

    /// When non-nil, filters the swiper to these term IDs.
    var filterTermIDs: [UUID]? = nil

    /// When set, shows as a navigation-pushed filtered feed with this nav-bar title.
    var presentedTitle: String? = nil

    /// When set, the queue is rotated so this term is shown first.
    var startAtTermID: UUID? = nil

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

            // Collection picker — centered floating card overlay
            if showCollectionPicker, let vm = viewModel {
                collectionPickerOverlay(vm: vm)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if presentedTitle == nil {
                // Normal mode: full top chrome with embedded toast overlay
                topChrome
            } else {
                // Filtered/pushed mode: toast only (navigation bar provides title + back)
                if let vm = viewModel, let name = vm.saveToastCollectionName {
                    toastPill(collectionName: name)
                        .padding(.horizontal, SlangSpacing.md)
                        .padding(.vertical, SlangSpacing.xs)
                        .background(SlangColor.background)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .navigationTitle(presentedTitle ?? "")
        .navigationBarTitleDisplayMode(presentedTitle != nil ? .inline : .automatic)
        .task {
            guard viewModel == nil else { return }
            let vm = SwiperViewModel(
                repository: env.slangTermRepository,
                hapticService: env.hapticService,
                filterTermIDs: filterTermIDs,
                startAtTermID: startAtTermID
            )
            viewModel = vm
            vm.onAppear()
        }
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView()
        }
        .fullScreenCover(isPresented: $showGames) {
            QuizzesView()
                .environment(\.appEnvironment, env)
                .environment(authState)
        }
        .sheet(isPresented: $showBrowseByVibe) {
            BrowseByVibeView { selection in
                showBrowseByVibe = false
                vibeFeed = selection
            }
            .environment(\.appEnvironment, env)
        }
        .fullScreenCover(item: $vibeFeed) { feed in
            NavigationStack {
                SwiperView(
                    filterTermIDs: feed.termIDs,
                    presentedTitle: feed.title
                )
                .environment(\.appEnvironment, env)
                .environment(authState)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            vibeFeed = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(.label).opacity(0.55))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Top Chrome (normal mode only)

    private var topChrome: some View {
        ZStack {
            // Background chrome row
            HStack(spacing: 0) {
                if presentedTitle == nil {
                    Button { showProfile = true } label: {
                        profileAvatar.frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "swiper.chrome.profile",
                                               defaultValue: "Open profile"))

                    Spacer()
                    sessionProgress
                    Spacer()
                    Button { showGames = true } label: {
                        Image(systemName: "gamecontroller")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(Color(.label).opacity(0.40))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "swiper.games.accessibility",
                                              defaultValue: "Games"))
                    .frame(width: 44, height: 44)

                    Button { showBrowseByVibe = true } label: {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(Color(.label).opacity(0.40))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "swiper.browse.accessibility",
                                              defaultValue: "Browse by vibe"))
                    .frame(width: 44, height: 44)
                }
            }

            // Toast pill — overlays the center of the chrome
            if let vm = viewModel, let name = vm.saveToastCollectionName {
                toastPill(collectionName: name)
                    // On iPad: constrain to the space between the 44pt left and right icons
                    .padding(.horizontal, horizontalSizeClass == .regular ? 74 : 0)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85),
                   value: viewModel?.saveToastCollectionName)
        .padding(.horizontal, SlangSpacing.md)
        .padding(.vertical, SlangSpacing.xs)
        .background(SlangColor.background)
    }

    // MARK: - Toast Pill (image #1 style)

    private func toastPill(collectionName: String) -> some View {
        HStack(spacing: 12) {
            (Text("Saved to ") + Text(collectionName).bold())
                .font(.montserrat(size: 14))
                .foregroundStyle(.primary)
                .lineLimit(1)

            if horizontalSizeClass == .regular {
                Spacer(minLength: 0)
            }

            Button {
                showCollectionPicker = true
                viewModel?.dismissSaveToast()
            } label: {
                Text(String(localized: "swiper.toast.change", defaultValue: "Change"))
                    .font(.montserrat(size: 14))
                    .fontWeight(.bold)
                    .foregroundStyle(Color(.label))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(SlangColor.onboardingTeal)
                            .shadow(color: .black.opacity(0.55), radius: 0, x: 0, y: 3)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)
        )
    }

    // MARK: - Collection Picker Overlay (image #2 style)

    private func collectionPickerOverlay(vm: SwiperViewModel) -> some View {
        ZStack {
            // Invisible tap target to dismiss on outside tap
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    showCollectionPicker = false
                    keyboardHeight = 0
                }

            // Floating card — shifts up when keyboard is active
            CollectionPickerCard(viewModel: vm, isPresented: $showCollectionPicker)
                .padding(.horizontal, 28)
                .offset(y: -keyboardHeight / 2)
        }
        .ignoresSafeArea(.keyboard)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: showCollectionPicker)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
            guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                keyboardHeight = frame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                keyboardHeight = 0
            }
        }
    }

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
    @State private var dragY: CGFloat = 0
    @AppStorage("swiperSwipeCount") private var swiperSwipeCount: Int = 0
    @State private var infoTerm: SlangTerm? = nil
    @State private var chevronBounce: CGFloat = 0

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
        .onAppear { startChevronBounce() }
        .onDisappear { viewModel.onDisappear() }
        .sheet(item: $infoTerm) { term in
            TermInfoSheet(term: term)
        }
    }

    // MARK: - Term Stack

    private var termStack: some View {
        GeometryReader { geo in
            let height = geo.size.height

            ZStack {
                if viewModel.canGoBack, let previous = viewModel.historyStack.last {
                    termView(previous)
                        .offset(y: dragY > 0 ? -height + dragY : -height)
                        .allowsHitTesting(false)
                }

                if viewModel.cardQueue.count > 1 {
                    termView(viewModel.cardQueue[1])
                        .offset(y: dragY < 0 ? height + dragY : height)
                        .allowsHitTesting(false)
                }

                // SAFE: only rendered when !isQueueEmpty, guard ensures non-nil
                if let currentTerm = viewModel.cardQueue.first {
                    termView(currentTerm)
                        .offset(y: dragY > 0 && !viewModel.canGoBack
                                ? dragY * 0.15
                                : dragY)
                }
            }
            .clipped()
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
        VStack(spacing: 0) {
            Spacer()

            Text(term.term.lowercased())
                .font(.slangTerm(size: 52))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.xl)

            definitionText(term: term)
                .font(.slangDefinition(size: 20))
                .foregroundStyle(.primary.opacity(0.82))
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.xl)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, SlangSpacing.xl)

            if !term.exampleSentence.isEmpty {
                Text("\u{201C}\(term.exampleSentence)\u{201D}")
                    .font(.slangDefinition(size: 18))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .italic()
                    .padding(.horizontal, SlangSpacing.xl + SlangSpacing.md)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, SlangSpacing.lg)
            }

            Spacer()

            swipeHintView
                .padding(.bottom, SlangSpacing.sm)

            actionButtons(term: term)
                .padding(.bottom, SlangSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(term.term). \(term.definition)")
        .accessibilityAction(named: String(localized: "swiper.accessibility.next",
                                          defaultValue: "Next card")) {
            viewModel.swipeUp()
        }
    }

    // MARK: - Definition Helpers

    private func definitionText(term: SlangTerm) -> Text {
        if term.partOfSpeechShort.isEmpty {
            return Text(term.definition)
        }
        return Text("(\(term.partOfSpeechShort)) ").bold() + Text(term.definition)
    }

    // MARK: - Action Buttons

    private func actionButtons(term: SlangTerm) -> some View {
        HStack(spacing: SlangSpacing.xl) {
            Button { infoTerm = term } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color(.label).opacity(0.40))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "swiper.info.accessibility", defaultValue: "Term info"))

            Button { viewModel.toggleFavoriteCurrentCard() } label: {
                Image(systemName: viewModel.isTopCardLiked ? "heart.fill" : "heart")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(
                        viewModel.isTopCardLiked ? Color.red.opacity(0.75) : Color(.label).opacity(0.40)
                    )
            }
            .buttonStyle(.plain)

            Button { viewModel.toggleSaveCurrentCard() } label: {
                Image(systemName: viewModel.isTopCardSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(
                        viewModel.isTopCardSaved ? SlangColor.primary : Color(.label).opacity(0.40)
                    )
            }
            .buttonStyle(.plain)

            Button { SlangShareCard.share(term: term) } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color(.label).opacity(0.40))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "swiper.share.accessibility", defaultValue: "Share term"))
        }
    }

    // MARK: - Swipe Hint

    private var swipeHintView: some View {
        VStack(spacing: 4) {
            Image(systemName: "chevron.up")
                .font(.system(size: 14, weight: .light))
                .offset(y: chevronBounce)
            Text(String(localized: "swiper.hint.swipe", defaultValue: "swipe up for next"))
                .font(.system(size: 12, design: .monospaced))
        }
        .foregroundStyle(Color(.tertiaryLabel))
        .opacity(showSwipeHint ? 1 : 0)
        .animation(.easeOut(duration: 0.6), value: showSwipeHint)
    }

    /// Repeating bounce: chevron eases up 8 pt then springs back, looping forever.
    private func startChevronBounce() {
        let upDuration   = 0.45
        let downDuration = 0.55
        let pause        = 0.9

        func cycle() {
            withAnimation(.easeOut(duration: upDuration)) {
                chevronBounce = -8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + upDuration) {
                withAnimation(.spring(response: downDuration, dampingFraction: 0.5)) {
                    chevronBounce = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + downDuration + pause) {
                    cycle()
                }
            }
        }

        cycle()
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

            Button { viewModel.reshuffleAll() } label: {
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
