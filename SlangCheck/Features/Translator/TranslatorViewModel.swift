// Features/Translator/TranslatorViewModel.swift
// SlangCheck
//
// ViewModel for the Translator tab.
// Manages input text, translation direction, 400ms debounce, and clipboard state.

import Foundation
import OSLog
import SwiftUI

// MARK: - TranslatorViewModel

/// Owns the state and business logic for the Translator screen.
///
/// Translation is debounced 400ms after each input change to avoid firing on every keystroke.
/// Changing direction immediately re-triggers translation with the current input text.
@Observable
@MainActor
final class TranslatorViewModel {

    // MARK: - Observable State

    /// Text typed by the user into the input panel.
    var inputText: String = "" {
        didSet { scheduleTranslation() }
    }

    /// The current translation direction. Changing direction re-triggers translation.
    var direction: TranslationDirection = .genZToStandard {
        didSet { scheduleTranslation() }
    }

    /// The most recent translation result. `nil` when the input field is empty.
    private(set) var result: TranslationResult? = nil

    /// `true` while a translation `Task` is in flight.
    private(set) var isTranslating: Bool = false

    /// Non-nil when translation fails. Cleared on the next successful attempt.
    private(set) var errorMessage: String? = nil

    // MARK: - Dependencies

    private let translationService: any TranslationService

    /// Exposed as `internal` (not `private`) so `TranslatorContentView` can call haptics
    /// directly for UI-driven events like clipboard copy.
    let hapticService: any HapticServiceProtocol

    // MARK: - Private

    /// Cancelled and re-created on every keystroke to implement the 400ms debounce.
    private var debounceTask: Task<Void, Never>? = nil

    // MARK: - Initialization

    init(translationService: any TranslationService, hapticService: any HapticServiceProtocol) {
        self.translationService = translationService
        self.hapticService      = hapticService
    }

    // MARK: - Public Actions

    /// Swaps the translation direction and loads the previous output as the new input.
    /// If there is no current output, only the direction toggles.
    func swapDirection() {
        let previousOutput = result?.translatedText ?? ""
        direction = direction.toggled
        if !previousOutput.isEmpty {
            inputText = previousOutput
        }
    }

    /// Clears the input field and resets all translation state.
    func clear() {
        debounceTask?.cancel()
        inputText    = ""
        result       = nil
        errorMessage = nil
    }

    // MARK: - Debounce

    private func scheduleTranslation() {
        debounceTask?.cancel()

        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            result = nil
            return
        }

        let text      = inputText
        let direction = direction

        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await self?.performTranslation(text: text, direction: direction)
        }
    }

    // MARK: - Translation

    private func performTranslation(text: String, direction: TranslationDirection) async {
        isTranslating = true
        errorMessage  = nil
        defer { isTranslating = false }

        do {
            result = try await translationService.translate(text: text, direction: direction)
            Logger.translator.debug(
                "Translation complete — \(self.result?.substitutions.count ?? 0) substitution(s)"
            )
        } catch {
            errorMessage = String(
                localized: "translator.error.generic",
                defaultValue: "Translation failed. Please try again."
            )
            Logger.translator.error("Translation error: \(error.localizedDescription)")
        }
    }
}
