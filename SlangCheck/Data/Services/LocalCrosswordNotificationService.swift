// Data/Services/LocalCrosswordNotificationService.swift
// SlangCheck
//
// UNUserNotificationCenter-based implementation of CrosswordNotificationService.
// Used as the default before Firebase Cloud Messaging is integrated (A-007).
// Schedules a local notification that fires at puzzle publish time each day.

import Foundation
import OSLog
import UserNotifications

// MARK: - LocalCrosswordNotificationService

/// Schedules a daily crossword reminder via `UNUserNotificationCenter`.
///
/// This service is the offline-capable fallback implementation of
/// `CrosswordNotificationService`. Once Firebase Cloud Messaging is added
/// (developer action A-007), switch `AppEnvironment` to
/// `FCMCrosswordNotificationService` for server-push delivery.
///
/// The notification identifier is stable (`crossword.daily`) so that
/// rescheduling a new puzzle replaces the existing pending notification
/// rather than accumulating duplicate entries.
public actor LocalCrosswordNotificationService: CrosswordNotificationService {

    // MARK: - Constants

    /// Stable UNNotificationRequest identifier. One active reminder at a time.
    private static let notificationID = "crossword.daily"

    private static let log = Logger(subsystem: "com.slangcheck", category: "LocalCrosswordNotificationService")

    // MARK: - CrosswordNotificationService

    public func scheduleDailyReminder(for puzzleDate: Date) async throws(CrosswordNotificationError) {
        // 1. Request authorisation (no-op if already granted/denied).
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                LocalCrosswordNotificationService.log.info("Notification permission denied by user.")
                throw CrosswordNotificationError.permissionDenied
            }
        } catch let notifError as CrosswordNotificationError {
            throw notifError
        } catch {
            throw CrosswordNotificationError.schedulingFailed(underlying: error)
        }

        // 2. Build notification content.
        let content        = UNMutableNotificationContent()
        content.title      = String(localized: "notification.crossword.title",
                                   defaultValue: "Daily Crossword is Live!")
        content.body       = String(localized: "notification.crossword.body",
                                   defaultValue: "Don't lose your Aura Farmer status! The daily crossword is ready.")
        content.sound      = .default
        content.badge      = 1

        // 3. Build a calendar trigger at the puzzle's publish time.
        let calendar   = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second],
                                                  from: puzzleDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // 4. Schedule, replacing any existing reminder with the same ID.
        let request = UNNotificationRequest(
            identifier: LocalCrosswordNotificationService.notificationID,
            content: content,
            trigger: trigger
        )
        do {
            try await center.add(request)
            LocalCrosswordNotificationService.log.info("Daily crossword reminder scheduled for \(puzzleDate).")
        } catch {
            LocalCrosswordNotificationService.log.error("Failed to schedule notification: \(error).")
            throw CrosswordNotificationError.schedulingFailed(underlying: error)
        }
    }

    public func cancelDailyReminder() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: [LocalCrosswordNotificationService.notificationID]
        )
        LocalCrosswordNotificationService.log.info("Daily crossword reminder cancelled.")
    }
}
