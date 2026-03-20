# Design System: SlangCheck
### "The Digital Zeitgeist"

> This document is the **single source of truth** for all visual and interaction decisions in SlangCheck.
> Every color, font, component, and effect used in the app must trace back to a token defined here.
> Deviating from this document requires explicit design approval before implementation.

---

## 1. Design Ideology

The core philosophy is to transform a language-learning platform into a **comprehensive digital ecosystem that evolves at the speed of a TikTok scroll.**

SlangCheck is the *"GenZ Rosetta Stone."* The interface must feel **"chill" yet high-performance** — turning what some call "brainrot" into "brain-gain."

### Pillars

| Pillar | Principle |
|---|---|
| **Gamified Fluency** | The "Aura System" turns acquisition of the GenZ lexicon into a competitive sport. Learning must feel like winning. |
| **Familiarity & Frictionless UX** | Utilize established UI patterns (the Swiper UX, alphabetical scrubbers) to reduce cognitive load for "The Uncs" while staying engaging for Trend-Seekers. |
| **Dynamic Relevance** | The backend-driven dictionary ensures the app remains "fluent" without constant App Store updates — 3–5 new terms weekly. |

---

## 2. Visual Language

To achieve a modern, minimalist, and eye-catching look, SlangCheck utilizes two complementary visual styles:

- **Glassmorphism** — Frosted, translucent surfaces with blur and a subtle border, conveying depth and modernity.
- **Neumorphism** — Soft inner/outer shadows on surfaces to give UI elements a physical, tactile feel.

These are never mixed on the same component. Cards and floating elements use Glassmorphism. Surface panels and input fields use Neumorphism.

---

## 3. Color Palette — Dual-Mode Adaptive System

> The palette is vibrant to reflect GenZ energy, with high-contrast accents for readability.

### Token Reference

| Token Name | Role | Light Mode — "Vibrant Day" | Dark Mode — "Midnight Cyber" |
|---|---|---|---|
| `primary` | Aura Purple — CTAs, active states, highlights | `#A855F7` Electric Lavender | `#C084FC` Neon Heliotrope |
| `secondary` | Rizz Green — success states, streaks, confirmations | `#22C55E` Vivid Emerald | `#4ADE80` Cyber Mint |
| `background` | Page/screen background | `#F8FAFC` Frosted White | `#0F172A` Deep Slate |
| `accent` | Warning / mid-level indicators, gold highlights | `#F59E0B` Sunset Amber | `#FBBF24` Bright Gold |

### Usage Rules

- `primary` is used for interactive elements: buttons, selected tabs, active card borders, progress fills.
- `secondary` is used for positive feedback only: correct answers, streak indicators, saved-to-lexicon confirmations.
- `background` is the base canvas. Never place content directly on a pure white/pure black surface; always use these specific values.
- `accent` is used sparingly — warnings, "mid" indicators, and rank badges. Not for primary actions.
- **Never hardcode a hex value in a SwiftUI view.** All colors must reference the `SlangColor` design token enum in `DesignSystem/Colors.swift`.

---

## 4. Typography

Typography must convey energy without sacrificing legibility. Use SF Pro (system default) with carefully chosen weights and sizes. Custom fonts, if introduced, must be added as a design token — never inline.

### Type Scale

| Token | Usage | Weight | Size (pt) |
|---|---|---|---|
| `.display` | Hero text, onboarding headlines | Black (900) | 34 |
| `.title` | Screen titles, card headers | Bold (700) | 28 |
| `.heading` | Section headings | Semibold (600) | 22 |
| `.subheading` | Subsection labels, tier names | Medium (500) | 17 |
| `.body` | Definitions, body copy | Regular (400) | 15 |
| `.caption` | Metadata, timestamps, secondary labels | Regular (400) | 12 |
| `.label` | Buttons, tab labels | Semibold (600) | 15 |

### Typography Rules

- Always use Dynamic Type. Never fix a font size with a hardcoded `CGFloat` in a view.
- Line spacing for `.body` must be 1.4× the font size.
- Never use all-caps for body text. All-caps is reserved for tier badge labels only.

---

## 5. Spacing & Layout

A consistent 4pt grid governs all spacing decisions.

| Token | Value | Usage |
|---|---|---|
| `spacing.xs` | 4pt | Icon padding, micro gaps |
| `spacing.sm` | 8pt | Inline element gaps |
| `spacing.md` | 16pt | Card internal padding, form field gaps |
| `spacing.lg` | 24pt | Section spacing |
| `spacing.xl` | 32pt | Screen-level vertical rhythm |
| `spacing.xxl` | 48pt | Hero section padding |

- **Card corner radius:** 20pt (Glassmorphic cards), 14pt (list cells).
- **Screen edge margins:** 16pt horizontal padding on all screens.
- **Tab bar height:** Follow system default; do not override.

---

## 6. Effects & Surface Treatments

### 6.1 Glassmorphism — `.glassCard()`

Applied to: Flashcards (Swiper), floating panels, modals, Aura Cards.

```
Background:  ultra-thin material (.ultraThinMaterial) OR frosted blur (blur radius 20pt)
Border:      0.5pt, white at 30% opacity (light) / white at 10% opacity (dark)
Shadow:      y: 8pt, blur: 20pt, color: black at 15% opacity
Corner:      20pt radius
```

### 6.2 Neumorphism — `.neumorphicSurface()`

