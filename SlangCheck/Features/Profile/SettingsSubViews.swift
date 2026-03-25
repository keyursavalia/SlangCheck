// Features/Profile/SettingsSubViews.swift
// SlangCheck
//
// Dedicated sub-page views for each settings category.
// Pushed from SettingsView via NavigationLink inside ProfileView's NavigationStack.

import SwiftUI
import UserNotifications

// MARK: - NameSettingsView

/// Lets the user change their display name.
struct NameSettingsView: View {

    @Bindable var vm: ProfileSettingsViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        List {
            Section {
                TextField(
                    String(localized: "settings.name.placeholder", defaultValue: "Your name"),
                    text: Binding(
                        get: { vm.pendingDisplayName },
                        set: { vm.pendingDisplayName = $0 }
                    )
                )
                .font(.system(size: 17))
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isFocused)
                .onSubmit { Task { await vm.saveDisplayName() } }
            } footer: {
                Text(String(localized: "settings.name.footer",
                            defaultValue: "This name is visible to you across the app."))
                    .font(.system(size: 13))
            }

            Section {
                Button {
                    Task { await vm.saveDisplayName() }
                } label: {
                    HStack {
                        Spacer()
                        if vm.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(String(localized: "settings.save", defaultValue: "Save"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: SlangCornerRadius.cell)
                        .fill(SlangColor.primary)
                )
                .disabled(vm.isLoading || vm.pendingDisplayName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.name", defaultValue: "Name"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear { isFocused = true }
    }
}

// MARK: - GenderSettingsView

/// Lets the user select or update their gender identity.
struct GenderSettingsView: View {

    @AppStorage("userGender") private var selectedGender: String = ""

    private let options = OnboardingGender.allCases.map(\.rawValue)

    var body: some View {
        List {
            Section {
                ForEach(options, id: \.self) { option in
                    Button {
                        selectedGender = option
                    } label: {
                        HStack {
                            Text(option)
                                .font(.system(size: 17))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedGender == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(SlangColor.primary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.gender", defaultValue: "Gender Identity"))
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - AgeSettingsView

/// Lets the user select their age range.
struct AgeSettingsView: View {

    @AppStorage("userAgeRange") private var selectedAge: String = ""

    private let options = ["Under 18", "18–24", "25–34", "35–44", "45+"]

    var body: some View {
        List {
            Section {
                ForEach(options, id: \.self) { option in
                    Button {
                        selectedAge = option
                    } label: {
                        HStack {
                            Text(option)
                                .font(.system(size: 17))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedAge == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(SlangColor.primary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.age", defaultValue: "Age"))
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - SlangLevelSettingsView

/// Lets the user update their self-reported slang level.
struct SlangLevelSettingsView: View {

    @AppStorage(AppConstants.userSegmentKey) private var selectedSegment: String = ""

    private let options = OnboardingSlangLevel.allCases

    var body: some View {
        List {
            Section {
                ForEach(options, id: \.rawValue) { level in
                    Button {
                        selectedSegment = segmentValue(for: level)
                    } label: {
                        HStack {
                            Text(level.rawValue)
                                .font(.system(size: 17))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedSegment == segmentValue(for: level) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(SlangColor.primary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text(String(localized: "settings.level.footer",
                            defaultValue: "Your level helps personalize your learning experience."))
                    .font(.system(size: 13))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.level", defaultValue: "Slang Level"))
        .navigationBarTitleDisplayMode(.large)
    }

    private func segmentValue(for level: OnboardingSlangLevel) -> String {
        switch level {
        case .newbie:     return UserSegment.unc.rawValue
        case .someBasics: return UserSegment.trendSeeker.rawValue
        case .fluent:     return UserSegment.languageEnthusiast.rawValue
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
                .font(.system(size: 17))
            }

            if notificationsEnabled {
                Section(String(localized: "settings.notifications.schedule",
                               defaultValue: "SCHEDULE")) {
                    HStack {
                        Text(String(localized: "settings.notifications.howMany",
                                    defaultValue: "Daily reminders"))
                            .font(.system(size: 17))
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
                                .font(.system(size: 17, weight: .semibold))
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
                    .font(.system(size: 17))

                    DatePicker(
                        String(localized: "settings.notifications.endAt",
                               defaultValue: "End at"),
                        selection: $endTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(.system(size: 17))
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
                                    .font(.system(size: 17))
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
                        .font(.system(size: 13))
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
                            .font(.system(size: 17))
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
                    .font(.system(size: 13))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(SlangColor.background.ignoresSafeArea())
        .navigationTitle(String(localized: "settings.language", defaultValue: "Language"))
        .navigationBarTitleDisplayMode(.large)
    }
}
