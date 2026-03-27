// Features/Profile/ProfileSettingsViewModel.swift
// SlangCheck
//
// ViewModel for the Profile Settings screen.
// Handles display name editing, profile photo upload (compress → upload → patch URL),
// sign-out, and account deletion (with Firestore cleanup before Auth deletion).

import Foundation
import OSLog
import UIKit

// MARK: - ProfileSettingsViewModel

/// `@MainActor` `@Observable` ViewModel for `ProfileSettingsView`.
@MainActor
@Observable
final class ProfileSettingsViewModel {

    // MARK: - State

    /// The display name currently being edited.
    var pendingDisplayName: String = ""

    /// `true` while any async operation (save, upload, delete) is in flight.
    var isLoading: Bool = false

    /// Non-nil when an error should be shown in the UI.
    var errorMessage: String? = nil

    /// `true` after a display name save succeeds — drives a brief confirmation tick.
    var displayNameSaved: Bool = false

    // MARK: - Private

    private let authState: AuthState

    // MARK: - Init

    init(authState: AuthState) {
        self.authState = authState
        self.pendingDisplayName = authState.currentProfile?.displayName ?? ""
    }

    // MARK: - Display Name

    /// Persists the edited display name to Firestore and updates the in-memory profile.
    func saveDisplayName() async {
        let trimmed = pendingDisplayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            errorMessage = String(localized: "settings.error.emptyName",
                                  defaultValue: "Display name cannot be empty.")
            return
        }
        guard trimmed != authState.currentProfile?.displayName else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authState.updateDisplayName(trimmed)
            displayNameSaved = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                displayNameSaved = false
            }
        } catch {
            errorMessage = error.localizedDescription
            Logger.app.error("saveDisplayName failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Profile Photo

    /// Resizes and compresses the picked `UIImage`, then uploads to Firebase Storage.
    ///
    /// Resize target: 800 × 800 px max (square, aspect-fit). JPEG quality: 0.72.
    /// Typical result: 80–300 KB — well within the 1 MB Storage rule.
    func uploadPhoto(_ image: UIImage) async {
        guard let data = compress(image) else {
            errorMessage = String(localized: "settings.error.photoCompress",
                                  defaultValue: "Could not process the selected photo.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authState.updateProfilePhoto(data: data)
        } catch {
            errorMessage = error.localizedDescription
            Logger.app.error("uploadPhoto failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Preferences Sync

    /// Syncs a single preference field to Firestore (if authenticated).
    func syncPreference(_ prefs: UserPreferences) {
        guard authState.isAuthenticated else { return }
        Task {
            do {
                try await authState.updatePreferences(prefs)
            } catch {
                Logger.app.error("syncPreference failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        authState.signOut()
    }

    // MARK: - Delete Account

    /// Deletes the Firestore document then the Firebase Auth account.
    /// `AuthState.deleteAccount()` clears `currentProfile` on completion.
    func deleteAccount() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await authState.deleteAccount()
        } catch {
            errorMessage = error.localizedDescription
            Logger.app.error("deleteAccount failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Compression

    /// Scales `image` to fit within 800 × 800 px, then encodes as JPEG at 0.72 quality.
    private func compress(_ image: UIImage) -> Data? {
        let maxDimension: CGFloat = 800
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1)
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized  = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.72)
    }
}
