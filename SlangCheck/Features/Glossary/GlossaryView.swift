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

    /// When set, pre-selects this category filter on first load.
    /// Nil means show all terms (the default).
    var initialCategory: SlangCategory? = nil

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
            // Set initialCategory before onAppear so the first fetch uses the correct filter.
            if let category = initialCategory {
                vm.selectedCategory = category
            }
            viewModel = vm
            vm.onAppear()
        }
        // Destination is registered here — on GlossaryView — NOT inside GlossaryContentView.
        // This guarantees exactly one SlangTerm destination in MoreMenuView's NavigationStack.
        // LexiconContentView also registers a SlangTerm destination (for its own stack), but
        // its NavigationStack is presented inside a sheet. In some SwiftUI versions that
        // registration bleeds into the parent stack; keeping ours at the GlossaryView level
        // (shallower than the Lexicon sheet's stack) ensures the correct destination always wins.
        .navigationDestination(for: SlangTerm.self) { term in
            // SAFE: the term list is only visible after viewModel is set, so viewModel
            // is always non-nil by the time the user can trigger this navigation.
            if let vm = viewModel {
                SlangTermDetailView(term: term, viewModel: vm)
            }
        }
    }
}

// MARK: - GlossaryContentView

/// The actual rendered content once the ViewModel is available.
private struct GlossaryContentView: View {

    @Bindable var viewModel: GlossaryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        ZStack(alignment: .trailing) {
            ScrollViewReader { proxy in
                ScrollView {
                    // pinnedViews: .sectionHeaders keeps letter headers (A, B, C…) sticky.
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                        contentSection
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear { scrollProxy = proxy }
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
                // maxHeight: .infinity so the GeometryReader spans the available height
                // BELOW the search+filter safeAreaInset — scrubber aligns with list content.
                .frame(maxHeight: .infinity)
            }
        }
        // safeAreaInset on the outer ZStack — pushes BOTH the ScrollView AND the
        // AlphabetScrubberView below the search+filter header. If the inset were only
        // on the inner ScrollViewReader, the scrubber would start at y=0 (behind the
        // search bar). Moving it here fixes both the scrubber position and the
        // horizontal gesture conflict with CategoryFilterBar.
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                searchBar
                CategoryFilterBar(selectedCategory: $viewModel.selectedCategory)
            }
            .background(SlangColor.background)
        }
        .navigationTitle(String(localized: "glossary.title", defaultValue: "Explore"))
        // .inline keeps the title fixed in the nav bar. .large would render it as
        // scroll content BELOW the safeAreaInset header, which makes it scroll away
        // with the list instead of staying fixed — the broken behavior shown in
        // glossary_broken_title_scroll.png.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel(String(localized: "glossary.close", defaultValue: "Close"))
            }
        }
        .background(SlangColor.background.ignoresSafeArea())
        // navigationDestination(for: SlangTerm.self) is on GlossaryView (the parent),
        // not here — keeping it at one level prevents duplicate-destination warnings.
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
        .background(
            RoundedRectangle(cornerRadius: SlangCornerRadius.cell)
                .fill(Color(.systemBackground))
        )
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
                .background(Color(.systemBackground))
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
    NavigationStack {
        GlossaryView()
    }
    .environment(\.appEnvironment, .preview())
}
