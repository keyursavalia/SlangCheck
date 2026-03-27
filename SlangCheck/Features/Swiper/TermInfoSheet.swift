// Features/Swiper/TermInfoSheet.swift
// SlangCheck
//
// Full-screen detail sheet for a slang term.
// Opens directly at large detent. POS abbreviations are expanded to full words.

import SwiftUI

// MARK: - TermInfoSheet

struct TermInfoSheet: View {

    let term: SlangTerm
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    termHeader
                        .padding(.bottom, SlangSpacing.sm)

                    Divider()
                        .overlay(SlangColor.separator)
                        .padding(.bottom, SlangSpacing.lg)

                    definitionSection
                        .padding(.bottom, SlangSpacing.xl)

                    exampleSection
                    standardEnglishSection
                    originSection
                    metaInfoRow
                }
                .padding(.horizontal, SlangSpacing.lg)
                .padding(.top, SlangSpacing.md)
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
        // Opens directly at large detent — skip the half-screen intermediate step.
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(SlangColor.background)
    }

    // MARK: - Header

    private var termHeader: some View {
        VStack(alignment: .leading, spacing: SlangSpacing.xs) {
            Text(term.term.lowercased())
                .font(.slangTerm(size: 46))
                .foregroundStyle(.primary)

            if !term.partOfSpeechFull.isEmpty {
                tagChip(term.partOfSpeechFull)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sections

    private var definitionSection: some View {
        infoSection(label: String(localized: "info.sheet.definition", defaultValue: "definition")) {
            Text(term.definition)
                .font(.slangDefinition(size: 20))
                .foregroundStyle(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var exampleSection: some View {
        if !term.exampleSentence.isEmpty {
            infoSection(label: String(localized: "info.sheet.example", defaultValue: "example")) {
                Text("\u{201C}\(term.exampleSentence)\u{201D}")
                    .font(.slangDefinition(size: 19))
                    .foregroundStyle(.primary.opacity(0.6))
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, SlangSpacing.xl)
        }
    }

    @ViewBuilder
    private var standardEnglishSection: some View {
        if !term.standardEnglish.isEmpty {
            infoSection(label: String(localized: "info.sheet.standardEnglish", defaultValue: "standard english")) {
                Text(term.standardEnglish)
                    .font(.slangDefinition(size: 19))
                    .foregroundStyle(.primary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, SlangSpacing.xl)
        }
    }

    @ViewBuilder
    private var originSection: some View {
        if !term.origin.isEmpty {
            infoSection(label: String(localized: "info.sheet.origin", defaultValue: "origin")) {
                Text(term.origin)
                    .font(.slangDefinition(size: 19))
                    .foregroundStyle(.primary.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, SlangSpacing.xl)
        }
    }

    /// Category, usage, and generation on a single horizontal row.
    private var metaInfoRow: some View {
        HStack(alignment: .top, spacing: SlangSpacing.xl) {
            VStack(alignment: .leading, spacing: SlangSpacing.xs) {
                Text(String(localized: "info.sheet.category", defaultValue: "category").uppercased())
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                tagChip(term.category.displayName)
            }

            VStack(alignment: .leading, spacing: SlangSpacing.xs) {
                Text(String(localized: "info.sheet.usage", defaultValue: "usage").uppercased())
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                tagChip(term.usageFrequency.rawValue)
            }

            if !term.generationTags.isEmpty {
                VStack(alignment: .leading, spacing: SlangSpacing.xs) {
                    Text(String(localized: "info.sheet.generation", defaultValue: "generation").uppercased())
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: SlangSpacing.xs) {
                        ForEach(term.generationTags, id: \.rawValue) { tag in
                            tagChip(tag.rawValue)
                        }
                    }
                }
            }

            Spacer()
        }
    }


    // MARK: - Layout Helpers

    @ViewBuilder
    private func infoSection<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: SlangSpacing.xs) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .tracking(2)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func tagChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold, design: .monospaced))
            .foregroundStyle(SlangColor.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
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
