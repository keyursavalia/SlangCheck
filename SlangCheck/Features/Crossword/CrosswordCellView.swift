// Features/Crossword/CrosswordCellView.swift
// SlangCheck
//
// Renders a single crossword cell: barrier, empty letter cell,
// filled letter cell, highlighted (in-clue), selected, correct, or incorrect.

import SwiftUI

// MARK: - CrosswordCellView

/// Renders a single crossword grid cell.
///
/// Barrier cells use `SlangColor.crosswordBarrierCell` — a near-black in light mode
/// and a warm deep-charcoal in dark mode — so they always read as "blocked" regardless
/// of the system appearance. Input cells default to `SlangColor.crosswordInputCell`
/// (white in light mode, warm cream in dark mode) so the "write here" affordance is
/// immediately clear in both colour modes.
struct CrosswordCellView: View {

    // MARK: - Input

    let cell: CrosswordCell

    /// Letter entered by the user, or `nil` if the cell is empty.
    let enteredLetter: String?

    /// `true` when this cell is the active cursor position.
    let isSelected: Bool

    /// `true` when this cell falls within the currently active clue.
    let isHighlighted: Bool

    /// `true` when this cell was revealed via the hint feature.
    let isRevealed: Bool

    /// Post-submission: `true` = correct, `false` = incorrect, `nil` = not yet submitted.
    let correctness: Bool?

    /// Called when the user taps this cell.
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        if cell.isBlack {
            blackCell
        } else {
            letterCell
        }
    }

    // MARK: - Barrier Cell

    private var blackCell: some View {
        Rectangle()
            .fill(SlangColor.crosswordBarrierCell)
    }

    // MARK: - Letter Cell

    private var letterCell: some View {
        ZStack(alignment: .topLeading) {
            // Background fill
            cellBackground

            // Clue number badge
            if let num = cell.clueNumber {
                Text("\(num)")
                    .font(.montserrat(size: 8, weight: .semibold))
                    .foregroundStyle(textColor)
                    .padding(.leading, 2)
                    .padding(.top, 1)
            }

            // Entered letter (centred)
            if let letter = enteredLetter {
                Text(letter)
                    .font(.montserrat(size: 20, weight: .bold))
                    .foregroundStyle(isRevealed ? SlangColor.secondary : textColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(
            Rectangle()
                .strokeBorder(borderColor, lineWidth: isSelected ? 2 : 0.5)
        )
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Computed Colors

    private var cellBackground: some View {
        Group {
            if let correct = correctness {
                // Post-submission state
                correct
                    ? SlangColor.secondary.opacity(0.25)
                    : SlangColor.errorRed.opacity(0.25)
            } else if isSelected {
                SlangColor.primary.opacity(0.35)
            } else if isHighlighted {
                SlangColor.primary.opacity(0.15)
            } else {
                // Use the semantic crossword input token so the cell reads as
                // "write here" in both light (white) and dark (warm cream) modes.
                SlangColor.crosswordInputCell
            }
        }
    }

    private var textColor: Color {
        if let correct = correctness {
            return correct ? SlangColor.secondary : SlangColor.errorRed
        }
        // Mirror the barrier cell color for text so letters are always
        // dark-on-light — legible against both the white (light mode) and
        // warm-cream (dark mode) input cell backgrounds.
        return SlangColor.crosswordBarrierCell
    }

    private var borderColor: Color {
        if isSelected { return SlangColor.primary }
        // Slightly stronger separator so cell boundaries are visible against
        // the cream input cell background in dark mode.
        return SlangColor.separator
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var parts: [String] = []
        if let num = cell.clueNumber { parts.append("Clue \(num)") }
        parts.append("Row \(cell.row + 1), column \(cell.col + 1)")
        if let letter = enteredLetter {
            parts.append("Letter: \(letter)")
        } else {
            parts.append("Empty")
        }
        if isRevealed { parts.append("Revealed") }
        return parts.joined(separator: ". ")
    }
}
