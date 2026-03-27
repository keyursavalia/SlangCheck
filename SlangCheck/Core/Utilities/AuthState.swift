// Core/Utilities/AuthState.swift
// SlangCheck
//
// Global observable authentication state. Injected into the SwiftUI environment once
// at the app root via `.environment(authState)`. Every view that needs to know if the
// user is signed in reads from this object — never from Firebase directly.
//
// Lifecycle:
//   1. App launches → SlangCheckApp creates AuthState and calls `reload()`.
//   2. If Firebase has a persisted session, `reload()` fetches the Firestore profile
//      and sets `currentProfile`, making `isAuthenticated` true.
//   3. On sign-in: `handleSignIn(uid:email:displayName:)` creates the profile if new,
//      fetches it if existing, and sets `currentProfile`.
//   4. On sign-out / delete: `currentProfile` is cleared.

import Foundation
import OSLog

// MARK: - AuthState

/// `@MainActor` observable that is the single source of truth for sign-in status.
///
/// Inject at the app root:
/// ```swift
/// WindowGroup { RootView().environment(authState) }
/// ```
/// Consume in any view:
/// ```swift
/// @Environment(AuthState.self) private var authState
/// ```
@MainActor
@Observable
public final class AuthState {

    // MARK: - Public State

    /// The signed-in user's profile, or `nil` when unauthenticated.
    public private(set) var currentProfile: UserProfile?

    /// `true` when a Firebase user is signed in and their Firestore profile is loaded.
    public var isAuthenticated: Bool { currentProfile != nil }

    // MARK: - Private

    private let authService: any AuthenticationService
    private let profileRepository: any UserProfileRepository

    // MARK: - Init

    public init(
        authService: any AuthenticationService,
        profileRepository: any UserProfileRepository
    ) {
        self.authService       = authService
        self.profileRepository = profileRepository
    }

    // MARK: - Public API

    /// Re-fetches the profile from Firestore using the currently persisted Firebase UID.
    /// Call once at app launch to restore session state.
    public func reload() async {
        guard let uid = authService.currentUserID else {
            currentProfile = nil
            return
        }
        do {
            currentProfile = try await profileRepository.fetchProfile(uid: uid)
        } catch {
            Logger.app.error("AuthState.reload failed: \(error.localizedDescription)")
            currentProfile = nil
        }
    }

    /// Called immediately after a successful sign-in or account creation.
    ///
    /// - Fetches an existing Firestore profile, or creates a new one on first sign-in.
    /// - Sets `currentProfile` so downstream views update instantly.
    public func handleSignIn(uid: String, email: String, displayName: String?) async {
        do {
            if let existing = try await profileRepository.fetchProfile(uid: uid) {
                currentProfile = existing
                // Sync any locally-collected onboarding data that isn't in Firestore yet.
                await syncLocalPreferencesToFirestore(uid: uid)
            } else {
                let generatedName = displayName?.nilIfEmpty ?? UserProfile.generateUsername(from: uid)
                let prefs = localPreferences()
                let profile = UserProfile(
                    id:          uid,
                    username:    UserProfile.generateUsername(from: uid),
                    displayName: prefs.displayName ?? generatedName,
                    email:       email,
                    gender:      prefs.gender,
                    ageRange:    prefs.ageRange,
                    slangLevel:  prefs.slangLevel,
                    goal:        prefs.goal,
                    categories:  prefs.categories
                )
                try await profileRepository.saveProfile(profile)
                currentProfile = profile
                Logger.app.info("New user profile created. username=\(profile.username)")
            }
        } catch {
            Logger.app.error("AuthState.handleSignIn failed: \(error.localizedDescription)")
        }
    }

    /// Refreshes `currentProfile` from Firestore after a local edit (display name, photo).
    public func refreshProfile() async {
        await reload()
    }

