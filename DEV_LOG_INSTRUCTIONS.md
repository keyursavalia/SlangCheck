# DEV_LOG_INSTRUCTIONS.md — SlangCheck
### Development Documentation Protocol for Claude Code

> This document tells Claude Code **how to document its own work** as it builds the SlangCheck codebase.
> Follow this protocol exactly. Documentation is not optional and is not done "at the end."
> It is written **as the code is written**, entry by entry, decision by decision.

---

## 1. Why This Exists

You are building a multi-iteration iOS application. The developer needs to:

- **Monitor** what you did in each session without reading every file you changed.
- **Navigate** the direction of the build — catch wrong turns early.
- **Understand** your architectural and design decisions without asking after the fact.
- **Onboard** future contributors (or a future Claude Code session) without knowledge gaps.
- **Audit** security and data decisions at any point in the project.

Code without documentation is a liability. You write the documentation. The developer reads it. This is the protocol.

---

## 2. The Documentation File Structure

You shall maintain the following documentation files in a `Docs/DevLog/` folder at the root of the repository:

```
Docs/
└── DevLog/
    ├── INDEX.md                        ← Master table of contents (you maintain this)
    ├── ARCHITECTURE_DECISIONS.md       ← All ADRs (Architecture Decision Records)
    ├── ITERATION_1/
    │   ├── STEP_1.1_DesignSystem.md
    │   ├── STEP_1.2_CoreModels.md
    │   ├── STEP_1.3_LocalDataLayer.md
    │   ├── STEP_1.4_Glossary.md
    │   ├── STEP_1.5_SmartSearch.md
    │   ├── STEP_1.6_SwiperUX.md
    │   ├── STEP_1.7_PersonalLexicon.md
    │   ├── STEP_1.8_AppShell.md
    │   └── STEP_1.9_TestingVerification.md
    ├── ITERATION_2/
    │   ├── STEP_2.1_TranslationServiceProtocol.md
    │   ├── STEP_2.2_TranslationEngine.md
    │   ├── STEP_2.3_TranslatorUI.md
    │   └── STEP_2.4_TestingVerification.md
    ├── ITERATION_3/
    │   └── ...
    ├── ITERATION_4/
    │   └── ...
    ├── QUESTIONS_AND_ANSWERS.md        ← All developer Q&A logged here
    └── KNOWN_ISSUES.md                 ← Active issues, deferred decisions, tech debt
```

Create this folder structure **before writing the first line of production code.**

---

## 3. The INDEX.md File

`INDEX.md` is the developer's dashboard. You maintain it continuously.

### Format

```markdown
# SlangCheck — Development Log Index

**Last updated:** [date and step]
**Current iteration:** Iteration X — [name]
**Current step:** Step X.Y — [step name]
**Overall status:** [In Progress / Iteration N Complete / Blocked]

---

## Iteration Status

| Iteration | Name | Status | Completed Steps | Total Steps |
|---|---|---|---|---|
| 1 | The Learn Phase | ✅ Complete | 9/9 | 9 |
| 2 | The Translator Phase | 🔄 In Progress | 2/4 | 4 |
| 3 | The Quizzes Phase | ⏳ Not Started | 0/6 | 6 |
| 4 | The Daily Crossword Phase | ⏳ Not Started | 0/7 | 7 |

---

## Recent Entries

| Date | Step | Summary |
|---|---|---|
| YYYY-MM-DD | Step 2.2 | Implemented local dictionary-based translation engine. See STEP_2.2_TranslationEngine.md |
| YYYY-MM-DD | Step 2.1 | Defined TranslationService protocol. Blocked on developer Q&A #3. |
| YYYY-MM-DD | Step 1.9 | All Iteration 1 tests pass. Iteration 1 marked complete. |

---

## Open Questions Requiring Developer Input

| # | Question | Status | Step |
|---|---|---|---|
| Q-003 | Remote translation API provider? | ⏳ Awaiting Answer | Step 2.1 |
| Q-002 | AP sync conflict resolution strategy? | ✅ Answered | Step 3.3 |

---

## Known Issues & Tech Debt

| ID | Description | Severity | Step Introduced |
|---|---|---|---|
| KI-001 | Crossword timer does not account for app backgrounding | Medium | Step 4.2 |

---

## Architecture Decisions

See [ARCHITECTURE_DECISIONS.md](./ARCHITECTURE_DECISIONS.md) for all ADRs.
```

---

## 4. Per-Step Documentation Files

For **every step** you complete (e.g., Step 1.4 — Glossary), you create a corresponding markdown file using this template:

### Template: `STEP_X.Y_FeatureName.md`

