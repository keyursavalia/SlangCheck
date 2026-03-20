# Architecture Decision Records — SlangCheck

---

## ADR-001: @Observable over ObservableObject for ViewModels

**Date:** 2026-03-19
**Status:** Accepted
**Step:** 1.1 — Design System Foundation

### Context

The project targets iOS 17.0 minimum (per TECH_STACK.md). Two patterns exist for reactive ViewModels in SwiftUI: the legacy `ObservableObject` + `@Published` pattern and the modern `@Observable` macro introduced in iOS 17.

### Decision

All ViewModels use the `@Observable` macro from the Observation framework. No `ObservableObject`, no `@Published`.

### Rationale

`@Observable` provides finer-grained view invalidation (only views reading a specific property re-render, not the entire view tree). It eliminates the need for `@StateObject`/`@ObservedObject` distinction. It produces less boilerplate and is Apple's recommended forward-looking pattern.

### Alternatives Considered

- **ObservableObject + @Published:** Rejected. Coarser invalidation, more boilerplate, deprecated in spirit for iOS 17+.
- **Combine PassthroughSubject:** Rejected. Adds complexity without benefit given @Observable's capabilities.

### Consequences

ViewModels are easier to test (no SwiftUI dependency for instantiation). Child views receive ViewModels via `@Bindable` or direct property access. Views must use `@State` to own a ViewModel, not `@StateObject`.

### Related Files

- All `Features/**/` ViewModel files

---

## ADR-002: CoreData as Primary Persistence Layer for Iteration 1

**Date:** 2026-03-19
**Status:** Accepted
**Step:** 1.1 — Design System Foundation

### Context

The app needs to store 90+ slang terms (seeded from JSON), a user lexicon (saved term IDs + timestamps), and future quiz/profile data. Two options exist: CoreData (mature, NSFetchedResultsController, lightweight migration) and SwiftData (modern, Swift-native, but less migration tooling).

### Decision

CoreData via `NSPersistentContainer` is the primary persistence layer for Iteration 1 entities (`SlangTerm`, `LexiconEntry`). SwiftData is reserved for new isolated entities introduced in Iteration 3+.

### Rationale

CoreData's `NSFetchedResultsController` satisfies NF-P-003 (batch fetching, batch size 20). CoreData's migration tooling (`.xcmappingmodel`) satisfies NF-R-004 (migration policy from day one). SwiftData's migration story is less mature for complex schemas.

### Alternatives Considered

- **SwiftData for everything:** Rejected. Migration tooling is insufficient for the long-lived schema we need. NF-R-004 explicitly requires migration policy.
- **JSON file storage:** Rejected. No query capability, no reactive updates, poor performance at 500+ terms.

### Consequences

More boilerplate than SwiftData. NSManagedObject subclasses must be written manually (since Xcode codegen runs at build time). The repository pattern cleanly hides this from the rest of the app.

### Related Files

- `SlangCheck/Data/CoreData/PersistenceController.swift`
- `SlangCheck/Data/CoreData/CoreDataSlangTermRepository.swift`
- `SlangCheck/Data/CoreData/SlangCheckData.xcdatamodeld/`

---

## ADR-003: Repository Protocol Pattern for Data Access

**Date:** 2026-03-19
**Status:** Accepted
**Step:** 1.1 — Design System Foundation

### Context

ViewModels need access to slang term data. They must not import CoreData directly (per CLAUDE.md MVVM contract). Tests must be able to mock data access without a real CoreData stack.

### Decision

Define `SlangTermRepository` as a protocol in `Core/Repositories/`. The concrete `CoreDataSlangTermRepository` implementation lives in `Data/CoreData/`. ViewModels depend only on the protocol.

### Rationale

Protocol abstraction allows test injection of mock repositories. Enables future migration to a different persistence layer without touching ViewModel code. Satisfies NF-T-001 (all Core types protocol-driven and injectable).

### Alternatives Considered

- **Direct CoreData in ViewModel:** Rejected. Violates MVVM contract. Makes testing impossible without a real CoreData stack.
- **Singleton data store:** Rejected. Global state, cannot be mocked, violates DI principle.

### Consequences

More files/types. Each new data entity needs a protocol + implementation pair. Test mocks must implement the protocol. This cost is worth the testability and architectural clarity.

### Related Files