    /// Updates the in-memory `displayName` immediately and persists to Firestore.
    public func updateDisplayName(_ name: String) async throws {
        guard let uid = authService.currentUserID else { return }
        try await profileRepository.updateDisplayName(name, uid: uid)
        currentProfile?.displayName = name
    }

    /// Patches user preference fields (gender, ageRange, slangLevel, goal, categories) in Firestore.
    public func updatePreferences(_ prefs: UserPreferences) async throws {
        guard let uid = authService.currentUserID else { return }
        try await profileRepository.updatePreferences(prefs, uid: uid)
        // Mirror changes into the in-memory profile.
        if let g = prefs.gender     { currentProfile?.gender     = g }
        if let a = prefs.ageRange   { currentProfile?.ageRange   = a }
        if let l = prefs.slangLevel { currentProfile?.slangLevel = l }
        if let g = prefs.goal       { currentProfile?.goal       = g }
        if let c = prefs.categories { currentProfile?.categories = c }
    }

    /// Uploads photo data, updates Firestore `photoURL`, and refreshes in-memory profile.
    public func updateProfilePhoto(data: Data) async throws {
        guard let uid = authService.currentUserID else { return }
        let url = try await profileRepository.uploadProfilePhoto(data: data, uid: uid)
        try await profileRepository.updatePhotoURL(url, uid: uid)
        currentProfile?.photoURL = url
    }

    /// Signs out and clears local state synchronously.
    public func signOut() {
        do {
            try authService.signOut()
            currentProfile = nil
        } catch {
            Logger.app.error("AuthState.signOut failed: \(error.localizedDescription)")
        }
    }

    /// Permanently deletes the Firestore document then the Firebase Auth account.
    /// After this call the user is signed out and `currentProfile` is `nil`.
    public func deleteAccount() async throws {
        guard let uid = authService.currentUserID else { return }
        // Delete Firestore data first so Storage/Firestore rules still allow the write
        // while the Auth account still exists.
        try await profileRepository.deleteProfile(uid: uid)
        try await authService.deleteAccount()
        currentProfile = nil
        Logger.app.info("Account deleted. uid=\(uid)")
    }

    // MARK: - Local Preferences Sync

    /// Reads onboarding preferences from UserDefaults for initial Firestore population.
    private func localPreferences() -> (
        displayName: String?, gender: String?, ageRange: String?,
        slangLevel: String?, goal: String?, categories: [String]?
    ) {
        let ud = UserDefaults.standard
        let cats: [String]? = {
            guard let data = ud.data(forKey: AppConstants.userCategoriesKey),
                  let decoded = try? JSONDecoder().decode([String].self, from: data)
            else { return nil }
            return decoded
        }()
        return (
            displayName: ud.string(forKey: "userDisplayName"),
            gender:      ud.string(forKey: "userGender"),
            ageRange:    ud.string(forKey: "userAgeRange"),
            slangLevel:  ud.string(forKey: AppConstants.userSegmentKey),
            goal:        ud.string(forKey: "userGoal"),
            categories:  cats
        )
    }

    /// Patches Firestore with any local preferences that are missing from the remote profile.
    private func syncLocalPreferencesToFirestore(uid: String) async {
        let local = localPreferences()
        var prefs = UserPreferences()
        if currentProfile?.gender == nil, let g = local.gender       { prefs.gender = g }
        if currentProfile?.ageRange == nil, let a = local.ageRange   { prefs.ageRange = a }
        if currentProfile?.slangLevel == nil, let l = local.slangLevel { prefs.slangLevel = l }
        if currentProfile?.goal == nil, let g = local.goal           { prefs.goal = g }
        if currentProfile?.categories == nil, let c = local.categories { prefs.categories = c }
        guard !prefs.firestoreData.isEmpty else { return }
        do {
            try await updatePreferences(prefs)
            Logger.app.info("Synced local preferences to Firestore for uid=\(uid)")
        } catch {
            Logger.app.error("syncLocalPreferences failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - String Helper

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