Applied to: Input fields, quiz option buttons (resting state), settings panels.

```
Light Mode:
  Outer shadow 1:  x: -4pt, y: -4pt, blur: 8pt, color: white at 80% opacity
  Outer shadow 2:  x: 4pt, y: 4pt, blur: 8pt, color: #CBD5E1 at 60% opacity
  Background:      #F8FAFC (matches background token)

Dark Mode:
  Outer shadow 1:  x: -4pt, y: -4pt, blur: 8pt, color: #1E293B at 80% opacity
  Outer shadow 2:  x: 4pt, y: 4pt, blur: 8pt, color: #000000 at 60% opacity
  Background:      #0F172A (matches background token)
```

### 6.3 Pressed / Active State

All interactive surfaces animate to a pressed state:

```
Scale:       0.96×
Duration:    0.12s, easeOut
Shadow:      reduce to 50% opacity on press
```

### 6.4 Swipe Card Rotation

During drag gesture:

```
Rotation angle:  (drag x translation / screen width) × 12°
Opacity:         1.0 at center → 0.6 at full swipe
Secondary card:  scales from 0.94 → 1.0 as top card moves
```

---

## 7. UI Components

### 7.1 The Swiper (Flashcard Stack)

- Cards stacked with a visible "peek" of the card beneath (scale 0.94, offset 12pt down).
- Term displayed in `.title` weight, centered.
- Definition revealed on tap (flip animation: `.rotation3DEffect` on Y axis, 0.4s spring).
- Right-swipe action label: "SAVE" in `secondary` color. Left-swipe: "SKIP" in `accent`.

### 7.2 The Glossary

- `ScrollView` + `LazyVStack` with alphabetical section headers.
- Alphabetical scrubber on the right margin: 12pt labels, `primary` color on selection.
- Each row: term in `.subheading`, short definition preview in `.caption`, right chevron.
- Tapping a row navigates to the full `SlangTermDetailView`.

### 7.3 Smart Search Bar

- Positioned at the top of the Glossary screen.
- `.neumorphicSurface()` style.
- Magnifying glass icon in `primary` color.
- Debounced 300ms. Shows "No results" empty state with a brief illustration.

### 7.4 The Translator

- Two vertically split panels: GenZ (top) and Standard English (bottom).
- A swap button (↕) centered on the divider, animated with `.rotation3DEffect`.
- Both panels use `.neumorphicSurface()` inset styling.
- Copy button: clipboard icon, `secondary` color, triggers `.notificationFeedback(.success)`.

### 7.5 Quiz Cards

- Multiple-choice options displayed as tappable `.neumorphicSurface()` rows.
- Correct answer: animates to `secondary` fill + checkmark icon.
- Wrong answer: animates to a red tint (`#EF4444`) + shake animation.
- Hint button: uses `accent` color. Increments hint counter in the ViewModel.

### 7.6 Aura Profile & Tier Badge

- Tier badge: pill-shaped, filled with a gradient from `primary` to `secondary`.
- All-caps label (only acceptable all-caps usage per typography rules).
- Progress bar to next tier: `primary` fill on `background`-colored track, 8pt corner radius.
- Streak flame icon: `accent` color with a subtle pulse animation when streak > 3.

### 7.7 Aura Card (Share Card)

- Fixed 1080×1920pt (Instagram Story canvas) rendered off-screen via `ImageRenderer`.
- Background: dark gradient from `background` to a darkened `primary`.
- Rank/tier text: centered, `.display` size.
- App logo + "SlangCheck" wordmark in the bottom third.
- No personal data other than the tier name and score. (Confirm with developer before adding any identifier.)

### 7.8 Daily Crossword Grid

- Square cells, uniform size, calculated to fill screen width minus `spacing.md` × 2.
- Active cell: `primary` fill, white text.
- Completed cell: `secondary` border, neutral fill.
- Blocked cell (black square): pure black (light) / `#1E293B` (dark).
- Current clue displayed in a sticky bar at the bottom of the grid in `.subheading`.

---

## 8. Motion & Animation Principles

- **Purposeful only.** Animation communicates state change; it is never decorative for its own sake.
- **Spring over easing.** Use `.spring(response: 0.35, dampingFraction: 0.7)` as the default for interactive transitions.
- **Durations:** Micro-interactions: 120–180ms. Screen transitions: 280–350ms. Never exceed 500ms for any UI animation.
- **Reduce Motion.** All animations must respect `@Environment(\.accessibilityReduceMotion)`. When reduce motion is on, crossfade replaces sliding/scaling transitions.

---

## 9. Iconography

- Use **SF Symbols** exclusively. No third-party icon libraries.
- Symbol weight must match the typographic weight of adjacent text.
- Interactive icons use `primary` color. Informational/decorative icons use `.secondary` opacity label color.

---

## 10. Accessibility

- **Minimum contrast ratio:** 4.5:1 for body text, 3:1 for large text and UI components (WCAG AA).
- All interactive elements must have a minimum tap target of 44×44pt.
- Every image and icon must have a meaningful `accessibilityLabel`. Decorative elements must be marked `.accessibilityHidden(true)`.
- VoiceOver must be able to navigate the Swiper, Glossary, Translator, and Quiz flows without visual reference.
- Dynamic Type is mandatory at all text sizes. Test at the largest accessibility size category.

---

*Reference documents: `CLAUDE.md`, `PROPOSAL.md`*
