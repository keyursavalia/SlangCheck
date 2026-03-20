// Features/Profile/LexiconView.swift
// SlangCheck
//
// Personal Lexicon screen. Shows saved terms, supports sort toggle
// and swipe-to-delete with confirmation (FR-L-001 through FR-L-006).

import SwiftUI

// MARK: - LexiconView

struct LexiconView: View {

    @Environment(\.appEnvironment) private var env
    @State private var viewModel: LexiconViewModel?
    @State private var termToDelete: SlangTerm? = nil

    var body: some View {
        Group {
            if let viewModel {
                LexiconContentView(
                    viewModel: viewModel,
                    termToDelete: $termToDelete
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(SlangColor.background.ignoresSafeArea())
            }
        }
        .task {
            guard viewModel == nil else { return }
            let vm = LexiconViewModel(repository: env.slangTermRepository)
            viewModel = vm
            vm.onAppear()
        }
        // Confirmation alert for destructive removal (NF-UX-003).
        .alert(
            String(localized: "lexicon.delete.title", defaultValue: "Remove from Lexicon?"),
            isPresented: Binding(
                get: { termToDelete != nil },
                set: { if !$0 { termToDelete = nil } }
            )
        ) {
            Button(
                String(localized: "lexicon.delete.confirm", defaultValue: "Remove"),
                role: .destructive
            ) {
                if let term = termToDelete {
                    viewModel?.remove(term: term)
                }
                termToDelete = nil
            }
            Button(
                String(localized: "lexicon.delete.cancel", defaultValue: "Cancel"),
                role: .cancel
            ) {
                termToDelete = nil
            }
        } message: {
            if let term = termToDelete {
                Text(String(localized: "lexicon.delete.message \(term.term)",
                            defaultValue: "Remove \"\(term.term)\" from your Lexicon?"))
            }
        }
    }
}

// MARK: - LexiconContentView

private struct LexiconContentView: View {

    @Bindable var viewModel: LexiconViewModel
    @Binding var termToDelete: SlangTerm?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.savedTerms.isEmpty {
                    emptyState
                } else {
                    termList
                }
            }
            .background(SlangColor.background.ignoresSafeArea())
            .navigationTitle(
                String(localized: "lexicon.title", defaultValue: "My Lexicon")
            )
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    sortMenu
                }
            }
            .navigationDestination(for: SlangTerm.self) { term in
                LexiconTermDetailView(term: term, onRemove: {
                    termToDelete = term
                    navigationPath.removeLast()
                })
            }
        }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: - Term List

    private var termList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.savedTerms) { term in
                    SwipeToDeleteRow(onDelete: { termToDelete = term }) {
                        NavigationLink(value: term) {
                            SlangTermRow(term: term, isSaved: true)
                        }
                        .buttonStyle(.plain)
                    }
                    Divider()
                        .padding(.leading, SlangSpacing.md)
                }
            }
            .background(SlangColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.cell))
            .padding(.horizontal, SlangSpacing.md)
            .padding(.top, SlangSpacing.sm)
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(LexiconSortOrder.allCases, id: \.rawValue) { order in
                Button {
                    viewModel.sortOrder = order
                } label: {
                    Label {
                        Text(order.displayName)
                    } icon: {
                        if viewModel.sortOrder == order {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SlangColor.primary)
                .accessibilityLabel(
                    String(localized: "lexicon.sort.accessibilityLabel", defaultValue: "Sort options")
                )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            symbolName: "bookmark",
            title: String(localized: "lexicon.empty.title", defaultValue: "Your Lexicon is Empty"),
            message: String(localized: "lexicon.empty.message",
                            defaultValue: "Swipe right on a card or tap 'Save to Lexicon' on any term to build your collection.")
        )
    }

    // MARK: - Loading

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - SwipeToDeleteRow

/// Wraps a row with a left-drag gesture that reveals a red delete zone.
private struct SwipeToDeleteRow<Content: View>: View {

    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    private let deleteThreshold: CGFloat = -80

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background
            Rectangle()
                .fill(SlangColor.errorRed)
                .overlay(
                    Image(systemName: "trash")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.trailing, SlangSpacing.lg)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .accessibilityHidden(true)
                )

            content()
                .background(SlangColor.surface)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = max(value.translation.width, deleteThreshold)
                            }
                        }
                        .onEnded { value in
                            if value.translation.width < deleteThreshold {
                                onDelete()
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                offset = 0
                            }
                        }
                )
        }
        .clipped()
    }
}

// MARK: - LexiconTermDetailView

/// Read-only detail view for a saved term, with a Remove from Lexicon option.
private struct LexiconTermDetailView: View {

    let term: SlangTerm
    let onRemove: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlangSpacing.lg) {
                // Term info card
                VStack(alignment: .leading, spacing: SlangSpacing.sm) {
                    Text(term.term)
                        .font(.slang(.title))
                    Text(term.category.displayName.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(SlangColor.primary)
                        .tracking(1.2)
                }
                .padding(SlangSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()

                // Definition
                VStack(alignment: .leading, spacing: SlangSpacing.sm) {
                    Text(String(localized: "termDetail.definition", defaultValue: "Definition"))
                        .font(.slang(.label))
                        .foregroundStyle(SlangColor.primary)
                    Text(term.definition)
                        .font(.slang(.body))
                        .slangBodySpacing()
                }
                .padding(SlangSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SlangColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.cell))

                // Example
                VStack(alignment: .leading, spacing: SlangSpacing.sm) {
                    Text(String(localized: "termDetail.example", defaultValue: "Example"))
                        .font(.slang(.label))
                        .foregroundStyle(SlangColor.primary)
                    Text("\u{201C}\(term.exampleSentence)\u{201D}")
                        .font(.slang(.body))
                        .foregroundStyle(.secondary)
                        .italic()
                        .slangBodySpacing()
                }
                .padding(SlangSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SlangColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.cell))

                // Remove button
                Button(action: onRemove) {
                    HStack(spacing: SlangSpacing.sm) {
                        Image(systemName: "bookmark.slash")
                        Text(String(localized: "termDetail.removeFromLexicon",
                                    defaultValue: "Remove from Lexicon"))
                            .font(.slang(.label))
                    }
                    .foregroundStyle(SlangColor.errorRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SlangSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: SlangCornerRadius.button)
                            .fill(SlangColor.errorRed.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: SlangCornerRadius.button)
                                    .strokeBorder(SlangColor.errorRed, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(SlangSpacing.md)
        }
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(term.term)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("LexiconView") {
    LexiconView()
        .environment(\.appEnvironment, .preview())
}
