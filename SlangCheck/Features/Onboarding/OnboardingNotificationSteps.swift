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
                        defaultValue: "Get slang throughout\nthe day"))
                .font(.custom("NoticiaText-Bold", size: 30))
                .foregroundStyle(.primary)
                .padding(.horizontal, SlangSpacing.md)
                .padding(.top, SlangSpacing.xl)

            Text(String(localized: "onboarding.notif.subtitle",
                        defaultValue: "Allow notifications to get daily slang"))
                .font(.custom("NoticiaText-Regular", size: 15))
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
                        .font(.custom("NoticiaText-Regular", size: 16))
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
                            .font(.custom("NoticiaText-Bold", size: 16))
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
                        .font(.custom("NoticiaText-Regular", size: 16))
                        .foregroundStyle(.primary)
                    Spacer()
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                // End at time picker row
                settingsRow {
                    Text(String(localized: "onboarding.notif.endAt", defaultValue: "End at"))
                        .font(.custom("NoticiaText-Regular", size: 16))
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

    // MARK: - Notification Preview Card

    private var notificationPreview: some View {
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(String(localized: "onboarding.notif.preview.body",
                            defaultValue: "bussin (adj.) — really good, excellent"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(String(localized: "onboarding.notif.preview.time", defaultValue: "Now"))
                .font(.system(size: 12))
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
            }
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
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
                        defaultValue: "SlangCheck works better\nwith reminders"))
                .font(.custom("NoticiaText-Bold", size: 28))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SlangSpacing.lg)

            Text(String(localized: "onboarding.permission.subtitle",
                        defaultValue: "Enable notifications to receive daily slang drops."))
                .font(.custom("NoticiaText-Regular", size: 16))
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
                        .font(.custom("NoticiaText-Regular", size: 16))
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

/// Final onboarding screen. Tapping anywhere — or the chevron hint — completes the flow.
struct WelcomeSplashStep: View {

    let onContinue: () -> Void
    @State private var showHint = false

    var body: some View {
        ZStack {
            // Centered welcome text
            Text(String(localized: "onboarding.welcome.title",
                        defaultValue: "Welcome to\nSlangCheck"))
                .font(.custom("NoticiaText-Bold", size: 36))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            // Swipe-up hint fades in after a short delay
            VStack {
                Spacer()
                Button(action: onContinue) {
                    VStack(spacing: SlangSpacing.xs) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 20, weight: .medium))
                        Text(String(localized: "onboarding.welcome.swipeUp",
                                    defaultValue: "Swipe up"))
                            .font(.custom("NoticiaText-Regular", size: 15))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(showHint ? 1 : 0)
                .animation(.easeIn(duration: 0.6).delay(0.8), value: showHint)
                .padding(.bottom, SlangSpacing.xxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onContinue() }
        .onAppear { showHint = true }
    }
}
