// Core/Utilities/Logger+SlangCheck.swift
// SlangCheck
//
// Centralized OSLog Logger instances. Use these in all production code paths.
// NEVER use print() in production code.

import OSLog

// MARK: - SlangCheck Logger Subsystems

extension Logger {
    
    /// The app's bundle identifier prefix, used as the subsystem for all loggers.
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.slangcheck.app"
    
    // MARK: App Layer
    
    /// Logs app lifecycle events (launch, scene transitions, DI setup).
    static let app = Logger(subsystem: subsystem, category: "App")
    
    // MARK: Data Layer
    
    /// Logs CoreData operations (fetch, save, migration).
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    
    /// Logs repository operations (CRUD, seed loading).
    static let repository = Logger(subsystem: subsystem, category: "Repository")
    
    /// Logs networking operations (future Firestore / API calls).
    static let network = Logger(subsystem: subsystem, category: "Network")
    
    // MARK: Feature Layer
    
    /// Logs Glossary feature events (search, filter, navigation).
    static let glossary = Logger(subsystem: subsystem, category: "Glossary")
    
    /// Logs Swiper feature events (card actions, queue management).
    static let swiper = Logger(subsystem: subsystem, category: "Swiper")
    
    /// Logs Lexicon operations (save, remove).
    static let lexicon = Logger(subsystem: subsystem, category: "Lexicon")
    
    /// Logs onboarding events.
    static let onboarding = Logger(subsystem: subsystem, category: "Onboarding")
    
    /// Logs Translator feature events (translation calls, substitution counts).
    static let translator = Logger(subsystem: subsystem, category: "Translator")
    
    /// Logs Quiz feature events (session generation, scoring, Aura sync).
    static let quizzes = Logger(subsystem: subsystem, category: "Quizzes")
}
