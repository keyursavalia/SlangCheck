// DesignSystem/Components/SlangCardView.swift
// SlangCheck
//
// Neon Tokyo-themed flashcard. Always-dark card background with a triple-layer
// neon green glow border that ignites when the definition face is revealed.
// True 3D flip via rotation3DEffect (FR-S-004). No third-party libraries.

import SwiftUI

// MARK: - SlangCardView

/// A single flashcard for the Swiper tab. Tap to flip (3D rotation). Drag to swipe.
///
/// **Front face** — category chip + giant term + subtle "tap to reveal" hint.
/// **Back face**  — full definition, example (blockquote), origin + neon green glow border.
public struct SlangCardView: View {

    // MARK: Properties

    let term: SlangTerm
    let isFlipped: Bool
    let dragOffset: CGSize
    let isTopCard: Bool

    // MARK: - Computed Visual Properties

    private var rotationAngle: Double {
        guard isTopCard else { return 0 }
        return (dragOffset.width / UIScreen.main.bounds.width) * AppConstants.swiperMaxRotationDegrees
    }

    private var cardOpacity: Double {
        guard isTopCard else { return 1.0 }
        let progress = abs(dragOffset.width) / UIScreen.main.bounds.width
        return 1.0 - (progress * (1.0 - AppConstants.swiperMinCardOpacity))
    }

    private var saveOpacity: Double {
        guard isTopCard else { return 0 }
        return max(0, dragOffset.width / 80)
    }

    private var skipOpacity: Double {
        guard isTopCard else { return 0 }
        return max(0, -dragOffset.width / 80)
    }

