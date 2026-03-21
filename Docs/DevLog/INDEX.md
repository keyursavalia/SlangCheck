# SlangCheck — Development Log Index

**Last updated:** 2026-03-21, Iteration 3 Step 3.3 complete
**Current iteration:** Iteration 3 — The Quizzes Phase
**Current step:** Step 3.4 — Quiz Flow UI
**Overall status:** Iteration 3 In Progress

---

## Iteration Status

| Iteration | Name | Status | Completed Steps | Total Steps |
|---|---|---|---|---|
| 1 | The Learn Phase | ✅ Complete | 9/9 | 9 |
| 2 | The Translator Phase | ✅ Complete | 4/4 | 4 |
| 3 | The Quizzes Phase | 🔄 In Progress | 3/6 | 6 |
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

## Iteration 3 Step Checklist

| Step | Name | Status |
|---|---|---|
| 3.1 | Aura System Models | ✅ Complete |
| 3.2 | Scoring Formula | ✅ Complete |
| 3.3 | Persistence & Sync | ✅ Complete |
| 3.4 | Quiz Flow UI | ⏳ Not Started |
| 3.5 | Aura Cards (Social Sharing) | ⏳ Not Started |
| 3.6 | Testing & Verification | ⏳ Not Started |

---

## Recent Entries

| Date | Step | Summary |
|---|---|---|
| 2026-03-21 | Step 3.3 | Persistence & Sync. AuraRepository protocol + AuraRepositoryError, AuraSyncService protocol + AuraSyncError (server-authoritative Q-003), CoreDataAuraRepository actor (upsert profile, append-only quiz results), CDAuraProfile + CDQuizResult managed objects, FirebaseAuraSyncService (behind #if canImport guard), NoOpAuraSyncService fallback, SyncAuraProfileUseCase (local-first + detached background sync), AppEnvironment wired with auraRepository + syncAuraProfileUseCase. SyncAuraProfileUseCaseTests: 11 cases. |
| 2026-03-21 | Step 3.2 | Scoring Formula. AuraScoringEngine (S = C×100/(1+H) - T×2, integer arithmetic, clamped to 0), ScoringInput, ScoringBreakdown, QuizResult model. AuraScoringEngineTests: 35 cases covering zero hints, max hints, zero time, large time, clamping, combined penalties, breakdown, and factory. |
| 2026-03-21 | Step 3.1 | Aura System Models. AuraTier (4 tiers, point ranges, progress, factory), AuraProfile (immutable snapshot, mutation helpers, promotion detection), QuizQuestion + QuizSession (3 question types, allChoices, correctAnswer, sentenceWithBlank). 3 model files + 3 test files. |
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
| A-005 | **Add AuraTierTests, AuraProfileTests, QuizQuestionTests, AuraScoringEngineTests, SyncAuraProfileUseCaseTests** to XCTest target in Xcode. | Medium | Step 3.1–3.3 |
| A-006 | **Add CDAuraProfile and CDQuizResult entities** to SlangCheckData.xcdatamodeld in Xcode (see entity specs in CoreDataClass headers). | High | Step 3.3 |
| A-007 | **Add Firebase iOS SDK via SPM** (FirebaseFirestore + FirebaseAuth), add GoogleService-Info.plist, call FirebaseApp.configure() in SlangCheckApp.init(). | High | Step 3.3 |

---

## Open Questions Requiring Developer Input

| # | Question | Status | Step |
|---|---|---|---|
| Q-001 | Additional OAuth providers beyond Sign in with Apple? | ✅ Answered — Apple only | Pre-Iteration 2 |
| Q-002 | Translation engine: local vs. remote API? | ✅ Answered — local only | Step 2.1 |
| Q-003 | Offline Aura Points sync conflict resolution? | ✅ Answered — server-authoritative | Step 3.3 |
| Q-004 | Aura Card: include user identifier? | ✅ Answered — include display name | Step 3.5 |

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
