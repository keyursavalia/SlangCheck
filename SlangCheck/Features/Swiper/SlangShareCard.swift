// Features/Swiper/SlangShareCard.swift
// SlangCheck
//
// A fixed-size card rendered via ImageRenderer for the iOS share sheet.
// This view is not interactive — it exists solely as a snapshot target.

import SwiftUI
import UIKit

// MARK: - SlangShareCard

/// A fixed-size card view that visually presents a slang term for sharing.
/// Use `SlangShareCard.share(term:)` to render and present the iOS share sheet.
struct SlangShareCard: View {

    let term: SlangTerm

    // MARK: - Body

    var body: some View {
        ZStack {
            SlangColor.background

            VStack(alignment: .leading, spacing: 0) {

                // ── App header ───────────────────────────────────
                HStack(alignment: .firstTextBaseline) {
                    Text("SLANGCHECK")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(2.5)
                        .foregroundStyle(SlangColor.primary)
                    Spacer()
                    if !term.partOfSpeechShort.isEmpty {
                        Text("(\(term.partOfSpeechShort))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(SlangColor.primary.opacity(0.65))
                    }
                }

                Spacer()

                // ── Term ─────────────────────────────────────────
                Text(term.term.lowercased())
                    .font(.slangTerm(size: 52))
                    .foregroundStyle(.primary)
                    .padding(.bottom, 14)

                // ── Definition ───────────────────────────────────
                Text(term.definition)
                    .font(.slangDefinition(size: 18))
                    .foregroundStyle(.primary.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)

                // ── Example ──────────────────────────────────────
                if !term.exampleSentence.isEmpty {
                    Text("\u{201C}\(term.exampleSentence)\u{201D}")
                        .font(.slangDefinition(size: 15))
                        .foregroundStyle(.primary.opacity(0.50))
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)
                }

                Spacer()

                // ── Footer ───────────────────────────────────────
                Text("slangcheck.app")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.primary.opacity(0.30))
            }
            .padding(32)
        }
        .frame(width: 375, height: 480)
    }

}

// MARK: - Share Action

extension SlangShareCard {

    /// Renders the card for `term` as a high-resolution `UIImage` and presents
    /// the native iOS share sheet from the current key window's root view controller.
    @MainActor
    static func share(term: SlangTerm) {
        let card = SlangShareCard(term: term)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0   // @3x for crisp rendering on all devices
        guard let image = renderer.uiImage else { return }

        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)

        // Locate the key window's root view controller to present from
        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first(where: \.isKeyWindow)?
            .rootViewController

        // Walk up to the topmost presented controller to avoid "already presenting" errors
        var presenter = rootVC
        while let presented = presenter?.presentedViewController {
            presenter = presented
        }
        presenter?.present(vc, animated: true)
    }
}

// MARK: - Preview

#Preview("SlangShareCard") {
    SlangShareCard(term: SlangTerm(
        id: UUID(),
        term: "rizz",
        partOfSpeechShort: "n.",
        partOfSpeechFull: "noun",
        definition: "Natural charm or ability to attract others, especially romantically.",
        standardEnglish: "charisma",
        exampleSentence: "Bro walked in and had instant rizz — everyone was locked in.",
        category: .foundationalDescriptor,
        origin: "Derived from 'charisma'.",
        usageFrequency: .high,
        generationTags: [.genZ, .genAlpha],
        addedDate: Date(),
        isBrainrot: false,
        isEmojiTerm: false
    ))
}
