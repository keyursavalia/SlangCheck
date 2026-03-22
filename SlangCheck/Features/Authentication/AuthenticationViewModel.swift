// Features/Authentication/AuthenticationViewModel.swift
// SlangCheck
//
// ViewModel for sign-in and sign-up flows.
// Owns nonce generation for Sign in with Apple (RFC-compliant SHA-256 hash).
// Drives both AuthGateView (game entry) and any standalone sign-in screen.

import AuthenticationServices
import CryptoKit
import Foundation
import OSLog

// MARK: - AuthenticationViewModel

/// `@MainActor` `@Observable` ViewModel shared between sign-in and sign-up modes.
///
/// Sign in with Apple flow:
///   1. UI calls `prepareAppleRequest(_:)` to stamp the request with a fresh nonce.
///   2. `SignInWithAppleButton` triggers ASAuthorization.
///   3. UI calls `handleAppleResult(_:)` with the credential.
@MainActor
@Observable
final class AuthenticationViewModel {

    // MARK: - Mode

    enum Mode {
        case signIn
        case signUp
    }

    // MARK: - State

    var mode: Mode = .signIn

    // Shared fields
    var email:    String = ""
    var password: String = ""

    // Sign-up only
    var displayName:     String = ""
    var confirmPassword: String = ""

    var isLoading:    Bool    = false
    var errorMessage: String? = nil

    // MARK: - Private

    /// The raw (un-hashed) nonce; stored so it can be passed to Firebase after Apple returns.
    private var pendingNonce: String?

    private let authService: any AuthenticationService
    private let authState:   AuthState

    // MARK: - Init

    init(authService: any AuthenticationService, authState: AuthState) {
        self.authService = authService
        self.authState   = authState
    }

    // MARK: - Email / Password

    /// Validates input and calls `signIn` or `createAccount` on the auth service.
    func submit() async {
        errorMessage = nil
        guard validate() else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            switch mode {
            case .signIn:
                let uid = try await authService.signIn(email: email, password: password)
                await authState.handleSignIn(uid: uid, email: email, displayName: nil)
            case .signUp:
                let uid = try await authService.createAccount(email: email, password: password)
                await authState.handleSignIn(
                    uid: uid,
                    email: email,
                    displayName: displayName.nilIfEmpty
                )
            }
        } catch let err as AuthError {
            errorMessage = err.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign in with Apple

    /// Stamps the provided `ASAuthorizationAppleIDRequest` with a fresh SHA-256 nonce.
    /// Call this inside the `SignInWithAppleButton` `onRequest` closure.
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        pendingNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    /// Handles the result from `SignInWithAppleButton`'s `onCompletion` closure.
    func handleAppleResult(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            // ASAuthorizationError.canceled (code 1001) — user dismissed sheet, not an error.
            guard (error as NSError).code != ASAuthorizationError.canceled.rawValue else { return }
            errorMessage = error.localizedDescription

        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData  = credential.identityToken,
                let nonce      = pendingNonce
            else {
                errorMessage = String(localized: "auth.error.appleGeneric",
                                      defaultValue: "Apple sign-in failed. Please try again.")
                return
            }

            let fullName: String? = {
                guard let name = credential.fullName else { return nil }
                return [name.givenName, name.familyName]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                    .nilIfEmpty
            }()

            isLoading = true
            defer { isLoading = false }

            do {
                let uid = try await authService.signInWithApple(
                    identityToken: tokenData,
                    nonce: nonce,
                    fullName: fullName
                )
                await authState.handleSignIn(
                    uid: uid,
                    email: credential.email ?? "",
                    displayName: fullName
                )
            } catch let err as AuthError {
                errorMessage = err.errorDescription
            }
        }
    }

    // MARK: - Validation

    private func validate() -> Bool {
        switch mode {
        case .signIn:
            guard !email.isEmpty, !password.isEmpty else {
                errorMessage = String(localized: "auth.error.emptyFields",
                                      defaultValue: "Please enter your email and password.")
                return false
            }
        case .signUp:
            guard !email.isEmpty else {
                errorMessage = String(localized: "auth.error.emptyEmail",
                                      defaultValue: "Please enter your email.")
                return false
            }
            guard password.count >= 6 else {
                errorMessage = AuthError.weakPassword.errorDescription
                return false
            }
            guard password == confirmPassword else {
                errorMessage = String(localized: "auth.error.passwordMismatch",
                                      defaultValue: "Passwords do not match.")
                return false
            }
        }
        return true
    }

    // MARK: - Nonce Helpers

    /// Generates a cryptographically random alphanumeric string.
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    /// Returns the lowercase hex-encoded SHA-256 hash of `input`.
    private func sha256(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - String Helper

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
