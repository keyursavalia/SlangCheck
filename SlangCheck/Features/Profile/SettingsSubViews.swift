// Features/Profile/SettingsSubViews.swift
// SlangCheck
//
// Dedicated sub-page views for each settings category.
// Pushed from SettingsView via NavigationLink inside ProfileView's NavigationStack.
// UI matches onboarding style (pill rows with drop shadows, Save/back button).

import SwiftUI
import UserNotifications

// MARK: - NameSettingsView

/// Lets the user change their display name.
struct NameSettingsView: View {

    @Bindable var vm: ProfileSettingsViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: SlangSpacing.xl)

            TextField(
                String(localized: "settings.name.placeholder", defaultValue: "Your name"),
                text: Binding(
                    get: { vm.pendingDisplayName },
                    set: { vm.pendingDisplayName = $0 }
                )
            )
            .font(.custom("Montserrat-Regular", size: 17))
            .textFieldStyle(.plain)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($isFocused)
            .onSubmit { Task { await vm.saveDisplayName() } }
            .padding(.horizontal, SlangSpacing.md)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.systemBackground))
            }
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(SlangColor.hardShadow)
                    .offset(y: 4)
            }
            .padding(.horizontal, SlangSpacing.md)

            Text(String(localized: "settings.name.footer",
                        defaultValue: "This name is visible to you across the app."))
                .font(.montserrat(size: 13))
                .foregroundStyle(.secondary)
                .padding(.horizontal, SlangSpacing.lg)
                .padding(.top, SlangSpacing.sm)

            Spacer()

            settingsSaveButton {
                Task { await vm.saveDisplayName() }
            }
            .disabled(vm.isLoading || vm.pendingDisplayName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.name", defaultValue: "Name"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear { isFocused = true }
    }
}

// MARK: - GenderSettingsView

/// Lets the user select or update their gender identity.
struct GenderSettingsView: View {

    @Environment(AuthState.self) private var authState
    @AppStorage("userGender") private var selectedGender: String = ""

    private let options = OnboardingGender.allCases.map(\.rawValue)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: SlangSpacing.xl)

            VStack(spacing: SlangSpacing.sm) {
                ForEach(options, id: \.self) { option in
                    OnboardingOptionRow(
                        label: option,
                        isSelected: selectedGender == option,
                        action: { selectedGender = option }
                    )
                }
            }
            .padding(.horizontal, SlangSpacing.md)

            Spacer()
        }
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.gender", defaultValue: "Gender Identity"))
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: selectedGender) { _, newValue in
            syncToFirestore(UserPreferences(gender: newValue))
        }
    }

    private func syncToFirestore(_ prefs: UserPreferences) {
        guard authState.isAuthenticated else { return }
        Task { try? await authState.updatePreferences(prefs) }
    }
}

// MARK: - AgeSettingsView

/// Lets the user select their age range.
struct AgeSettingsView: View {

    @Environment(AuthState.self) private var authState
    @AppStorage("userAgeRange") private var selectedAge: String = ""

    private let options = ["Under 18", "18–24", "25–34", "35–44", "45+"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: SlangSpacing.xl)

            VStack(spacing: SlangSpacing.sm) {
                ForEach(options, id: \.self) { option in
                    OnboardingOptionRow(
                        label: option,
                        isSelected: selectedAge == option,
                        action: { selectedAge = option }
                    )
                }
            }
            .padding(.horizontal, SlangSpacing.md)

            Spacer()
        }
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.age", defaultValue: "Age"))
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: selectedAge) { _, newValue in
            guard authState.isAuthenticated else { return }
            Task { try? await authState.updatePreferences(UserPreferences(ageRange: newValue)) }
        }
    }
}

// MARK: - SlangLevelSettingsView

/// Lets the user update their self-reported slang level.
struct SlangLevelSettingsView: View {

    @Environment(AuthState.self) private var authState
    @AppStorage(AppConstants.userSegmentKey) private var selectedSegment: String = ""

    private let options = OnboardingSlangLevel.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: SlangSpacing.xl)

            VStack(spacing: SlangSpacing.sm) {
                ForEach(options, id: \.rawValue) { level in
                    OnboardingOptionRow(
                        label: level.rawValue,
                        isSelected: selectedSegment == segmentValue(for: level),
                        action: { selectedSegment = segmentValue(for: level) }
                    )
                }
            }
            .padding(.horizontal, SlangSpacing.md)

            Text(String(localized: "settings.level.footer",
                        defaultValue: "Your level helps personalize your learning experience."))
                .font(.montserrat(size: 13))
                .foregroundStyle(.secondary)
                .padding(.horizontal, SlangSpacing.lg)
                .padding(.top, SlangSpacing.md)

            Spacer()
        }
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.level", defaultValue: "Slang Level"))
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: selectedSegment) { _, newValue in
            guard authState.isAuthenticated else { return }
            Task { try? await authState.updatePreferences(UserPreferences(slangLevel: newValue)) }
        }
    }

    private func segmentValue(for level: OnboardingSlangLevel) -> String {
        switch level {
        case .newbie:     return UserSegment.unc.rawValue
        case .someBasics: return UserSegment.trendSeeker.rawValue
        case .fluent:     return UserSegment.languageEnthusiast.rawValue
        }
    }
}

