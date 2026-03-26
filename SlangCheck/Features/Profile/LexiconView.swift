// Features/Profile/LexiconView.swift
// SlangCheck
//
// Collections screen — shows all collections with word counts.
// Tapping a collection navigates to CollectionDetailView.
// Pushed as a NavigationLink destination within ProfileView's NavigationStack.

import SwiftUI

// MARK: - LexiconView

struct LexiconView: View {

    @Environment(\.appEnvironment) private var env

    @State private var collections: [SlangCollection] = []
    @State private var showingNewCollection = false
    @State private var newCollectionName = ""

    var body: some View {
        Group {
            if collections.isEmpty {
                emptyState
            } else {
                collectionList
            }
        }
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "lexicon.title", defaultValue: "Collections"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newCollectionName = ""
                    showingNewCollection = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SlangColor.primary)
                }
                .accessibilityLabel(String(localized: "lexicon.addNew", defaultValue: "Add new collection"))
            }
        }
        .alert(
            String(localized: "lexicon.new.title", defaultValue: "New Collection"),
            isPresented: $showingNewCollection
        ) {
            TextField(
                String(localized: "collections.new.placeholder", defaultValue: "Collection name"),
                text: $newCollectionName
            )
            .autocorrectionDisabled()
            Button(String(localized: "collections.new.save", defaultValue: "Create")) {
                createCollection()
            }
            .disabled(newCollectionName.trimmingCharacters(in: .whitespaces).isEmpty)
            Button(String(localized: "lexicon.delete.cancel", defaultValue: "Cancel"), role: .cancel) {}
        }
        .onAppear { collections = SwiperViewModel.loadCollections() }
        .navigationDestination(for: SlangCollection.self) { collection in
            CollectionDetailView(collection: collection)
                .environment(\.appEnvironment, env)
        }
    }

    // MARK: - Collection List

    private var collectionList: some View {
        ScrollView {
            LazyVStack(spacing: SlangSpacing.sm) {
                ForEach(collections) { collection in
                    NavigationLink(value: collection) {
                        collectionRow(collection)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, SlangSpacing.md)
            .padding(.top, SlangSpacing.sm)
            .padding(.bottom, SlangSpacing.xxl)
        }
    }

    // MARK: - Collection Row

    private func collectionRow(_ collection: SlangCollection) -> some View {
        HStack(spacing: SlangSpacing.md) {
            VStack(alignment: .leading, spacing: 3) {
                Text(collection.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(String(format: NSLocalizedString(
                    "lexicon.wordCount",
                    value: "%d words",
                    comment: "Word count in a collection"
                ), collection.termIDs.count))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(.tertiaryLabel))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, SlangSpacing.md)
        .padding(.vertical, SlangSpacing.md)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.cell))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            symbolName: "bookmark",
            title: String(localized: "lexicon.empty.title", defaultValue: "No Collections Yet"),
            message: String(localized: "lexicon.empty.message",
                            defaultValue: "Save a term from the swiper to start building your collection.")
        )
    }

    // MARK: - Actions

    private func createCollection() {
        let trimmed = newCollectionName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let new = SlangCollection(name: trimmed)
        collections.append(new)
        SwiperViewModel.saveCollections(collections)
    }
}

// MARK: - CollectionDetailView

/// Detail view for a single collection — shows its terms with action buttons.
struct CollectionDetailView: View {

    @Environment(\.appEnvironment) private var env

    let collection: SlangCollection

    @State private var terms: [SlangTerm] = []
    @State private var lexicon: UserLexicon = UserLexicon()
    @State private var favorites: UserFavorites = UserFavorites()
    @State private var isLoading = true
    @State private var showingFeed = false
    @State private var feedStartTermID: UUID? = nil

