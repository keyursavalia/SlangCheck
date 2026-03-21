// Features/Quizzes/AuraCardView.swift
// SlangCheck
//
// Shareable Aura Card — a fixed-size decorative card rendered to UIImage
// via ImageRenderer and shared via ShareLink.
//
// Design contract:
// - Always renders in dark ("Midnight Cyber") palette regardless of system theme.
// - Uses explicit gradient colors (never .ultraThinMaterial) so ImageRenderer
//   produces a correct snapshot.
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

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer
            decorativeGlow
            contentLayer
        }
        .frame(width: Self.cardWidth, height: Self.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: SlangCornerRadius.card))
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color(red: 0.059, green: 0.090, blue: 0.165),   // #0F172A Deep Slate
                Color(red: 0.102, green: 0.075, blue: 0.251)    // #1A1340 Deep Indigo
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var decorativeGlow: some View {
        ZStack {
            // Large soft circle behind the tier icon
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tierColor.opacity(0.25), tierColor.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)
                .offset(y: -60)

            // Subtle grid of dots in the background
            Canvas { context, size in
                let spacing: CGFloat = 28
                let dotRadius: CGFloat = 1.2
                var x: CGFloat = spacing
                while x < size.width {
                    var y: CGFloat = spacing
                    while y < size.height {
                        let rect = CGRect(x: x - dotRadius, y: y - dotRadius,
                                         width: dotRadius * 2, height: dotRadius * 2)
                        context.fill(Path(ellipseIn: rect),
                                     with: .color(.white.opacity(0.06)))
                        y += spacing
                    }
                    x += spacing
                }
            }
        }
    }

    // MARK: - Content

    private var contentLayer: some View {
        VStack(spacing: 0) {
            // ── Brand header ──────────────────────────────
            brandHeader
                .padding(.top, SlangSpacing.lg)
                .padding(.horizontal, SlangSpacing.lg)

            Spacer()

            // ── Tier badge ────────────────────────────────
            tierBadge

            Spacer()

            // ── Divider ───────────────────────────────────
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)
                .padding(.horizontal, SlangSpacing.xl)

            Spacer()

            // ── User info ─────────────────────────────────
            userInfo

            Spacer()

            // ── Footer ────────────────────────────────────
            cardFooter
                .padding(.bottom, SlangSpacing.lg)
                .padding(.horizontal, SlangSpacing.lg)
        }
    }

    // MARK: - Brand Header

    private var brandHeader: some View {
        HStack {
            Text("slangcheck")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(tierColor)
                .tracking(1.5)

            Spacer()

            // Three decorative dots (brand accent)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(tierColor.opacity(i == 2 ? 1.0 : 0.4))
                        .frame(width: 5, height: 5)
                }
            }
        }
    }

    // MARK: - Tier Badge

    private var tierBadge: some View {
        VStack(spacing: SlangSpacing.sm) {
            ZStack {
                Circle()
                    .fill(tierColor.opacity(0.15))
                    .frame(width: 88, height: 88)

                Circle()
                    .strokeBorder(tierColor.opacity(0.35), lineWidth: 1)
                    .frame(width: 88, height: 88)

                Image(systemName: tierSymbol)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(tierColor)
                    .accessibilityHidden(true)
            }

            Text(profile.currentTier.displayName.uppercased())
                .font(.system(size: 22, weight: .black, design: .default))
                .foregroundStyle(.white)
                .tracking(3)

            Text(profile.currentTier.subtitle)
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundStyle(Color.white.opacity(0.55))
                .tracking(0.5)
        }
    }

    // MARK: - User Info

    private var userInfo: some View {
        VStack(spacing: SlangSpacing.xs) {
            Text(profile.displayName)
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundStyle(.white)

            Text("\(profile.totalPoints) pts")
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(tierColor)
        }
    }

    // MARK: - Footer

    private var cardFooter: some View {
        HStack {
            Text("slangcheck.app")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.30))
                .tracking(0.5)

            Spacer()

            // Streak indicator
            if profile.streak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(SlangColor.accent)
                        .accessibilityHidden(true)
                    Text("\(profile.streak)d streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }
        }
    }

    // MARK: - Tier Helpers

    private var tierColor: Color {
        switch profile.currentTier {
        case .unc:        return Color(red: 0.70, green: 0.75, blue: 0.85)  // soft silver
        case .lurk:       return Color(red: 0.984, green: 0.749, blue: 0.141) // amber
        case .auraFarmer: return Color(red: 0.290, green: 0.867, blue: 0.502) // cyber mint
        case .rizzler:    return Color(red: 0.753, green: 0.518, blue: 0.988) // neon heliotrope
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
