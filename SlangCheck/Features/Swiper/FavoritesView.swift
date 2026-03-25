// Features/Swiper/FavoritesView.swift
// SlangCheck
//
// Full-screen paged viewer of liked/favorited slang terms.
// Each page shows the term, its definition, a category chip, heart (unlike) and share actions.

import SwiftUI

// MARK: - FavoritesView

/// Paged viewer for liked terms. Accessed from ProfileView → YOUR VOCABULARY → Favorites.
struct FavoritesView: View {

    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var terms: [SlangTerm] = []
    @State private var favorites: UserFavorites = UserFavorites()
    @State private var isLoading = true
    @State private var currentPage = 0

    var body: some View {
        NavigationStack {
            ZStack {
                SlangColor.background.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(SlangColor.secondary)
                } else if terms.isEmpty {
                    emptyState
                } else {
                    pagedContent
                }
            }
            .navigationTitle(String(localized: "favorites.title", defaultValue: "Favorites"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(String(localized: "favorites.close", defaultValue: "Close"))
                }
            }
        }
        .task { await loadFavorites() }
    }

    // MARK: - Paged Content

    private var pagedContent: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(terms.enumerated()), id: \.element.id) { index, term in
                FavoritePageView(
                    term: term,
                    isLiked: favorites.contains(termID: term.id),
                    onUnlike: { unlike(term: term) },
                    onShare: { SlangShareCard.share(term: term) }
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
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

    private func loadFavorites() async {
        isLoading = true
        favorites = loadPersistedFavorites()
        if let allTerms = try? await env.slangTermRepository.fetchAllTerms() {
            terms = allTerms.filter { favorites.contains(termID: $0.id) }
        }
        isLoading = false
    }

    private func unlike(term: SlangTerm) {
        favorites = favorites.removing(termID: term.id)
        persistFavorites(favorites)
        withAnimation {
            terms.removeAll { $0.id == term.id }
            currentPage = min(currentPage, max(0, terms.count - 1))
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

// MARK: - FavoritePageView

/// A single page in the favorites pager: term, definition, category chip, heart + share actions.
private struct FavoritePageView: View {

    let term: SlangTerm
    let isLiked: Bool
    let onUnlike: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Category chip
            Text(term.category.displayName)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(SlangColor.primary)
                .padding(.horizontal, SlangSpacing.md)
                .padding(.vertical, SlangSpacing.xs)
                .background(Capsule().fill(SlangColor.primary.opacity(0.12)))
                .padding(.bottom, SlangSpacing.lg)

            // Term
            Text(term.term)
                .font(.custom("NoticiaText-Bold", size: 42))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.xl)
                .padding(.bottom, SlangSpacing.md)

            // Definition
            Text(term.definition)
                .font(.custom("NoticiaText-Regular", size: 17))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, SlangSpacing.xl)

            Spacer()

            // Action bar: heart + share
            HStack(spacing: SlangSpacing.xxl) {
                Button(action: onUnlike) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(isLiked ? Color.red.opacity(0.75) : Color(.label).opacity(0.35))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "favorites.unlike", defaultValue: "Remove from favorites"))

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color(.label).opacity(0.35))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "favorites.share", defaultValue: "Share term"))
            }
            .padding(.bottom, SlangSpacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("FavoritesView") {
    FavoritesView()
        .environment(\.appEnvironment, .preview())
}
