// DesignSystem/Components/EmptyStateView.swift
// SlangCheck
//
// Reusable empty state component with SF Symbol illustration, title, message, and optional CTA.

import SwiftUI

// MARK: - EmptyStateView

/// A standardized empty state view per UX requirements (NF-UX-004: all error/empty states
/// must include a user-actionable recovery path).
public struct EmptyStateView: View {

    // MARK: Properties

    let symbolName: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    // MARK: Body

    public var body: some View {
        VStack(spacing: SlangSpacing.lg) {
            Image(systemName: symbolName)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(SlangColor.primary.opacity(0.5))
                .accessibilityHidden(true)

            VStack(spacing: SlangSpacing.sm) {
                Text(title)
                    .font(.slang(.heading))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.slang(.body))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .slangBodySpacing()
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.slang(.label))
                        .foregroundStyle(.white)
                        .padding(.horizontal, SlangSpacing.xl)
                        .padding(.vertical, SlangSpacing.sm + 4)
                        .background(
                            Capsule().fill(SlangColor.primary)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(SlangSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("EmptyStateView — Search") {
    EmptyStateView(
        symbolName: "magnifyingglass",
        title: String(localized: "emptyState.search.title",
                      defaultValue: "No slang found"),
        message: String(localized: "emptyState.search.message",
                        defaultValue: "No slang found. Maybe it's too niche \u{1F440}"),
        actionTitle: String(localized: "emptyState.search.action",
                             defaultValue: "Browse by category"),
        action: {}
    )
    .background(SlangColor.background)
}
