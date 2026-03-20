// Features/Translator/TranslatorPlaceholderView.swift
// SlangCheck
//
// Coming-soon placeholder for the Translator tab (FR-G-002: visible but shows
// "Coming Soon" state when tapped). Full implementation in Iteration 2.

import SwiftUI

// MARK: - TranslatorPlaceholderView

/// Visible in the tab bar from Iteration 1. Replaced by the full TranslatorView in Iteration 2.
struct TranslatorPlaceholderView: View {

    var body: some View {
        NavigationStack {
            EmptyStateView(
                symbolName: "character.bubble",
                title: String(localized: "translator.comingSoon.title",
                              defaultValue: "Translator Coming Soon"),
                message: String(localized: "translator.comingSoon.message",
                                defaultValue: "The bi-directional GenZ \u{2194} Standard English translator arrives in the next update.")
            )
            .background(SlangColor.background.ignoresSafeArea())
            .navigationTitle(String(localized: "translator.title", defaultValue: "Translator"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

#Preview("TranslatorPlaceholderView") {
    TranslatorPlaceholderView()
}
