// Features/Swiper/TermInfoSheet.swift
// SlangCheck
//
// Bottom sheet presenting full details of a slang term.
// Presented when the user taps the info (i) button in the Swiper.

import SwiftUI

// MARK: - TermInfoSheet

struct TermInfoSheet: View {

    let term: SlangTerm
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SlangSpacing.xl) {

                    termHeader
                    Divider().overlay(SlangColor.separator)
                    definitionSection
                    exampleSection
                    standardEnglishSection
                    originSection
                    categoryAndUsageRow
                    generationSection
                }
                .padding(.horizontal, SlangSpacing.lg)
                .padding(.top, SlangSpacing.lg)
                .padding(.bottom, SlangSpacing.xxl)
            }
            .background(SlangColor.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "info.sheet.done", defaultValue: "Done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(SlangColor.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(SlangColor.background)
    }

    // MARK: - Sections

    private var termHeader: some View {
        VStack(alignment: .leading, spacing: SlangSpacing.sm) {
            Text(term.term.lowercased())
                .font(.slangTerm(size: 44))
                .foregroundStyle(.primary)

            if let tag = posTag {
                tagChip(tag)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var definitionSection: some View {
        infoSection(label: String(localized: "info.sheet.definition", defaultValue: "definition")) {
            Text(cleanDefinition)
                .font(.slangDefinition(size: 18))
                .foregroundStyle(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var exampleSection: some View {
        if !term.exampleSentence.isEmpty {
            infoSection(label: String(localized: "info.sheet.example", defaultValue: "example")) {
                Text("\u{201C}\(term.exampleSentence)\u{201D}")
                    .font(.slangDefinition(size: 17))
                    .foregroundStyle(.primary.opacity(0.6))
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var standardEnglishSection: some View {
        if !term.standardEnglish.isEmpty {
            infoSection(label: String(localized: "info.sheet.standardEnglish", defaultValue: "standard english")) {
                Text(term.standardEnglish)
                    .font(.slangDefinition(size: 17))
                    .foregroundStyle(.primary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var originSection: some View {
        if !term.origin.isEmpty {
            infoSection(label: String(localized: "info.sheet.origin", defaultValue: "origin")) {
                Text(term.origin)
                    .font(.slangDefinition(size: 17))
                    .foregroundStyle(.primary.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var categoryAndUsageRow: some View {
        HStack(alignment: .top, spacing: SlangSpacing.xl) {
            infoSection(label: String(localized: "info.sheet.category", defaultValue: "category")) {
                tagChip(term.category.displayName)
            }
            infoSection(label: String(localized: "info.sheet.usage", defaultValue: "usage")) {
                tagChip(term.usageFrequency.rawValue)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var generationSection: some View {
        if !term.generationTags.isEmpty {
            infoSection(label: String(localized: "info.sheet.generation", defaultValue: "generation")) {
                HStack(spacing: SlangSpacing.sm) {
                    ForEach(term.generationTags, id: \.rawValue) { tag in
                        tagChip(tag.rawValue)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Splits the `"(adj.) Some definition"` format into a POS tag and clean definition.
    private var posTag: String? {
        guard term.definition.hasPrefix("("),
              let endIdx = term.definition.firstIndex(of: ")") else { return nil }
        return String(term.definition[term.definition.index(after: term.definition.startIndex)..<endIdx])
    }

    private var cleanDefinition: String {
        guard term.definition.hasPrefix("("),
              let endIdx = term.definition.firstIndex(of: ")") else { return term.definition }
        return String(term.definition[term.definition.index(after: endIdx)...])
            .trimmingCharacters(in: .whitespaces)
    }

    @ViewBuilder
    private func infoSection<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: SlangSpacing.xs) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .tracking(2)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func tagChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundStyle(SlangColor.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                SlangColor.primary.opacity(0.12),
                in: RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
            )
    }
}

// MARK: - Preview

#Preview("TermInfoSheet") {
    Color.clear.sheet(isPresented: .constant(true)) {
        TermInfoSheet(term: SlangTerm(
            id: UUID(),
            term: "rizz",
            definition: "(n.) Natural charm or ability to attract others, especially romantically.",
            standardEnglish: "charisma",
            exampleSentence: "Bro walked in and had instant rizz — everyone was locked in.",
            category: .foundationalDescriptor,
            origin: "Derived from 'charisma'. Popularized by Kai Cenat on Twitch.",
            usageFrequency: .high,
            generationTags: [.genZ, .genAlpha],
            addedDate: Date(),
            isBrainrot: false,
            isEmojiTerm: false
        ))
    }
}
