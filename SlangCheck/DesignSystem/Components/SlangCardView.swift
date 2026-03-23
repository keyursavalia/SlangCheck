// DesignSystem/Components/SlangCardView.swift
// SlangCheck
//
// SlangCardView (flip-card design) is commented out.
// The Swiper tab now uses a full-screen term layout — see SwiperView.swift.

import SwiftUI

/*
// MARK: - SlangCardView [COMMENTED OUT — replaced by full-screen term layout]
//
// The 3D flip card (front face / back face / rotation3DEffect) has been
// superseded by a full-screen single-face layout in SwiperContentView.
// Preserved here for reference. Do not delete until the new design is stable.

public struct SlangCardView: View {

    let term: SlangTerm
    let isFlipped: Bool
    let dragOffset: CGSize
    let isTopCard: Bool

    private var swipeUpProgress: Double {
        guard isTopCard else { return 0 }
        return min(1, max(0, -dragOffset.height / 120))
    }

    private var cardOpacity: Double {
        guard isTopCard else { return 1.0 }
        return 1.0 - (swipeUpProgress * 0.45)
    }

    private var glowIntensity: Double {
        guard isTopCard else { return 0 }
        return isFlipped ? 0.7 : swipeUpProgress * 0.9
    }

    private var cardBackground: Color { SlangColor.cardSurface }

    private var tagLabels: [String] {
        var tags: [String] = []
        for tag in term.generationTags {
            tags.append(tag == .genZ ? "Gen Z" : "Gen Alpha")
        }
        if term.isBrainrot { tags.append("Brainrot") }
        if term.isEmojiTerm { tags.append("Emoji") }
        return tags
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: SlangCornerRadius.card).fill(cardBackground)
            frontFace
                .rotation3DEffect(.degrees(isFlipped ? -90 : 0), axis: (x:0,y:1,z:0), anchor:.center, perspective:0.4)
                .opacity(isFlipped ? 0 : 1)
            backFace
                .rotation3DEffect(.degrees(isFlipped ? 0 : 90), axis: (x:0,y:1,z:0), anchor:.center, perspective:0.4)
                .opacity(isFlipped ? 1 : 0)
        }
        .offset(x:0, y: isTopCard ? (dragOffset.height < 0 ? dragOffset.height : dragOffset.height * 0.15) : AppConstants.swiperBackCardOffset)
        .scaleEffect(isTopCard ? 1.0 : AppConstants.swiperBackCardIdleScale)
        .opacity(cardOpacity)
        .shadow(color: SlangColor.secondary.opacity(glowIntensity * 0.80), radius: 8,  x: 0, y: 0)
        .shadow(color: SlangColor.secondary.opacity(glowIntensity * 0.40), radius: 24, x: 0, y: 0)
        .shadow(color: SlangColor.secondary.opacity(glowIntensity * 0.15), radius: 50, x: 0, y: 0)
    }

    private var frontFace: some View {
        VStack(spacing: 0) {
            Spacer()
            Text(term.term)
                .font(.slangTerm(size: 54))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
            tapHint.frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(SlangSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: SlangCornerRadius.card).fill(cardBackground))
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.card))
        .overlay(RoundedRectangle(cornerRadius: SlangCornerRadius.card).strokeBorder(SlangColor.primary.opacity(0.18), lineWidth: 1))
    }

    private var backFace: some View {
        VStack(alignment: .leading, spacing: SlangSpacing.md) {
            categoryChip
            Text(term.term)
                .font(.slangTerm(size: 44))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(SlangColor.accent.opacity(0.55)).frame(height: 1)
            Text(term.definition)
                .font(.slangDefinition(size: 17))
                .foregroundStyle(.primary.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
            if !term.exampleSentence.isEmpty {
                Text("\u{201C}\(term.exampleSentence)\u{201D}")
                    .font(.slangDefinition(size: 15))
                    .foregroundStyle(SlangColor.accent.opacity(0.85))
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, SlangSpacing.sm + 4)
                    .background(Rectangle().fill(SlangColor.accent).frame(width:2).cornerRadius(1), alignment:.leading)
            }
            Spacer(minLength: 0)
            if !term.origin.isEmpty {
                HStack(alignment: .top, spacing: SlangSpacing.xs) {
                    Image(systemName: "clock").font(.system(size:11)).foregroundStyle(.primary.opacity(0.40)).padding(.top,1).accessibilityHidden(true)
                    Text(term.origin).font(.system(size:13,design:.monospaced)).foregroundStyle(.primary.opacity(0.45)).fixedSize(horizontal:false,vertical:true).lineLimit(2)
                }
            }
            if !tagLabels.isEmpty { tagChips }
        }
        .padding(SlangSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: SlangCornerRadius.card).fill(cardBackground))
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.card))
        .overlay(RoundedRectangle(cornerRadius: SlangCornerRadius.card).strokeBorder(SlangColor.secondary.opacity(0.45), lineWidth: 1.5))
    }

    private var categoryChip: some View {
        Text(term.category.displayName.uppercased())
            .font(.system(size:10,weight:.semibold,design:.monospaced)).tracking(1.5)
            .foregroundStyle(SlangColor.accent)
            .padding(.horizontal, SlangSpacing.sm).padding(.vertical, SlangSpacing.xs)
            .overlay(RoundedRectangle(cornerRadius: SlangCornerRadius.chip).strokeBorder(SlangColor.accent.opacity(0.65), lineWidth:1))
            .accessibilityLabel("Category: \(term.category.displayName)")
    }

    private var tapHint: some View {
        HStack(spacing: SlangSpacing.xs) {
            Image(systemName: "hand.tap").font(.system(size:13)).accessibilityHidden(true)
            Text(String(localized:"swiper.card.tapToFlip",defaultValue:"Tap to reveal definition")).font(.system(size:12,design:.monospaced))
        }
        .foregroundStyle(.primary.opacity(0.35))
    }

    private var tagChips: some View {
        HStack(spacing: SlangSpacing.xs) {
            Text("Tags:").font(.system(size:11,weight:.medium,design:.monospaced)).foregroundStyle(.primary.opacity(0.40))
            ForEach(tagLabels, id:\.self) { tag in
                Text(tag).font(.system(size:11,weight:.semibold,design:.monospaced)).foregroundStyle(SlangColor.accent)
                    .padding(.horizontal,SlangSpacing.sm).padding(.vertical,SlangSpacing.xs)
                    .overlay(RoundedRectangle(cornerRadius:SlangCornerRadius.chip).strokeBorder(SlangColor.accent.opacity(0.60),lineWidth:1))
            }
        }
    }
}

#Preview("SlangCardView") {
    let term = SlangTerm(id:UUID(),term:"Extra",definition:"Over the top, excessively dramatic behavior.",standardEnglish:"Overdramatic",exampleSentence:"She showed up in a ballgown — so extra.",category:.foundationalDescriptor,origin:"AAVE / 2000s",usageFrequency:.high,generationTags:[.genZ],addedDate:Date(),isBrainrot:false,isEmojiTerm:false)
    VStack(spacing:24) {
        SlangCardView(term:term,isFlipped:false,dragOffset:.zero,isTopCard:true).frame(height:480)
        SlangCardView(term:term,isFlipped:true,dragOffset:.zero,isTopCard:true).frame(height:480)
    }
    .padding(.horizontal,24).background(SlangColor.background)
}
*/
