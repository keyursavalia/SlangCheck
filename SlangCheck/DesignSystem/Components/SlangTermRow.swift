// DesignSystem/Components/SlangTermRow.swift
// SlangCheck
//
// Reusable list row component used in both the Glossary and the Personal Lexicon.
// Per CLAUDE.md: shared between Glossary (Step 1.4) and Lexicon (Step 1.7).

import SwiftUI

// MARK: - SlangTermRow

/// A list row displaying a slang term's name, a one-line definition preview,
/// and a navigation chevron. Matches the spec in DESIGN_SYSTEM.md §7.2.
public struct SlangTermRow: View {

    // MARK: Properties

    let term: SlangTerm

    /// Substring to highlight in the term name (for search results). FR-SR-004.
    var searchQuery: String = ""

    /// Whether this term is saved in the user's lexicon (controls saved indicator).
    var isSaved: Bool = false

    // MARK: Body

    public var body: some View {
        HStack(spacing: SlangSpacing.md) {
            VStack(alignment: .leading, spacing: SlangSpacing.xs) {
                highlightedTermText
                Text(term.definition)
                    .font(.slang(.caption))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .accessibilityLabel("Definition: \(term.definition)")
            }

            Spacer(minLength: SlangSpacing.sm)

            HStack(spacing: SlangSpacing.xs) {
                if isSaved {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SlangColor.primary)
                        .accessibilityLabel(
                            String(localized: "accessibility.termRow.saved",
                                   defaultValue: "Saved to lexicon")
                        )
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, SlangSpacing.md)
        .padding(.vertical, SlangSpacing.sm)
        .contentShape(Rectangle()) // Ensures full-row tap target (FR-G-009: 44pt min).
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(term.term). \(term.definition)")
    }

    // MARK: - Highlighted Term Text

    @ViewBuilder
    private var highlightedTermText: some View {
        if searchQuery.isEmpty {
            Text(term.term)
                .font(.slang(.subheading))
                .foregroundStyle(.primary)
        } else {
            Text(attributedTerm)
                .font(.slang(.subheading))
        }
    }

    /// Builds an `AttributedString` with the search match highlighted in `SlangColor.primary`.
    private var attributedTerm: AttributedString {
        var attributed = AttributedString(term.term)
        let loweredTerm  = term.term.lowercased()
        let loweredQuery = searchQuery.lowercased()

        if let range = loweredTerm.range(of: loweredQuery),
           let attrRange = attributed.range(
                of: String(loweredTerm[range]),
                options: .caseInsensitive
           ) {
            attributed[attrRange].foregroundColor = UIColor(SlangColor.primary)
            attributed[attrRange].font = UIFont.systemFont(ofSize: 17, weight: .bold)
        }
        return attributed
    }
}

// MARK: - Preview

#Preview("SlangTermRow — Light") {
    let term = SlangTerm(
        id: UUID(),
        term: "No Cap",
        definition: "An intensifier meaning 'for real' or 'honestly'.",
        standardEnglish: "Honestly / For real",
        exampleSentence: "No cap, that was the best movie ever.",
        category: .foundationalDescriptor,
        origin: "AAVE",
        usageFrequency: .high,
        generationTags: [.genZ],
        addedDate: Date(),
        isBrainrot: false,
        isEmojiTerm: false
    )
    VStack {
        SlangTermRow(term: term, searchQuery: "", isSaved: false)
        Divider().padding(.leading, SlangSpacing.md)
        SlangTermRow(term: term, searchQuery: "cap", isSaved: true)
    }
    .background(SlangColor.background)
}
