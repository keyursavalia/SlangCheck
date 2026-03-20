# FUNCTIONAL_REQUIREMENTS.md — SlangCheck
### Comprehensive End-to-End Functional Requirements

> This document defines **what the app must do** across all four iterations.
> Every feature described here maps to at least one ViewModel, UseCase, and View.
> Claude Code must implement each requirement exactly as written, or flag ambiguity before proceeding.
> Requirements are written in the form: **The system shall…**

---

## Table of Contents

1. [Global / Cross-Cutting Requirements](#1-global--cross-cutting-requirements)
2. [Onboarding](#2-onboarding)
3. [Iteration 1 — The Learn Phase](#3-iteration-1--the-learn-phase)
4. [Iteration 2 — The Translator Phase](#4-iteration-2--the-translator-phase)
5. [Iteration 3 — The Quizzes Phase](#5-iteration-3--the-quizzes-phase)
6. [Iteration 4 — The Daily Crossword Phase](#6-iteration-4--the-daily-crossword-phase)
7. [Profile & Aura Economy](#7-profile--aura-economy)
8. [Social Sharing](#8-social-sharing)
9. [Dynamic Dictionary](#9-dynamic-dictionary)
10. [Notifications](#10-notifications)

---

## 1. Global / Cross-Cutting Requirements

### 1.1 Navigation

- FR-G-001: The app shall provide a persistent bottom tab bar with tabs for: **Swiper**, **Glossary**, **Translator** (unlocked in Iteration 2), **Quizzes** (unlocked in Iteration 3), and **Profile**.
- FR-G-002: Tabs not yet unlocked shall be visible but display an "Coming Soon" state when tapped, not be hidden.
- FR-G-003: The app shall support deep linking into any top-level tab via a URL scheme (`slangcheck://`).
- FR-G-004: The app shall preserve scroll position and navigation state when switching between tabs.

### 1.2 Offline Mode

- FR-G-005: The app shall be fully functional in airplane mode for all Iteration-1 features (Swiper, Glossary, Lexicon).
- FR-G-006: The app shall be fully functional in airplane mode for Iteration-3 Quiz features (pre-downloaded question sets).
- FR-G-007: The app shall display a non-blocking, inline banner (not a modal alert) when the device loses internet connectivity.
- FR-G-008: The app shall automatically resume sync operations when connectivity is restored, without requiring user action.

### 1.3 Accessibility

- FR-G-009: All interactive elements shall have a minimum tap target of 44×44pt.
- FR-G-010: All text shall support Dynamic Type from the smallest to the largest accessibility size category without layout breakage.
- FR-G-011: All images and icons shall have descriptive `accessibilityLabel` values. Decorative elements shall be marked hidden from VoiceOver.
- FR-G-012: The app shall respect the system "Reduce Motion" accessibility setting. All animations shall degrade gracefully to a crossfade.
- FR-G-013: Color shall never be the sole means of conveying information. Every color-coded state (correct/wrong, save/dismiss) shall also have a distinct shape or label.

### 1.4 Theming

- FR-G-014: The app shall automatically adapt to the device's system-level Light/Dark mode setting.
- FR-G-015: The app shall not provide an in-app manual theme toggle (system setting is the source of truth).

---

## 2. Onboarding

### 2.1 First Launch

- FR-O-001: On first launch, the app shall display an onboarding flow of no more than 4 screens explaining the core value proposition.
- FR-O-002: Onboarding shall ask the user to self-identify as one of the three target segments: "The Unc," "Trend-Seeker," or "Language Enthusiast." This selection shall influence the initial Swiper card order (surfacing most-relevant terms first).
- FR-O-003: Onboarding shall include one interactive demo of the Swiper UX so the user learns the gesture before entering the main app.
- FR-O-004: The user shall be able to skip onboarding at any point. Skipped users shall be assigned the "Language Enthusiast" default segment.
- FR-O-005: Onboarding shall only be shown once. A `hasCompletedOnboarding` flag shall be persisted in `UserDefaults` (non-sensitive; appropriate for this use).

### 2.2 Account & Identity

- FR-O-006: The app shall not require account creation to use Iteration-1 features. All Iteration-1 data is local-only.
- FR-O-007: The app shall prompt the user to create an account (or sign in) when they first attempt to access a feature that requires cloud sync (Iteration-3 Aura Points, Leaderboard).
- FR-O-008: The app shall support **Sign in with Apple** as the primary authentication method.
- FR-O-009: ⚠️ **Requires developer input before implementation:** Determine if email/password or other OAuth providers (Google) are also required.
- FR-O-010: The app shall generate an anonymous guest profile for users who decline to create an account, allowing local Aura Points accumulation. Guest data shall be migrated to a full account upon sign-in.

---

## 3. Iteration 1 — The Learn Phase

### 3.1 The Swiper UX

- FR-S-001: The system shall present slang terms one at a time on a vertically stacked card interface, with the next card partially visible beneath the current card (scaled to 94%, offset 12pt down).
- FR-S-002: The system shall support a **right-swipe gesture** to save the current term to the user's Personal Lexicon.
- FR-S-003: The system shall support a **left-swipe gesture** to dismiss the current term (mark as "not interested" for the current session).
- FR-S-004: The system shall support **tap-to-flip** on the card to reveal the full definition and example sentence (the card shall animate with a 3D Y-axis flip).
- FR-S-005: During a drag gesture, the card shall rotate proportionally (max ±12°) and fade (min 0.6 opacity). A direction label ("SAVE" in Rizz Green / "SKIP" in Sunset Amber) shall appear at the appropriate card edge.
- FR-S-006: The system shall display swipeable button alternatives below the card (a ✓ button and a ✕ button) for users who prefer tap-based interaction over gesture-based.
- FR-S-007: The Swiper queue shall be drawn from the full local dictionary, excluding terms already in the user's Lexicon. Terms shall be ordered by `usageFrequency` descending, then randomized within frequency groups.
- FR-S-008: When the Swiper queue is exhausted, the system shall display an empty state with an illustration and options to "Review My Lexicon" or "Reshuffle All Terms."
- FR-S-009: The system shall support **undo** of the last swipe action (one level deep) via a visible "Undo" button that appears for 3 seconds after each swipe.

### 3.2 The Glossary

- FR-GL-001: The system shall display a scrollable, alphabetically sorted list of all slang terms in the local database.
- FR-GL-002: The list shall be grouped by the first letter of each term, with sticky section headers for each letter.
- FR-GL-003: The system shall display an **alphabetical scrubber** along the right margin. Dragging on it shall instantly jump the list to the corresponding letter section.
- FR-GL-004: Each list row shall display: the term (heading weight), a one-line definition preview truncated to a single line, and a right-pointing chevron.
- FR-GL-005: Tapping a row shall navigate to a **Term Detail View** showing the full term, definition, example sentence, category badge, and generation tag.
- FR-GL-006: The Term Detail View shall include a "Save to Lexicon" / "Remove from Lexicon" toggle button that reflects real-time Lexicon state.
- FR-GL-007: The Glossary shall display a **category filter bar** horizontally scrollable at the top, allowing filtering by: All, Descriptors, Brainrot, Archetypes, Relationships, Gaming, Emoji, Aesthetics, Emerging.
- FR-GL-008: Applying a category filter shall instantly update the list without a loading state.

### 3.3 Smart Search

- FR-SR-001: The system shall display a persistent search bar at the top of the Glossary screen.
- FR-SR-002: Search shall perform a **fuzzy match** across both the `term` and `definition` fields.
- FR-SR-003: Search input shall be debounced by 300ms before triggering a filter operation.
- FR-SR-004: Search results shall highlight the matched substring within each result row.
- FR-SR-005: When no results are found, the system shall display an empty state with the message "No slang found. Maybe it's too niche 👀" and a suggestion to browse by category.
- FR-SR-006: Clearing the search field shall immediately restore the full, unfiltered list.

### 3.4 Personal Lexicon

- FR-L-001: The system shall maintain a **Personal Lexicon** — a persistent, user-curated collection of saved slang terms.
- FR-L-002: The Lexicon shall be accessible from a dedicated section within the Profile tab.
- FR-L-003: Terms in the Lexicon shall be displayed in the order they were saved (most recent first by default), with an option to sort alphabetically.
- FR-L-004: The user shall be able to remove a term from the Lexicon via swipe-to-delete on the Lexicon list row.
- FR-L-005: The Lexicon count (number of saved terms) shall be displayed as a badge on the Profile tab icon.
- FR-L-006: The Lexicon shall be persisted locally via CoreData and survive app termination and device restart.

---

## 4. Iteration 2 — The Translator Phase

### 4.1 Bi-Directional Translation Engine

- FR-T-001: The system shall provide a **Translator screen** accessible from the main tab bar.
- FR-T-002: The Translator shall feature two panels: **Panel A** (input) and **Panel B** (output).
- FR-T-003: By default, Panel A shall be "GenZ Mode" (input in slang) and Panel B shall be "Standard English" (translated output).
- FR-T-004: A **swap button** between the panels shall reverse the translation direction. The swap shall animate with a 180° rotation effect.
- FR-T-005: The translation engine shall tokenize the input sentence and replace known slang tokens with their `standardEnglish` equivalents. Unrecognized tokens shall be passed through unchanged.
- FR-T-006: Translation output shall update reactively as the user types, debounced by 400ms.
- FR-T-007: ⚠️ **Requires developer input:** If a remote translation API is to be used in addition to local dictionary lookup, the API provider, endpoint, and data retention policy must be confirmed before implementation. Local dictionary lookup shall be implemented first regardless.
- FR-T-008: The system shall display a character count in Panel A. No hard character limit shall be enforced in Iteration-2, but a soft visual warning shall appear at 280 characters.

### 4.2 Clipboard & Utility

- FR-T-009: Panel B shall include a **"Copy" button** (clipboard icon) that copies the translated output to the system clipboard.
- FR-T-010: Upon successful copy, the system shall display a brief haptic feedback (`.notificationFeedback(.success)`) and change the button icon to a checkmark for 1.5 seconds.
- FR-T-011: Panel A shall include a **"Clear" button** (×) to erase the input field.
- FR-T-012: The Translator shall display example sentence suggestions beneath Panel A when the input field is empty, cycling through 3 pre-written examples to help users understand the feature.

---

## 5. Iteration 3 — The Quizzes Phase

### 5.1 Quiz Flow

- FR-Q-001: The system shall present multiple-choice quizzes where the user is shown a definition and must select the correct slang term from 4 options.
- FR-Q-002: Alternatively (alternate question type), the system shall show a term and ask the user to select the correct definition.
- FR-Q-003: The question type shall alternate to maintain variety within a single quiz session.
- FR-Q-004: Each quiz session shall consist of **10 questions** by default.
- FR-Q-005: The system shall generate distractors (wrong answer options) from terms in the same category as the correct answer to increase difficulty.
- FR-Q-006: After the user selects an answer:
  - **Correct:** The selected option animates to Rizz Green with a checkmark. A brief positive sound plays (if system sounds enabled).
  - **Incorrect:** The selected option animates to red with an ✕. The correct option is revealed in Rizz Green. A brief error haptic plays.
- FR-Q-007: The user shall not be able to change their answer after selection.
- FR-Q-008: The system shall display a **progress bar** at the top of the Quiz screen showing questions completed vs. total.
- FR-Q-009: A **hint button** shall be available on each question. Using a hint eliminates one incorrect option. Each hint usage is tracked and affects the Aura Point score.
- FR-Q-010: Upon completing all 10 questions, the system shall navigate to a **Quiz Result Screen**.

### 5.2 Quiz Result Screen

- FR-Q-011: The Quiz Result Screen shall display: questions correct (C), hints used (H), time taken (T in minutes), and Aura Points earned (S).
- FR-Q-012: The Points earned shall be computed using the formula: `S = (C × 100) / (1 + H) - (T × 2)`. The result shall be floored at 0 (no negative Aura Points from a single quiz).
- FR-Q-013: The screen shall display an animated Aura Points counter that counts up from 0 to the earned value.
- FR-Q-014: If the user's total Aura Points cross a tier threshold, the screen shall play a **tier promotion animation** before displaying the result.
- FR-Q-015: The user shall be able to **retry** the same quiz (new randomized question set from the same category) or **return to home**.

### 5.3 The Aura Economy

- FR-A-001: The system shall maintain a cumulative **Aura Points (AP)** total for each user.
- FR-A-002: AP shall be awarded for: completing quizzes (formula above), completing the Daily Crossword (Iteration-4), and maintaining daily streaks.
- FR-A-003: The system shall track a **daily streak** counter. A streak increments when the user completes at least one quiz or the Daily Crossword on consecutive calendar days (in the user's local timezone).
- FR-A-004: Missing a day shall reset the streak to 0.
- FR-A-005: The system shall determine the user's **Aura Tier** based on cumulative AP:

| Tier | Points Required | Notes |
|---|---|---|
| Unc | 0 – 500 AP | Entry state |
| Lurk | 501 – 1,500 AP | |
| Aura Farmer | Streak ≥ 7 days AND ≥ 1,500 AP | Streak-gated |
| Rizzler | Top 1% of global leaderboard | Leaderboard-gated |

- FR-A-006: Tier thresholds shall be defined as named constants in `Core/Constants/AuraConstants.swift` and never hardcoded in a view or ViewModel.
- FR-A-007: Local AP shall be cached in CoreData/SwiftData and synced to Firebase upon connectivity.
- FR-A-008: ⚠️ **Requires developer input:** Conflict resolution strategy for AP sync (local-wins, server-wins, delta-merge?) must be confirmed before implementing the sync layer.

### 5.4 Leaderboard

- FR-LB-001: The system shall display a **global leaderboard** of top users ranked by cumulative AP.
- FR-LB-002: The leaderboard shall display: rank number, display name (or anonymized identifier for guests), tier badge, and AP total.
- FR-LB-003: The user's own rank shall always be visible in a pinned row at the bottom of the leaderboard list, even if they are not in the top visible results.
- FR-LB-004: The leaderboard shall refresh at app foreground, with a pull-to-refresh option.
- FR-LB-005: "Rizzler" tier shall be awarded to users in the **top 1% of the global leaderboard** at the time of the last leaderboard refresh.

---

## 6. Iteration 4 — The Daily Crossword Phase

### 6.1 Puzzle Delivery

- FR-C-001: The system shall deliver a **single, globally synchronized crossword puzzle** to all users.
- FR-C-002: A new puzzle shall be available at **12:00 AM in the user's local timezone** each day.
- FR-C-003: The puzzle content (grid, clues) shall be fetched from Firebase Firestore. The puzzle document shall include a `revealAt` timestamp field.
- FR-C-004: ⚠️ **Requires developer input:** The answer key delivery mechanism must be decided (server-gated reveal vs. encrypted client-side payload) before implementation. The answer key must never be fully present on the client before `revealAt`.
- FR-C-005: The system shall cache the current day's puzzle locally so it is playable offline after the initial fetch.
- FR-C-006: The system shall not allow access to puzzle answers before `revealAt`, even if the user manipulates their device clock.

### 6.2 Crossword Grid UI

- FR-C-007: The crossword grid shall be rendered as a square matrix of uniform cells sized to fill the screen width minus horizontal margins.
- FR-C-008: Tapping a white cell shall make it the active cell (highlighted in `primary` color). Tapping again on the same cell shall toggle between across/down direction.
- FR-C-009: Keyboard input shall fill the active cell and automatically advance to the next cell in the active word direction.
- FR-C-010: The current clue (across or down) for the active cell shall be displayed in a sticky bar below the grid at all times.
- FR-C-011: Completed cells (correct letter entered) shall display a subtle `secondary` border.
- FR-C-012: The system shall support a **"Check Word"** option that reveals whether the letters in the currently selected word are correct, at the cost of one hint (penalized in scoring).
- FR-C-013: The system shall support a **"Reveal Letter"** option that fills in a single cell, at the cost of one hint.

### 6.3 Crossword Scoring

- FR-C-014: Crossword scoring shall use the same formula as quizzes: `S = (C × 100) / (1 + H) - (T × 2)`, where C = correct words, H = hints/reveals used, T = minutes elapsed.
- FR-C-015: Completing the crossword **with zero hints** shall award a **Aura Bonus multiplier** of ×1.5 applied to the base score. The multiplier constant shall be defined in `AuraConstants.swift`.
- FR-C-016: The timer shall start when the user first interacts with the grid and stop when the puzzle is submitted or auto-detected as complete.
- FR-C-017: The user shall only be able to submit the puzzle **once per day**. Partial progress shall be auto-saved locally.

### 6.4 The Reveal

- FR-C-018: At `revealAt` time, the system shall unlock the answer key and display a **"Yesterday's Answers"** option on the Crossword tab.
- FR-C-019: The system shall generate a shareable **Crossword Result Card** (analogous to Wordle's grid share) showing the user's score, tier, and a censored grid pattern — no answers revealed in the share image.
- FR-C-020: The share card shall be shareable via `ShareLink` to any system share sheet destination.

---

## 7. Profile & Aura Economy

- FR-P-001: The Profile tab shall display: display name, current Aura Tier badge, cumulative AP, daily streak counter, and total terms saved to Lexicon.
- FR-P-002: The Profile tab shall display a **progress bar** showing AP progress to the next tier.
- FR-P-003: The Profile tab shall provide access to: Personal Lexicon, Quiz History (last 10 sessions), and Settings.
- FR-P-004: Settings shall include: Sign Out, Delete Account, Notification Preferences, and a link to the Privacy Policy.
- FR-P-005: "Delete Account" shall require explicit confirmation (two-step: warning modal → type "DELETE" → confirm) and shall purge all user data from Firebase and local storage.

---

## 8. Social Sharing

- FR-SS-001: The system shall generate an **Aura Card** — a static image (1080×1920pt canvas) suitable for Instagram Stories.
- FR-SS-002: The Aura Card shall display: the user's tier name, AP total, and the app name/logo. It shall contain **no personally identifiable information** unless the user has set a display name and explicitly opted in to showing it.
- FR-SS-003: ⚠️ **Requires developer input:** Confirm what, if any, user identifier appears on the Aura Card before implementing `ImageRenderer` output.
- FR-SS-004: The Aura Card shall be generated on-device using `ImageRenderer` and shared via `ShareLink`. No data shall be sent to a server to generate the card.
- FR-SS-005: The Crossword Result Card shall follow the same privacy rules as the Aura Card.

---

## 9. Dynamic Dictionary

- FR-DD-001: The system shall support **remote dictionary updates** delivered via Firebase without requiring an App Store update.
- FR-DD-002: New terms shall be delivered as Firebase Firestore documents in a `terms` collection, following the same schema as the local seed database.
- FR-DD-003: The system shall check for new terms at app launch (if connected) and on a background fetch schedule.
- FR-DD-004: New terms shall be **merged** into the local CoreData store, never replacing existing entries.
- FR-DD-005: The user shall see a "New Terms Added" notification badge on the Glossary tab when new terms have been synced since the last visit.
- FR-DD-006: The system shall add 3–5 new terms per week. This is an operational target, not a technical constraint — the system shall handle any number of terms in a single update batch.

---

## 10. Notifications

- FR-N-001: The system shall request notification permission during Iteration-3 onboarding (when the Aura streak feature is introduced), with a clear explanation of why notifications are needed.
- FR-N-002: The system shall send a **daily streak reminder** notification if the user has not opened the app and completed a quiz or crossword by a configurable time (default: 8:00 PM local time).
- FR-N-003: Streak reminder copy: *"Don't lose your 'Aura Farmer' status! The daily crossword is live."*
- FR-N-004: The system shall send a **Daily Crossword available** notification at 12:00 AM local time.
- FR-N-005: All notification types shall be individually toggleable in the app's Settings screen.
- FR-N-006: The system shall respect the user's system-level notification permissions. If permission is denied, the in-app notification toggle shall show a "Enable in Settings" prompt linking to the system Settings app.
- FR-N-007: ⚠️ **Requires developer input:** Confirm whether push notifications are delivered via APNs + Firebase Cloud Messaging or APNs direct before implementing the notification service.

---

*Reference documents: `CLAUDE.md`, `PROPOSAL.md`, `DESIGN_SYSTEM.md`, `DATABASE.md`, `NON_FUNCTIONAL_SPECS.md`, `TECH_STACK.md`*
