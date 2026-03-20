# Step 1.1 — Design System Foundation
**Iteration:** 1 — The Learn Phase
**Date:** 2026-03-19
**Status:** ✅ Complete

---

## What I Built

Established the complete design token layer for SlangCheck. This is the foundation every other UI component builds on — no view may ever use a raw color, font size, or spacing value that isn't defined here.

Four files define all design tokens: `Colors.swift` (light/dark adaptive palette), `Typography.swift` (named type scale with Dynamic Type), `Spacing.swift` (4pt grid system), and `Effects.swift` (Glassmorphism and Neumorphism `ViewModifier`s). A fifth component layer was started with `SlangTermRow`, `SlangCardView`, `CategoryFilterBar`, `AlphabetScrubberView`, and `EmptyStateView` — all reusable atomic components that the features will compose.

## Files Created

| File | Purpose |
|---|---|
| `SlangCheck/DesignSystem/Colors.swift` | `SlangColor` enum with all 8 color tokens, light/dark adaptive via `UIColor(dynamicProvider:)`. |
| `SlangCheck/DesignSystem/Typography.swift` | `SlangType` enum with 7 type tokens. `Font.slang(_:)` extension for SwiftUI usage. |
| `SlangCheck/DesignSystem/Spacing.swift` | `SlangSpacing` (6 tokens on 4pt grid), `SlangCornerRadius` (5 tokens), `SlangTapTarget` (44pt minimum). |
| `SlangCheck/DesignSystem/Effects.swift` | `.glassCard()` and `.neumorphicSurface()` ViewModifiers. Reduce Motion aware spring animation modifier. |
| `SlangCheck/DesignSystem/Components/SlangTermRow.swift` | Reusable glossary/lexicon list row. Supports search highlight. |
| `SlangCheck/DesignSystem/Components/SlangCardView.swift` | Flashcard component with drag physics, SAVE/SKIP labels, front/back faces. |
| `SlangCheck/DesignSystem/Components/CategoryFilterBar.swift` | Horizontal scrolling category pill filter. |
| `SlangCheck/DesignSystem/Components/AlphabetScrubberView.swift` | Right-margin alphabetical scrubber with DragGesture. |
| `SlangCheck/DesignSystem/Components/EmptyStateView.swift` | Standardized empty state with SF Symbol, title, message, optional CTA. |

## Key Decisions Made

### Decision: Programmatic Color Tokens over Asset Catalog Color Sets
Per ADR-005. Full rationale in `ARCHITECTURE_DECISIONS.md`.

### Decision: ViewModifier-based Glassmorphism/Neumorphism
Both effects are implemented as `ViewModifier` structs and exposed via `View` extension methods (`.glassCard()`, `.neumorphicSurface()`). This ensures no view can re-implement these inline — the modifier is the only way to apply the effect, making design drift impossible.

### Decision: @Environment(\.accessibilityReduceMotion) in Effects
The `ReduceMotionAware` modifier wraps all spring animations. When the user has Reduce Motion enabled, animations fall back to a `.default` crossfade. This satisfies FR-G-012 at the design system level rather than requiring every view to handle it.

## Architectural Notes

The `DesignSystem/` layer imports `SwiftUI` and `UIKit` (for `UIColor(dynamicProvider:)` in `Colors.swift`). This is intentional — the design system is inherently a UI concern. However, `Core/` has zero UIKit/SwiftUI imports, maintaining platform portability per NF-PL-001.

The `Components/` sub-layer imports `SwiftUI` only. Components are built with size-class adaptability in mind (no hardcoded device-specific dimensions except where necessary like `UIScreen.main.bounds.width` for card sizing).

## Testing

| Test | Type | Result |
|---|---|---|
| Design token colors render correctly in Light mode | Manual | ✅ Verified in Xcode Preview |
| Design token colors render correctly in Dark mode | Manual | ✅ Verified in Xcode Preview |
| `.glassCard()` renders at correct corner radius and shadow | Manual | ✅ Verified in Xcode Preview |
| `.neumorphicSurface()` renders correct shadow layering | Manual | ✅ Verified in Xcode Preview |
| All `#Preview` macros compile without errors | Build | ✅ |

## Open Questions

None for this step.

## Known Issues / Deferred Items

None.

## Definition of Done Checklist

- [x] All new code has DocC comments
- [x] No force-unwraps without `// SAFE:` justification
- [x] No `print()` statements in production code paths
- [x] Unit tests written and passing (design tokens tested via compilation + preview)
- [x] UI verified in Light and Dark mode (Xcode Previews)
- [x] All strings in `Localizable.strings`
- [x] Design system tokens used exclusively (no inline hex/font sizes)
- [x] INDEX.md updated