- `SlangCheck/Core/Repositories/SlangTermRepository.swift`
- `SlangCheck/Data/CoreData/CoreDataSlangTermRepository.swift`

---

## ADR-004: AppEnvironment Value Type for Dependency Injection

**Date:** 2026-03-19
**Status:** Accepted
**Step:** 1.1 — Design System Foundation

### Context

ViewModels and UseCases need access to repository implementations and services. Options: service locator (global singleton), environment injection, constructor injection per view.

### Decision

A root `AppEnvironment` struct (value type) is created at app startup and injected into the SwiftUI view hierarchy via `.environment()`. ViewModels receive what they need via the environment or constructor injection from the view.

### Rationale

Per CLAUDE.md: "Use a root AppEnvironment struct (value type) that is injected via SwiftUI's .environment() modifier. Never use a service locator or global singleton (except Logger)." Value type prevents shared mutable state. SwiftUI environment propagation is idiomatic.

### Alternatives Considered

- **Service Locator / Singleton:** Rejected. Explicitly banned by CLAUDE.md. Makes testing hard.
- **Constructor injection at every view:** Rejected. Verbose, requires threading services through many view layers.

### Consequences

All concrete service instances are created once at app launch in `SlangCheckApp.swift`. Easy to swap for test environments by providing a different `AppEnvironment`.

### Related Files

- `SlangCheck/App/AppEnvironment.swift`
- `SlangCheck/App/SlangCheckApp.swift`

---

## ADR-005: Programmatic Color Tokens over Asset Catalog Color Sets

**Date:** 2026-03-19
**Status:** Accepted
**Step:** 1.1 — Design System Foundation

### Context

Design tokens need to support Light ("Vibrant Day") and Dark ("Midnight Cyber") modes. Two implementation paths: SwiftUI Color Sets in `.xcassets` (GUI-driven, binary-ish format) or programmatic `Color` initializers using `UIColor(dynamicProvider:)`.

### Decision

Colors are defined programmatically in `DesignSystem/Colors.swift` using `UIColor(dynamicProvider:)` to switch between light/dark hex values. The `SlangColor` enum exposes `static var` properties returning `Color`.

### Rationale

Programmatic tokens are fully version-controllable (plain Swift text). They do not require Xcode GUI to edit. They can be reviewed in PRs as readable code. The approach is consistent with the "design system as code" principle.

### Alternatives Considered

- **Asset Catalog Color Sets:** Rejected. Binary `.xcassets` format is harder to review in PRs. Adding a new color requires Xcode GUI interaction.

### Consequences

`UIKit` import is required in `Colors.swift` for `UIColor(dynamicProvider:)`. This is acceptable since `DesignSystem/` is a UI-layer concern (it imports `SwiftUI` anyway). `Core/` remains UIKit-free.

### Related Files

- `SlangCheck/DesignSystem/Colors.swift`

---

## ADR-006: LazyVStack + ScrollView over List for Glossary

**Date:** 2026-03-19
**Status:** Accepted
**Step:** 1.4 — The Glossary Feature

### Context

The Glossary needs a scrollable, alphabetically grouped list of 500+ terms. `List` is the obvious SwiftUI choice. `LazyVStack` inside `ScrollView` is the alternative.

### Decision

`LazyVStack` inside a `ScrollView` with `ScrollViewReader` for scrubber navigation. `List` is not used.

### Rationale

Per CLAUDE.md Step 1.4: "use LazyVStack inside ScrollView, not List, to allow future custom cell styling." `List` applies system row styling (separator, background) that conflicts with our Glassmorphism/Neumorphism design. `LazyVStack` gives complete styling control while maintaining lazy rendering for performance (satisfies NF-P-007, NF-P-002).

### Alternatives Considered

- **List:** Rejected. System-imposed styling conflicts with design system. Swipe-to-delete in Lexicon must be reimplemented anyway.
- **UICollectionView via UIViewRepresentable:** Rejected. Unnecessary UIKit complexity per CLAUDE.md.

### Consequences

Manual implementation of alphabetical section headers and sticky positioning. `ScrollViewReader` + `ScrollViewProxy.scrollTo()` used for scrubber jump. Swipe-to-delete in Lexicon implemented via `DragGesture` on rows.

### Related Files

- `SlangCheck/Features/Glossary/GlossaryView.swift`
- `SlangCheck/Features/Profile/LexiconView.swift`
