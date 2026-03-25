// DesignSystem/Components/CategoryFilterBar.swift
// SlangCheck
//
// Horizontally scrollable category filter bar used in the Glossary screen (FR-GL-007).

import SwiftUI

// MARK: - CategoryFilterBar

/// A horizontal scroll of pill-shaped filter buttons for slang term categories.
/// Selecting a category instantly updates the list without a loading state (FR-GL-008).
public struct CategoryFilterBar: View {

    // MARK: Properties

    @Binding var selectedCategory: SlangCategory?

    // MARK: Body

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SlangSpacing.sm) {
                FilterPill(
                    title: String(localized: "filter.all", defaultValue: "All"),
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(SlangCategory.allCases) { category in
                    FilterPill(
                        title: category.displayName,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, SlangSpacing.md)
            .padding(.vertical, SlangSpacing.xs)
        }
    }
}

// MARK: - FilterPill

/// An individual pill-shaped filter button.
private struct FilterPill: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.slang(.label))
                .foregroundStyle(isSelected ? .white : SlangColor.primary)
                .padding(.horizontal, SlangSpacing.md)
                .padding(.vertical, SlangSpacing.xs + 2)
                .background(
                    Capsule()
                        .fill(isSelected ? SlangColor.primary : SlangColor.primary.opacity(0.12))
                )
        }
        // FilterPillButtonStyle handles pressed scale via ButtonStyle — not DragGesture —
        // so the parent horizontal ScrollView can steal the gesture for panning freely.
        .buttonStyle(FilterPillButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - FilterPillButtonStyle

/// Scales the pill on press. Using ButtonStyle (not simultaneousGesture) so
/// the enclosing horizontal ScrollView receives drag gestures without conflict.
private struct FilterPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("CategoryFilterBar") {
    @Previewable @State var selected: SlangCategory? = nil
    VStack {
        CategoryFilterBar(selectedCategory: $selected)
        Text(selected?.displayName ?? "All")
            .font(.slang(.caption))
            .foregroundStyle(.secondary)
    }
    .background(SlangColor.background)
}
