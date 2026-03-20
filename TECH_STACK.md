# TECH_STACK.md — SlangCheck
### Technology Stack & Architectural Decisions Reference

> This document is the **authoritative technology reference** for every dependency, framework,
> service, and tooling decision in the SlangCheck project. Claude Code must consult this
> document before adding any new dependency or framework. Any deviation from the listed
> stack requires explicit developer approval and an update to this document.

---

## 1. Platform & Language

| Component | Choice | Version / Notes |
|---|---|---|
| **Language** | Swift | 5.9+ (use modern features: typed throws, `@Observable`, macros) |
| **UI Framework** | SwiftUI | Primary. UIKit used only when SwiftUI cannot achieve the requirement — must be documented. |
| **Minimum Deployment Target** | iOS 17.0 | Enables `@Observable`, `SwiftData`, `ImageRenderer` stable API. |
| **Target SDK** | Latest stable Xcode at time of development | Always build against the latest stable SDK. |
| **Xcode** | Latest stable release | No beta Xcode in production builds. |

### Swift Version Policy

- Use `@Observable` (Observation framework) over `ObservableObject` + `@Published` for all new ViewModels. iOS 17+ makes this viable for the full deployment target.
- Use Swift's `async/await` and structured concurrency (`Task`, `TaskGroup`, `actor`) exclusively. No `DispatchQueue`, `OperationQueue`, or GCD unless wrapping a legacy callback-based API.
- Use typed `throws` where the error type is known. Define typed error enums per domain (e.g., `SlangRepositoryError`, `AuraSyncError`).

---

## 2. Architecture

| Pattern | Application |
|---|---|
| **MVVM** | Universal across all features. View → ViewModel → UseCase → Repository → Service. |
| **Clean Architecture layers** | `Core/` (pure Swift), `Data/` (platform implementations), `Features/` (SwiftUI) |
| **Dependency Injection** | Constructor injection via `AppEnvironment` value type, passed through SwiftUI `.environment()` |
| **Coordinator / Navigation** | SwiftUI native `NavigationStack` with programmatic path binding. No third-party router. |
| **Reactive layer** | Swift's `Observation` framework (`@Observable`) + `AsyncStream` for one-directional data flows. `Combine` only where `AsyncStream` is insufficient. |

---

## 3. Local Persistence

### 3.1 CoreData (Primary Persistence)

| Aspect | Detail |
|---|---|
| **Usage** | All slang term data, user lexicon, quiz history, aura profile, crossword progress |
| **Stack** | `NSPersistentContainer` with `NSPersistentStoreDescription` configured for the `Application Support` directory |
| **Concurrency** | Use `NSManagedObjectContext` with `perform` / `performAndWait` on a private background context for all writes. The view context (main thread) is read-only. |
| **Migration** | Lightweight migration enabled from day one. Every model version increment requires a `.xcmappingmodel` if lightweight migration is insufficient. |
| **Thread safety** | Never pass `NSManagedObject` instances across thread boundaries. Use object IDs and re-fetch on the target context. |

### 3.2 SwiftData (Secondary / New Entities)

| Aspect | Detail |
|---|---|
| **Usage** | New entities introduced in Iteration-3+ that don't need to coexist with legacy CoreData models. Evaluate per entity. |
| **When to use** | Prefer SwiftData for new, self-contained models with no migration complexity. Use CoreData for any entity that must coexist with the existing schema. |
| **Concurrency** | Use `ModelActor` for background context operations. |

### 3.3 UserDefaults

| Aspect | Detail |
|---|---|
| **Usage** | Non-sensitive, non-critical preferences only: `hasCompletedOnboarding`, `selectedUserSegment`, `notificationPreferences`, `lastGlossaryScrollPosition`. |
| **Banned** | Tokens, session IDs, Aura Points, any user-generated content. |

### 3.4 Keychain

| Aspect | Detail |
|---|---|
| **Usage** | Firebase Auth token refresh tokens, any future API keys stored client-side. |
| **Implementation** | A `KeychainManager` struct wrapping `Security` framework APIs. No third-party Keychain library without developer approval. |
| **Accessibility** | `kSecAttrAccessibleAfterFirstUnlock` for tokens that must be readable in background tasks. |

---

## 4. Backend & Cloud Services

### 4.1 Firebase

> Firebase is the **sole cloud platform** for SlangCheck. All cloud services route through Firebase.

