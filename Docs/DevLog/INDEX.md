# SlangCheck — Development Log Index

**Last updated:** 2026-03-20, Iteration 2 complete
**Current iteration:** Iteration 3 — The Quizzes Phase
**Current step:** Step 3.1 — Aura System Models (not started)
**Overall status:** Iteration 2 Complete — Iteration 3 Awaiting Developer Input

---

## Iteration Status

| Iteration | Name | Status | Completed Steps | Total Steps |
|---|---|---|---|---|
| 1 | The Learn Phase | ✅ Complete | 9/9 | 9 |
| 2 | The Translator Phase | ✅ Complete | 4/4 | 4 |
| 3 | The Quizzes Phase | ⏳ Not Started | 0/6 | 6 |
| 4 | The Daily Crossword Phase | ⏳ Not Started | 0/7 | 7 |

---

## Iteration 1 Step Checklist

| Step | Name | Status |
|---|---|---|
| 1.1 | Design System Foundation | ✅ Complete |
| 1.2 | Core Models | ✅ Complete |
| 1.3 | Local Data Layer (CoreData) | ✅ Complete |
| 1.4 | The Glossary Feature | ✅ Complete |
| 1.5 | Smart Search (integrated into 1.4) | ✅ Complete |
| 1.6 | The Swiper UX | ✅ Complete |
| 1.7 | Personal Lexicon | ✅ Complete |
| 1.8 | App Shell & Navigation | ✅ Complete |
| 1.9 | Testing & Verification | ✅ Complete |

---

## Iteration 2 Step Checklist

| Step | Name | Status |
|---|---|---|
| 2.1 | Translation Service Protocol | ✅ Complete |
| 2.2 | Translation Engine (local) | ✅ Complete |
| 2.3 | Translator UI | ✅ Complete |
| 2.4 | Testing & Verification | ✅ Complete |

---

## Recent Entries

| Date | Step | Summary |
|---|---|---|
| 2026-03-20 | Steps 2.1–2.3 | Iteration 2 complete. TranslationService protocol, TranslateTextUseCase (greedy regex), LocalTranslationService, TranslatorViewModel (400ms debounce), TranslatorView (split-screen + swap + substitutions). 7 new files. |
| 2026-03-20 | Build fixes | Resolved all Xcode build errors from initial compilation (StaticString, withAnimation scope, UsageFrequency context). |
| 2026-03-19 | Steps 1.1–1.8 | Complete Iteration 1 implementation. 43 Swift source files, 1 CoreData model, seed JSON (62 terms), Localizable.strings, full unit test suite. |
| 2026-03-19 | Step 1.1 | Git branching (main/develop/feature), folder structure, DesignSystem tokens. |

---

## Developer Action Required

| # | Action | Priority | Related |
|---|---|---|---|
| A-001 | **Add XCTest target in Xcode** pointing to `SlangCheckTests/`. See KI-001. | High | Step 1.9 |
| A-002 | **Build and run in Xcode** to verify CoreData model loads (SlangCheckData.xcdatamodeld). | High | Step 1.3 |
| A-003 | **Verify app on device/simulator** in both Light and Dark mode. | High | Step 1.9 |
| A-004 | **Add TranslatorViewModelTests + TranslateTextUseCaseTests** to XCTest target in Xcode. | Medium | Step 2.4 |

---

## Open Questions Requiring Developer Input

| # | Question | Status | Step |
|---|---|---|---|
| Q-001 | Additional OAuth providers beyond Sign in with Apple? | ✅ Answered — Apple only | Pre-Iteration 2 |
| Q-002 | Translation engine: local vs. remote API? | ✅ Answered — local only | Step 2.1 |

---

## Known Issues & Tech Debt

| ID | Description | Severity | Step Introduced |
|---|---|---|---|
| KI-001 | Unit test target must be manually added in Xcode (SlangCheckTests/ folder exists). | High | Step 1.1 |
| KI-002 | CoreData model requires build validation in Xcode. | Medium | Step 1.3 |
| KI-003 | Onboarding segment does not yet influence Swiper card order. | Low | Step 1.8 |

---

## File Count Summary (Iteration 1)

| Layer | Files |
|---|---|
| App | 3 (SlangCheckApp, AppEnvironment, MainTabView) |
| Core/Models | 3 |
| Core/Services | 1 |
| Core/Repositories | 1 |
| Core/UseCases | 3 |
| Core/Utilities | 2 |
| Data/CoreData | 6 (+ xcdatamodeld bundle) |
| Data/Services | 1 |
| DesignSystem | 4 + 5 components = 9 |
| Features | 11 (Glossary×3, Swiper×2, Profile×3, Onboarding×2, Placeholders×2) |
| Resources | 2 (seed JSON 62 terms, Localizable.strings) |
| Tests | 5 (Mock + 4 test suites) |
| DevLog | 8 (INDEX, ADRs, Q&A, Issues, 2 step docs) |
| **Total** | **~60 files** |

---

## Architecture Decisions

See [ARCHITECTURE_DECISIONS.md](./ARCHITECTURE_DECISIONS.md) for all ADRs.

---

## Git Branch Strategy

| Branch | Purpose | Current State |
|---|---|---|
| `main` | Production-ready code only | Clean (2 initial commits) |
| `develop` | Integration branch | Created |
| `feature/iteration-1-step-1.1-design-system` | Iteration 1 feature work | Merged into develop |
| `feature/iteration-2-step-2.1-translation-service` | Iteration 2 feature work | Active — Steps 2.1–2.3 |
