// Features/Glossary/GlossaryView.swift
// SlangCheck
//
// The main Glossary screen: alphabetically grouped, LazyVStack-based list
// with a right-margin scrubber, horizontal category filter, and debounced search.
// Uses LazyVStack + ScrollView (ADR-006). ViewModel created lazily from environment.

import SwiftUI

// MARK: - GlossaryView

/// Entry point for the Glossary tab. Creates the ViewModel from the environment
/// on first appear and hands off to the content view.
struct GlossaryView: View {

    @Environment(\.appEnvironment) private var env
    @State private var viewModel: GlossaryViewModel?

    var body: some View {
        Group {
            if let viewModel {
                GlossaryContentView(viewModel: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(SlangColor.background.ignoresSafeArea())
            }
        }
        .task {
            guard viewModel == nil else { return }
            let vm = GlossaryViewModel(repository: env.slangTermRepository)
            viewModel = vm
            vm.onAppear()
        }
    }
}

// MARK: - GlossaryContentView

/// The actual rendered content once the ViewModel is available.
private struct GlossaryContentView: View {

    @Bindable var viewModel: GlossaryViewModel
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .trailing) {
                ScrollViewReader { proxy in
                    ScrollView {
                        // pinnedViews: .sectionHeaders keeps the alphabetical letter
                        // headers (A, B, C…) stuck to the top as the user scrolls.
                        // The search + category bar is placed via .safeAreaInset below
                        // so it lives OUTSIDE the vertical ScrollView — this eliminates
                        // the horizontal-vs-vertical gesture conflict that prevented
                        // the CategoryFilterBar from scrolling.
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                            contentSection
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onAppear { scrollProxy = proxy }
                    // Place search + category header outside the ScrollView's scroll area
                    // so its own horizontal ScrollView receives gestures without conflict.
                    .safeAreaInset(edge: .top, spacing: 0) {
                        VStack(spacing: 0) {
                            searchBar
                            CategoryFilterBar(selectedCategory: $viewModel.selectedCategory)
                        }
                        .background(SlangColor.background)
                    }
                }
                .padding(.trailing, 28)

                if !viewModel.sectionHeaders.isEmpty {
                    AlphabetScrubberView(
                        availableLetters: viewModel.sectionHeaders
                    ) { letter in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            scrollProxy?.scrollTo(letter, anchor: .top)
                        }
                    }
                    .padding(.trailing, SlangSpacing.xs)
                    // Fill the ZStack height so GeometryReader spans the full screen —
                    // letters are then distributed top-to-bottom (like iOS Contacts).
                    .frame(maxHeight: .infinity)
                }
            }
            .navigationTitle(String(localized: "glossary.title", defaultValue: "Glossary"))
            // .inline keeps the title in the navigation bar at all times.
            // .large would render the title as scroll content, causing it to scroll
            // behind the fixed .safeAreaInset search+category header.
            .navigationBarTitleDisplayMode(.inline)
            .background(SlangColor.background.ignoresSafeArea())
            .navigationDestination(for: SlangTerm.self) { term in
                SlangTermDetailView(term: term, viewModel: viewModel)
            }
        }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: SlangSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SlangColor.primary)
                .accessibilityHidden(true)

            TextField(
                String(localized: "glossary.search.placeholder", defaultValue: "Search slang..."),
                text: $viewModel.searchQuery
            )
            .font(.slang(.body))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .accessibilityLabel(
                String(localized: "glossary.search.accessibilityLabel",
                       defaultValue: "Search slang terms")
            )

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(.tertiaryLabel))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    String(localized: "glossary.search.clear", defaultValue: "Clear search")
                )
            }
        }
        .padding(SlangSpacing.sm + 4)
        .neumorphicSurface()
        .padding(.horizontal, SlangSpacing.md)
        .padding(.top, SlangSpacing.sm)
        .padding(.bottom, SlangSpacing.xs)
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading {
            loadingPlaceholder
        } else if viewModel.displayedTerms.isEmpty {
            emptyState
        } else {
            termList
        }
    }

    // MARK: - Term List

    private var termList: some View {
        ForEach(viewModel.sectionHeaders, id: \.self) { letter in
            Section {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.groupedTerms[letter] ?? []) { term in
                        NavigationLink(value: term) {
                            SlangTermRow(
                                term: term,
                                searchQuery: viewModel.searchQuery,
                                isSaved: viewModel.lexicon.contains(termID: term.id)
                            )
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, SlangSpacing.md)
                    }
                }
                .background(SlangColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.cell))
                .padding(.horizontal, SlangSpacing.md)
                .padding(.bottom, SlangSpacing.sm)
            } header: {
                HStack {
                    Text(letter)
                        .font(.slang(.label))
                        .foregroundStyle(SlangColor.primary)
                        .padding(.horizontal, SlangSpacing.md)
                        .padding(.vertical, SlangSpacing.xs)
                    Spacer()
                }
                .background(SlangColor.background)
                .id(letter)
                .accessibilityLabel("Section \(letter)")
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.searchQuery.isEmpty {
            EmptyStateView(
                symbolName: "books.vertical",
                title: String(localized: "glossary.empty.title", defaultValue: "No Terms Found"),
                message: String(localized: "glossary.empty.message",
                                defaultValue: "Try selecting a different category."),
                actionTitle: String(localized: "glossary.empty.action", defaultValue: "Show All"),
                action: { viewModel.selectedCategory = nil }
            )
        } else {
            EmptyStateView(
                symbolName: "magnifyingglass",
                title: String(localized: "glossary.search.empty.title",
                              defaultValue: "No slang found"),
                message: String(localized: "glossary.search.empty.message",
                                defaultValue: "No slang found. Maybe it's too niche \u{1F440}"),
                actionTitle: String(localized: "glossary.search.empty.action",
                                    defaultValue: "Browse by category"),
                action: {
                    viewModel.searchQuery = ""
                    viewModel.selectedCategory = nil
                }
            )
        }
    }

    // MARK: - Loading Skeleton (NF-UX-002: non-blocking skeleton for >200ms ops)

    private var loadingPlaceholder: some View {
        VStack(spacing: SlangSpacing.sm) {
            ForEach(0..<8, id: \.self) { _ in
                RoundedRectangle(cornerRadius: SlangCornerRadius.cell)
                    .fill(Color(.systemFill))
                    .frame(height: 56)
                    .padding(.horizontal, SlangSpacing.md)
            }
        }
        .padding(.top, SlangSpacing.sm)
    }
}

// MARK: - Preview

#Preview("GlossaryView") {
    GlossaryView()
        .environment(\.appEnvironment, .preview())
}
