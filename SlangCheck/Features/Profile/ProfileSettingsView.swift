// Features/Profile/ProfileSettingsView.swift
// SlangCheck
//
// Settings screen pushed from ProfileView.
// Each ABOUT YOU and MAKE IT YOURS item navigates to its own dedicated sub-page.

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
            premiumSection
            aboutYouSection(vm: vm)
            makeItYoursSection
            accountSection(vm: vm)
            supportSection
            followSection
            otherSection
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

    // MARK: - PREMIUM Section

    private var premiumSection: some View {
        Section(String(localized: "settings.section.premium", defaultValue: "PREMIUM")) {
            HStack(spacing: SlangSpacing.md) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SlangColor.primary)
                    .frame(width: 22)
                    .accessibilityHidden(true)
                Text(String(localized: "settings.manageSubscription",
                            defaultValue: "Manage Subscription"))
                    .font(.slang(.body))
                    .foregroundStyle(.primary)
                Spacer()
                Text(String(localized: "settings.comingSoon", defaultValue: "Coming soon"))
                    .font(.slang(.caption))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - ABOUT YOU Section

    @ViewBuilder
    private func aboutYouSection(vm: ProfileSettingsViewModel) -> some View {
        Section(String(localized: "settings.section.aboutYou", defaultValue: "ABOUT YOU")) {
            NavigationLink(destination: NameSettingsView(vm: vm)) {
                settingsRowContent(
                    icon: "person.fill",
                    title: String(localized: "settings.name", defaultValue: "Name"),
                    value: authState.currentProfile?.displayName
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
                    value: UserDefaults.standard.string(forKey: AppConstants.userSegmentKey)
                )
            }
        }
    }

    // MARK: - MAKE IT YOURS Section

    private var makeItYoursSection: some View {
        Section(String(localized: "settings.section.makeItYours", defaultValue: "MAKE IT YOURS")) {
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

    // MARK: - ACCOUNT Section

    @ViewBuilder
    private func accountSection(vm: ProfileSettingsViewModel) -> some View {
        Section(String(localized: "settings.section.account", defaultValue: "ACCOUNT")) {
            if !authState.isAuthenticated {
                Button { showingSignIn = true } label: {
                    HStack(spacing: SlangSpacing.md) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SlangColor.primary)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "settings.signIn", defaultValue: "Sign In"))
                                .font(.slang(.body))
                                .foregroundStyle(.primary)
                            Text(String(localized: "settings.signIn.subtitle",
                                        defaultValue: "Unlock quizzes, streaks & more"))
                                .font(.slang(.caption))
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
                // Change Photo
                PhotosPicker(selection: $photoPicker, matching: .images) {
                    HStack(spacing: SlangSpacing.md) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SlangColor.primary)
                            .frame(width: 22)
                        Text(String(localized: "settings.changePhoto", defaultValue: "Change Photo"))
                            .font(.slang(.body))
                            .foregroundStyle(.primary)
                        Spacer()
                        if vm.isLoading {
                            ProgressView().tint(SlangColor.primary)
                        }
                    }
                }
                .disabled(vm.isLoading)

                // Email (read-only)
                HStack {
                    Text(String(localized: "settings.email", defaultValue: "Email"))
                        .font(.slang(.body)).foregroundStyle(.primary)
                    Spacer()
                    Text(authState.currentProfile?.email ?? "--")
                        .font(.slang(.body)).foregroundStyle(.secondary).lineLimit(1)
                }

                // Sign Out
                Button { showingSignOut = true } label: {
                    Label(
                        String(localized: "settings.signOut", defaultValue: "Sign Out"),
                        systemImage: "rectangle.portrait.and.arrow.right"
                    )
                    .font(.slang(.body))
                    .foregroundStyle(SlangColor.primary)
                }

                // Delete Account
                Button(role: .destructive) { showingDeleteConfirm = true } label: {
                    Label(
                        String(localized: "settings.deleteAccount", defaultValue: "Delete Account"),
                        systemImage: "trash.fill"
                    )
                    .font(.slang(.body))
                }
            }
        }
    }

    // MARK: - SUPPORT US Section

    private var supportSection: some View {
        Section(String(localized: "settings.section.support", defaultValue: "SUPPORT US")) {
            Button { shareApp() } label: {
                settingsActionRow(
                    icon: "square.and.arrow.up",
                    title: String(localized: "settings.share", defaultValue: "Share SlangCheck")
                )
            }
            .buttonStyle(.plain)

            Button {} label: {
                settingsActionRow(
                    icon: "star.fill",
                    title: String(localized: "settings.review", defaultValue: "Leave a Review")
                )
            }
            .buttonStyle(.plain)

            Button {} label: {
                settingsActionRow(
                    icon: "hand.thumbsup.fill",
                    title: String(localized: "settings.vote", defaultValue: "Vote on Next Features")
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - FOLLOW US Section

    private var followSection: some View {
        Section(String(localized: "settings.section.follow", defaultValue: "FOLLOW US")) {
            settingsLinkRow(icon: "camera", title: "Instagram", urlString: "https://instagram.com")
            settingsLinkRow(icon: "person.2.fill", title: "Facebook", urlString: "https://facebook.com")
            settingsLinkRow(icon: "xmark", title: "X (formerly Twitter)", urlString: "https://x.com")
        }
    }

    // MARK: - OTHER Section

    private var otherSection: some View {
        Section(String(localized: "settings.section.other", defaultValue: "OTHER")) {
            settingsLinkRow(
                icon: "lock.shield",
                title: String(localized: "settings.privacy", defaultValue: "Privacy Policy"),
                urlString: "https://slangcheck.app/privacy"
            )
            settingsLinkRow(
                icon: "doc.text",
                title: String(localized: "settings.terms", defaultValue: "Terms and Conditions"),
                urlString: "https://slangcheck.app/terms"
            )
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
                .font(.slang(.body))
                .foregroundStyle(.primary)
            Spacer()
            if let value {
                Text(value)
                    .font(.slang(.caption))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private func settingsActionRow(icon: String, title: String) -> some View {
        HStack(spacing: SlangSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SlangColor.primary)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(title)
                .font(.slang(.body))
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(.tertiaryLabel))
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func settingsLinkRow(icon: String, title: String, urlString: String) -> some View {
        if let url = URL(string: urlString) {
            Link(destination: url) {
                HStack(spacing: SlangSpacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(SlangColor.primary)
                        .frame(width: 22)
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.slang(.body))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .accessibilityHidden(true)
                }
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func shareApp() {
        let text = String(
            localized: "settings.share.message",
            defaultValue: "Check out SlangCheck — learn Gen Z slang and level up your rizz. slangcheck.app"
        )
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first(where: \.isKeyWindow)?
            .rootViewController
        var presenter = rootVC
        while let presented = presenter?.presentedViewController { presenter = presented }
        presenter?.present(vc, animated: true)
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
