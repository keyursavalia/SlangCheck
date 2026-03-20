# Project Proposal: SlangCheck
### Subtitle: The GenZ Rosetta Stone

---

## Executive Summary

**SlangCheck** (referred to as *VibeCheck* in development) is a high-energy, sleek iOS application designed to bridge the generational communication gap. By combining the addictive mechanics of dating apps with the educational rigor of a language-learning platform, SlangCheck transforms "brainrot" into "brain-gain."

It is a comprehensive digital ecosystem where users can learn, translate, and master the ever-evolving GenZ lexicon. The project is structured into **four distinct development phases**, evolving from a simple dictionary to a globally synchronized competitive gaming platform.

> In an era where language evolves at the speed of a TikTok scroll, staying "fluent" is a challenge for anyone outside the immediate zeitgeist. SlangCheck provides a "chill" environment for users to explore slangs, terms, and cultural nuances.

---

## Target Audience

| Segment | Description |
|---|---|
| **"The Uncs"** | Millennials and GenX-ers looking to understand what their younger siblings, children, or coworkers are saying. |
| **The Trend-Seekers** | Individuals who want to stay relevant with internet culture. |
| **The Language Enthusiasts** | Users fascinated by the sociolinguistics of modern digital slang. |

---

## Product Roadmap & Iterative Development

### Iteration 1 — The "Learn" Phase (MVP)

**Core objective:** Build a foundation of knowledge using familiar UI patterns.

#### Features

- **The Swiper UX** — A Tinder-style interface where terms appear on "Flashcards."
  - Right Swipe → Save to "My Personal Lexicon."
  - Left Swipe → Dismiss / Not interested.
- **The Glossary** — A high-performance, scrollable list (similar to the iOS Contacts app) with an alphabetical "scrubber" on the right margin.
- **Smart Search** — A real-time fuzzy search bar that suggests terms as the user types.

---

### Iteration 2 — The "Translator" Phase

**Core objective:** Introduce utility-driven tools to help users communicate in real-time.

#### Features

- **Bi-Directional Engine** — A split-screen UI mirroring Google Translate.
  - *Input A (GenZ):* "That fit is mid, no cap."
  - *Output B (Standard English):* "That outfit is of average quality, I am telling the truth."
- **Copy-to-Clipboard** — A one-tap feature to copy translated text for use in Messages or social apps.

---

### Iteration 3 — The "Quizzes" Phase (Gamification)

**Core objective:** Introduce the Aura System, turning learning into a competitive sport.

#### Features

- **The Gamification Loop** — Users take multiple-choice quizzes to identify terms based on definitions or situational examples.
- **The Aura Economy** — Users earn Aura Points (AP) for correct answers.
- **Offline Support** — Using local persistence (CoreData/SwiftData), quizzes are playable anywhere. Points are cached locally and synced to the cloud via a background process once a handshake with the server is established.

#### Aura Status Tiers

| Tier | Points | Description |
|---|---|---|
| **Unc** | 0 – 500 AP | The "clueless" entry phase. |
| **Lurk** | 501 – 1,500 AP | Getting warmer. |
| **Aura Farmer** | Streak-based | Granted for maintaining high daily streaks. |
| **Rizzler** | Top 1% | Top of the global leaderboard. |

---

### Iteration 4 — The "Daily Crossword" Phase

**Core objective:** Introduce a community-wide event to drive daily active users (DAU).

#### Features

- **Global Sync** — Every user receives the same crossword puzzle at 12:00 AM local time.
- **The Reveal** — Answers are locked until the following day, creating a "Wordle-like" viral sharing opportunity.
- **Competitive Stakes** — Completing the crossword without hints grants a massive "Aura Boost."

---

## Technical Specifications

### Aura Point Scoring Formula

To ensure the game remains fair yet challenging, Aura Points for the Daily Crossword are calculated based on speed and accuracy:

$$S = \left(\frac{C \times 100}{1 + H}\right) - (T \times 2)$$

| Variable | Meaning |
|---|---|
| `S` | Total score (Aura Points earned) |
| `C` | Number of correct answers |
| `H` | Number of hints used |
| `T` | Time taken in minutes |

### Tech Stack

| Component | Technology |
|---|---|
| Frontend | SwiftUI (for modern, fluid animations) |
| Local Storage | CoreData & SwiftData (offline quiz support) |
| Backend | Firebase (real-time Aura Point syncing & global crosswords) |
| Architecture | MVVM (Model-View-ViewModel) |
| Design Style | Glassmorphism / Neumorphism for a trendy aesthetic |

---

## Retention & Engagement Strategy

- **Push Notifications** — "Don't lose your 'Aura Farmer' status! The daily crossword is live."
- **Social Sharing** — Generated "Aura Cards" that users can post on their Instagram Stories to flex their rank.
- **Dynamic Dictionary** — A backend-driven dictionary that adds 3–5 new words weekly without requiring a full App Store update.

---

*Reference documents: `CLAUDE.md`, `DESIGN_SYSTEM.md`*
