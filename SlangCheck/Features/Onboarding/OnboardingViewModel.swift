// Features/Onboarding/OnboardingViewModel.swift
// SlangCheck
//
// ViewModel and domain models for the redesigned onboarding flow.
// Flow: Splash → Name → Gender → Goal → Level → Frequency → Description
//       → Weekly goal → Test intro → 3 word tests → Notifications → Welcome

import Foundation
import OSLog
import SwiftUI
import UserNotifications

// MARK: - OnboardingStep

/// Each step in the onboarding flow (FR-O-001).
enum OnboardingStep: Int, CaseIterable {
    case splash               = 0
    case displayName          = 1
    case gender               = 2
    case learningGoal         = 3
    case slangLevel           = 4
    case wordFrequency        = 5
    case vocabDescription     = 6
    case weeklyGoal           = 7
    case testIntro            = 8
    case testBeginner         = 9
    case testIntermediate     = 10
    case testAdvanced         = 11
    case notificationSchedule = 12
    case notificationPermission = 13
    case welcomeSplash        = 14

    /// Whether a Skip button appears on this step.
    var isSkippable: Bool {
        switch self {
        case .splash, .testIntro, .welcomeSplash,
             .notificationSchedule, .notificationPermission:
            return false
        default:
            return true
        }
    }
}

// MARK: - Option Enums

enum OnboardingGender: String, CaseIterable {
    case female         = "Female"
    case male           = "Male"
    case other          = "Other"
    case preferNotToSay = "Prefer not to say"
}

enum OnboardingGoal: String, CaseIterable {
    case stayCurrent          = "Stay culturally current"
    case understandYouth      = "Understand younger generations"
    case improveCommunication = "Improve my communication"
    case funCuriosity         = "Just for fun / curiosity"
    case other                = "Other"
}

enum OnboardingSlangLevel: String, CaseIterable {
    case newbie     = "Total newbie"
    case someBasics = "I know some basics"
    case fluent     = "Pretty fluent in slang"
}

enum OnboardingWordFrequency: String, CaseIterable {
    case daily        = "Daily"
    case fewTimesWeek = "A few times a week"
    case rarely       = "Rarely"
    case never        = "Never"
}

enum OnboardingVocabDescription: String, CaseIterable {
    case oftenStruggle = "Often struggle to keep up"
    case getBy         = "Get by but want to improve"
    case comfortable   = "Comfortable in most situations"
    case veryFluent    = "Very fluent in internet culture"
}

enum OnboardingWeeklyGoal: String, CaseIterable {
    case ten    = "10 terms a week"
    case thirty = "30 terms a week"
    case fifty  = "50 terms a week"
}

// MARK: - Word Bank

/// Static slang term lists used in the vocabulary knowledge test.
enum OnboardingWordBank {
    static let beginner: [String]     = ["bussin", "no cap", "slay", "vibe", "goat", "lowkey"]
    static let intermediate: [String] = ["rizz", "mid", "touch grass", "ate", "based", "rent free"]
    static let advanced: [String]     = ["delulu", "NPC", "main character",
                                          "chronically online", "shadowban",
                                          "understood the assignment"]
}

// MARK: - OnboardingViewModel

/// Manages state and navigation for the full onboarding flow.
@Observable
@MainActor
final class OnboardingViewModel {

    // MARK: - Navigation

    var currentStep: OnboardingStep = .splash
    private(set) var isComplete = false

    // MARK: - Collected Data

    var displayName: String = ""
    var selectedGender: OnboardingGender?
    var selectedGoal: OnboardingGoal?
    var selectedSlangLevel: OnboardingSlangLevel?
    var selectedFrequency: OnboardingWordFrequency?
    var selectedVocabDescription: OnboardingVocabDescription?
    var selectedWeeklyGoal: OnboardingWeeklyGoal?
    var knownBeginnerTerms: Set<String>     = []
    var knownIntermediateTerms: Set<String> = []
    var knownAdvancedTerms: Set<String>     = []
    var notificationCount: Int = 10
    // SAFE: Calendar.current.date always returns a valid date for these components.
    var notificationStartTime: Date = Calendar.current
        .date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    var notificationEndTime: Date = Calendar.current
        .date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()

    // MARK: - Derived

    /// Whether the Continue button is enabled on the current step.
    var canAdvance: Bool {
        switch currentStep {
        case .gender:           return selectedGender != nil
        case .learningGoal:     return selectedGoal != nil
        case .slangLevel:       return selectedSlangLevel != nil
        case .wordFrequency:    return selectedFrequency != nil
        case .vocabDescription: return selectedVocabDescription != nil
        case .weeklyGoal:       return selectedWeeklyGoal != nil
        default:                return true
        }
    }

    // MARK: - Actions

    /// Advances to the next step, or completes onboarding on the last step.
    func advance() {
        if currentStep == .welcomeSplash {
            completeOnboarding()
            return
        }
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            completeOnboarding()
            return
        }
        withAnimation(.easeInOut(duration: 0.28)) { currentStep = next }
    }

    /// Skips the current step without saving a selection and advances.
    func skip() { advance() }

    /// Requests iOS notification permission, then jumps to welcomeSplash (granted)
    /// or notificationPermission (denied/error).
    func requestNotifications() {
        Task {
            let granted = (try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            withAnimation(.easeInOut(duration: 0.28)) {
                currentStep = granted ? .welcomeSplash : .notificationPermission
            }
        }
    }

    // MARK: - Private

    private func completeOnboarding() {
        // Map slang level → UserSegment for backward compatibility with existing persistence.
        let segment: UserSegment
        switch selectedSlangLevel {
        case .newbie:      segment = .unc
        case .someBasics:  segment = .trendSeeker
        case .fluent, nil: segment = .languageEnthusiast
        }
        UserDefaults.standard.set(true, forKey: AppConstants.hasCompletedOnboardingKey)
        UserDefaults.standard.set(segment.rawValue, forKey: AppConstants.userSegmentKey)
        Logger.onboarding.info("Onboarding complete. Segment: \(segment.rawValue)")
        isComplete = true
    }
}