| Firebase Service | Usage |
|---|---|
| **Firebase Auth** | User authentication (Sign in with Apple primary). Anonymous auth for guest users. |
| **Firestore** | Aura profiles (`/users/{uid}`), global leaderboard (`/leaderboard`), daily crossword puzzles (`/crosswords/{date}`), dynamic dictionary terms (`/terms/{termId}`). |
| **Firebase Cloud Functions** | Server-side Aura Point validation for the leaderboard write path. Crossword answer key gating. Scheduled dictionary term publication. |
| **Firebase Cloud Messaging (FCM)** | Push notifications for daily crossword alerts and streak reminders (pending developer confirmation — see FR-N-007). |
| **Firebase Remote Config** | Feature flags for toggling Iteration features (e.g., enabling Iteration-2 tab for all users). Aura tier threshold values (allows adjustment without App Store update). |
| **Firebase Analytics** | ⚠️ **Requires developer approval before enabling.** If approved: only non-PII events (screen views, quiz completion, tier promotions). No user-generated content logged. |
| **Firebase Crashlytics** | Crash reporting. PII scrubbing must be confirmed before enabling. |

### 4.2 Firestore Data Model

```
/users/{userId}
  - displayName: String?
  - auraPoints: Int
  - currentTier: String
  - streak: Int
  - lastActivityDate: Timestamp
  - segment: String  // "unc" | "trendSeeker" | "languageEnthusiast"

/leaderboard/{userId}
  - displayName: String?         // anonymized if user opted out
  - auraPoints: Int
  - currentTier: String
  - rank: Int                    // written by Cloud Function only

/crosswords/{YYYY-MM-DD}
  - grid: [[CrosswordCellData]]
  - clues: { across: [Clue], down: [Clue] }
  - revealAt: Timestamp
  - answerKey: EncryptedPayload  // never readable before revealAt

/terms/{termId}
  - term: String
  - definition: String
  - standardEnglish: String
  - exampleSentence: String
  - category: String
  - usageFrequency: String
  - generationTags: [String]
  - addedDate: Timestamp
  - isActive: Bool
```

### 4.3 Firebase Security Rules Principles

- Users can only read/write their own `/users/{userId}` document.
- `/leaderboard` is readable by all authenticated users; writable only by Cloud Functions service account.
- `/crosswords/{date}` is readable by all authenticated users; `answerKey` field is hidden behind a Cloud Function endpoint that validates `revealAt`.
- `/terms` is readable by all (authenticated and anonymous); writable only by admin SDK (Cloud Functions).
- ⚠️ All rules must be reviewed and approved by the developer before deployment.

---

## 5. Networking

| Aspect | Choice |
|---|---|
| **HTTP client** | `URLSession` with async/await. No third-party networking library (Alamofire, etc.) unless specifically approved. |
| **TLS** | TLS 1.3 preferred, TLS 1.2 minimum. `NSAllowsArbitraryLoads = false`. |
| **Certificate pinning** | Not required for Firebase (handles internally). Required for any custom backend API added in future. |
| **Request timeout** | 30s default for all `URLSession` data tasks. |
| **Retry policy** | Exponential backoff: initial 5s, multiplier ×2, max delay 5min, max retries 10. Implemented in a reusable `RetryPolicy` struct in `Core/Network/`. |
| **API Keys** | Stored in `Secrets.xcconfig` (gitignored). Never in source code. Injected at build time via `Info.plist` variable substitution. |

---

## 6. Animation & Graphics

| Concern | Approach |
|---|---|
| **Standard transitions** | SwiftUI's `.animation(.spring(response: 0.35, dampingFraction: 0.7), value:)` |
| **Card flip** | `.rotation3DEffect` on Y axis, 0.4s spring |
| **Swipe gesture** | `DragGesture` with `@GestureState`. Pure SwiftUI — no UIKit gesture recognizer. |
| **Social card generation** | `ImageRenderer` (iOS 16+, stable on iOS 17 target) for Aura Cards and Crossword Result Cards. All rendering on `@MainActor`. |
| **Glassmorphism blur** | `.ultraThinMaterial` SwiftUI material. Custom `glassCard()` `ViewModifier`. |
| **Neumorphism shadows** | `.shadow()` modifier layered with light/dark adaptive colors. Custom `neumorphicSurface()` `ViewModifier`. |
| **Lottie animations** | ⚠️ **Not included by default.** If complex vector animations are needed (e.g., tier promotion celebration), Lottie may be added with developer approval. Prefer SwiftUI-native alternatives. |
| **SF Symbols** | Used exclusively for all iconography. No third-party icon set. Symbol weight matches adjacent typography weight. |

---

## 7. Haptics

| Trigger | Generator |
|---|---|
| Swipe completion (save/dismiss) | `UIImpactFeedbackGenerator(style: .medium)` |
| Quiz answer: correct | `UINotificationFeedbackGenerator` with `.success` |
| Quiz answer: incorrect | `UINotificationFeedbackGenerator` with `.error` |
| Copy to clipboard | `UINotificationFeedbackGenerator` with `.success` |
| Tier promotion | `UINotificationFeedbackGenerator` with `.success` (accompanied by animation) |
| Swipe card button (tap alternative) | `UIImpactFeedbackGenerator(style: .light)` |

