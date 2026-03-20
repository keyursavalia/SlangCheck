// Features/Onboarding/OnboardingView.swift
// SlangCheck
//
// Onboarding flow (FR-O-001 through FR-O-005):
//   Page 0: Welcome
//   Page 1: Segment picker
//   Page 2: Interactive Swiper demo
//   Page 3: Ready screen
// Skippable at any point (FR-O-004). Shows only once (FR-O-005).

import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {

    @State private var viewModel = OnboardingViewModel()
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            SlangColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button (FR-O-004)
                HStack {
                    Spacer()
                    Button(action: viewModel.skip) {
                        Text(String(localized: "onboarding.skip", defaultValue: "Skip"))
                            .font(.slang(.label))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, SlangSpacing.md)
                    .padding(.top, SlangSpacing.md)
                    .accessibilityLabel(
                        String(localized: "onboarding.skip.accessibility",
                               defaultValue: "Skip onboarding and go to the app")
                    )
                }

                TabView(selection: $viewModel.currentPage) {
                    ForEach(OnboardingPage.allCases, id: \.rawValue) { page in
                        pageView(for: page)
                            .tag(page.rawValue)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                continueButton
                    .padding(.horizontal, SlangSpacing.md)
                    .padding(.bottom, SlangSpacing.xl)
            }
        }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            if isComplete { onComplete() }
        }
    }

    // MARK: - Page View Builder

    @ViewBuilder
    private func pageView(for page: OnboardingPage) -> some View {
        switch page {
        case .welcome:
            StandardOnboardingPage(page: page)
        case .segmentPicker:
            SegmentPickerPage(selectedSegment: $viewModel.selectedSegment)
        case .swiperDemo:
            SwiperDemoPage()
        case .ready:
            StandardOnboardingPage(page: page)
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: viewModel.advance) {
            Text(viewModel.continueButtonTitle)
                .font(.slang(.label))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, SlangSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SlangCornerRadius.button)
                        .fill(viewModel.canAdvance
                              ? SlangColor.primary
                              : SlangColor.primary.opacity(0.4))
                )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canAdvance)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: viewModel.canAdvance)
    }
}

// MARK: - StandardOnboardingPage

private struct StandardOnboardingPage: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: SlangSpacing.xl) {
            Spacer()

            Image(systemName: page.symbolName)
                .font(.system(size: 72, weight: .ultraLight))
                .foregroundStyle(SlangColor.primary)
                .accessibilityHidden(true)

            VStack(spacing: SlangSpacing.md) {
                Text(page.title)
                    .font(.slang(.display))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(page.message)
                    .font(.slang(.body))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .slangBodySpacing()
            }
            .padding(.horizontal, SlangSpacing.lg)

            Spacer()
        }
    }
}

// MARK: - SegmentPickerPage (FR-O-002)

private struct SegmentPickerPage: View {
    @Binding var selectedSegment: UserSegment?

    var body: some View {
        VStack(spacing: SlangSpacing.xl) {
            Spacer()

            VStack(spacing: SlangSpacing.md) {
                Text(OnboardingPage.segmentPicker.title)
                    .font(.slang(.display))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(OnboardingPage.segmentPicker.message)
                    .font(.slang(.body))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .slangBodySpacing()
            }
            .padding(.horizontal, SlangSpacing.lg)

            VStack(spacing: SlangSpacing.md) {
                ForEach(UserSegment.allCases, id: \.rawValue) { segment in
                    SegmentCard(
                        segment: segment,
                        isSelected: selectedSegment == segment,
                        onSelect: { selectedSegment = segment }
                    )
                    .padding(.horizontal, SlangSpacing.md)
                }
            }

            Spacer()
        }
    }
}

// MARK: - SegmentCard

private struct SegmentCard: View {
    let segment: UserSegment
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: SlangSpacing.md) {
                Image(systemName: segment.symbolName)
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(isSelected ? .white : SlangColor.primary)
                    .frame(width: 32)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: SlangSpacing.xs) {
                    Text(segment.displayName)
                        .font(.slang(.subheading))
                        .foregroundStyle(isSelected ? .white : .primary)
                    Text(segment.description)
                        .font(.slang(.caption))
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }
            }
            .padding(SlangSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: SlangCornerRadius.cell)
                    .fill(isSelected ? SlangColor.primary : SlangColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: SlangCornerRadius.cell)
                            .strokeBorder(
                                isSelected ? SlangColor.primary : SlangColor.separator,
                                lineWidth: isSelected ? 0 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityLabel("\(segment.displayName). \(segment.description)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - SwiperDemoPage (FR-O-003)

private struct SwiperDemoPage: View {
    @State private var demoOffset: CGSize = .zero
    @State private var isDemoFlipped = false

    private let demoTerm = SlangTerm(
        id: UUID(),
        term: "No Cap",
        definition: "An intensifier meaning 'for real'; used to assert truthfulness.",
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

    var body: some View {
        VStack(spacing: SlangSpacing.xl) {
            Spacer()

            VStack(spacing: SlangSpacing.sm) {
                Text(OnboardingPage.swiperDemo.title)
                    .font(.slang(.title))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                Text(OnboardingPage.swiperDemo.message)
                    .font(.slang(.body))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .slangBodySpacing()
            }
            .padding(.horizontal, SlangSpacing.lg)

            // Interactive demo card
            SlangCardView(
                term: demoTerm,
                isFlipped: isDemoFlipped,
                dragOffset: demoOffset,
                isTopCard: true
            )
            .frame(width: UIScreen.main.bounds.width - 80, height: 340)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isDemoFlipped.toggle()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in demoOffset = value.translation }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            demoOffset = .zero
                        }
                    }
            )

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("OnboardingView") {
    OnboardingView(onComplete: {})
}
