# Step 1.2 — Core Models
**Iteration:** 1 — The Learn Phase
**Date:** 2026-03-19
**Status:** ✅ Complete

---

## What I Built

Defined all pure Swift domain models in the `Core/Models/` layer. These types have zero UIKit, SwiftUI, or CoreData imports — they are portable to watchOS, visionOS, or a server-side Swift target without modification. All types conform to `Codable`, `Identifiable`, `Hashable`, and `Sendable` as required.

## Files Created

| File | Purpose |
|---|---|
| `Core/Models/SlangTerm.swift` | The primary domain model. Includes `SlangCategory` and `UsageFrequency` enums. Custom `Decodable` for ISO 8601 date strings. `matchesSearchQuery(_:)` and `firstLetter` computed properties. |
| `Core/Models/UserLexicon.swift` | Value type for the user's saved collection. Immutable mutations return new values. `LexiconEntry` sub-model with termID + savedDate. |
| `Core/Models/UserSegment.swift` | The three user audience segments from onboarding. Display name, description, and SF Symbol name. |

## Key Decisions Made

### Decision: Immutable UserLexicon Mutations Return New Values
`UserLexicon.saving(termID:)` and `.removing(termID:)` return new `UserLexicon` values rather than mutating `self`. This makes state changes explicit, prevents accidental mutation in view code, and makes the model trivially testable without dependency on any mutation framework.

### Decision: Custom Decodable for ISO 8601 Date Strings
The seed JSON represents dates as `"2025-01-01"` strings. Swift's default `JSONDecoder` with `.iso8601` strategy can't parse date-only strings without a time component. The custom `init(from:)` uses `ISO8601DateFormatter` with `.withFullDate` options and falls back to `Date()` if parsing fails, which is safe for seed data where the date is informational.

### Decision: GenerationTag as an Enum (not String)
Enums prevent typos, enable exhaustive switching, and are Codable at no extra cost. The seed JSON uses `"genZ"` and `"genAlpha"` raw values which map cleanly.

## Architectural Notes

All enums in `Core/Models/` use `String` raw values matching the exact strings in the seed JSON. This is the single source of truth for these strings — the JSON must match, not the other way around. If a new category is added, it goes here first, then in the JSON.

## Testing

| Test | Type | Result |
|---|---|---|
| `UserLexiconTests` — full suite | Unit | ✅ Pass (18 assertions) |
| `SlangTerm` decodes from sample JSON | Unit | ✅ Pass |
| `matchesSearchQuery` returns correct results | Unit | ✅ Covered by `SearchSlangTermsUseCaseTests` |

## Open Questions

None.

## Definition of Done Checklist

- [x] All new code has DocC comments
- [x] No force-unwraps without `// SAFE:` justification
- [x] No `print()` statements
- [x] Unit tests written and passing
- [x] All strings in `Localizable.strings`
- [x] Design system tokens not applicable (pure Swift models)
- [x] INDEX.md updated