All haptic generators shall be wrapped in a `HapticEngine` abstraction in `Core/Services/` to allow mocking in tests and easy disabling via a user preference.

---

## 8. Testing

| Type | Framework | Notes |
|---|---|---|
| **Unit Tests** | XCTest | For all `Core/` layer: models, use cases, repositories (mocked), scoring engine |
| **ViewModel Tests** | XCTest + Swift Testing (iOS 17+) | ViewModels tested without SwiftUI, using mock service protocols |
| **UI Tests** | XCUITest | One test per major user flow (see NF-T-005) |
| **Snapshot Tests** | ⚠️ Optional — requires developer approval | If added: swift-snapshot-testing library |
| **Mock generation** | Manual protocol mocks | No mock generation library unless project grows beyond 20 services |
| **Test data** | In-memory CoreData store (`NSInMemoryStoreType`) for all persistence tests | Never tests against a real Firestore instance |

---

## 9. Developer Tooling

| Tool | Purpose |
|---|---|
| **swift-format** | Code formatting. Configuration committed at `.swift-format`. Enforced pre-commit. |
| **SwiftLint** | Static analysis. `.swiftlint.yml` committed. Warnings treated as errors in CI. |
| **Xcode Cloud / GitHub Actions** | CI/CD. Build, test, lint on every PR. (Confirm provider with developer.) |
| **DocC** | Documentation generation. `/// DocC` comments on all public/internal types. |
| **Instruments** | Performance profiling. Time Profiler, Leaks, Core Animation required before each iteration sign-off. |
| **Git** | Version control. Branching strategy: `main` (production), `develop` (integration), `feature/iteration-X-feature-name` |
| **Secrets.xcconfig** | API key management. Listed in `.gitignore`. Template (`Secrets.xcconfig.template`) committed with placeholder values. |

---

## 10. Third-Party Dependencies Policy

> This project follows a **minimal dependency philosophy.** Every third-party package adds
> supply chain risk, binary size, and update burden. Before adding any dependency, ask:
> "Can this be implemented in < 2 hours with stdlib/framework APIs?"

### Approved Dependencies (Iteration-1 baseline)

| Package | Source | Purpose | Approved by |
|---|---|---|---|
| `firebase-ios-sdk` | Google / Swift Package Manager | Auth, Firestore, FCM, Remote Config | Project inception |

### Packages Requiring Developer Approval Before Adding

| Category | Examples | Reason for caution |
|---|---|---|
| Analytics | Amplitude, Mixpanel, Segment | PII risk, privacy policy implications |
| Crash reporting | Crashlytics (via Firebase), Sentry | Data sent off-device; PII scrubbing required |
| Networking | Alamofire | Unnecessary given `URLSession` async/await |
| Image loading | Kingfisher, Nuke | Evaluate if `AsyncImage` is insufficient first |
| Animation | Lottie | Only if SwiftUI animations are genuinely insufficient |
| Keychain | KeychainAccess | Only if custom `KeychainManager` becomes complex |
| Snapshot testing | swift-snapshot-testing | Only with CI integration plan |

### Banned Dependencies

- Any dependency that enables ad tracking, device fingerprinting, or cross-app data sharing.
- Any dependency with a non-OSS license that requires revenue sharing or per-user fees without explicit business approval.
- Any dependency that was last updated more than 18 months ago.

---

## 11. Deployment & Distribution

| Aspect | Detail |
|---|---|
| **Bundle ID** | To be confirmed by developer before first build |
| **App Store Connect** | Primary distribution |
| **TestFlight** | Internal testing (developer + testers) during each iteration |
| **Provisioning** | Automatic signing in Xcode for development; manual for distribution |
| **App Rating** | 17+ (due to emoji slang category adult content) |
| **Privacy Nutrition Label** | Must be updated before each TestFlight or App Store submission |
| **`PrivacyInfo.xcprivacy`** | Maintained from Iteration-1 and updated with each new API usage |

---

## 12. Future Platform Expansion Readiness

| Platform | Readiness Requirement |
|---|---|
| **watchOS** | `Core/` has zero UIKit/SwiftUI imports. Business logic is immediately portable. A watchOS target can be added with a new `Features/Watch/` folder. |
| **visionOS** | Same as watchOS. `DesignSystem/` components built with size-class adaptability. Glassmorphism maps well to visionOS materials. |
| **macOS (Catalyst)** | Portrait-only constraint means Catalyst requires layout adjustments. Not planned but not blocked. |
| **Widget Extension** | Aura streak / daily crossword reminder widget is a natural future addition. `Core/` data access is portable to a Widget extension via shared App Group container. |

---

*Reference documents: `CLAUDE.md`, `NON_FUNCTIONAL_SPECS.md`, `FUNCTIONAL_REQUIREMENTS.md`*
