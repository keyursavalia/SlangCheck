// Features/Crossword/CrosswordCompletionView.swift
// SlangCheck
//
// Shows the crossword completion summary: accuracy, Aura earned, and a
// shareable completion card generated via ImageRenderer.

import SwiftUI
import UniformTypeIdentifiers

// MARK: - CrosswordCompletionCardImage

/// Wraps a rendered completion card `UIImage` for use with `ShareLink`.
struct CrosswordCompletionCardImage: Transferable {
    let uiImage: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { card in
            card.uiImage.pngData() ?? Data()
        }
    }
}

// MARK: - CrosswordCompletionCardView

/// The fixed-size card rendered to `UIImage` by `ImageRenderer`.
/// Always rendered in dark mode so the gradient is consistent.
private struct CrosswordCompletionCardView: View {

    let result: CrosswordResult

    static let cardWidth:  CGFloat = 360
    static let cardHeight: CGFloat = 360

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.059, green: 0.090, blue: 0.165),
                    Color(red: 0.102, green: 0.075, blue: 0.251)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 20) {
                // App wordmark
                Text("SlangCheck")
                    .font(.montserrat(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0.753, green: 0.518, blue: 0.988))

                // Trophy
                Image(systemName: result.isPerfect ? "trophy.fill" : "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        result.isPerfect
                            ? Color(red: 0.984, green: 0.749, blue: 0.141)
                            : Color(red: 0.133, green: 0.773, blue: 0.502)
                    )

                // "Daily Crossword" label
                Text("Daily Crossword")
                    .font(.montserrat(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                // Date
                Text(result.puzzleDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.montserrat(size: 13))
                    .foregroundStyle(Color.white.opacity(0.6))

                // Stats row
                HStack(spacing: 32) {
                    stat(label: "Accuracy",
                         value: "\(Int(result.accuracy * 100))%")
                    stat(label: "Aura",
                         value: "+\(result.auraPointsEarned)")
                    stat(label: "Reveals",
                         value: "\(result.revealsUsed)")
                }

                if result.isPerfect {
                    Text("Perfect Solve ⚡")
                        .font(.montserrat(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 0.984, green: 0.749, blue: 0.141))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.984, green: 0.749, blue: 0.141).opacity(0.15))
                        )
                }
            }
            .padding(28)
        }
        .frame(width: Self.cardWidth, height: Self.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func stat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.montserrat(size: 20, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.montserrat(size: 11))
                .foregroundStyle(Color.white.opacity(0.6))
        }
    }

    @MainActor
    static func render(for result: CrosswordResult) -> UIImage? {
        let view = CrosswordCompletionCardView(result: result)
            .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        return renderer.uiImage
    }
}

// MARK: - CrosswordCompletionView

/// Shown when the user submits the crossword. Displays accuracy, Aura earned,
/// and a Share button for the rendered completion card.
struct CrosswordCompletionView: View {

    // MARK: - Input

    let result: CrosswordResult
    let viewModel: CrosswordViewModel
    var onSessionEnd: (() -> Void)?

    // MARK: - State

    @State private var cardImage: CrosswordCompletionCardImage?

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: SlangSpacing.xl) {
                completionHeader
                statsGrid
                auraSection
                CrosswordCountdownView()
                if let cardImage {
                    shareButton(cardImage: cardImage)
                }
                doneButton
                Spacer(minLength: SlangSpacing.xxl)
            }
            .padding(SlangSpacing.md)
        }
        .onAppear { renderCard() }
    }

    // MARK: - Header

    private var completionHeader: some View {
        VStack(spacing: SlangSpacing.sm) {
            Image(systemName: result.isPerfect ? "trophy.fill" : "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    result.isPerfect ? SlangColor.accent : SlangColor.secondary
                )

            Text(result.isPerfect
                 ? String(localized: "crossword.result.perfectTitle", defaultValue: "Perfect Solve!")
                 : String(localized: "crossword.result.title", defaultValue: "Puzzle Complete"))
                .font(.slang(.title))
                .foregroundStyle(.primary)

            Text(result.puzzleDate.formatted(date: .long, time: .omitted))
                .font(.slang(.caption))
                .foregroundStyle(.primary.opacity(0.6))
        }
        .padding(.top, SlangSpacing.lg)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: SlangSpacing.md) {
            statCell(
                value: "\(Int(result.accuracy * 100))%",
                label: String(localized: "crossword.result.accuracy", defaultValue: "Accuracy")
            )
            statCell(
                value: "\(result.correctCells)/\(result.totalCells)",
                label: String(localized: "crossword.result.correct", defaultValue: "Correct")
            )
            statCell(
                value: "\(result.revealsUsed)",
                label: String(localized: "crossword.result.reveals", defaultValue: "Reveals")
            )
        }
        .padding(SlangSpacing.md)
        .profileCard()
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: SlangSpacing.xs) {
            Text(value)
                .font(.slang(.heading))
                .foregroundStyle(.primary)
            Text(label)
                .font(.slang(.caption))
                .foregroundStyle(.primary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Aura Section

    private var auraSection: some View {
        VStack(spacing: SlangSpacing.sm) {
            Text("+\(result.auraPointsEarned) \(String(localized: "crossword.result.aura", defaultValue: "Aura"))")
                .font(.slang(.heading))
                .foregroundStyle(SlangColor.primary)

            if result.isPerfect {
                Text(String(localized: "crossword.result.perfectBonus",
                            defaultValue: "Perfect Solve Bonus: 1.5\u{00D7} multiplier applied"))
                    .font(.slang(.caption))
                    .foregroundStyle(SlangColor.accent)
            }

            if let profile = viewModel.auraProfile {
                Text("\(profile.totalPoints) \(String(localized: "crossword.result.totalAura", defaultValue: "total Aura"))")
                    .font(.slang(.caption))
                    .foregroundStyle(.primary.opacity(0.6))
            }
        }
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button {
            onSessionEnd?()
        } label: {
            Text(String(localized: "crossword.result.done", defaultValue: "Done"))
                .font(.custom("Montserrat-Bold", size: 18))
                .foregroundStyle(Color(.label))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(SlangColor.onboardingTeal)
                }
                .background {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.black)
                        .offset(y: 4)
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Share Button

    private func shareButton(cardImage: CrosswordCompletionCardImage) -> some View {
        ShareLink(
            item: cardImage,
            preview: SharePreview(
                String(localized: "crossword.shareCard.preview", defaultValue: "My Daily Crossword"),
                image: Image(uiImage: cardImage.uiImage)
            )
        ) {
            Label(
                String(localized: "crossword.shareCard", defaultValue: "Share My Result"),
                systemImage: "square.and.arrow.up"
            )
            .font(.slang(.label))
            .foregroundStyle(SlangColor.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, SlangSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: SlangCornerRadius.button)
                    .strokeBorder(SlangColor.primary, lineWidth: 1)
            )
        }
        .accessibilityLabel(String(localized: "crossword.shareCard.accessibility",
                                   defaultValue: "Share your crossword completion card"))
    }

    // MARK: - Rendering

    private func renderCard() {
        Task { @MainActor in
            if let image = CrosswordCompletionCardView.render(for: result) {
                cardImage = CrosswordCompletionCardImage(uiImage: image)
            }
        }
    }
}
