// Features/Onboarding/OnboardingNotificationSteps.swift
// SlangCheck
//
// Step views: NotificationSchedule, NotificationPermission, WelcomeSplash.

import SwiftUI

// MARK: - NotificationScheduleStep

/// Lets the user configure daily notification frequency and time window,
/// then taps "Allow and Save" which triggers the iOS permission request.
struct NotificationScheduleStep: View {

    @Binding var count: Int
    @Binding var startTime: Date
    @Binding var endTime: Date
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "onboarding.notif.title",
                        defaultValue: "Get slang throughout the day"))
                .font(.custom("Montserrat-Bold", size: 30))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
                .padding(.horizontal, SlangSpacing.md)
                .padding(.top, SlangSpacing.xl)

            Text(String(localized: "onboarding.notif.subtitle",
                        defaultValue: "Allow notifications to get daily slang"))
                .font(.custom("Montserrat-Regular", size: 15))
                .foregroundStyle(.secondary)
                .padding(.horizontal, SlangSpacing.md)
                .padding(.top, SlangSpacing.xs)

            Spacer().frame(height: SlangSpacing.lg)

            notificationPreview
                .padding(.horizontal, SlangSpacing.md)

            Spacer().frame(height: SlangSpacing.lg)

            VStack(spacing: SlangSpacing.sm) {
                // How many stepper row
                settingsRow {
                    Text(String(localized: "onboarding.notif.howMany", defaultValue: "How many"))
                        .font(.custom("Montserrat-Regular", size: 16))
                        .foregroundStyle(.primary)
                    Spacer()
                    HStack(spacing: SlangSpacing.md) {
                        Button {
                            if count > 1 { count -= 1 }
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 28, height: 28)
                        }
                        Text("\(count)x")
                            .font(.custom("Montserrat-Bold", size: 16))
                            .frame(minWidth: 36, alignment: .center)
                        Button {
                            if count < 20 { count += 1 }
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 28, height: 28)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                }

                // Start at time picker row
                settingsRow {
                    Text(String(localized: "onboarding.notif.startAt", defaultValue: "Start at"))
                        .font(.custom("Montserrat-Regular", size: 16))
                        .foregroundStyle(.primary)
                    Spacer()
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                // End at time picker row
                settingsRow {
                    Text(String(localized: "onboarding.notif.endAt", defaultValue: "End at"))
                        .font(.custom("Montserrat-Regular", size: 16))
                        .foregroundStyle(.primary)
                    Spacer()
                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
            .padding(.horizontal, SlangSpacing.md)

            Spacer()

            OnboardingCTAButton(
                title: String(localized: "onboarding.notif.save", defaultValue: "Allow and Save"),
                action: onSave
            )
            .padding(.horizontal, SlangSpacing.md)
            .padding(.bottom, SlangSpacing.xl)
        }
    }

    // MARK: - Notification Preview Card (stacked)

    private var notificationPreview: some View {
        ZStack {
            // Background card (second notification, partially visible)
            notificationCard(
                body: String(localized: "onboarding.notif.preview.body2",
                             defaultValue: "slay (v.) — to do something exceptionally well")
            )
            .offset(y: 10)
            .opacity(0.5)
            .scaleEffect(0.97)

            // Foreground card (primary notification)
            notificationCard(
                body: String(localized: "onboarding.notif.preview.body",
                             defaultValue: "bussin (adj.) — really good, excellent")
            )
        }
    }

    private func notificationCard(body: String) -> some View {
        HStack(spacing: SlangSpacing.sm) {
            RoundedRectangle(cornerRadius: 8)
                .fill(SlangColor.onboardingTeal)
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "onboarding.notif.preview.app", defaultValue: "SlangCheck"))
                    .font(.montserrat(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(body)
                    .font(.montserrat(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(String(localized: "onboarding.notif.preview.time", defaultValue: "Now"))
                .font(.montserrat(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(SlangSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: SlangCornerRadius.cell)
                .fill(Color(.systemBackground))
        }
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    // MARK: - Settings Row Container

    @ViewBuilder
    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack { content() }
            .padding(.horizontal, SlangSpacing.md)
            .frame(height: 52)
            .background {
                RoundedRectangle(cornerRadius: SlangCornerRadius.cell)
                    .fill(Color(.systemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: SlangCornerRadius.cell)
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                    }
            }
    }
}

// MARK: - NotificationConsentStep

/// Asks the user if they want to set up notifications before showing the schedule step.
/// Tapping "Go to settings" proceeds to the schedule page.
/// Tapping "I'm not ready yet" skips to the welcome splash.
struct NotificationConsentStep: View {

    let onAllow: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration — bell with a phone mockup feel
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(SlangColor.onboardingTeal.opacity(0.08))
                    .frame(width: 200, height: 200)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(SlangColor.onboardingTeal)
            }
            .accessibilityHidden(true)
            .padding(.bottom, SlangSpacing.xl)

            Text(String(localized: "onboarding.consent.title",
                        defaultValue: "SlangCheck works better with reminders"))
                .font(.custom("Montserrat-Bold", size: 28))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
                .padding(.horizontal, SlangSpacing.lg)

            Text(String(localized: "onboarding.consent.subtitle",
                        defaultValue: "Allow notifications to get daily words"))
                .font(.custom("Montserrat-Regular", size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, SlangSpacing.sm)
                .padding(.horizontal, SlangSpacing.lg)

            Spacer()

            VStack(spacing: SlangSpacing.md) {
                OnboardingCTAButton(
                    title: String(localized: "onboarding.consent.allow",
                                  defaultValue: "Go to settings"),
                    action: onAllow
                )

                Button(action: onSkip) {
                    Text(String(localized: "onboarding.consent.skip",
                                defaultValue: "I'm not ready yet"))
                        .font(.custom("Montserrat-Regular", size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, SlangSpacing.md)
            .padding(.bottom, SlangSpacing.xl)
        }
    }
}

// MARK: - NotificationPermissionStep

/// Shown when notifications are denied or need manual Settings activation.
struct NotificationPermissionStep: View {

    let onGoToSettings: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(SlangColor.onboardingTeal)
                .accessibilityHidden(true)
                .padding(.bottom, SlangSpacing.xl)

            Text(String(localized: "onboarding.permission.title",
                        defaultValue: "SlangCheck works better with reminders"))
                .font(.custom("Montserrat-Bold", size: 28))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.lg)

            Text(String(localized: "onboarding.permission.subtitle",
                        defaultValue: "Enable notifications to receive daily slang drops."))
                .font(.custom("Montserrat-Regular", size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, SlangSpacing.sm)
                .padding(.horizontal, SlangSpacing.lg)

            Spacer()

            VStack(spacing: SlangSpacing.md) {
                OnboardingCTAButton(
                    title: String(localized: "onboarding.permission.settings",
                                  defaultValue: "Go to settings"),
                    action: onGoToSettings
                )

                Button(action: onSkip) {
                    Text(String(localized: "onboarding.permission.skip",
                                defaultValue: "I'm not ready yet"))
                        .font(.custom("Montserrat-Regular", size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, SlangSpacing.md)
            .padding(.bottom, SlangSpacing.xl)
        }
    }
}

// MARK: - WelcomeSplashStep

/// Final onboarding screen. Swiping up (≥ 60 pt) completes the flow.
/// The chevron bounces on a repeating loop once the hint appears.
struct WelcomeSplashStep: View {

    let onContinue: () -> Void

    @State private var showHint = false
    @State private var chevronBounce: CGFloat = 0
    /// Tracks how far the user has dragged up — used to give live feedback.
    @State private var dragOffset: CGFloat = 0

    /// Minimum upward drag (pt) required to trigger completion.
    private let swipeThreshold: CGFloat = 60

    var body: some View {
        ZStack {
            // Centered welcome text shifts slightly with the drag for a responsive feel.
            Text(String(localized: "onboarding.welcome.title",
                        defaultValue: "Welcome to SlangCheck"))
                .font(.custom("Montserrat-Bold", size: 36))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .offset(y: dragOffset * 0.25)

            // Swipe-up hint — fades in after a short delay, then chevron bounces.
            VStack {
                Spacer()
                VStack(spacing: SlangSpacing.xs) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 20, weight: .medium))
                        .offset(y: chevronBounce + dragOffset * 0.5)
                    Text(String(localized: "onboarding.welcome.swipeUp",
                                defaultValue: "Swipe up"))
                        .font(.custom("Montserrat-Regular", size: 15))
                        .offset(y: dragOffset * 0.5)
                }
                .foregroundStyle(.secondary)
                .opacity(showHint ? 1 : 0)
                .animation(.easeIn(duration: 0.6).delay(0.8), value: showHint)
                .padding(.bottom, SlangSpacing.xxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    // Only track upward movement (negative translation = up).
                    let upwardDelta = -value.translation.height
                    dragOffset = upwardDelta > 0 ? -upwardDelta : 0
                }
                .onEnded { value in
                    let upwardDelta = -value.translation.height
                    if upwardDelta >= swipeThreshold {
                        onContinue()
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            showHint = true
            startChevronBounce()
        }
    }

    /// Repeating bounce: moves the chevron up 8 pt then springs back, forever.
    private func startChevronBounce() {
        let upDuration = 0.45
        let downDuration = 0.55
        let pause = 0.9

        func cycle() {
            withAnimation(.easeOut(duration: upDuration)) {
                chevronBounce = -8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + upDuration) {
                withAnimation(.spring(response: downDuration, dampingFraction: 0.5)) {
                    chevronBounce = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + downDuration + pause) {
                    cycle()
                }
            }
        }

        // Start after the hint has faded in.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            cycle()
        }
    }
}
