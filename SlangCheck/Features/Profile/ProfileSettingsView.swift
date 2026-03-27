// Features/Profile/ProfileSettingsView.swift
// SlangCheck
//
// Settings screen pushed from ProfileView.
// Each About You and Make It Yours item navigates to its own dedicated sub-page.

import PhotosUI
import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {

    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ProfileSettingsViewModel?
    @State private var photoPicker: PhotosPickerItem? = nil
    @State private var showingSignOut = false
    @State private var showingDeleteConfirm = false
    @State private var showingSignIn = false

    var body: some View {
        Group {
            if let vm = viewModel {
                settingsList(vm: vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(SlangColor.background.ignoresSafeArea())
            }
        }
        .navigationTitle(String(localized: "settings.title", defaultValue: "Settings"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            guard viewModel == nil else { return }
            viewModel = ProfileSettingsViewModel(authState: authState)
        }
        .onChange(of: authState.isAuthenticated) { _, authenticated in
            if !authenticated { dismiss() }
        }
    }

    // MARK: - Settings List

    @ViewBuilder
    private func settingsList(vm: ProfileSettingsViewModel) -> some View {
        List {
            aboutYouSection(vm: vm)
            makeItYoursSection
            accountSection(vm: vm)
            footerSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(SlangColor.background.ignoresSafeArea())
        .alert(
            String(localized: "settings.error.title", defaultValue: "Something went wrong"),
            isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .confirmationDialog(
            String(localized: "settings.signOut.title", defaultValue: "Sign Out?"),
            isPresented: $showingSignOut,
            titleVisibility: .visible
        ) {
            Button(
                String(localized: "settings.signOut.confirm", defaultValue: "Sign Out"),
                role: .destructive
            ) { vm.signOut() }
            Button(
                String(localized: "settings.signOut.cancel", defaultValue: "Cancel"),
                role: .cancel
            ) {}
        } message: {
            Text(String(
                localized: "settings.signOut.message",
                defaultValue: "You'll need to sign back in to play Quiz & Daily Crossword."
            ))
        }
        .confirmationDialog(
            String(localized: "settings.deleteAccount.title", defaultValue: "Delete Account?"),
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(
                String(localized: "settings.deleteAccount.confirm", defaultValue: "Delete"),
                role: .destructive
            ) {
                Task { await vm.deleteAccount() }
            }
            Button(
                String(localized: "settings.deleteAccount.cancel", defaultValue: "Cancel"),
                role: .cancel
            ) {}
        } message: {
            Text(String(
                localized: "settings.deleteAccount.message",
                defaultValue: "This permanently deletes your account and all data. This cannot be undone."
            ))
        }
        .sheet(isPresented: $showingSignIn) {
            AuthGateView(onSuccess: { showingSignIn = false })
        }
        .onChange(of: photoPicker) { _, item in
            guard let item, let vm = viewModel else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await vm.uploadPhoto(image)
                }
                photoPicker = nil
            }
        }
    }

    // MARK: - About You Section

    @ViewBuilder
    private func aboutYouSection(vm: ProfileSettingsViewModel) -> some View {
        Section(String(localized: "settings.section.aboutYou", defaultValue: "About you")) {
            NavigationLink(destination: NameSettingsView(vm: vm)) {
                settingsRowContent(
                    icon: "person.fill",
                    title: String(localized: "settings.name", defaultValue: "Name"),
                    value: authState.currentProfile?.displayName
                        ?? UserDefaults.standard.string(forKey: "userDisplayName")
                )
            }
            NavigationLink(destination: GenderSettingsView()) {
                settingsRowContent(
                    icon: "person.2.fill",
                    title: String(localized: "settings.gender", defaultValue: "Gender Identity"),
                    value: UserDefaults.standard.string(forKey: "userGender")
                )
            }
            NavigationLink(destination: AgeSettingsView()) {
                settingsRowContent(
                    icon: "calendar",
                    title: String(localized: "settings.age", defaultValue: "Age"),
                    value: UserDefaults.standard.string(forKey: "userAgeRange")
                )
            }
            NavigationLink(destination: SlangLevelSettingsView()) {
                settingsRowContent(
                    icon: "chart.line.uptrend.xyaxis",
                    title: String(localized: "settings.level", defaultValue: "Slang Level"),
                    value: slangLevelDisplayValue
                )
            }
            NavigationLink(destination: GoalSettingsView()) {
                settingsRowContent(
                    icon: "target",
                    title: String(localized: "settings.goal", defaultValue: "Goal"),
                    value: UserDefaults.standard.string(forKey: "userGoal")
                )
            }
        }
    }

    /// Maps the stored UserSegment rawValue to the OnboardingSlangLevel display text.
    private var slangLevelDisplayValue: String? {
        guard let raw = UserDefaults.standard.string(forKey: AppConstants.userSegmentKey) else {
            return nil
        }
        switch raw {
        case UserSegment.unc.rawValue:              return OnboardingSlangLevel.newbie.rawValue
        case UserSegment.trendSeeker.rawValue:       return OnboardingSlangLevel.someBasics.rawValue
        case UserSegment.languageEnthusiast.rawValue: return OnboardingSlangLevel.fluent.rawValue
        default: return raw
        }
    }

    // MARK: - Make It Yours Section

    private var makeItYoursSection: some View {
        Section(String(localized: "settings.section.makeItYours", defaultValue: "Make it yours")) {
            NavigationLink(destination: NotificationSettingsView()) {
                settingsRowContent(
                    icon: "bell.fill",
                    title: String(localized: "settings.notifications", defaultValue: "Notifications"),
                    value: nil
                )
            }
            NavigationLink(destination: LanguageSettingsView()) {
                settingsRowContent(
                    icon: "globe",
                    title: String(localized: "settings.language", defaultValue: "Language"),
                    value: String(localized: "settings.language.english", defaultValue: "English")
                )
            }
        }
    }

    // MARK: - Account Section

    @ViewBuilder
    private func accountSection(vm: ProfileSettingsViewModel) -> some View {
        Section(String(localized: "settings.section.account", defaultValue: "Account")) {
            if !authState.isAuthenticated {
                Button { showingSignIn = true } label: {
                    HStack(spacing: SlangSpacing.md) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SlangColor.primary)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "settings.signIn", defaultValue: "Sign In"))
                                .font(.montserrat(size: 17))
                                .foregroundStyle(.primary)
                            Text(String(localized: "settings.signIn.subtitle",
                                        defaultValue: "Unlock quizzes, streaks & more"))
                                .font(.montserrat(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                    .padding(.vertical, SlangSpacing.xs)
                }
                .buttonStyle(.plain)
            } else {
                // Change Photo — redesigned as a teal pill
                PhotosPicker(selection: $photoPicker, matching: .images) {
                    HStack {
                        Spacer()
                        if vm.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Label(
                                String(localized: "settings.changePhoto",
                                       defaultValue: "Change Photo"),
                                systemImage: "camera.fill"
                            )
                            .font(.montserrat(size: 16, weight: .semibold))
                            .foregroundStyle(Color(.label))
                        }
                        Spacer()
                    }
                    .frame(height: 48)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(SlangColor.onboardingTeal)
                )
                .disabled(vm.isLoading)

                // Email (read-only)
                HStack {
                    Text(String(localized: "settings.email", defaultValue: "Email"))
                        .font(.montserrat(size: 17)).foregroundStyle(.primary)
                    Spacer()
                    Text(authState.currentProfile?.email ?? "--")
                        .font(.montserrat(size: 17)).foregroundStyle(.secondary).lineLimit(1)
                }

                // Sign Out — teal pill button
                Button { showingSignOut = true } label: {
                    HStack {
                        Spacer()
                        Text(String(localized: "settings.signOut", defaultValue: "Sign Out"))
                            .font(.montserrat(size: 16, weight: .semibold))
                            .foregroundStyle(Color(.label))
                        Spacer()
                    }
                    .frame(height: 48)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(SlangColor.onboardingTeal)
                )

                // Delete Account — red pill button
                Button { showingDeleteConfirm = true } label: {
                    HStack {
                        Spacer()
                        Text(String(localized: "settings.deleteAccount",
                                    defaultValue: "Delete Account"))
                            .font(.montserrat(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .frame(height: 48)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(SlangColor.errorRed)
                )
            }
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                       let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        Text("SlangCheck v\(version) (\(build))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    if let uid = authState.currentProfile?.id {
                        Text("User ID: \(uid)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color(.tertiaryLabel))
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Row Helpers

    private func settingsRowContent(icon: String, title: String, value: String?) -> some View {
        HStack(spacing: SlangSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SlangColor.primary)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(title)
                .font(.montserrat(size: 17))
                .foregroundStyle(.primary)
            Spacer()
            if let value {
                Text(value)
                    .font(.montserrat(size: 15))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Preview

#Preview("SettingsView") {
    NavigationStack { SettingsView() }
        .environment(AuthState(
            authService: NoOpAuthenticationService(),
            profileRepository: NoOpUserProfileRepository()
        ))
        .environment(\.appEnvironment, .preview())
}
