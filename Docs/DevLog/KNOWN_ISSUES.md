# Known Issues & Technical Debt — SlangCheck

---

## KI-001 — Unit Test Target Must Be Added Manually in Xcode

**ID:** KI-001
**Severity:** High (blocks Step 1.9 verification)
**Status:** Open
**Step Introduced:** Step 1.1 — Design System Foundation
**Iteration:** 1

**Description:**
The Xcode project (SlangCheck.xcodeproj) was created from a SwiftUI template that uses `PBXFileSystemSynchronizedRootGroup`. Test files are written in `SlangCheckTests/` at the repo root, but there is no XCTest target in the project file referencing this folder.

**Required Action by Developer:**
1. Open `SlangCheck.xcodeproj` in Xcode.
2. File → New → Target → Unit Testing Bundle.
3. Name it `SlangCheckTests`.
4. Set the "Test Host" to the `SlangCheck` app target.
5. Remove the auto-generated test file Xcode creates.
6. The `SlangCheckTests/` folder on disk will be automatically picked up by the new target if using the file-system synchronized group approach, or manually add the folder reference.

**Impact:**
Test files exist and are correct Swift code, but cannot be run until the target is configured.

**Why Deferred:**
Cannot add an Xcode target programmatically without modifying the `.pbxproj` binary format, which is high-risk. Developer must perform this one-time setup in Xcode.

---

## KI-002 — CoreData Model Requires Xcode Build to Validate Schema

**ID:** KI-002
**Severity:** Medium
**Status:** Open
**Step Introduced:** Step 1.3 — Local Data Layer
**Iteration:** 1

**Description:**
The CoreData model (`SlangCheckData.xcdatamodeld`) is created as a hand-authored XML file on disk. While the schema is correct per CoreData's documented format, it should be validated by building the project in Xcode to confirm the `NSPersistentContainer` can load the model without errors.

**Required Action by Developer:**
Build the project in Xcode after the initial checkout. Any CoreData schema errors will appear as runtime errors in the `PersistenceController` initializer, which uses `fatalError` with a descriptive message.

---

## KI-003 — Onboarding Segment Does Not Yet Influence Swiper Card Order

**ID:** KI-003
**Severity:** Low
**Status:** Open
**Step Introduced:** Step 1.8 — App Shell & Navigation
**Iteration:** 1

**Description:**
FR-O-002 states that the user's onboarding segment selection ("Unc", "Trend-Seeker", "Language Enthusiast") should influence the initial Swiper card order. In Iteration 1, the Swiper orders cards by `usageFrequency` descending and randomizes within groups (FR-S-007). Segment-based reordering requires knowing which categories each segment cares about most, which is not yet defined.

**Proposed Fix:**
Define a mapping in `AppConstants` (e.g., `segmentPreferredCategories: [UserSegment: [SlangCategory]]`). The `SwiperViewModel` applies this as an additional sort dimension when building the card queue.

**Why Deferred:**
The category-to-segment mapping requires product design input. The default sort (usage frequency) is reasonable for all segments in Iteration 1 MVP.

---
