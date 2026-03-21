// Data/Services/LocalTranslationService.swift
// SlangCheck
//
// Concrete TranslationService that operates entirely on-device using the
// CoreData repository. No network calls. No user input text leaves the device.

import Foundation

// MARK: - LocalTranslationService

/// Translates text using the local slang term dictionary via ``TranslateTextUseCase``.
/// Implements ``TranslationService`` so ViewModels are decoupled from the concrete engine.
///
/// Per the Q-001 decision (2026-03-20): translation is local-only.
/// If a remote API is introduced in a future iteration, implement a new
/// `RemoteTranslationService` conforming to the same protocol — no ViewModel changes required.
public struct LocalTranslationService: TranslationService {

    private let useCase: TranslateTextUseCase

    /// - Parameter repository: The data source from which all slang terms are loaded.
    public init(repository: any SlangTermRepository) {
        self.useCase = TranslateTextUseCase(repository: repository)
    }

    // MARK: - TranslationService

    public func translate(text: String, direction: TranslationDirection) async throws -> TranslationResult {
        // Typed throws from the use case are bridged to untyped throws here.
        // The ViewModel receives `any Error` and handles it generically.
        try await useCase.translate(text: text, direction: direction)
    }
}
