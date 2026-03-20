// DesignSystem/Components/AlphabetScrubberView.swift
// SlangCheck
//
// Alphabetical scrubber for the Glossary right margin (FR-GL-003, DESIGN_SYSTEM.md §7.2).
// Pure SwiftUI — no UITableView or UIKit. Gesture-driven letter selection.

import SwiftUI

// MARK: - AlphabetScrubberView

/// A vertical list of letter labels on the right margin.
/// Dragging or tapping jumps the associated `ScrollView` to the corresponding section.
public struct AlphabetScrubberView: View {

    // MARK: Properties

    /// The set of letters that have actual terms (only these are displayed).
    let availableLetters: [String]

    /// Called when the user selects a letter, passing the selected letter string.
    var onLetterSelected: (String) -> Void

    @State private var selectedLetter: String? = nil
    @GestureState private var isDragging = false

    // MARK: Body

    public var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 1) {
                ForEach(availableLetters, id: \.self) { letter in
                    Text(letter)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(
                            selectedLetter == letter
                                ? SlangColor.primary
                                : Color(.secondaryLabel)
                        )
                        .frame(width: 20, height: max(
                            SlangTapTarget.minimum / CGFloat(max(availableLetters.count, 1)),
                            12
                        ))
                        .accessibilityLabel(letter)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction {
                            selectLetter(letter)
                        }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let itemHeight = geometry.size.height / CGFloat(max(availableLetters.count, 1))
                        let index = Int(value.location.y / itemHeight)
                        let clamped = min(max(index, 0), availableLetters.count - 1)
                        let letter = availableLetters[clamped]
                        if letter != selectedLetter {
                            selectLetter(letter)
                        }
                    }
                    .onEnded { _ in
                        // Clear highlight after a short delay so the user sees the selection.
                        Task {
                            try? await Task.sleep(for: .milliseconds(300))
                            selectedLetter = nil
                        }
                    }
            )
        }
        .frame(width: 24)
    }

    // MARK: - Private

    private func selectLetter(_ letter: String) {
        selectedLetter = letter
        onLetterSelected(letter)
    }
}

// MARK: - Preview

#Preview("AlphabetScrubberView") {
    let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
    AlphabetScrubberView(availableLetters: letters) { letter in
        print("Selected: \(letter)")
    }
    .padding()
    .background(SlangColor.background)
}
