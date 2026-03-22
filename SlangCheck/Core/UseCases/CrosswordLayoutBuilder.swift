// Core/UseCases/CrosswordLayoutBuilder.swift
// SlangCheck
//
// Deterministic crossword grid builder. Takes term-clue pairs and produces
// a valid CrosswordLayout (unencrypted) that can be turned into a CrosswordPuzzle.
// Zero UIKit/SwiftUI/CryptoKit imports — pure Swift, platform-agnostic.

import Foundation

// MARK: - CrosswordLayout

/// A fully built crossword grid ready for encryption and puzzle creation.
///
/// `CrosswordLayoutBuilder.build(entries:)` produces this value. The answer map
/// is in plaintext here — the Data layer (repository) is responsible for
/// AES-GCM encryption before storing in `CrosswordPuzzle`.
public struct CrosswordLayout: Sendable {

    /// Number of grid rows.
    public let rows: Int

    /// Number of grid columns.
    public let cols: Int

    /// All cells in row-major order (including black squares).
    public let cells: [CrosswordCell]

    /// All clues, Across and Down, sorted by clue number ascending.
    public let clues: [CrosswordClue]

    /// Plaintext answer map: cell ID (`"row-col"`) → uppercase letter.
    public let answerMap: [String: String]
}

// MARK: - CrosswordLayoutBuilder

/// Builds a valid crossword grid from a list of term-clue pairs.
///
/// ## Algorithm
/// 1. Sort words by length descending (longest word anchors the grid).
/// 2. Place the first word horizontally at (0, 0).
/// 3. For each subsequent word, scan all placed words for a shared letter.
///    When found, attempt to place the new word perpendicular at the intersection.
/// 4. Accept the first geometrically valid placement found.
/// 5. Normalise coordinates so the minimum row/col is zero.
/// 6. Assign clue numbers in row-major order.
/// 7. Build `CrosswordLayout`.
///
/// Grid validity rules enforced:
/// - No two letters occupy the same cell unless they are the same letter (intersection).
/// - The cell immediately before the word start and after the word end (in word direction)
///   must be empty, preventing two words from butting end-to-end.
public struct CrosswordLayoutBuilder: Sendable {

    /// Maximum grid dimension. Words that would exceed this are skipped.
    private static let maxDimension: Int = 20

    public init() {}

    // MARK: - Public

    /// Builds a `CrosswordLayout` from the provided term-clue entries.
    ///
    /// - Parameter entries: Term-clue pairs. Terms are uppercased and non-letter
    ///   characters stripped automatically.
    /// - Returns: A valid `CrosswordLayout`, or `nil` if fewer than 2 words
    ///   could be placed (i.e., no intersections were found).
    public func build(entries: [AICrosswordEntry]) -> CrosswordLayout? {
        let words = entries.map { AICrosswordEntry(term: $0.term, clue: $0.clue) }
            .filter { !$0.term.isEmpty }
            .sorted { $0.term.count > $1.term.count }

        guard !words.isEmpty else { return nil }

        var placed: [PlacedWord] = [
            PlacedWord(term: words[0].term, clue: words[0].clue,
                       startRow: 0, startCol: 0, direction: .across)
        ]

        for entry in words.dropFirst() {
            if let candidate = findPlacement(for: entry, placed: placed) {
                placed.append(candidate)
            }
        }

        guard placed.count >= 2 else { return nil }
        return buildLayout(from: placed)
    }

    // MARK: - Private: Placement

    private func findPlacement(for entry: AICrosswordEntry, placed: [PlacedWord]) -> PlacedWord? {
        let word = entry.term
        for placedWord in placed {
            for (i, ch1) in word.enumerated() {
                for (j, ch2) in placedWord.term.enumerated() {
                    guard ch1 == ch2 else { continue }
                    let newDirection: ClueDirection = placedWord.direction == .across ? .down : .across
                    let intersection = placedWord.cell(at: j)
                    let (sr, sc): (Int, Int)
                    switch newDirection {
                    case .across: sr = intersection.row;     sc = intersection.col - i
                    case .down:   sr = intersection.row - i; sc = intersection.col
                    }
                    let candidate = PlacedWord(term: word, clue: entry.clue,
                                               startRow: sr, startCol: sc,
                                               direction: newDirection)
                    if isValid(candidate: candidate, placed: placed) {
                        return candidate
                    }
                }
            }
        }
        return nil
    }