```markdown
# Step X.Y — [Step Name]
**Iteration:** X — [Iteration Name]
**Date:** YYYY-MM-DD
**Status:** ✅ Complete | 🔄 In Progress | ⛔ Blocked

---

## What I Built

[A plain English description of what was implemented in this step. Write as if explaining to
a developer who has not read the code. 3–10 sentences. Focus on what exists now that didn't
before. No jargon without explanation.]

## Files Created

| File | Purpose |
|---|---|
| `Features/Glossary/GlossaryView.swift` | The main scrollable list view for the Glossary feature. |
| `Features/Glossary/GlossaryViewModel.swift` | Manages term fetching, category filtering, and search state. |
| `Core/UseCases/SearchSlangTermsUseCase.swift` | Encapsulates the fuzzy search logic. Single responsibility. |

## Files Modified

| File | What Changed | Why |
|---|---|---|
| `Core/Models/SlangTerm.swift` | Added `matchesSearchQuery(_:)` method | Centralizes search matching logic for reuse in both Glossary and Swiper |

## Key Decisions Made

### Decision: Used `LazyVStack` instead of `List`

**Why:** `List` applies system row styling that conflicts with the custom Glassmorphism card
design from `DESIGN_SYSTEM.md`. `LazyVStack` inside a `ScrollView` gives full control over
cell appearance while maintaining lazy rendering for performance.

**Trade-off:** Manual implementation of swipe-to-delete and selection highlight,
which was implemented in `SlangTermRow.swift` using `DragGesture` and `@State`.

**Alternative considered:** `UICollectionView` via `UIViewRepresentable`. Rejected because
it introduces UIKit complexity that violates the SwiftUI-first principle in `CLAUDE.md`.

### Decision: Alphabetical scrubber built with `DragGesture` on a `VStack` of labels

**Why:** No native SwiftUI equivalent to UITableView's `sectionIndexTitles`. Built a custom
`AlphabetScrubberView` component that translates drag position to a letter and calls a
closure on the parent.

---

## Architectural Notes

[Any structural observations about how this step's code integrates with the broader
architecture. Note if this step creates a pattern that future steps should follow, or if
it reveals a tension in the current architecture that needs monitoring.]

---

## Testing

| Test | Type | Result |
|---|---|---|
| `GlossaryViewModelTests.testSearchFiltersCorrectly` | Unit | ✅ Pass |
| `GlossaryViewModelTests.testCategoryFilterUpdatesTermList` | Unit | ✅ Pass |
| `GlossaryViewModelTests.testEmptySearchShowsAllTerms` | Unit | ✅ Pass |
| Glossary UI — Light Mode | Manual | ✅ Verified |
| Glossary UI — Dark Mode | Manual | ✅ Verified |
| VoiceOver navigation through list | Manual | ✅ Verified |

---

## Open Questions

[List any questions that arose during this step that need developer input.
Log them here AND add them to QUESTIONS_AND_ANSWERS.md.]

- None for this step.

---

## Known Issues / Deferred Items

[Anything you deliberately deferred, a known edge case not yet handled, or a performance
concern you noted but did not optimize. These must also be logged in KNOWN_ISSUES.md.]

- The alphabetical scrubber does not yet support VoiceOver swipe-between-letters. Logged as KI-002.

---

## Definition of Done Checklist

- [x] All new code has DocC comments
- [x] No force-unwraps without `// SAFE:` justification
- [x] No `print()` statements in production code paths
- [x] Unit tests written and passing
- [x] UI verified in Light and Dark mode
- [x] UI verified on iPhone SE, iPhone 15 Pro, iPhone 15 Pro Max
- [x] All strings in `Localizable.strings`
- [x] Design system tokens used exclusively
- [x] INDEX.md updated
```

---

## 5. Architecture Decision Records (ADRs)

Every time you make a decision that has lasting architectural impact, you record it in `ARCHITECTURE_DECISIONS.md` using this format:

```markdown
## ADR-XXX: [Short Title]

**Date:** YYYY-MM-DD
**Status:** Accepted | Superseded by ADR-YYY | Deprecated
**Step:** X.Y

### Context

[What situation or requirement forced this decision? What constraints existed?]

### Decision

[Exactly what was decided.]

### Rationale

[Why this option over the alternatives? What does it enable? What does it cost?]

### Alternatives Considered

- **Option A:** [description] — Rejected because [reason].
- **Option B:** [description] — Rejected because [reason].

### Consequences

[What becomes easier? What becomes harder? What future decisions does this constrain?]

### Related Files

- `Core/Repositories/SlangTermRepository.swift`
- `Data/CoreData/CoreDataSlangTermRepository.swift`
```

**Mandatory ADR triggers** — you must write an ADR whenever you:

- Choose one persistence technology over another for an entity.
- Introduce a new architectural layer or pattern not already in `CLAUDE.md`.
- Decide on a sync conflict resolution strategy.
- Introduce or reject a third-party dependency.
- Choose between two SwiftUI approaches where both are viable.
- Make a security-relevant decision (storage location of any credential or key).
- Design a Firestore data model or security rule.
- Add any `#if os()` conditional compilation block (platform divergence decision).

---

## 6. Questions & Answers Log

`QUESTIONS_AND_ANSWERS.md` is a living record of every question asked to the developer and their answer.

### Format

