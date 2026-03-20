// Features/Glossary/SlangTermDetailView.swift
// SlangCheck
//
// Full-detail view for a single slang term (FR-GL-005, FR-GL-006).
// Shows definition, example sentence, category badge, generation tags,
// and a Save/Remove lexicon toggle button.

import SwiftUI

// MARK: - SlangTermDetailView

/// Displays the complete information for a slang term and allows saving/removing
/// from the Personal Lexicon.
struct SlangTermDetailView: View {

    // MARK: Properties

    let term: SlangTerm
    @Bindable var viewModel: GlossaryViewModel

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SlangSpacing.lg) {
                termHeader
                definitionSection
                exampleSection
                originSection
                metadataSection
                lexiconButton
            }
            .padding(SlangSpacing.md)
        }
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(term.term)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Term Header

    private var termHeader: some View {
        VStack(alignment: .leading, spacing: SlangSpacing.sm) {
            Text(term.term)
                .font(.slang(.title))
                .foregroundStyle(.primary)

            HStack(spacing: SlangSpacing.sm) {
                CategoryBadge(category: term.category)
                ForEach(term.generationTags, id: \.rawValue) { tag in
                    GenerationTagBadge(tag: tag)
                }
            }
        }
        .padding(SlangSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - Definition Section

    private var definitionSection: some View {
        DetailSection(
            iconName: "text.alignleft",
            title: String(localized: "termDetail.definition", defaultValue: "Definition")
        ) {
            Text(term.definition)
                .font(.slang(.body))
                .foregroundStyle(.primary)
                .slangBodySpacing()
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Example Section

    private var exampleSection: some View {
        DetailSection(
            iconName: "quote.bubble",
            title: String(localized: "termDetail.example", defaultValue: "Example")
        ) {
            Text("\u{201C}\(term.exampleSentence)\u{201D}")
                .font(.slang(.body))
                .foregroundStyle(.secondary)
                .italic()
                .slangBodySpacing()
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Origin Section

    @ViewBuilder
    private var originSection: some View {
        if !term.origin.isEmpty {
            DetailSection(
                iconName: "clock.arrow.circlepath",
                title: String(localized: "termDetail.origin", defaultValue: "Origin")
            ) {
                Text(term.origin)
                    .font(.slang(.body))
                    .foregroundStyle(.secondary)
                    .slangBodySpacing()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        HStack(spacing: SlangSpacing.md) {
            MetadataChip(
                label: String(localized: "termDetail.frequency", defaultValue: "Frequency"),
                value: term.usageFrequency.rawValue.capitalized
            )
            if term.isBrainrot {
                MetadataChip(
                    label: String(localized: "termDetail.brainrot", defaultValue: "Type"),
                    value: String(localized: "termDetail.brainrotValue", defaultValue: "Brainrot")
                )
            }
        }
    }

    // MARK: - Lexicon Button (FR-GL-006)

    private var lexiconButton: some View {
        let isSaved = viewModel.lexicon.contains(termID: term.id)

        return Button {
            viewModel.toggleLexicon(for: term)
        } label: {
            HStack(spacing: SlangSpacing.sm) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 17, weight: .semibold))
                Text(
                    isSaved
                        ? String(localized: "termDetail.removeFromLexicon",
                                 defaultValue: "Remove from Lexicon")
                        : String(localized: "termDetail.saveToLexicon",
                                 defaultValue: "Save to Lexicon")
                )
                .font(.slang(.label))
            }
            .foregroundStyle(isSaved ? SlangColor.errorRed : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, SlangSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: SlangCornerRadius.button)
                    .fill(isSaved ? SlangColor.errorRed.opacity(0.12) : SlangColor.primary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SlangCornerRadius.button)
                    .strokeBorder(isSaved ? SlangColor.errorRed : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSaved)
        .accessibilityLabel(
            isSaved
                ? String(localized: "termDetail.removeFromLexicon", defaultValue: "Remove from Lexicon")
                : String(localized: "termDetail.saveToLexicon", defaultValue: "Save to Lexicon")
        )
    }
}

// MARK: - Supporting Sub-Views

private struct DetailSection<Content: View>: View {
    let iconName: String
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: SlangSpacing.sm) {
            HStack(spacing: SlangSpacing.xs) {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SlangColor.primary)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.slang(.label))
                    .foregroundStyle(SlangColor.primary)
            }
            content()
        }
        .padding(SlangSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SlangColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.cell))
    }
}

private struct CategoryBadge: View {
    let category: SlangCategory

    var body: some View {
        Text(category.displayName)
            .font(.slang(.caption))
            .foregroundStyle(SlangColor.primary)
            .padding(.horizontal, SlangSpacing.sm)
            .padding(.vertical, SlangSpacing.xs)
            .background(Capsule().fill(SlangColor.primary.opacity(0.12)))
    }
}

private struct GenerationTagBadge: View {
    let tag: GenerationTag

    var body: some View {
        Text(tag.rawValue)
            .font(.slang(.caption))
            .foregroundStyle(SlangColor.accent)
            .padding(.horizontal, SlangSpacing.sm)
            .padding(.vertical, SlangSpacing.xs)
            .background(Capsule().fill(SlangColor.accent.opacity(0.12)))
    }
}

private struct MetadataChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.slang(.caption))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.slang(.subheading))
                .foregroundStyle(.primary)
        }
        .padding(SlangSpacing.sm)
        .background(SlangColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.chip))
    }
}

// MARK: - Preview

#Preview("SlangTermDetailView") {
    let term = SlangTerm(
        id: UUID(),
        term: "No Cap",
        definition: "An intensifier meaning 'for real' or 'honestly'; used to assert truthfulness.",
        standardEnglish: "Honestly / For real",
        exampleSentence: "No cap, that was the best movie I've ever seen.",
        category: .foundationalDescriptor,
        origin: "African American Vernacular English (AAVE), popularized via hip-hop and social media.",
        usageFrequency: .high,
        generationTags: [.genZ, .genAlpha],
        addedDate: Date(),
        isBrainrot: false,
        isEmojiTerm: false
    )

    NavigationStack {
        SlangTermDetailView(
            term: term,
            viewModel: GlossaryViewModel(repository: CoreDataSlangTermRepository(persistence: .preview))
        )
    }
    .environment(\.appEnvironment, .preview())
}
