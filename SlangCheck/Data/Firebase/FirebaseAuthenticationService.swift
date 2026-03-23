// Data/Firebase/FirebaseAuthenticationService.swift
// SlangCheck
//
// Firebase Authentication implementation of AuthenticationService.
// Supports Sign in with Apple (RFC-compliant SHA-256 nonce) and email/password.
//
// DEVELOPER ACTION REQUIRED before this compiles:
//   1. Add Firebase iOS SDK via SPM → select FirebaseAuth, FirebaseFirestore, FirebaseStorage.
//   2. Add GoogleService-Info.plist to the SlangCheck target.
//   3. In SlangCheckApp.init(), call FirebaseApp.configure() before AppEnvironment.production().
//   4. Enable "Sign in with Apple" capability in Xcode → Signing & Capabilities.
//   5. In Firebase console → Authentication → Sign-in method: enable Apple and Email/Password.

#if canImport(FirebaseAuth)

import AuthenticationServices
import FirebaseAuth
import Foundation
import OSLog

// MARK: - FirebaseAuthenticationService

/// Production `AuthenticationService` backed by Firebase Authentication.
public struct FirebaseAuthenticationService: AuthenticationService {

    public init() {}

    // MARK: - AuthenticationService

    public var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }

    public func signInWithApple(
        identityToken: Data,
        nonce: String,
        fullName: String?
    ) async throws(AuthError) -> String {
        guard let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw .unknown("Invalid identity token encoding.")
        }
        let credential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce:    nonce,
            fullName:    nil // display name is handled separately via UserProfile
        )
        do {
            let result = try await Auth.auth().signIn(with: credential)
            Logger.app.info("Sign in with Apple succeeded. uid=\(result.user.uid)")
            return result.user.uid
        } catch {
            throw map(error)
        }
    }

    public func createAccount(email: String, password: String) async throws(AuthError) -> String {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            Logger.app.info("Account created. uid=\(result.user.uid)")
            return result.user.uid
        } catch {
            throw map(error)
        }
    }

    public func signIn(email: String, password: String) async throws(AuthError) -> String {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            Logger.app.info("Email sign-in succeeded. uid=\(result.user.uid)")
            return result.user.uid
        } catch {
            throw map(error)
        }
    }

    public func signOut() throws(AuthError) {
        do {
            try Auth.auth().signOut()
            Logger.app.info("User signed out.")
        } catch {
            throw map(error)
        }
    }

    public func deleteAccount() async throws(AuthError) {
        guard let user = Auth.auth().currentUser else { throw .unauthenticated }
        do {
            try await user.delete()
            Logger.app.info("Firebase Auth account deleted.")
        } catch {
            throw map(error)
        }
    }

    // MARK: - Error Mapping

    private func map(_ error: Error) -> AuthError {
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        switch code {
        case .invalidEmail:                   return .invalidEmail
        case .weakPassword:                   return .weakPassword
        case .emailAlreadyInUse:              return .emailAlreadyInUse
        case .wrongPassword, .invalidCredential: return .wrongPassword
        case .userNotFound:                   return .userNotFound
        case .networkError:                   return .networkError
        default:
            Logger.app.error("Unmapped FirebaseAuth error: \(error.localizedDescription)")
            return .unknown(error.localizedDescription)
        }
    }
}

#endif // canImport(FirebaseAuth)