```markdown
# Questions & Answers Log

---

## Q-001 — Translation API Provider

**Asked:** YYYY-MM-DD
**Step:** Step 2.1 — Translation Service Protocol
**Status:** ✅ Answered

**Question:**
Will translation be handled locally (dictionary lookup only) or via a remote API?
If remote: what API, endpoint, and what is the data retention policy for user-input text?

**Developer Answer:** [Developer's response verbatim or closely paraphrased]
YYYY-MM-DD

**Action Taken:** Implemented `RemoteTranslationService` using [API name].
API key stored in Keychain via `KeychainManager`. No user input text is logged
per the policy confirmed above.

---

## Q-002 — Aura Point Sync Conflict Resolution

**Asked:** YYYY-MM-DD
**Step:** Step 3.3 — Persistence & Sync
**Status:** ✅ Answered

**Question:**
What is the conflict resolution strategy when offline-cached Aura Points are synced
to Firebase? Options: (a) last-write-wins, (b) server-authoritative, (c) client delta merge.

**Developer Answer:** [Response]

**Action Taken:** [What was implemented as a result]
```

### Rules

- Add a new entry every time you ask the developer a question — before implementation begins.
- Update the entry with the developer's answer and the action taken.
- Never close a question without recording what was implemented as a result.
- Mirror all open questions in `INDEX.md` under "Open Questions Requiring Developer Input."

---

## 7. Known Issues Log

`KNOWN_ISSUES.md` tracks deferred items, known edge cases, and technical debt.

### Format

```markdown
# Known Issues & Technical Debt

---

## KI-001 — Crossword Timer Does Not Account for Backgrounding

**ID:** KI-001
**Severity:** Medium (affects scoring fairness)
**Status:** 🔄 Open
**Step Introduced:** Step 4.2 — Crossword Grid UI
**Iteration:** 4

**Description:**
The crossword timer (`CrosswordViewModel.elapsedTime`) uses a `Task`-based loop with
`Task.sleep`. If the app is backgrounded mid-puzzle, the timer pauses but the real-world
time continues. Upon foreground, the timer resumes from where it paused, giving the user
"free" time.

**Proposed Fix:**
Store `puzzleStartDate: Date` in the ViewModel. Compute elapsed time as
`Date.now.timeIntervalSince(puzzleStartDate)` rather than accumulating a counter.
This makes the timer wall-clock-accurate regardless of backgrounding.

**Why Deferred:**
Low user impact in Iteration-4 MVP. The scoring formula still penalizes hints.
Will address in first post-launch patch.

**Impact:**
Slightly inflated scores for users who background the app mid-puzzle.
```

### Severity Levels

| Level | Meaning |
|---|---|
| **Critical** | Security vulnerability, data loss risk, or crash. Must fix before this iteration is done. |
| **High** | Materially incorrect behavior visible to most users. Fix before App Store submission. |
| **Medium** | Incorrect behavior in edge cases or minor impact. Fix in next iteration or first patch. |
| **Low** | Cosmetic or negligible impact. Fix if time permits. |
| **Tech Debt** | No user-facing impact but increases future maintenance cost. Scheduled for refactor. |

---

## 8. When to Write Documentation

This table tells you exactly when each document gets updated:

| Event | Action |
|---|---|
| Before writing any code for a step | Create the step's `.md` file with Status: 🔄 In Progress |
| After completing each file in the step | Add the file to "Files Created" or "Files Modified" in the step doc |
| After making an architectural decision | Write the ADR in `ARCHITECTURE_DECISIONS.md` immediately |
| Before asking the developer a question | Log the question in `QUESTIONS_AND_ANSWERS.md` |
| After receiving a developer's answer | Update the Q&A entry and record the action taken |
| When you discover an issue you will not fix now | Add it to `KNOWN_ISSUES.md` |
| After completing a step | Mark Status: ✅ Complete, fill in the DoD checklist, update `INDEX.md` |
| After completing an iteration | Update the Iteration Status table in `INDEX.md` |

---

## 9. Writing Style Rules

The development logs are **read by a human developer**, not parsed by a machine. Write accordingly.

- **Plain English.** Explain what you built and why as if writing to a smart colleague who wasn't in the room.
- **No hedging.** Don't write "I attempted to implement..." — write "I implemented..." or "I did not implement X because Y."
- **Be specific.** "Modified `GlossaryViewModel`" is useless. "Added `searchQuery` as a `@Published` property and wired it to `SearchSlangTermsUseCase` via a `Task` with 300ms debounce" is useful.
- **Decisions over descriptions.** The code describes what was built. The log explains why it was built that way.
- **Short sentences.** Each sentence has one idea.
- **No passive voice** for decisions. Write "I chose `LazyVStack` over `List`," not "A `LazyVStack` was used."

---

## 10. What the Developer Uses This For

To be concrete about the value: the developer reads `INDEX.md` at the start of every session to orient. They read the most recent step doc to understand exactly where things stand. They check `QUESTIONS_AND_ANSWERS.md` to see if there are unanswered questions blocking progress. They check `KNOWN_ISSUES.md` to monitor accumulating debt. They read `ARCHITECTURE_DECISIONS.md` when they want to understand a design choice or are considering a direction change.

The documentation is not a report. It is the developer's **steering wheel**. Keep it accurate and it keeps the project on track.

---

*Reference documents: `CLAUDE.md`, `FUNCTIONAL_REQUIREMENTS.md`, `PROPOSAL.md`*