    private func isValid(candidate: PlacedWord, placed: [PlacedWord]) -> Bool {
        // Build snapshot of all existing cells.
        var existing: [String: String] = [:]
        for pw in placed {
            for (i, ch) in pw.term.enumerated() {
                let c = pw.cell(at: i)
                existing["\(c.row)-\(c.col)"] = String(ch)
            }
        }
        // Guard against grid overflow.
        let cells = (0..<candidate.term.count).map { candidate.cell(at: $0) }
        guard cells.allSatisfy({
            $0.row >= -Self.maxDimension && $0.row <= Self.maxDimension &&
            $0.col >= -Self.maxDimension && $0.col <= Self.maxDimension
        }) else { return false }

        // Check each cell: empty or matching letter.
        for (i, ch) in candidate.term.enumerated() {
            let c = candidate.cell(at: i)
            let key = "\(c.row)-\(c.col)"
            if let ex = existing[key], ex != String(ch) { return false }
        }
        // Ends must not butt into existing cells.
        let start = candidate.cell(at: 0)
        let end   = candidate.cell(at: candidate.term.count - 1)
        switch candidate.direction {
        case .across:
            if existing["\(start.row)-\(start.col - 1)"] != nil { return false }
            if existing["\(end.row)-\(end.col + 1)"] != nil { return false }
        case .down:
            if existing["\(start.row - 1)-\(start.col)"] != nil { return false }
            if existing["\(end.row + 1)-\(end.col)"] != nil { return false }
        }
        return true
    }

    // MARK: - Private: Layout Construction

    private func buildLayout(from placed: [PlacedWord]) -> CrosswordLayout {
        // Normalise so minimum row/col == 0.
        let allCells = placed.flatMap { pw in (0..<pw.term.count).map { pw.cell(at: $0) } }
        let minRow = allCells.map(\.row).min() ?? 0
        let minCol = allCells.map(\.col).min() ?? 0
        let normalised = placed.map {
            PlacedWord(term: $0.term, clue: $0.clue,
                       startRow: $0.startRow - minRow,
                       startCol: $0.startCol - minCol,
                       direction: $0.direction)
        }

        // Grid dimensions.
        let normCells = normalised.flatMap { pw in (0..<pw.term.count).map { pw.cell(at: $0) } }
        let rows = (normCells.map(\.row).max() ?? 0) + 1
        let cols = (normCells.map(\.col).max() ?? 0) + 1

        // Build answer map.
        var answerMap: [String: String] = [:]
        for pw in normalised {
            for (i, ch) in pw.term.enumerated() {
                let c = pw.cell(at: i)
                answerMap["\(c.row)-\(c.col)"] = String(ch)
            }
        }

        // Assign clue numbers in row-major order.
        var clueNumbers: [String: Int] = [:]
        var next = 1
        for r in 0..<rows {
            for c in 0..<cols {
                let id = "\(r)-\(c)"
                guard answerMap[id] != nil else { continue }
                let startsAcross = normalised.contains { $0.direction == .across && $0.startRow == r && $0.startCol == c }
                let startsDown   = normalised.contains { $0.direction == .down   && $0.startRow == r && $0.startCol == c }
                if startsAcross || startsDown { clueNumbers[id] = next; next += 1 }
            }
        }

        // Build CrosswordCell array.
        var cells: [CrosswordCell] = []
        for r in 0..<rows {
            for c in 0..<cols {
                let id = "\(r)-\(c)"
                cells.append(CrosswordCell(row: r, col: c,
                                           kind: answerMap[id] != nil ? .letter : .black,
                                           clueNumber: clueNumbers[id]))
            }
        }

        // Build CrosswordClue array.
        var clues: [CrosswordClue] = []
        for pw in normalised {
            let startID = "\(pw.startRow)-\(pw.startCol)"
            guard let number = clueNumbers[startID] else { continue }
            let cellIDs = (0..<pw.term.count).map { i -> String in
                let c = pw.cell(at: i); return "\(c.row)-\(c.col)"
            }
            clues.append(CrosswordClue(number: number, direction: pw.direction,
                                       text: pw.clue, cellIDs: cellIDs))
        }

        return CrosswordLayout(rows: rows, cols: cols, cells: cells,
                               clues: clues.sorted { $0.number < $1.number },
                               answerMap: answerMap)
    }
}

// MARK: - PlacedWord (Private)

private struct PlacedWord {
    let term: String
    let clue: String
    let startRow: Int
    let startCol: Int
    let direction: ClueDirection

    func cell(at index: Int) -> (row: Int, col: Int) {
        switch direction {
        case .across: return (startRow, startCol + index)
        case .down:   return (startRow + index, startCol)
        }
    }
}
