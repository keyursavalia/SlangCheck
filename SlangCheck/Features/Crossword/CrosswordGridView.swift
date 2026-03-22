// Features/Crossword/CrosswordGridView.swift
// SlangCheck
//
// Renders the complete crossword grid as a LazyVGrid of CrosswordCellViews.
// Tapping any letter cell selects it and shows the system keyboard
// via the hidden TextField in CrosswordView.

import SwiftUI

// MARK: - CrosswordGridView

/// The interactive crossword puzzle grid.
///
/// Uses `LazyVGrid` for efficient layout. Cells are square, sized to fill
/// the available width with a configurable gap between them.
struct CrosswordGridView: View {

    // MARK: - Input

    let puzzle: CrosswordPuzzle
    let viewModel: CrosswordViewModel

    // MARK: - Layout Constants

    /// Pixel gap between cells. Kept to 2pt so the grid looks tight.
    private let cellGap: CGFloat = 2

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let cellSize = cellSize(in: geo.size.width)
            let columns  = Array(
                repeating: GridItem(.fixed(cellSize), spacing: cellGap),
                count: puzzle.cols
            )

            LazyVGrid(columns: columns, spacing: cellGap) {
                ForEach(puzzle.cells) { cell in
                    CrosswordCellView(
                        cell:          cell,
                        enteredLetter: viewModel.enteredLetter(for: cell.id),
                        isSelected:    viewModel.selectedCellID == cell.id,
                        isHighlighted: viewModel.highlightedCellIDs.contains(cell.id),
                        isRevealed:    viewModel.isRevealed(cell.id),
                        correctness:   correctness(for: cell)
                    ) {
                        viewModel.selectCell(cell.id)
                    }
                    .frame(width: cellSize, height: cellSize)
                }
            }
            // Lay out from the top-left so the grid doesn't float.
            .frame(width: geo.size.width, height: gridHeight(cellSize: cellSize), alignment: .topLeading)
        }
        .frame(height: estimatedHeight)
    }

    // MARK: - Helpers

    private func cellSize(in availableWidth: CGFloat) -> CGFloat {
        let totalGap = cellGap * CGFloat(puzzle.cols - 1)
        return (availableWidth - totalGap) / CGFloat(puzzle.cols)
    }

    private func gridHeight(cellSize: CGFloat) -> CGFloat {
        cellSize * CGFloat(puzzle.rows) + cellGap * CGFloat(puzzle.rows - 1)
    }

    /// A rough estimate used to pre-allocate the GeometryReader frame on first render.
    /// Assumes square cells based on screen width with standard margins.
    private var estimatedHeight: CGFloat {
        let estimatedCellSize = (UIScreen.main.bounds.width - SlangSpacing.md * 2) / CGFloat(puzzle.cols)
        return gridHeight(cellSize: estimatedCellSize)
    }

    private func correctness(for cell: CrosswordCell) -> Bool? {
        guard case .completed = viewModel.phase else { return nil }
        guard cell.isLetter else { return nil }
        return viewModel.isCorrect(cell.id)
    }
}
