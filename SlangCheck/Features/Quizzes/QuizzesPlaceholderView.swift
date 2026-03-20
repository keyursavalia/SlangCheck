// Features/Quizzes/QuizzesPlaceholderView.swift
// SlangCheck
//
// Coming-soon placeholder for the Quizzes tab (FR-G-002). Full implementation in Iteration 3.

import SwiftUI

// MARK: - QuizzesPlaceholderView

struct QuizzesPlaceholderView: View {

    var body: some View {
        NavigationStack {
            EmptyStateView(
                symbolName: "trophy",
                title: String(localized: "quizzes.comingSoon.title",
                              defaultValue: "Quizzes & Aura System Coming Soon"),
                message: String(localized: "quizzes.comingSoon.message",
                                defaultValue: "Earn Aura Points, climb the leaderboard, and prove your slang mastery. Coming in the Quizzes update.")
            )
            .background(SlangColor.background.ignoresSafeArea())
            .navigationTitle(String(localized: "quizzes.title", defaultValue: "Quizzes"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

#Preview("QuizzesPlaceholderView") {
    QuizzesPlaceholderView()
}
