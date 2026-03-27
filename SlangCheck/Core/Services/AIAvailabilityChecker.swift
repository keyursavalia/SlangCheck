// Core/Services/AIAvailabilityChecker.swift
// SlangCheck
//
// Checks whether Apple Intelligence (FoundationModels) is available at runtime.
// Pure Foundation — no UIKit or SwiftUI imports.

import Foundation

// MARK: - AIProvider

/// Which AI backend is powering the games.
public enum AIProvider: String, Sendable {
    /// On-device Apple Intelligence (FoundationModels, iOS 26+).
    case appleIntelligence
    /// Google Gemini REST API (remote, all iOS versions).
    case gemini
    /// No AI available (Gemini key missing, offline, etc.). Static fallback content.
    case none
}

// MARK: - AIAvailabilityChecker

/// Determines the best available AI provider at runtime.
///
/// Call `currentProvider()` to get the active provider. The result may change
/// between app launches (e.g. user enables Apple Intelligence in Settings).
public enum AIAvailabilityChecker {

    /// Returns the best AI provider available right now.
    public static func currentProvider() -> AIProvider {
        if isAppleIntelligenceAvailable() { return .appleIntelligence }
        if isGeminiConfigured()           { return .gemini }
        return .none
    }

    /// `true` when the device is iOS 26+ and Apple Intelligence is active.
    public static func isAppleIntelligenceAvailable() -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return _checkFoundationModelsAvailability()
        }
        #endif
        return false
    }

    /// `true` when iOS is 26+ but Apple Intelligence is NOT yet active.
    /// This is the window where we should prompt the user to enable it.
    public static func canPromptForAppleIntelligence() -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return !_checkFoundationModelsAvailability()
        }
        #endif
        return false
    }

    /// `true` when a Gemini API key is present in `Secrets.plist`.
    public static func isGeminiConfigured() -> Bool {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key  = dict["GeminiAPIKey"] as? String,
              !key.isEmpty
        else { return false }
        return true
    }

    // MARK: - Private

    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private static func _checkFoundationModelsAvailability() -> Bool {
        // Import is compile-time guarded; this function is only called on iOS 26+.
        _foundationModelsAvailable()
    }
    #endif
}

// MARK: - FoundationModels Runtime Check (Isolated)

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, *)
func _foundationModelsAvailable() -> Bool {
    SystemLanguageModel.default.availability == .available
}
#endif