    var body: some View {
        Group {
            if isLoading {
                ProgressView().tint(SlangColor.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if terms.isEmpty {
                emptyState
            } else {
                termListWithCTA
            }
        }
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showingFeed) {
            SwiperView(
                filterTermIDs: collection.termIDs,
                presentedTitle: collection.name,
                startAtTermID: feedStartTermID
            )
            .environment(\.appEnvironment, env)
        }
        .task { await loadData() }
    }

    // MARK: - Term List + CTA

    private var termListWithCTA: some View {
        ScrollView {
            VStack(spacing: SlangSpacing.md) {
                showInFeedButton
                    .padding(.horizontal, SlangSpacing.md)

                LazyVStack(spacing: SlangSpacing.sm) {
                    ForEach(terms) { term in
                        termCard(term: term)
                            .padding(.horizontal, SlangSpacing.md)
                    }
                }
                .padding(.bottom, SlangSpacing.xxl)
            }
            .padding(.top, SlangSpacing.sm)
        }
    }

    // MARK: - Show in Feed Button

    private var showInFeedButton: some View {
        Button { feedStartTermID = nil; showingFeed = true } label: {
            Text(String(localized: "favorites.showInFeed", defaultValue: "Show all in feed"))
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color(.label))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(SlangColor.onboardingTeal)
                        .shadow(color: .black.opacity(0.55), radius: 0, x: 0, y: 4)
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Term Card

    private func termCard(term: SlangTerm) -> some View {
        let isLiked = favorites.contains(termID: term.id)
        let isSaved = lexicon.contains(termID: term.id)

        return VStack(alignment: .leading, spacing: SlangSpacing.xs) {
            Button {
                feedStartTermID = term.id
                showingFeed = true
            } label: {
                VStack(alignment: .leading, spacing: SlangSpacing.xs) {
                    Text(term.term.lowercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(term.definition)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if !term.exampleSentence.isEmpty {
                        Text("\u{201C}\(term.exampleSentence)\u{201D}")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(.tertiaryLabel))
                            .italic()
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            HStack(spacing: SlangSpacing.lg) {
                Spacer()

                Button { toggleLike(term: term) } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(isLiked ? Color.red.opacity(0.75) : Color(.tertiaryLabel))
                }
                .buttonStyle(.plain)

                Button { toggleSave(term: term) } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(isSaved ? SlangColor.primary : Color(.tertiaryLabel))
                }
                .buttonStyle(.plain)

                Button { SlangShareCard.share(term: term) } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "swiper.share.accessibility", defaultValue: "Share term"))
            }
            .padding(.top, SlangSpacing.xs)
        }
        .padding(SlangSpacing.md)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.cell))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            symbolName: "bookmark",
            title: String(localized: "collectionDetail.empty.title", defaultValue: "No Terms Yet"),
            message: String(localized: "collectionDetail.empty.message",
                            defaultValue: "Save terms from the swiper to add them to this collection.")
        )
    }

    // MARK: - Actions

    private func loadData() async {
        isLoading = true
        if let all = try? await env.slangTermRepository.fetchAllTerms() {
            let map = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
            // Preserve collection order
            terms = collection.termIDs.compactMap { map[$0] }
        }
        if let fetchedLexicon = try? await env.slangTermRepository.fetchLexicon() {
            lexicon = fetchedLexicon
        }
        if let data = UserDefaults.standard.data(forKey: AppConstants.userFavoritesKey),
           let decoded = try? JSONDecoder().decode(UserFavorites.self, from: data) {
            favorites = decoded
        }
        isLoading = false
    }

    private func toggleLike(term: SlangTerm) {
        if favorites.contains(termID: term.id) {
            favorites = favorites.removing(termID: term.id)
        } else {
            favorites = favorites.adding(termID: term.id)
        }
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.userFavoritesKey)
    }

    private func toggleSave(term: SlangTerm) {
        if lexicon.contains(termID: term.id) {
            lexicon = lexicon.removing(termID: term.id)
            var collections = SwiperViewModel.loadCollections()
            for i in collections.indices {
                collections[i].termIDs.removeAll { $0 == term.id }
            }
            SwiperViewModel.saveCollections(collections)
            Task { try? await env.slangTermRepository.removeFromLexicon(termID: term.id) }
        } else {
            lexicon = lexicon.saving(termID: term.id)
            var collections = SwiperViewModel.loadCollections()
            if let idx = collections.firstIndex(where: { $0.isDefault }),
               !collections[idx].termIDs.contains(term.id) {
                collections[idx].termIDs.append(term.id)
                SwiperViewModel.saveCollections(collections)
            }
            Task { try? await env.slangTermRepository.addToLexicon(termID: term.id) }
        }
    }
}

// MARK: - Preview

#Preview("LexiconView") {
    NavigationStack {
        LexiconView()
            .environment(\.appEnvironment, .preview())
    }
}
