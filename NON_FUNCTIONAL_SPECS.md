# NON_FUNCTIONAL_SPECS.md — SlangCheck
### Non-Functional Requirements & Quality Attributes

> This document defines **how well the app must perform**, not what it does.
> These requirements constrain every architectural, implementation, and deployment decision.
> They are not optional. Claude Code must validate each spec before marking an iteration complete.

---

## 1. Performance

### 1.1 Launch Time

| Metric | Target | Hard Limit |
|---|---|---|
| Cold launch to interactive (first frame rendered) | ≤ 1.0s | 2.0s |
| Warm launch to interactive | ≤ 0.4s | 0.8s |

- NF-P-001: The app shall not perform any synchronous network calls on the main thread during launch.
- NF-P-002: The initial Glossary list shall render the first visible screen of content within 200ms of the Glossary tab being selected, even with 500+ terms in the database.
- NF-P-003: All CoreData fetch requests for list views shall use `NSFetchedResultsController` with batch fetching (batch size: 20 items).

### 1.2 Animation & Frame Rate

- NF-P-004: All animations shall maintain a consistent 60fps on an iPhone XS or later, and 120fps on ProMotion-capable devices (iPhone 13 Pro and later). Use Instruments Time Profiler to verify.
- NF-P-005: The Swiper card drag gesture shall have **zero perceptible latency** between touch input and card movement. The gesture recognizer shall run on the main thread with no intermediate async hops.
- NF-P-006: The crossword grid shall render within 100ms of the puzzle data being available in memory.

### 1.3 List & Scroll Performance

- NF-P-007: Scrolling through the full Glossary list (500+ items) shall exhibit no dropped frames, measured via Instruments Core Animation.
- NF-P-008: The alphabetical scrubber shall respond to drag input within one frame (≤ 16ms on 60Hz displays).
- NF-P-009: All `ForEach` loops over mutable collections shall use stable, non-index-based `id` values.

### 1.4 Memory

- NF-P-010: Peak memory usage during normal browsing (Glossary, Swiper) shall not exceed **80MB**.
- NF-P-011: The app shall not retain any in-memory cache of slang term content larger than the currently visible screen plus a 2-screen lookahead.
- NF-P-012: Instruments Leaks tool shall report **zero leaks** after any standard user session (onboarding → swiper → glossary → quiz → profile).

### 1.5 Battery

- NF-P-013: Background sync operations shall use `BGAppRefreshTask` or `BGProcessingTask` (not a background `Timer`), allowing the OS to schedule them intelligently.
- NF-P-014: The app shall not hold a continuous network connection when in the background. Firebase listeners shall be paused on `sceneDidEnterBackground` and resumed on `sceneWillEnterForeground`.

---

## 2. Reliability & Availability

- NF-R-001: Iteration-1 features (Swiper, Glossary, Lexicon) shall be available **100% of the time**, regardless of network state. No feature in Iteration-1 shall degrade due to a network failure.
- NF-R-002: The app shall handle Firebase Firestore unavailability gracefully. If a cloud sync fails, the app shall queue the operation locally and retry with **exponential backoff** (initial delay: 5s, max delay: 5min, max retries: 10).
- NF-R-003: The app shall never display a system-level crash or unhandled exception to the user. All thrown errors shall be caught and translated into user-visible error states within the UI.
- NF-R-004: CoreData shall be configured with a **migration policy** from the outset. Every future schema change must have a corresponding lightweight or custom migration. Claude Code must create a migration plan when modifying any CoreData model.
- NF-R-005: The Daily Crossword puzzle shall be cached locally upon first successful fetch. If the Firestore fetch fails at 12:00 AM, the system shall retry silently and serve the cached puzzle (previous day) with an inline notice.

---

## 3. Security

### 3.1 Data at Rest

