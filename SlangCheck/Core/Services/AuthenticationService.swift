// Core/Services/AuthenticationService.swift
// SlangCheck
//
// Protocol for the authentication layer. Concrete implementation lives in
// Data/Firebase/FirebaseAuthenticationService.swift.
// NoOpAuthenticationService lives in Data/Firebase/NoOpAuthService.swift.
// Keeping this in Core/ ensures ViewModels and UseCases never import FirebaseAuth directly.

import Foundation

// MARK: - AuthenticationService

/// Abstracts Firebase Authentication. All methods are async and throw `AuthError`.
public protocol AuthenticationService: Sendable {

    /// Sign in with Apple ID.
    /// - Parameters:
    ///   - identityToken: The JWT `Data` from `ASAuthorizationAppleIDCredential.identityToken`.
    ///   - nonce: The *raw* (un-hashed) nonce that was SHA-256-hashed and set on the Apple request.
    ///   - fullName: Optional display name extracted from `ASAuthorizationAppleIDCredential.fullName`.
    /// - Returns: Firebase UID of the authenticated user.
    func signInWithApple(
        identityToken: Data,
        nonce: String,
        fullName: String?
    ) async throws(AuthError) -> String

    /// Create a new email/password account.
    /// - Returns: Firebase UID of the newly created user.
    func createAccount(email: String, password: String) async throws(AuthError) -> String

    /// Sign in with email and password.
    /// - Returns: Firebase UID of the authenticated user.
    func signIn(email: String, password: String) async throws(AuthError) -> String

    /// Sign out the current user synchronously.
    func signOut() throws(AuthError)

    /// Permanently delete the current Firebase Auth account.
    /// Call `UserProfileRepository.deleteProfile(uid:)` *before* this to remove Firestore data first.
    func deleteAccount() async throws(AuthError)

    /// Firebase UID of the currently signed-in user, or `nil` when unauthenticated.
    var currentUserID: String? { get }
}

// MARK: - AuthError

/// Typed errors surfaced to the UI from `AuthenticationService`.
public enum AuthError: LocalizedError, Sendable {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case wrongPassword
    case userNotFound
    case unauthenticated
    case networkError
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .invalidEmail:        return String(localized: "auth.error.invalidEmail",
                                                  defaultValue: "Please enter a valid email address.")
        case .weakPassword:        return String(localized: "auth.error.weakPassword",
                                                  defaultValue: "Password must be at least 6 characters.")
        case .emailAlreadyInUse:   return String(localized: "auth.error.emailInUse",
                                                  defaultValue: "An account with this email already exists.")
        case .wrongPassword:       return String(localized: "auth.error.wrongPassword",
                                                  defaultValue: "Incorrect password. Please try again.")
        case .userNotFound:        return String(localized: "auth.error.userNotFound",
                                                  defaultValue: "No account found with this email.")
        case .unauthenticated:     return String(localized: "auth.error.unauthenticated",
                                                  defaultValue: "Please sign in to continue.")
        case .networkError:        return String(localized: "auth.error.network",
                                                  defaultValue: "Network error. Check your connection.")
        case .unknown(let msg):    return msg
        }
    }
}
