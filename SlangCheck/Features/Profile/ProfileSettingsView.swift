// Features/Profile/ProfileSettingsView.swift
// SlangCheck
//
// Settings screen for authenticated users: edit display name, upload profile photo,
// sign out, and delete account. Accessed from the Profile tab nav row.

import PhotosUI
import SwiftUI

// MARK: - ProfileSettingsView

/// The settings screen for an authenticated user.
struct ProfileSettingsView: View {

    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ProfileSettingsViewModel?
    @State private var photoPicker:       PhotosPickerItem? = nil
    @State private var showingSignOut:    Bool = false
    @State private var showingDeleteConfirm: Bool = false

    var body: some View {
        Group {
            if let vm = viewModel {
                content(vm: vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(SlangColor.background.ignoresSafeArea())
            }
        }
        .task {
            guard viewModel == nil else { return }
            viewModel = ProfileSettingsViewModel(authState: authState)
        }
        .onChange(of: authState.isAuthenticated) { _, authenticated in
            // If the user signs out or deletes their account, dismiss this screen.
            if !authenticated { dismiss() }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(vm: ProfileSettingsViewModel) -> some View {
        NavigationStack {
            List {
                profilePhotoSection(vm: vm)
                accountInfoSection
                displayNameSection(vm: vm)
                actionsSection(vm: vm)
                dangerSection(vm: vm)
            }
            .listStyle(.insetGrouped)
            .background(SlangColor.background.ignoresSafeArea())
            .navigationTitle(String(localized: "settings.title", defaultValue: "Settings"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "settings.done", defaultValue: "Done")) {
                        dismiss()
                    }
                    .font(.slang(.body))
                }
            }
            // Error banner
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
            // Sign-out confirmation
            .confirmationDialog(
                String(localized: "settings.signOut.title", defaultValue: "Sign Out?"),
                isPresented: $showingSignOut,
                titleVisibility: .visible
            ) {
                Button(String(localized: "settings.signOut.confirm", defaultValue: "Sign Out"),
                       role: .destructive) { vm.signOut() }
                Button(String(localized: "settings.signOut.cancel", defaultValue: "Cancel"),
                       role: .cancel) {}
            } message: {
                Text(String(localized: "settings.signOut.message",
                            defaultValue: "You'll need to sign back in to play Quiz & Daily Crossword."))
            }
            // Delete account confirmation
            .confirmationDialog(
                String(localized: "settings.deleteAccount.title", defaultValue: "Delete Account?"),
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(String(localized: "settings.deleteAccount.confirm", defaultValue: "Delete"),
                       role: .destructive) {
                    Task { await vm.deleteAccount() }
                }
                Button(String(localized: "settings.deleteAccount.cancel", defaultValue: "Cancel"),
                       role: .cancel) {}
            } message: {
                Text(String(localized: "settings.deleteAccount.message",
                            defaultValue: "This permanently deletes your account and all data. This cannot be undone."))
            }
        }
        // Photo picker — watch for selection and upload
        .photosPicker(
            isPresented: Binding(
                get: { photoPicker != nil },
                set: { if !$0 { photoPicker = nil } }
            ),
            selection: $photoPicker,
            matching: .images
        )
        .onChange(of: photoPicker) { _, item in
            guard let item else { return }
            Task {
                if let data  = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await vm.uploadPhoto(image)
                }
                photoPicker = nil
            }
        }
    }

    // MARK: - Profile Photo Section

    @ViewBuilder
    private func profilePhotoSection(vm: ProfileSettingsViewModel) -> some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: SlangSpacing.sm) {
                    profileAvatar(vm: vm)
                    PhotosPicker(
                        selection: $photoPicker,
                        matching: .images
                    ) {
                        if vm.isLoading {
                            ProgressView().tint(SlangColor.primary)
                        } else {
                            Label(
                                String(localized: "settings.changePhoto",
                                       defaultValue: "Change Photo"),
                                systemImage: "camera.fill"
                            )
                            .font(.slang(.caption))
                            .foregroundStyle(SlangColor.primary)
                        }
                    }
                    .disabled(vm.isLoading)
                }
                Spacer()
            }
            .padding(.vertical, SlangSpacing.sm)
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private func profileAvatar(vm: ProfileSettingsViewModel) -> some View {
        ZStack {
            Circle()
                .fill(SlangColor.primary.opacity(0.12))
                .frame(width: 88, height: 88)

            if let url = authState.currentProfile?.photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 88, height: 88)
                            .clipShape(Circle())
                    default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .overlay(
            Circle()
                .strokeBorder(SlangColor.primary.opacity(0.2), lineWidth: 2)
        )
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 36, weight: .light))
            .foregroundStyle(SlangColor.primary.opacity(0.6))
    }

    // MARK: - Account Info Section

    @ViewBuilder
    private var accountInfoSection: some View {
        Section(String(localized: "settings.section.account", defaultValue: "Account")) {
            infoRow(
                label: String(localized: "settings.username", defaultValue: "Username"),
                value: authState.currentProfile?.username ?? "--"
            )
            infoRow(
                label: String(localized: "settings.email", defaultValue: "Email"),
                value: authState.currentProfile?.email ?? "--"
            )
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.slang(.body))
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(.slang(.body))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Display Name Section

    @ViewBuilder
    private func displayNameSection(vm: ProfileSettingsViewModel) -> some View {
        Section(String(localized: "settings.section.profile", defaultValue: "Profile")) {
            HStack(spacing: SlangSpacing.sm) {
                TextField(
                    String(localized: "settings.displayName", defaultValue: "Display Name"),
                    text: Binding(
                        get: { vm.pendingDisplayName },
                        set: { vm.pendingDisplayName = $0 }
                    )
                )
                .font(.slang(.body))
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { Task { await vm.saveDisplayName() } }

                if vm.displayNameSaved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(SlangColor.secondary)
                        .transition(.scale.combined(with: .opacity))
                } else if vm.pendingDisplayName != authState.currentProfile?.displayName {
                    Button {
                        Task { await vm.saveDisplayName() }
                    } label: {
                        Text(String(localized: "settings.save", defaultValue: "Save"))
                            .font(.slang(.caption))
                            .foregroundStyle(.white)
                            .padding(.horizontal, SlangSpacing.sm)
                            .padding(.vertical, SlangSpacing.xs)
                            .background(Capsule().fill(SlangColor.primary))
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isLoading)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: vm.displayNameSaved)
        }
    }

    // MARK: - Actions Section

    @ViewBuilder
    private func actionsSection(vm: ProfileSettingsViewModel) -> some View {
        Section {
            Button {
                showingSignOut = true
            } label: {
                Label(
                    String(localized: "settings.signOut", defaultValue: "Sign Out"),
                    systemImage: "rectangle.portrait.and.arrow.right"
                )
                .font(.slang(.body))
                .foregroundStyle(SlangColor.primary)
            }
        }
    }

    // MARK: - Danger Zone

    @ViewBuilder
    private func dangerSection(vm: ProfileSettingsViewModel) -> some View {
        Section(String(localized: "settings.section.danger", defaultValue: "Danger Zone")) {
            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Label(
                    String(localized: "settings.deleteAccount", defaultValue: "Delete Account"),
                    systemImage: "trash.fill"
                )
                .font(.slang(.body))
            }
        }
    }
}

// MARK: - Preview

#Preview("ProfileSettingsView") {
    let authState = AuthState(
        authService:       NoOpAuthenticationService(),
        profileRepository: NoOpUserProfileRepository()
    )
    return ProfileSettingsView()
        .environment(authState)
        .environment(\.appEnvironment, .preview())
}
