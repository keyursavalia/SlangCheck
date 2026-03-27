// Features/Swiper/FavoritesView.swift
// SlangCheck
//
// List view of liked/favorited slang terms — term card style with actions.
// Pushed as a NavigationLink destination within ProfileView's NavigationStack.

import SwiftUI

// MARK: - FavoritesView

/// List viewer for liked terms. Accessed from ProfileView → Favorites.
/// No own NavigationStack — relies on ProfileView's NavigationStack.
struct FavoritesView: View {

    @Environment(\.appEnvironment) private var env

    @State private var terms: [SlangTerm] = []
    @State private var favorites: UserFavorites = UserFavorites()
    @State private var lexicon: UserLexicon = UserLexicon()
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
        .navigationTitle(String(localized: "favorites.title", defaultValue: "Favorites"))
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showingFeed) {
            SwiperView(
                filterTermIDs: Array(favorites.likedTermIDs),
                presentedTitle: String(localized: "favorites.title", defaultValue: "Favorites"),
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
                .font(.montserrat(size: 18, weight: .bold))
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
                        .font(.montserrat(size: 18))
                        .foregroundStyle(.primary)

                    Text(term.definition)
                        .font(.montserrat(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if !term.exampleSentence.isEmpty {
                        Text("\u{201C}\(term.exampleSentence)\u{201D}")
                            .font(.montserrat(size: 13))
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
                .accessibilityLabel(isLiked
                    ? String(localized: "favorites.unlike", defaultValue: "Remove from favorites")
                    : String(localized: "favorites.like", defaultValue: "Add to favorites"))

                Button { toggleSave(term: term) } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(isSaved ? SlangColor.primary : Color(.tertiaryLabel))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSaved
                    ? String(localized: "favorites.unsave", defaultValue: "Remove from collections")
                    : String(localized: "favorites.save", defaultValue: "Save to collections"))

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
        VStack(spacing: SlangSpacing.lg) {
            Image(systemName: "heart.slash")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(SlangColor.primary.opacity(0.4))

            VStack(spacing: SlangSpacing.sm) {
                Text(String(localized: "favorites.empty.title", defaultValue: "No favorites yet"))
                    .font(.slang(.heading))
                    .foregroundStyle(.primary)

                Text(String(localized: "favorites.empty.subtitle",
                            defaultValue: "Tap the heart on any term to save it here."))
                    .font(.slang(.body))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SlangSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadData() async {
        isLoading = true
        favorites = loadPersistedFavorites()
        if let fetched = try? await env.slangTermRepository.fetchAllTerms() {
            terms = fetched.filter { favorites.contains(termID: $0.id) }
        }
        if let fetchedLexicon = try? await env.slangTermRepository.fetchLexicon() {
            lexicon = fetchedLexicon
        }
        isLoading = false
    }

    private func toggleLike(term: SlangTerm) {
        if favorites.contains(termID: term.id) {
            favorites = favorites.removing(termID: term.id)
            persistFavorites(favorites)
            withAnimation {
                terms.removeAll { $0.id == term.id }
            }
        } else {
            favorites = favorites.adding(termID: term.id)
            persistFavorites(favorites)
        }
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

    private func loadPersistedFavorites() -> UserFavorites {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.userFavoritesKey),
              let decoded = try? JSONDecoder().decode(UserFavorites.self, from: data) else {
            return UserFavorites()
        }
        return decoded
    }

    private func persistFavorites(_ fav: UserFavorites) {
        guard let data = try? JSONEncoder().encode(fav) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.userFavoritesKey)
    }
}

// MARK: - Preview

#Preview("FavoritesView") {
    NavigationStack {
        FavoritesView()
            .environment(\.appEnvironment, .preview())
    }
}
