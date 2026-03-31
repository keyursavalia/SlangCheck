// Features/Quizzes/AuraCardView.swift
// SlangCheck
//
// Shareable Aura Card — a fixed-size decorative card rendered to UIImage
// via ImageRenderer and shared via ShareLink.
//
// Design contract:
// - Always renders in the "Chill & Cozy" dark palette so the card looks
//   identical on any device regardless of the system appearance setting.
// - Uses explicit concrete colors (never .ultraThinMaterial / adaptive tokens)
//   because ImageRenderer requires non-dynamic fill values to snapshot correctly.
// - Q-004: display name is rendered prominently on the card.

import SwiftUI
import UniformTypeIdentifiers

// MARK: - AuraCardView

/// The visual design of the shareable Aura Card.
///
/// Rendered to a `UIImage` by `AuraCardView.render(for:)` and shared
/// via `ShareLink` — no third-party SDKs used.
struct AuraCardView: View {

    let profile: AuraProfile

    // MARK: - Fixed Dimensions

    /// The exported card's point dimensions. `render(for:)` uses these.
    static let cardWidth:  CGFloat = 360
    static let cardHeight: CGFloat = 480

    // MARK: - Concrete palette constants
    // These are explicit concrete values for ImageRenderer — do NOT replace
    // with adaptive SlangColor tokens, which resolve to dynamic UIColors that
    // ImageRenderer cannot snapshot reliably.

