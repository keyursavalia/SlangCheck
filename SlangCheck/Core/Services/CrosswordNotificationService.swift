// Core/Services/CrosswordNotificationService.swift
// SlangCheck
//
// Protocol for scheduling the daily crossword push notification.
// Concrete implementations live in Data/Services/.
// Zero UIKit/SwiftUI/CoreData imports — platform-agnostic contract.

import Foundation

// MARK: - CrosswordNotificationError

/// Errors thrown by `CrosswordNotificationService` implementations.
public enum CrosswordNotificationError: LocalizedError, Sendable {
    /// The user has denied notification permission; prompt them to enable in Settings.
    case permissionDenied
    /// An unexpected error occurred while scheduling the notification.
    case schedulingFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return String(localized: "error.notification.permissionDenied",
                          defaultValue: "Enable notifications in Settings to get daily crossword reminders.")
        case .schedulingFailed(let err):
            return String(localized: "error.notification.schedulingFailed",
                          defaultValue: "Could not schedule the crossword notification: \(err.localizedDescription)")
        }
    }
}

// MARK: - CrosswordNotificationService Protocol

/// Schedules a local or remote notification alerting the user when the daily
/// crossword is live.
///
/// **Decision Q-006a**: APNs + Firebase Cloud Messaging.
/// - `LocalCrosswordNotificationService` (in `Data/Services/`) uses
///   `UNUserNotificationCenter` to schedule a local notification.
///   It is the default in the sample/offline build before Firebase is added (A-007).
/// - `FCMCrosswordNotificationService` (also in `Data/Services/`) is compiled
///   only when FirebaseMessaging is available (`#if canImport(FirebaseMessaging)`)
///   and registers the FCM token with the server so push messages can be sent.
public protocol CrosswordNotificationService: Sendable {

    /// Requests notification authorisation if not yet determined, then schedules
    /// the daily crossword reminder for the next puzzle's publish time.
    ///
    /// - Parameter puzzleDate: The `Date` (midnight UTC) of the next puzzle day.
    ///   The notification fires at this time.
    /// - Throws: `CrosswordNotificationError.permissionDenied` if the user has
    ///   denied authorisation; `.schedulingFailed` on system errors.
    func scheduleDailyReminder(for puzzleDate: Date) async throws(CrosswordNotificationError)

    /// Cancels any previously scheduled daily crossword reminder.
    func cancelDailyReminder() async
}