// MARK: - GoalSettingsView

/// Lets the user update their learning goal.
struct GoalSettingsView: View {

    @Environment(AuthState.self) private var authState
    @AppStorage("userGoal") private var selectedGoal: String = ""

    private let options = OnboardingGoal.allCases.map(\.rawValue)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: SlangSpacing.xl)

            VStack(spacing: SlangSpacing.sm) {
                ForEach(options, id: \.self) { option in
                    OnboardingOptionRow(
                        label: option,
                        isSelected: selectedGoal == option,
                        action: { selectedGoal = option }
                    )
                }
            }
            .padding(.horizontal, SlangSpacing.md)

            Spacer()
        }
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.goal", defaultValue: "Goal"))
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: selectedGoal) { _, newValue in
            guard authState.isAuthenticated else { return }
            Task { try? await authState.updatePreferences(UserPreferences(goal: newValue)) }
        }
    }
}

// MARK: - NotificationSettingsView

/// Notification preferences: enable/disable, count, and time window.
struct NotificationSettingsView: View {

    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("notificationCount") private var count: Int = 10
    @State private var startTime: Date = Calendar.current
        .date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime: Date = Calendar.current
        .date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        List {
            Section {
                Toggle(
                    String(localized: "settings.notifications.enable",
                           defaultValue: "Enable Notifications"),
                    isOn: $notificationsEnabled
                )
                .tint(SlangColor.onboardingTeal)
                .font(.montserrat(size: 17))
            }

            if notificationsEnabled {
                Section(String(localized: "settings.notifications.schedule",
                               defaultValue: "Schedule")) {
                    HStack {
                        Text(String(localized: "settings.notifications.howMany",
                                    defaultValue: "Daily reminders"))
                            .font(.montserrat(size: 17))
                            .foregroundStyle(.primary)
                        Spacer()
                        HStack(spacing: SlangSpacing.md) {
                            Button {
                                if count > 1 { count -= 1 }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(SlangColor.primary)
                            }
                            .buttonStyle(.plain)
                            Text("\(count)")
                                .font(.montserrat(size: 17, weight: .semibold))
                                .frame(minWidth: 28, alignment: .center)
                            Button {
                                if count < 20 { count += 1 }
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(SlangColor.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    DatePicker(
                        String(localized: "settings.notifications.startAt",
                               defaultValue: "Start at"),
                        selection: $startTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.montserrat(size: 17))

                    DatePicker(
                        String(localized: "settings.notifications.endAt",
                               defaultValue: "End at"),
                        selection: $endTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.montserrat(size: 17))
                }
            }

            if permissionStatus == .denied {
                Section {
                    // SAFE: openSettingsURLString is a compile-time constant known-valid URL.
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        Link(destination: url) {
                            HStack {
                                Text(String(localized: "settings.notifications.openSettings",
                                            defaultValue: "Enable in iOS Settings"))
                                    .font(.montserrat(size: 17))
                                    .foregroundStyle(SlangColor.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                        }
                    }
                } footer: {
                    Text(String(localized: "settings.notifications.deniedFooter",
                                defaultValue: "Notifications are blocked. Open iOS Settings to allow them."))
                        .font(.montserrat(size: 13))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.notifications", defaultValue: "Notifications"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            permissionStatus = settings.authorizationStatus
        }
    }
}

// MARK: - LanguageSettingsView

/// Placeholder for future multi-language support.
struct LanguageSettingsView: View {

    private let languages = ["English"]

    var body: some View {
        List {
            Section {
                ForEach(languages, id: \.self) { lang in
                    HStack {
                        Text(lang)
                            .font(.montserrat(size: 17))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SlangColor.primary)
                    }
                }
            } footer: {
                Text(String(localized: "settings.language.footer",
                            defaultValue: "More languages coming soon."))
                    .font(.montserrat(size: 13))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.language", defaultValue: "Language"))
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Shared Save Button

/// Onboarding-style pill save button with hard drop shadow for settings sub-pages.
private func settingsSaveButton(action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(String(localized: "settings.save", defaultValue: "Save"))
            .font(.custom("Montserrat-Bold", size: 18))
            .foregroundStyle(Color(.label))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(SlangColor.onboardingTeal)
            }
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(SlangColor.hardShadow)
                    .offset(y: 4)
            }
    }
    .buttonStyle(.plain)
    .padding(.horizontal, SlangSpacing.md)
    .padding(.bottom, SlangSpacing.xl)
}
