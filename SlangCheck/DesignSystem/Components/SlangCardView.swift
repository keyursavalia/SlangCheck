// DesignSystem/Components/SlangCardView.swift
// SlangCheck
//
// The flashcard component used in the Swiper. Supports tap-to-flip (3D Y-axis),
// drag gesture for swipe detection, and SAVE/SKIP action labels.
// Per DESIGN_SYSTEM.md §7.1 and §6.4. No third-party libraries.

import SwiftUI

// MARK: - SlangCardView

/// A single flashcard displaying a slang term. Tap to flip. Drag to swipe.
/// The gesture offsets and rotation are derived from `dragOffset` provided by the parent.
public struct SlangCardView: View {

    // MARK: Properties

    let term: SlangTerm

    /// Whether this card is currently showing the definition (flipped).
    let isFlipped: Bool

    /// The current drag translation. Provided by parent `SwiperView`.
    let dragOffset: CGSize

    /// Whether this is the top card (interactive) or a background card (decorative).
    let isTopCard: Bool

    // MARK: - Computed Visual Properties (DESIGN_SYSTEM.md §6.4)

    private var rotationAngle: Double {
        guard isTopCard else { return 0 }
        let screenWidth = UIScreen.main.bounds.width
        return (dragOffset.width / screenWidth) * AppConstants.swiperMaxRotationDegrees
    }

    private var cardOpacity: Double {
        guard isTopCard else { return 1.0 }
        let screenWidth = UIScreen.main.bounds.width
        let progress = abs(dragOffset.width) / screenWidth
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

    // MARK: - Body

    public var body: some View {
        ZStack {
            if isFlipped {
                backFace
            } else {
                frontFace
            }
        }
        .rotation3DEffect(.degrees(isFlipped ? 0 : 0), axis: (x: 0, y: 1, z: 0))
        .overlay(actionLabels)
        .rotationEffect(.degrees(rotationAngle))
        .offset(x: isTopCard ? dragOffset.width : 0,
                y: isTopCard ? dragOffset.height * 0.1 : AppConstants.swiperBackCardOffset)
        .scaleEffect(isTopCard ? 1.0 : AppConstants.swiperBackCardIdleScale)
        .opacity(cardOpacity)
    }

    // MARK: - Front Face (Term)

    private var frontFace: some View {
        VStack(spacing: SlangSpacing.lg) {
            Spacer()

            VStack(spacing: SlangSpacing.md) {
                categoryLabel
                Text(term.term)
                    .font(.slang(.title))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SlangSpacing.md)
            }

            tapHint

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassCard()
    }

    // MARK: - Back Face (Definition)

    private var backFace: some View {
        VStack(spacing: SlangSpacing.lg) {
            Spacer()

            VStack(spacing: SlangSpacing.md) {
                Text(term.term)
                    .font(.slang(.subheading))
                    .foregroundStyle(SlangColor.primary)

                Text(term.definition)
                    .font(.slang(.body))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .slangBodySpacing()
                    .padding(.horizontal, SlangSpacing.md)

                if !term.exampleSentence.isEmpty {
                    Text("\u{201C}\(term.exampleSentence)\u{201D}")
                        .font(.slang(.caption))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .italic()
                        .padding(.horizontal, SlangSpacing.md)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassCard()
    }

    // MARK: - Action Labels (SAVE / SKIP)

    private var actionLabels: some View {
        HStack {
            // SAVE label (right swipe)
            Text(String(localized: "swiper.action.save", defaultValue: "SAVE"))
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(SlangColor.secondary)
                .padding(SlangSpacing.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: SlangSpacing.xs)
                        .stroke(SlangColor.secondary, lineWidth: 2.5)
                )
                .rotationEffect(.degrees(-15))
                .opacity(saveOpacity)
                .accessibilityHidden(true)

            Spacer()

            // SKIP label (left swipe)
            Text(String(localized: "swiper.action.skip", defaultValue: "SKIP"))
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(SlangColor.accent)
                .padding(SlangSpacing.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: SlangSpacing.xs)
                        .stroke(SlangColor.accent, lineWidth: 2.5)
                )
                .rotationEffect(.degrees(15))
                .opacity(skipOpacity)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, SlangSpacing.xl)
        .padding(.top, SlangSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Supporting Sub-Views

    private var categoryLabel: some View {
        Text(term.category.displayName.uppercased())
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(SlangColor.primary)
            .tracking(1.2)
            .accessibilityLabel(
                String(localized: "swiper.card.category \(term.category.displayName)",
                       defaultValue: "Category: \(term.category.displayName)")
            )
    }

    private var tapHint: some View {
        HStack(spacing: SlangSpacing.xs) {
            Image(systemName: "hand.tap")
                .font(.system(size: 13))
                .accessibilityHidden(true)
            Text(String(localized: "swiper.card.tapToFlip", defaultValue: "Tap to reveal definition"))
                .font(.slang(.caption))
        }
        .foregroundStyle(Color(.tertiaryLabel))
    }
}

// MARK: - Preview

#Preview("SlangCardView — Front") {
    let term = SlangTerm(
        id: UUID(),
        term: "Rizz",
        definition: "Short for charisma; the ability to charm or flirt successfully.",
        standardEnglish: "Charisma / Charm",
        exampleSentence: "He's got mad rizz — everyone loves him.",
        category: .relationship,
        origin: "Shortened from 'charisma'",
        usageFrequency: .high,
        generationTags: [.genZ],
        addedDate: Date(),
        isBrainrot: false,
        isEmojiTerm: false
    )
    SlangCardView(
        term: term,
        isFlipped: false,
        dragOffset: .zero,
        isTopCard: true
    )
    .frame(width: 340, height: 480)
    .padding()
    .background(SlangColor.background)
}