- NF-S-001: No user credentials, authentication tokens, or session secrets shall be stored in `UserDefaults`, `NSUserDefaults`, or any plist file. All secrets shall use the **iOS Keychain** via a `KeychainManager` abstraction.
- NF-S-002: CoreData stores shall be stored in the app's `Application Support` directory (not `Documents`), which is excluded from user-accessible iCloud Drive backups by default.
- NF-S-003: Any sensitive user data (display name, email) shall be stored only in Firebase Auth and accessed via the Firebase SDK — never duplicated into a local flat file.

### 3.2 Data in Transit

- NF-S-004: All network communication shall use **HTTPS/TLS 1.3**. `NSAllowsArbitraryLoads` in `Info.plist` must remain `false`.
- NF-S-005: The Firebase SDK handles its own TLS; no additional pinning is required unless a custom API backend is added. If a custom backend is added, **certificate pinning** shall be implemented and the mechanism confirmed with the developer.
- NF-S-006: API keys shall never be compiled into source code. All third-party API keys shall be stored in a `Secrets.xcconfig` file that is listed in `.gitignore` and never committed.

### 3.3 Authentication & Authorization

- NF-S-007: Firebase Security Rules shall enforce that a user can only read and write their own Aura profile document (`/users/{userId}`). No user shall be able to read or modify another user's data directly.
- NF-S-008: The global leaderboard shall be a read-only Firestore collection for all authenticated users. Write access shall be restricted to a **Firebase Cloud Function** (server-side), never client-side.
- NF-S-009: The Daily Crossword answer key shall never be present in the client-readable Firestore document before `revealAt`. The answer delivery mechanism must be server-gated.
- NF-S-010: ⚠️ **Requires developer review:** All Firestore Security Rules must be reviewed and approved by the developer before any cloud feature is deployed to production.

### 3.4 Privacy

- NF-S-011: The app shall comply with **Apple's App Privacy requirements** (App Privacy Nutrition Labels). A complete `PrivacyInfo.xcprivacy` manifest shall be maintained for every iteration.
- NF-S-012: No personally identifiable information (PII) shall be included in log output, crash reports, or analytics events. User-generated text input (Translator) shall never be logged.
- NF-S-013: The app shall not use any third-party analytics SDK without explicit developer approval. If analytics are added, the SDK, data collected, and retention period must be documented in `TECH_STACK.md`.
- NF-S-014: Sign in with Apple shall be the **only** OAuth provider unless the developer explicitly approves additional providers. Apple's requirement to offer Sign in with Apple whenever any other OAuth provider is offered must be maintained.

---

## 4. Scalability

- NF-SC-001: The local CoreData schema and seed JSON format shall support an **unbounded number of slang terms**. No hardcoded limits shall exist on dictionary size.
- NF-SC-002: The Firestore data model shall be designed to support **1,000,000+ users** on the global leaderboard without client-side pagination limits. Leaderboard queries shall use Firestore cursor-based pagination.
- NF-SC-003: The Aura Point sync model shall use **delta updates** (write only changed fields), not full document replacement, to minimize Firestore write costs at scale.
- NF-SC-004: The Daily Crossword puzzle shall be delivered as a single shared Firestore document read by all users — not a per-user copy — to leverage Firestore's read scaling.

---

## 5. Maintainability

- NF-M-001: Every `public` and `internal` Swift type, method, and property shall have a **DocC comment** (`///`). The project shall build without documentation warnings.
- NF-M-002: No single Swift file shall exceed **300 lines** of code. Files approaching this limit shall be proactively refactored before the limit is reached.
- NF-M-003: The project shall maintain a minimum **unit test coverage of 80%** on all `Core/` layer code (Models, UseCases, Repositories, ScoringEngine). Coverage shall be measured via Xcode's code coverage report.
- NF-M-004: All magic strings shall be defined in `Localizable.strings`. All magic numbers shall be named constants in the appropriate `Constants` file.
- NF-M-005: The project shall use `swift-format` with a committed `.swift-format` configuration file. The CI (if configured) shall reject PRs with formatting violations.
- NF-M-006: No `TODO:` comment shall be merged without a corresponding item in the project's issue tracker. `FIXME:` comments shall be treated as blocking.

