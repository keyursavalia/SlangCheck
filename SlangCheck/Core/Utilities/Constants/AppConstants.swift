// Core/Utilities/Constants/AppConstants.swift
// SlangCheck
//
// Named constants used throughout the app. NEVER hardcode these values in views or ViewModels.
// This file is platform-agnostic (no UIKit/SwiftUI imports).

import Foundation

// MARK: - App-wide Constants

/// Top-level namespace for all application constants.
public enum AppConstants {

    // MARK: Search

    /// Debounce delay for the Glossary search bar input (FR-SR-003, Step 1.5).
    public static let searchDebounceMilliseconds: UInt64 = 300

    // MARK: Swiper

    /// Scale of the background (next) card when the top card is idle.
    public static let swiperBackCardIdleScale: Double = 0.94

    /// Vertical offset of the background card in the stack (slight peek from below).
    public static let swiperBackCardOffset: Double = 12

    /// The upward translation threshold (in points) to register a definitive swipe-up action.
    public static let swiperSwipeThreshold: Double = 100

    // MARK: Translator

    /// Debounce delay for translator input (FR-T-006).
    public static let translatorDebounceMilliseconds: UInt64 = 400

    /// Character count at which a soft visual warning appears in Panel A (FR-T-008).
    public static let translatorSoftCharacterLimit: Int = 280

    // MARK: Tab Indices

    /// Stable numeric indices for tabs, used by deep-link and tab-state logic.
    ///
    /// Tab bar (4 slots): Learn → Translator → Quizzes → More.
    /// Glossary and Profile are accessed via the More tab; Crossword is removed.
    public enum TabIndex {
        public static let swiper:     Int = 0
        public static let translator: Int = 1
        public static let quizzes:    Int = 2
        public static let more:       Int = 3
        // Legacy constants — features still exist but are not direct tabs.
        public static let glossary:   Int = -1
        public static let crossword:  Int = -2
        public static let profile:    Int = -3
    }

    // MARK: UserDefaults Keys

    /// UserDefaults key for tracking whether onboarding has been completed (FR-O-005).
    public static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    /// UserDefaults key for the user's selected segment (FR-O-002).
    public static let userSegmentKey = "userSegment"

    // MARK: Seed Data

    /// The filename (without extension) of the bundled slang seed JSON.
    public static let seedDataFilename = "slang_seed"

    /// The file extension of the seed data file.
    public static let seedDataExtension = "json"

    /// Monotonically increasing integer. Bump this whenever `slang_seed.json` is updated
    /// so existing installs automatically re-seed with the new terms on next launch.
    public static let seedVersion = 3

    /// UserDefaults key that stores the last-applied seed version on this device.
    public static let seedVersionKey = "slangSeedVersion"
}