    /// Deep warm charcoal — card background start (#1F1F1F)
    private static let bgStart   = Color(red: 0.122, green: 0.122, blue: 0.122)
    /// Warm near-black — card background end (#272420)
    private static let bgEnd     = Color(red: 0.153, green: 0.141, blue: 0.125)
    /// Warm cream text / off-white (#F0E8DC)
    private static let creamText = Color(red: 0.941, green: 0.910, blue: 0.863)
    /// Muted warm cream divider (#5A5248)
    private static let divider   = Color(red: 0.353, green: 0.322, blue: 0.282)

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer
            decorativeLayer
            contentLayer
        }
        .frame(width: Self.cardWidth, height: Self.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.card))
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [Self.bgStart, Self.bgEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Decorative Layer

    private var decorativeLayer: some View {
        ZStack {
            // Warm radial glow behind the tier badge
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tierColor.opacity(0.18), tierColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .offset(y: -50)

            // Subtle warm grain texture (dot grid)
            Canvas { context, size in
                let spacing: CGFloat = 24
                let dotRadius: CGFloat = 1.0
                var x: CGFloat = spacing
                while x < size.width {
                    var y: CGFloat = spacing
                    while y < size.height {
                        let rect = CGRect(
                            x: x - dotRadius, y: y - dotRadius,
                            width: dotRadius * 2, height: dotRadius * 2
                        )
                        context.fill(Path(ellipseIn: rect),
                                     with: .color(Self.creamText.opacity(0.05)))
                        y += spacing
                    }
                    x += spacing
                }
            }

            // Warm top-left corner accent arc
            Circle()
                .strokeBorder(tierColor.opacity(0.12), lineWidth: 60)
                .frame(width: 220, height: 220)
                .offset(x: -140, y: -160)
        }
    }

    // MARK: - Content

    private var contentLayer: some View {
        VStack(spacing: 0) {
            brandHeader
                .padding(.top, SlangSpacing.lg)
                .padding(.horizontal, SlangSpacing.lg)

            Spacer()

            tierBadge

            Spacer()

            Self.divider
                .frame(height: 0.5)
                .padding(.horizontal, SlangSpacing.xl)

            Spacer()

            userInfo

            Spacer()

            cardFooter
                .padding(.bottom, SlangSpacing.lg)
                .padding(.horizontal, SlangSpacing.lg)
        }
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        HStack {
            HStack(spacing: SlangSpacing.xs) {
                // Warm square brand mark
                RoundedRectangle(cornerRadius: 4)
                    .fill(tierColor)
                    .frame(width: 16, height: 16)
                Text("SlangCheck")
                    .font(.montserrat(size: 13, weight: .semibold))
                    .foregroundStyle(Self.creamText.opacity(0.70))
                    .tracking(0.5)
            }

            Spacer()

            // Tier label pill
            Text(profile.currentTier.displayName.uppercased())
                .font(.montserrat(size: 10, weight: .semibold))
                .foregroundStyle(tierColor)
                .tracking(1.2)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(tierColor.opacity(0.14))
                )
        }
    }

    // MARK: - Tier Badge

    private var tierBadge: some View {
        VStack(spacing: SlangSpacing.sm) {
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(tierColor.opacity(0.25), lineWidth: 1.5)
                    .frame(width: 96, height: 96)

                // Inner warm fill
                Circle()
                    .fill(tierColor.opacity(0.12))
                    .frame(width: 96, height: 96)

                // Tier icon
                Image(systemName: tierSymbol)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(tierColor)
                    .accessibilityHidden(true)
            }

            Text(profile.currentTier.displayName)
                .font(.montserrat(size: 26, weight: .bold))
                .foregroundStyle(Self.creamText)
                .tracking(1.5)

            Text(profile.currentTier.subtitle)
                .font(.montserrat(size: 12, weight: .regular))
                .foregroundStyle(Self.creamText.opacity(0.45))
                .tracking(0.3)
        }
    }

    // MARK: - User Info

    private var userInfo: some View {
        VStack(spacing: SlangSpacing.xs) {
            Text(profile.displayName)
                .font(.montserrat(size: 22, weight: .bold))
                .foregroundStyle(Self.creamText)

            HStack(spacing: SlangSpacing.xs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(tierColor)
                    .accessibilityHidden(true)
                Text("\(profile.totalPoints) pts")
                    .font(.montserrat(size: 15, weight: .semibold))
                    .foregroundStyle(tierColor)
            }
        }
    }

    // MARK: - Footer

    private var cardFooter: some View {
        HStack {
            Text("slangcheck.app")
                .font(.montserrat(size: 11, weight: .regular))
                .foregroundStyle(Self.creamText.opacity(0.25))
                .tracking(0.3)

            Spacer()

            if profile.streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(tierColor.opacity(0.80))
                        .accessibilityHidden(true)
                    Text("\(profile.streak)d streak")
                        .font(.montserrat(size: 11, weight: .medium))
                        .foregroundStyle(Self.creamText.opacity(0.45))
                }
            }
        }
    }

    // MARK: - Tier Helpers

    /// Per-tier accent colours — warm, muted, cohesive with the Chill & Cozy palette.
    private var tierColor: Color {
        switch profile.currentTier {
        case .unc:
            // Warm silver-taupe
            return Color(red: 0.722, green: 0.667, blue: 0.608)
        case .lurk:
            // Warm amber
            return Color(red: 0.816, green: 0.643, blue: 0.290)
        case .auraFarmer:
            // Dusty periwinkle — mirrors the secondary token in the dark palette
            return Color(red: 0.729, green: 0.784, blue: 0.878)
        case .rizzler:
            // Warm sand — mirrors the primary token in the dark palette, premium feel
            return Color(red: 0.816, green: 0.745, blue: 0.639)
        }
    }

    private var tierSymbol: String {
        switch profile.currentTier {
        case .unc:        return "figure.stand"
        case .lurk:       return "eye.fill"
        case .auraFarmer: return "flame.fill"
        case .rizzler:    return "crown.fill"
        }
    }

    // MARK: - Static Render

    /// Renders this card to a `UIImage` at @3x resolution.
    ///
    /// Always applies dark color scheme so the card looks identical on
    /// any device regardless of the system appearance setting.
    ///
    /// - Returns: A `UIImage`, or `nil` if `ImageRenderer` fails (e.g., in
    ///   a process with no display context, such as an app extension).
    @MainActor
    static func render(for profile: AuraProfile) -> UIImage? {
        let card = AuraCardView(profile: profile)
            .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0   // Always @3x — crisp on all devices
        return renderer.uiImage
    }
}

// MARK: - AuraCardImage

/// `Transferable` wrapper around a rendered `UIImage` so `AuraCardView.render(for:)`
/// output can be passed directly to SwiftUI's `ShareLink` without any third-party SDK.
struct AuraCardImage: Transferable {

    let uiImage: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { card in
            card.uiImage.pngData() ?? Data()
        }
    }
}

// MARK: - Preview

#Preview("AuraCardView — Rizzler") {
    AuraCardView(
        profile: AuraProfile(
            id: UUID(),
            totalPoints: 18_400,
            streak: 12,
            lastActivityDate: Date(),
            displayName: "Keyur"
        )
    )
    .padding()
    .background(Color.black)
}

#Preview("AuraCardView — Aura Farmer") {
    AuraCardView(
        profile: AuraProfile(
            id: UUID(),
            totalPoints: 7_250,
            streak: 3,
            lastActivityDate: Date(),
            displayName: "Alex"
        )
    )
    .padding()
    .background(Color.black)
}

#Preview("AuraCardView — Unc") {
    AuraCardView(
        profile: AuraProfile(
            id: UUID(),
            totalPoints: 0,
            streak: 0,
            lastActivityDate: nil,
            displayName: "Guest"
        )
    )
    .padding()
    .background(Color.black)
}
