// Features/Onboarding/OnboardingViewModel.swift
// SlangCheck
//
// ViewModel for the onboarding flow (FR-O-001 through FR-O-005).
// Manages page navigation and segment selection. Persists completion to UserDefaults.

import Foundation
import OSLog

// MARK: - OnboardingPage

/// Each page in the onboarding flow (FR-O-001: max 4 screens).
enum OnboardingPage: Int, CaseIterable {
    case welcome        = 0
    case segmentPicker  = 1
    case swiperDemo     = 2
    case ready          = 3

    var title: String {
        switch self {
        case .welcome:       return String(localized: "onboarding.welcome.title",
                                           defaultValue: "Welcome to SlangCheck")
        case .segmentPicker: return String(localized: "onboarding.segment.title",
                                           defaultValue: "Who are you?")
        case .swiperDemo:    return String(localized: "onboarding.swiper.title",
                                           defaultValue: "How the Swiper Works")
        case .ready:         return String(localized: "onboarding.ready.title",
                                           defaultValue: "You're Ready!")
        }
    }

    var message: String {
        switch self {
        case .welcome:
            return String(localized: "onboarding.welcome.message",
                          defaultValue: "The GenZ Rosetta Stone. Learn, translate, and master the ever-evolving modern lexicon.")
        case .segmentPicker:
            return String(localized: "onboarding.segment.message",
                          defaultValue: "Tell us a bit about yourself so we can personalize your experience.")
        case .swiperDemo:
            return String(localized: "onboarding.swiper.message",
                          defaultValue: "Swipe right to save a term. Swipe left to skip. Tap to flip the card and see the definition.")
        case .ready:
            return String(localized: "onboarding.ready.message",
                          defaultValue: "Dive into the Swiper or search the Glossary. Your slang journey starts now.")
        }
    }

    var symbolName: String {
        switch self {
        case .welcome:       return "globe"
        case .segmentPicker: return "person.3.fill"
        case .swiperDemo:    return "rectangle.stack.fill"
        case .ready:         return "checkmark.seal.fill"
        }
    }
}

// MARK: - OnboardingViewModel

/// Manages onboarding flow state and segment selection.
@Observable
@MainActor
final class OnboardingViewModel {

    // MARK: - Published State

    /// Current page index.
    var currentPage: Int = 0

    /// The user's selected segment. Defaults to nil until the user picks.
    var selectedSegment: UserSegment? = nil

    /// True when the flow is complete and the app should dismiss onboarding.
    private(set) var isComplete = false

    // MARK: - Computed

    var isLastPage: Bool { currentPage == OnboardingPage.allCases.count - 1 }

    var canAdvance: Bool {
        // On the segment picker page, require a selection.
        if currentPage == OnboardingPage.segmentPicker.rawValue {
            return selectedSegment != nil
        }
        return true
    }

    var continueButtonTitle: String {
        if isLastPage {
            return String(localized: "onboarding.button.start", defaultValue: "Let's Go")
        }
        return String(localized: "onboarding.button.next", defaultValue: "Continue")
    }

    // MARK: - Actions

    /// Advances to the next page or completes onboarding on the final page.
    func advance() {
        if isLastPage {
            completeOnboarding()
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                currentPage += 1
            }
        }
    }

    /// Skips the entire onboarding flow (FR-O-004). Assigns default segment.
    func skip() {
        selectedSegment = selectedSegment ?? .languageEnthusiast
        completeOnboarding()
    }

    // MARK: - Private

    private func completeOnboarding() {
        let segment = selectedSegment ?? .languageEnthusiast
        // Persist to UserDefaults (non-sensitive preference — FR-O-005, TECH_STACK.md §3.3).
        UserDefaults.standard.set(true, forKey: AppConstants.hasCompletedOnboardingKey)
        UserDefaults.standard.set(segment.rawValue, forKey: AppConstants.userSegmentKey)
        Logger.onboarding.info("Onboarding complete. Segment: \(segment.rawValue)")
        isComplete = true
    }
}