    /// The card is always dark regardless of system theme — neon accents require a dark canvas.
    private var cardBackground: Color {
        Color(UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(hex: "0D0D1A")
                : UIColor(hex: "141033")
        })
    }

    /// Tag labels derived from the term's generation tags and boolean properties.
    private var tagLabels: [String] {
        var tags: [String] = []
        for tag in term.generationTags {
            tags.append(tag == .genZ ? "Gen Z" : "Gen Alpha")
        }
        if term.isBrainrot { tags.append("Brainrot") }
        if term.isEmojiTerm { tags.append("Emoji") }
        return tags
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Opaque base — always fully visible, blocks the card beneath from
            // bleeding through while both faces are semi-transparent mid-flip.
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .fill(cardBackground)

            // Front face: rotates away to -90° (edge-on) when flipping
            frontFace
                .rotation3DEffect(
                    .degrees(isFlipped ? -90 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .center,
                    perspective: 0.4
                )
                .opacity(isFlipped ? 0 : 1)

            // Back face: enters from +90° (edge-on) when flipping
            backFace
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : 90),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .center,
                    perspective: 0.4
                )
                .opacity(isFlipped ? 1 : 0)
        }
        // No clipShape here — each face clips itself. A clipShape at this level
        // would cut off all shadow/glow modifiers applied below.
        .overlay(actionLabels)
        .rotationEffect(.degrees(rotationAngle))
        .offset(
            x: isTopCard ? dragOffset.width : 0,
            y: isTopCard ? dragOffset.height * 0.1 : AppConstants.swiperBackCardOffset
        )
        .scaleEffect(isTopCard ? 1.0 : AppConstants.swiperBackCardIdleScale)
        .opacity(cardOpacity)
        // Unified glow — tight inner bloom → mid → wide ambient
        .shadow(color: cardGlowColor.opacity(cardGlowIntensity * 0.85), radius: 8,  x: 0, y: 0)
        .shadow(color: cardGlowColor.opacity(cardGlowIntensity * 0.40), radius: 24, x: 0, y: 0)
        .shadow(color: cardGlowColor.opacity(cardGlowIntensity * 0.15), radius: 50, x: 0, y: 0)
    }

    // MARK: - Glow Helpers

    /// Amber when the user drags left (skip); green for everything else.
    private var cardGlowColor: Color {
        guard isTopCard else { return .clear }
        return skipOpacity > 0 ? SlangColor.accent : SlangColor.secondary
    }

    /// Back face glows permanently at full intensity; front face scales with drag amount.
    private var cardGlowIntensity: Double {
        guard isTopCard else { return 0 }
        if isFlipped { return 1.0 }
        return min(1, max(saveOpacity, skipOpacity))
    }

    // MARK: - Front Face (Term Only)

    private var frontFace: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(term.term)
                .font(.system(size: 54, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            tapHint
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(SlangSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .fill(cardBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Back Face (Definition + Neon Green Glow)

    private var backFace: some View {
        VStack(alignment: .leading, spacing: SlangSpacing.md) {
            categoryChip

            // Term — large and prominent on the revealed face
            Text(term.term)
                .font(.system(size: 44, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Neon separator line below term
            Rectangle()
                .fill(SlangColor.secondary.opacity(0.55))
                .frame(height: 1)

            // Definition — full text, no truncation
            Text(term.definition)
                .font(.slang(.body))
                .foregroundStyle(.white.opacity(0.88))
                .slangBodySpacing()
                .fixedSize(horizontal: false, vertical: true)

            // Example — blockquote: green left bar as background so it never grows taller than the text
            if !term.exampleSentence.isEmpty {
                Text("\u{201C}\(term.exampleSentence)\u{201D}")
                    .font(.slang(.caption))
                    .foregroundStyle(SlangColor.secondary.opacity(0.75))
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, SlangSpacing.sm + 4)
                    .background(
                        Rectangle()
                            .fill(SlangColor.secondary)
                            .frame(width: 2)
                            .cornerRadius(1),
                        alignment: .leading
                    )
            }

            Spacer(minLength: 0)

            // Origin — icon + muted monospaced label, wraps to 2 lines for long text
            if !term.origin.isEmpty {
                HStack(alignment: .top, spacing: SlangSpacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.35))
                        .padding(.top, 1)
                        .accessibilityHidden(true)
                    Text(term.origin)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.40))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                }
            }

            // Tags pinned to bottom
            if !tagLabels.isEmpty {
                tagChips
            }
        }
        .padding(SlangSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .fill(cardBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.card))
        // Border reacts to swipe direction: amber on left drag, green otherwise
        .overlay(
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .strokeBorder(cardGlowColor, lineWidth: 1.5)
        )
    }

    // MARK: - Action Labels (SAVE / SKIP Stamps)

    private var actionLabels: some View {
        HStack {
            // SAVE stamp — appears during right-swipe, centered over the term
            stampLabel(
                text: String(localized: "swiper.action.save", defaultValue: "SAVE"),
                color: SlangColor.secondary,
                rotation: -15
            )
            .opacity(saveOpacity)
            .accessibilityHidden(true)

            Spacer()

            // SKIP stamp — appears during left-swipe, centered over the term
            stampLabel(
                text: String(localized: "swiper.action.skip", defaultValue: "SKIP"),
                color: SlangColor.accent,
                rotation: 15
            )
            .opacity(skipOpacity)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, SlangSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func stampLabel(text: String, color: Color, rotation: Double) -> some View {
        Text(text)
            .font(.system(size: 34, weight: .black, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, SlangSpacing.md)
            .padding(.vertical, SlangSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(color, lineWidth: 2.5)
                    )
            )
            .rotationEffect(.degrees(rotation))
    }

    // MARK: - Supporting Sub-Views

    private var categoryChip: some View {
        Text(term.category.displayName.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(1.5)
            .foregroundStyle(SlangColor.secondary)
            .padding(.horizontal, SlangSpacing.sm)
            .padding(.vertical, SlangSpacing.xs)
            .overlay(
                RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                    .strokeBorder(SlangColor.secondary.opacity(0.65), lineWidth: 1)
            )
            .accessibilityLabel("Category: \(term.category.displayName)")
    }

    private var tapHint: some View {
        HStack(spacing: SlangSpacing.xs) {
            Image(systemName: "hand.tap")
                .font(.system(size: 13))
                .accessibilityHidden(true)
            Text(String(localized: "swiper.card.tapToFlip", defaultValue: "Tap to reveal definition"))
                .font(.system(size: 12, design: .monospaced))
        }
        .foregroundStyle(.white.opacity(0.30))
    }

    private var tagChips: some View {
        HStack(spacing: SlangSpacing.xs) {
            Text("Tags:")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))

            ForEach(tagLabels, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(SlangColor.secondary)
                    .padding(.horizontal, SlangSpacing.sm)
                    .padding(.vertical, SlangSpacing.xs)
                    .overlay(
                        RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                            .strokeBorder(SlangColor.secondary.opacity(0.60), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview("SlangCardView — Front") {
    let term = SlangTerm(
        id: UUID(),
        term: "Extra",
        definition: "Over the top, excessively dramatic behavior. Doing significantly more than what is required or expected.",
        standardEnglish: "Overdramatic / Excessive",
        exampleSentence: "She showed up to a casual dinner in a ballgown — so extra.",
        category: .foundationalDescriptor,
        origin: "AAVE / 2000s Pop Culture",
        usageFrequency: .high,
        generationTags: [.genZ],
        addedDate: Date(),
        isBrainrot: false,
        isEmojiTerm: false
    )
    VStack(spacing: 24) {
        SlangCardView(term: term, isFlipped: false, dragOffset: .zero, isTopCard: true)
            .frame(height: 480)
        SlangCardView(term: term, isFlipped: true, dragOffset: .zero, isTopCard: true)
            .frame(height: 480)
    }
    .padding(.horizontal, 24)
    .background(SlangColor.background)
}