---

## 6. Testability

- NF-T-001: All `Core/` layer types shall be **protocol-driven** and injectable. No `Core/` type shall instantiate a concrete Firebase, CoreData, or URLSession object directly.
- NF-T-002: All ViewModels shall be testable without a running SwiftUI view hierarchy. ViewModel unit tests shall use mock implementations of service protocols.
- NF-T-003: The `AuraScoringEngine` shall have **100% unit test coverage**, given its direct impact on competitive fairness.
- NF-T-004: The Firestore sync logic shall be testable via a mock `FirestoreService` protocol implementation. No unit test shall make a real network call.
- NF-T-005: The project shall include at minimum one **UI test** per major user flow: Onboarding, Swiper save flow, Glossary search, Quiz completion, Crossword submission.

---

## 7. Usability & UX Quality

- NF-UX-001: No loading spinner shall be shown for operations expected to complete in under 200ms (e.g., local search, category filter).
- NF-UX-002: All operations that may take over 500ms shall display a non-blocking skeleton or placeholder state — never a full-screen blocking spinner.
- NF-UX-003: Every destructive action (delete account, remove from lexicon, etc.) shall require a confirmation step.
- NF-UX-004: All error states shall include a **user-actionable recovery path** (retry, go back, open settings). Generic "Something went wrong" messages are not acceptable without a recovery CTA.
- NF-UX-005: The app shall provide **haptic feedback** for all swipe completions, quiz answer selections, successful copies, and tier promotions. Haptics shall use the appropriate `UIFeedbackGenerator` subclass for each context.
- NF-UX-006: The app shall support **iPad** at a minimum in a split-view-compatible layout. The Swiper, Glossary, and Translator must render correctly at all iPad size classes. Full iPad optimization is a stretch goal, not a hard requirement for Iteration-1.

---

## 8. Platform Compatibility

| Requirement | Value |
|---|---|
| Minimum iOS version | iOS 17.0 |
| Target SDK | Latest stable Xcode release at time of development |
| Supported devices | iPhone (all models supporting iOS 17+) |
| Orientation | Portrait only (all screens) |
| iPad | Compatible (not optimized in Iteration-1) |
| watchOS | Architecture must not preclude a future watchOS companion app |
| visionOS | Architecture must not preclude a future visionOS port |

- NF-PL-001: The `Core/` layer must have **zero platform-specific imports** (`UIKit`, `SwiftUI`, `AppKit`, `WatchKit`). This is the prerequisite for watchOS/visionOS expansion.
- NF-PL-002: All platform-specific APIs (notifications, haptics, clipboard) shall be accessed via **protocol abstractions** in `Core/Services/`, with concrete iOS implementations in `Data/`.

---

## 9. Localization

- NF-LC-001: All user-facing strings shall be externalized to `Localizable.strings` from the first line of code. No string shall be hardcoded in a SwiftUI view.
- NF-LC-002: The app shall ship in **English** in Iteration-1. The localization infrastructure (`.strings` file, `String(localized:)` usage) shall be in place to allow future language additions without code changes.
- NF-LC-003: Date and time formatting shall always use `DateFormatter` with the user's current `Locale`. No date format strings shall be hardcoded.

---

## 10. App Store Compliance

- NF-AS-001: The app shall comply with all current **App Store Review Guidelines** at the time of submission.
- NF-AS-002: The emoji slang category (Category 6 in `DATABASE.md`) contains adult-themed emoji definitions. The app shall be rated **17+** (Frequent/Intense Mature/Suggestive Themes) on the App Store.
- NF-AS-003: The app's `PrivacyInfo.xcprivacy` shall accurately declare all API usage, data types collected, and tracking usage prior to each submission.
- NF-AS-004: The app shall not use any private or undocumented Apple API.

---

*Reference documents: `CLAUDE.md`, `FUNCTIONAL_REQUIREMENTS.md`, `TECH_STACK.md`*
