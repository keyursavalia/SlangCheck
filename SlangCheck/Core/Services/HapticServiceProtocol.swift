// Core/Services/HapticServiceProtocol.swift
// SlangCheck
//
// Protocol abstraction for haptic feedback. Zero UIKit import in Core layer.
// The concrete iOS implementation lives in Data/Services/HapticService.swift.
// This protocol allows mock injection in unit tests and easy future
// disabling via a user preference (NF-PL-002).

import Foundation

// MARK: - HapticServiceProtocol

/// Abstraction over platform haptic feedback generators.
/// All haptic triggers defined in TECH_STACK.md §7 are represented here.
public protocol HapticServiceProtocol: Sendable {

    /// Called when a Swiper card swipe gesture completes (save or dismiss).
    func swipeCompleted()

    /// Called when a quiz answer is selected and is correct.
    func answerCorrect()

    /// Called when a quiz answer is selected and is incorrect.
    func answerIncorrect()

    /// Called when text is successfully copied to the clipboard.
    func copySucceeded()

    /// Called when the user achieves a tier promotion.
    func tierPromotion()

    /// Called when a tap-based swipe button (✓ / ✕) is pressed.
    func swipeButtonTapped()
}
