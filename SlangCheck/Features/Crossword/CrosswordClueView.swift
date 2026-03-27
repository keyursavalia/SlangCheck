// Features/Crossword/CrosswordClueView.swift
// SlangCheck
//
// Displays the currently active clue (number + direction + text) below the grid,
// plus scrollable Across / Down clue lists for clue-first navigation.

import SwiftUI

// MARK: - CrosswordClueView

/// Shows the active clue text below the grid and provides scrollable clue lists.
struct CrosswordClueView: View {

    // MARK: - Input

    let puzzle: CrosswordPuzzle
    let viewModel: CrosswordViewModel

    // MARK: - State

    @State private var showingClueList = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: SlangSpacing.sm) {
            activeClueBar
            if showingClueList {
                clueListPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingClueList)
    }

    // MARK: - Active Clue Bar

    private var activeClueBar: some View {
        Button {
            showingClueList.toggle()
        } label: {
            HStack(spacing: SlangSpacing.sm) {
                if let clue = viewModel.activeClue {
                    Text("\(clue.number) \(clue.direction == .across ? String(localized: "crossword.across", defaultValue: "Across") : String(localized: "crossword.down", defaultValue: "Down"))")
                        .font(.slang(.label))
                        .foregroundStyle(SlangColor.primary)
                        .frame(minWidth: 60, alignment: .leading)
                    Text(clue.text)
                        .font(.slang(.body))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                } else {
                    Text(String(localized: "crossword.tapCell", defaultValue: "Tap a cell to see its clue"))
                        .font(.slang(.body))
                        .foregroundStyle(.primary.opacity(0.5))
                }
                Spacer()
                Image(systemName: showingClueList ? "chevron.down" : "chevron.up")
                    .font(.caption)
                    .foregroundStyle(SlangColor.labelSecondary)
            }
            .padding(SlangSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: SlangCornerRadius.cell)
                    .fill(Color(.systemBackground))
            }
            .background {
                RoundedRectangle(cornerRadius: SlangCornerRadius.cell)
                    .fill(.black)
                    .offset(y: 3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            viewModel.activeClue.map {
                "\($0.number) \($0.direction == .across ? "Across" : "Down"): \($0.text)"
            } ?? "Tap a cell to see its clue"
        )
        .accessibilityHint(String(localized: "crossword.clueBar.hint", defaultValue: "Tap to browse all clues"))
    }

    // MARK: - Clue List Panel

    private var clueListPanel: some View {
        HStack(alignment: .top, spacing: SlangSpacing.sm) {
            clueColumn(title: String(localized: "crossword.across", defaultValue: "Across"),
                       clues: puzzle.acrossClues)
            Divider()
            clueColumn(title: String(localized: "crossword.down", defaultValue: "Down"),
                       clues: puzzle.downClues)
        }
        .padding(SlangSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .fill(Color(.systemBackground))
        }
        .background {
            RoundedRectangle(cornerRadius: SlangCornerRadius.card)
                .fill(.black)
                .offset(y: 4)
        }
        .frame(maxHeight: 200)
    }

    private func clueColumn(title: String, clues: [CrosswordClue]) -> some View {
        VStack(alignment: .leading, spacing: SlangSpacing.xs) {
            Text(title)
                .font(.slang(.label))
                .foregroundStyle(SlangColor.primary)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: SlangSpacing.xs) {
                    ForEach(clues) { clue in
                        Button {
                            viewModel.selectClue(clue)
                            showingClueList = false
                        } label: {
                            HStack(alignment: .top, spacing: SlangSpacing.xs) {
                                Text("\(clue.number).")
                                    .font(.slang(.caption))
                                    .foregroundStyle(SlangColor.primary)
                                    .frame(minWidth: 20, alignment: .trailing)
                                Text(clue.text)
                                    .font(.slang(.caption))
                                    .foregroundStyle(
                                        viewModel.activeClue?.id == clue.id
                                            ? SlangColor.primary
                                            : .primary
                                    )
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, SlangSpacing.xs)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
