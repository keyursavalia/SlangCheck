// Features/Crossword/CrosswordCountdownView.swift
// SlangCheck
//
// Countdown timer shown on the completion screen.
// Counts down to the next daily puzzle, which publishes at 7:00 AM local time.

import SwiftUI

// MARK: - CrosswordCountdownView

/// Displays a live HH:MM:SS countdown to the next 7 AM puzzle drop.
///
/// Uses `TimelineView(.periodic(from:by:1))` for second-level granularity without
/// a manual `Timer`. The `nextPuzzleAt` target is computed once at `init` and held
/// stable for the lifetime of the view.
struct CrosswordCountdownView: View {

    // MARK: - Constants

    /// Hour of day (local time) when a new puzzle is published.
    private static let publishHour: Int = 7

    // MARK: - State

    /// The absolute date the next puzzle drops. Computed once; stable for the lifetime of the view.
    private let nextPuzzleAt: Date

    // MARK: - Initialization

    init() {
        self.nextPuzzleAt = CrosswordCountdownView.computeNextPuzzleDate()
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: SlangSpacing.xs) {

            Label(
                String(localized: "crossword.countdown.title", defaultValue: "Next Puzzle"),
                systemImage: "clock.fill"
            )
            .font(.slang(.caption))
            .foregroundStyle(SlangColor.primary)

            TimelineView(.periodic(from: Date(), by: 1)) { _ in
                countdownRow(remaining: max(nextPuzzleAt.timeIntervalSinceNow, 0))
            }

            Text(
                String(localized: "crossword.countdown.subtitle",
                       defaultValue: "New puzzle drops at 7:00 AM")
            )
            .font(.slang(.caption))
            .foregroundStyle(.primary.opacity(0.6))
        }
        .padding(.vertical, SlangSpacing.sm)
        .padding(.horizontal, SlangSpacing.md)
        .profileCard()
    }

    // MARK: - Private Views

    @ViewBuilder
    private func countdownRow(remaining: TimeInterval) -> some View {
        let hours   = Int(remaining) / 3600
        let minutes = Int(remaining) % 3600 / 60
        let seconds = Int(remaining) % 60

        HStack(spacing: SlangSpacing.sm) {
            timeUnit(value: hours,   label: String(localized: "crossword.countdown.hrs", defaultValue: "HRS"))
            colonSeparator
            timeUnit(value: minutes, label: String(localized: "crossword.countdown.min", defaultValue: "MIN"))
            colonSeparator
            timeUnit(value: seconds, label: String(localized: "crossword.countdown.sec", defaultValue: "SEC"))
        }
    }

    private func timeUnit(value: Int, label: String) -> some View {
        VStack(spacing: 1) {
            Text(String(format: "%02d", value))
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.primary.opacity(0.6))
        }
        .frame(minWidth: 44)
        .padding(.vertical, SlangSpacing.xs)
        .padding(.horizontal, SlangSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: SlangCornerRadius.chip)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var colonSeparator: some View {
        Text(":")
            .font(.system(size: 18, weight: .bold, design: .monospaced))
            .foregroundStyle(SlangColor.primary)
            .padding(.bottom, SlangSpacing.md)
    }

    // MARK: - Static Helpers

    /// Returns the next occurrence of `publishHour`:00:00 local time.
    /// If it is currently before `publishHour` today, returns today's occurrence.
    /// Otherwise returns tomorrow's.
    private static func computeNextPuzzleDate() -> Date {
        let cal  = Calendar.current
        var components       = cal.dateComponents([.year, .month, .day], from: Date())
        components.hour      = publishHour
        components.minute    = 0
        components.second    = 0
        // SAFE: components are derived from Date() — date will always be valid.
        let todayAt7 = cal.date(from: components)!
        if Date() < todayAt7 {
            return todayAt7
        }
        // SAFE: adding 1 day to a valid Date always produces a valid Date.
        return cal.date(byAdding: .day, value: 1, to: todayAt7)!
    }
}

// MARK: - Preview

#Preview("CrosswordCountdownView") {
    CrosswordCountdownView()
        .padding()
        .background(SlangColor.background)
}
