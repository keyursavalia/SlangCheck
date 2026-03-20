// Data/Services/HapticService.swift
// SlangCheck
//
// Concrete iOS implementation of HapticServiceProtocol.
// Uses UIFeedbackGenerator subclasses as defined in TECH_STACK.md §7.
// iOS-specific — wrapped in #if os(iOS) for platform extensibility.

import Foundation
#if os(iOS)
import UIKit
#endif

// MARK: - HapticService

/// iOS implementation of haptic feedback using UIFeedbackGenerator subclasses.
/// All generators are created fresh on each call to avoid stale state from
/// prepare/generate lifecycle mismatches.
public struct HapticService: HapticServiceProtocol {

    public init() {}

    #if os(iOS)

    public func swipeCompleted() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    public func answerCorrect() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    public func answerIncorrect() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    public func copySucceeded() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    public func tierPromotion() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    public func swipeButtonTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    #else
    // TODO: watchOS/visionOS equivalent haptic implementations
    public func swipeCompleted() {}
    public func answerCorrect() {}
    public func answerIncorrect() {}
    public func copySucceeded() {}
    public func tierPromotion() {}
    public func swipeButtonTapped() {}
    #endif
}
