// Features/Swiper/BrowseByVibeView.swift
// SlangCheck
//
// Sheet presented from SwiperView's grid button — shows all featured slang categories.
// Tapping a category opens GlossaryView filtered to that category.

import SwiftUI

// MARK: - BrowseByVibeView

struct BrowseByVibeView: View {

    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    /// Term IDs grouped by category — populated once on appear.
    @State private var termIDsByCategory: [SlangCategory: [UUID]] = [:]
    /// Non-nil when a category card is tapped; drives navigationDestination.
    @State private var feedCategory: SlangCategory? = nil

    private let columns = [
        GridItem(.flexible(), spacing: SlangSpacing.md),
        GridItem(.flexible(), spacing: SlangSpacing.md)
    ]

    let featuredCategories: [SlangCategory] = [
        .foundationalDescriptor,
        .brainrot,
        .socialArchetype,
        .reaction,
        .gamingInternet,
        .aesthetic,
        .relationship,
        .emerging2026
    ]

    var body: some View {
        NavigationStack {
            Group {
                if termIDsByCategory.isEmpty {
                    ProgressView()
                        .tint(SlangColor.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: SlangSpacing.md) {
                            ForEach(featuredCategories, id: \.self) { category in
                                CategoryCard(category: category) {
                                    feedCategory = category
                                }
                            }
                        }
                        .padding(SlangSpacing.lg)
                    }
                }
            }
            .background(SlangColor.background.ignoresSafeArea())
            .navigationTitle(String(localized: "browse.title", defaultValue: "Browse by Vibe"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "browse.close", defaultValue: "Close")) { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(SlangColor.primary)
                }
            }
            .navigationDestination(item: $feedCategory) { category in
                SwiperView(
                    filterTermIDs: termIDsByCategory[category] ?? [],
                    presentedTitle: category.displayName
                )
                .environment(\.appEnvironment, env)
            }
        }
        .task {
            guard termIDsByCategory.isEmpty,
                  let all = try? await env.slangTermRepository.fetchAllTerms() else { return }
            var dict = [SlangCategory: [UUID]]()
            for term in all { dict[term.category, default: []].append(term.id) }
            termIDsByCategory = dict
        }
    }
}

// MARK: - CategoryCardContent

/// Generic visual card matching the Browse by Vibe grid style.
/// Used by both BrowseByVibeView (via CategoryCard) and ProfileView quick-access cards.
struct CategoryCardContent: View {
    let symbolName: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: SlangSpacing.xs) {
            Image(systemName: symbolName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(SlangColor.primary)
                .accessibilityHidden(true)

            Spacer()

            Text(title)
                .font(.slang(.label))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(subtitle)
                .font(.slang(.caption))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(SlangSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .profileCard()
    }
}

// MARK: - CategoryCard

/// Category-specific card wrapper — wires CategoryCardContent to a SlangCategory.
struct CategoryCard: View {
    let category: SlangCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CategoryCardContent(
                symbolName: categoryIcon(category),
                title: category.displayName,
                subtitle: categoryTagline(category)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.displayName)
    }

    private func categoryIcon(_ cat: SlangCategory) -> String {
        switch cat {
        case .foundationalDescriptor: return "book.fill"
        case .brainrot:               return "brain.fill"
        case .socialArchetype:        return "person.2.fill"
        case .reaction:               return "bubble.left.fill"
        case .gamingInternet:         return "gamecontroller.fill"
        case .aesthetic:              return "paintbrush.fill"
        case .relationship:           return "heart.fill"
        case .emerging2026:           return "arrow.up.right.circle.fill"
        case .emojiDescriptor:        return "face.smiling.fill"
        case .emojiReaction:          return "ellipsis.bubble.fill"
        case .emojiTone:              return "theatermasks.fill"
        case .regionalNorCal:         return "map.fill"
        case .regionalSoCal:          return "sun.max.fill"
        case .techSiliconValley:      return "laptopcomputer"
        }
    }

    private func categoryTagline(_ cat: SlangCategory) -> String {
        switch cat {
        case .foundationalDescriptor: return "Core slang"
        case .brainrot:               return "Gen Alpha coded"
        case .socialArchetype:        return "Who are you?"
        case .reaction:               return "Express yourself"
        case .gamingInternet:         return "For the gamers"
        case .aesthetic:              return "Vibes only"
        case .relationship:           return "Ship or skip"
        case .emerging2026:           return "Just dropped"
        case .emojiDescriptor:        return "Say it in emoji"
        case .emojiReaction:          return "React differently"
        case .emojiTone:              return "Tone check"
        case .regionalNorCal:         return "Bay Area speak"
        case .regionalSoCal:          return "SoCal vibes"
        case .techSiliconValley:      return "Tech bro lingo"
        }
    }
}
