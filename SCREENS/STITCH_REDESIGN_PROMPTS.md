# SlangCheck — Google Stitch Redesign Prompts
## Theme: Neon Tokyo × Gamified Education

> **How to use:** Copy each prompt block verbatim into Google Stitch. Upload the matching reference screenshot alongside the prompt so Stitch can preserve the exact layout, data hierarchy, and element positions while applying the new visual language.
>
> **Design Direction:** Neon Tokyo — the visual DNA of Akihabara at 2 AM meets a Gen Z education app. Dark mode feels like a cyberpunk arcade. Light mode feels like a sunny Harajuku street market bursting with colour. Every screen should feel like the app has *rizz* — warm, fun, and impossible to put down.

---

## Screen Index

| File | Screen |
|---|---|
| `01_learn-swiper-card-front-dark.png` | Learn — Swiper flashcard, front face |
| `02_learn-swiper-swipe-right-save-dark.png` | Learn — Swiper, swipe-right SAVE gesture mid-flight |
| `03_learn-swiper-swipe-left-skip-dark.png` | Learn — Swiper, swipe-left SKIP gesture mid-flight |
| `04_translator-empty-state-dark.png` | Translator — empty state |
| `05_games-hub-aura-banner-dark.png` | Games — hub with Aura banner + game mode cards |
| `06_games-hub-quiz-loading-dark.png` | Games — quiz loading state (spinner on card) |
| `07_quiz-active-question-unanswered-dark.png` | Quiz — active question, no answer selected yet |
| `08_quiz-active-question-correct-answer-dark.png` | Quiz — correct answer selected, Next button |
| `09_quiz-result-session-complete-dark.png` | Quiz Result — session complete, Aura earned |
| `10_crossword-grid-clue-bar-collapsed-dark.png` | Crossword — grid active, clue bar collapsed |
| `11_crossword-grid-clue-panel-expanded-dark.png` | Crossword — grid active, full clue panel expanded |
| `12_crossword-grid-active-cell-selected-dark.png` | Crossword — active cell selected, column highlighted |
| `13_more-menu-dark.png` | More Menu — Glossary + Profile entries |
| `14_glossary-alphabetical-list-dark.png` | Glossary — alphabetical list with search + filter |
| `15_profile-lurk-tier-dark.png` | Profile — user stats, Lurk tier, Aura progress |

---

## Global Design System Token Reference

> Include this in every prompt as a preamble so Stitch maintains consistency across all screens.

```
DESIGN SYSTEM TOKENS (apply to every screen):

DARK MODE PALETTE:
  Background:        #060612  (near-black with blue undertone, like Tokyo night sky)
  Surface/Card:      #0F0F2A  (deep navy, card background)
  Surface Elevated:  #161636  (slightly lighter card, for nested containers)
  Border/Separator:  rgba(139, 92, 246, 0.20)  (soft purple glow border)

  Neon Primary:      #9B4DFF  (electric violet — main brand accent, titles, active icons)
  Neon Cyan:         #00E5FF  (electric cyan — secondary highlights, tier progress, correct answers)
  Neon Pink:         #FF2D78  (hot pink — wrong answers, alerts, skip action)
  Neon Green:        #39FF85  (lime green — save action, streaks, correct confirm pulse)
  Neon Amber:        #FFB800  (warm amber — hint usage, stars, streak fire)

  Text Primary:      #F0F0FF  (off-white with cold blue tint)
  Text Secondary:    #8888BB  (muted lavender-grey)
  Text Tertiary:     #44446A  (dark muted, placeholder text)

LIGHT MODE PALETTE:
  Background:        #FDF6FF  (warm white with a whisper of lavender)
  Surface/Card:      #FFFFFF  with rgba(139,92,246,0.06) tint
  Surface Elevated:  #F3EEFF  (soft lavender tint)
  Border/Separator:  rgba(139, 92, 246, 0.15)

  Neon Primary:      #7B2FE0  (deep violet, readable on light)
  Neon Cyan:         #0099CC  (ocean teal, readable)
  Neon Pink:         #D90060  (deep hot pink)
  Neon Green:        #1A9E4A  (forest-neon green)
  Neon Amber:        #C47800  (deep amber)

  Text Primary:      #1A0A2E  (near-black violet)
  Text Secondary:    #6A5A8A  (muted violet-grey)

TYPOGRAPHY:
  Display/Hero:   "Syne" Bold — for big slang terms on flashcards, aura points numbers
  Heading:        "Space Grotesk" SemiBold — section titles, screen titles
  Body:           "Inter" Regular — definitions, descriptions, body copy
  Label/Tag:      "Space Mono" — category chips, timer numbers, crossword clue numbers
  Accent/Glow:    All primary-colored text should have a subtle text-shadow glow
                  matching its own color at 40% opacity, 0px x/y, 8px blur

EFFECTS:
  Glass Card:     backdrop-filter: blur(20px), background: rgba(15,15,42,0.7) dark /
                  rgba(255,255,255,0.6) light, border: 1px solid rgba(139,92,246,0.25),
                  border-radius: 20px, box-shadow: 0 8px 32px rgba(155,77,255,0.12)
  Neon Glow:      box-shadow: 0 0 12px currentColor, 0 0 24px currentColor at 50% opacity
  Active State:   element pulses with a soft neon glow (keyframe: scale 1→1.03→1)
  Tab Bar:        frosted glass, blur(30px), subtle top border with neon primary tint
  Dividers:       1px gradient lines — left: transparent → neon primary → transparent

ICONOGRAPHY:
  Style: SF Symbols filled variant, color-matched to their neon accent,
         with a 6px circular glow halo behind them using the same color at 25% opacity.
  Category chips should use small emoji or SF Symbol + label, pill-shaped,
  with neon border and glass fill.

CORNER RADII:
  Cards: 20px, Chips/Badges: 12px, Buttons: 16px, Cells/Rows: 16px, Input fields: 14px

TAB BAR:
  4 tabs: Learn · Translator · Games · More
  Active tab: icon + label in Neon Primary, with a small neon capsule indicator above icon
  Inactive: muted lavender-grey
  Background: glass blur, very subtle gradient from dark navy to transparent
```

---

## DARK MODE PROMPTS

---

### Screen 01 — Learn: Swiper Flashcard (Front Face) — DARK MODE

**Reference:** `01_learn-swiper-card-front-dark.png`

```
Design a full-screen iOS 17 SwiftUI app screen for "SlangCheck," a Gen Z slang learning app with a Neon Tokyo cyberpunk aesthetic. This is the DARK MODE version of the LEARN tab — the primary flashcard swiper screen.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS defined above.

SCREEN STRUCTURE (preserve all these elements exactly):
- Navigation bar: title "Learn" in Space Grotesk SemiBold, centered, #F0F0FF
- Background: full-screen #060612, with an extremely subtle radial gradient behind the card area — a bloom of Neon Primary (#9B4DFF) at 6% opacity centered where the card sits, fading outward. Like a faint neon aura behind the card.
- FLASHCARD (center stage, takes up ~65% of screen height):
    - Shape: rounded rectangle, corner radius 24px, 88% screen width
    - Background: glass card — deep navy #0F0F2A, backdrop blur, 1px border rgba(139,92,246,0.30)
    - Subtle scanline texture: horizontal lines 1px tall, 4px apart, rgba(139,92,246,0.03) — gives it a retro arcade CRT feel
    - TOP of card: Category chip (e.g. "DESCRIPTORS") — pill shape, Space Mono uppercase, 11px, neon primary color (#9B4DFF) with neon glow text-shadow, pill border 1px neon primary, pill background rgba(155,77,255,0.10)
    - CENTER of card (dominant): The slang word "Extra" in Syne Bold, 52px, white #F0F0FF. Apply a very subtle neon primary text-glow (purple, 10px blur). The word should feel like a glowing holographic label.
    - BELOW the word: "Tap to reveal definition" — Space Mono, 12px, tertiary text #44446A, with a tiny tap gesture icon (finger tap SF symbol) in the same muted color. This hint text subtly pulses in opacity (0.5 → 1.0) as if breathing.
    - Card box-shadow: 0 20px 60px rgba(155,77,255,0.25) — purple glow lift effect beneath the card
    - Card has a very faint inner top highlight: 1px line at top edge, rgba(200,160,255,0.12)

- BOTTOM ACTION AREA:
    - Two circular buttons, side by side, centered, 64px diameter each
    - LEFT — SKIP button: circle background #1A0A1A (dark warm), border 2px neon pink (#FF2D78), icon: X mark in neon pink. Outer glow: box-shadow 0 0 16px rgba(255,45,120,0.40)
    - RIGHT — SAVE button: circle background #0A1A10 (dark cool), border 2px neon green (#39FF85), icon: checkmark in neon green. Outer glow: box-shadow 0 0 16px rgba(57,255,133,0.40)
    - Buttons are spaced ~80px apart from center-to-center
    - Small label text below each: "SKIP" and "SAVE" in Space Mono 10px uppercase, matching their respective neon colors, with slight glow

- TAB BAR at bottom: glass blur, 4 tabs (Learn active with neon primary capsule above icon)

VIBE: This card should feel like a collectible trading card from a neon cyberpunk card game. Premium, glowing, alive. The user should feel excited to flip it.
```

---

### Screen 02 — Learn: Swipe-Right SAVE Gesture — DARK MODE

**Reference:** `02_learn-swiper-swipe-right-save-dark.png`

```
Design the DARK MODE "Learn" swiper screen mid-swipe-right gesture for SlangCheck (Neon Tokyo cyberpunk theme). This is the moment the user is dragging the top card to the right to SAVE a slang term.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS.

SCREEN STRUCTURE:
- Background: #060612. Behind the card stack, show a very faint neon green (#39FF85) bloom at 5% opacity on the right side — hinting at the save direction.

- BACK CARD (fully visible beneath the top card, centered, slightly scaled down ~96%, neutral state):
    - Shows a different slang term "Sigma" with category chip "ARCHETYPES"
    - Slightly dimmed (85% opacity), same glass card style, slight downward shadow

- TOP CARD (the one being dragged RIGHT):
    - Rotated ~8° clockwise (following the finger drag physics)
    - Translated rightward — card is ~40% off-center to the right
    - Same "Extra" / "DESCRIPTORS" card from Screen 01
    - As it tilts right, the card's border and glow transitions to neon green (#39FF85) — border 1.5px rgba(57,255,133,0.60), box-shadow 0 0 30px rgba(57,255,133,0.30)

- SAVE STAMP overlay on top-right area of the top card:
    - A bold rectangular badge, slightly rotated -12°, dark background #0A1A10, border 2.5px neon green (#39FF85), neon green glow box-shadow
    - Text: "SAVE" in Space Mono Bold uppercase, 22px, neon green (#39FF85), with text-glow
    - The stamp appears with a "POP" feeling — slightly oversized, confident

- The skip (X) button on bottom-left dims to ~40% opacity
- The save (✓) button on bottom-right brightens and pulses with a stronger neon green glow

VIBE: This feels satisfying — like swiping a rare card into your collection. The neon green surge tells you "yes, this is yours now."
```

---

### Screen 03 — Learn: Swipe-Left SKIP Gesture — DARK MODE

**Reference:** `03_learn-swiper-swipe-left-skip-dark.png`

```
Design the DARK MODE "Learn" swiper screen mid-swipe-left gesture for SlangCheck (Neon Tokyo theme). The user is discarding the "Sigma" flashcard.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS.

SCREEN STRUCTURE:
- Background: #060612. Faint neon pink (#FF2D78) bloom at 4% opacity on the LEFT side, hinting at the skip direction.

- BACK CARD: A fresh card waiting behind (showing just the "W" initial of the next term — mysterious placeholder), scaled down ~96%, dimmed

- TOP CARD ("Sigma" / "ARCHETYPES") being dragged LEFT:
    - Rotated ~-7° counter-clockwise
    - Translated leftward — ~35% off-center to the left
    - Card border and glow transitions to neon pink (#FF2D78): border 1.5px rgba(255,45,120,0.55), box-shadow 0 0 28px rgba(255,45,120,0.25)
    - Subtle red/pink screen-edge vignette bleeds in from the left

- SKIP Stamp on top-left of card:
    - Badge rotated +12°, dark red background #1A080A, border 2.5px neon pink (#FF2D78), pink glow
    - Text "SKIP" in Space Mono Bold, 22px, neon pink, with text-glow

- Skip (X) button brightens and pulses with stronger neon pink glow
- Save (✓) button dims to 40% opacity

VIBE: Feels like discarding a card you already know — fast, decisive, but no guilt. The pink flash is playful, not harsh.
```

---

### Screen 04 — Translator: Empty State — DARK MODE

**Reference:** `04_translator-empty-state-dark.png`

```
Design the DARK MODE Translator screen for SlangCheck (Neon Tokyo cyberpunk theme). This is the bidirectional Gen Z ↔ Standard English translator in its empty/idle state.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS.

SCREEN STRUCTURE:
- Navigation bar: "Translator" title, Space Grotesk SemiBold, centered
- Background: #060612 full bleed, with a very subtle diagonal grid pattern (like circuit board traces) in rgba(139,92,246,0.04) — thin lines forming a 40px grid

TOP INPUT PANEL (Gen Z → Standard English):
    - Glass card, #0F0F2A, rounded 20px, ~40% screen height
    - Header row inside card: small pencil/pen SF symbol in neon primary, label "Gen Z / Slang" in Space Mono 11px, neon primary color with glow
    - Large multiline text area below: placeholder text "Type some slang..." in tertiary color #44446A, italic, Space Mono 14px
    - Card has a 1px neon primary border on all sides when focused state implied
    - Subtle inner glow at top edge of card: rgba(155,77,255,0.08)

DIRECTION TOGGLE BUTTON (center, between the two panels):
    - 44px circle, background: neon primary (#9B4DFF) with radial gradient to #7B2FE0
    - Icon: up-down arrows (↕) in white
    - box-shadow: 0 0 20px rgba(155,77,255,0.50) — strong glow effect
    - Surrounded by a subtle circular halo ring: 56px circle, 1px dashed neon primary at 30% opacity

BOTTOM OUTPUT PANEL (Standard English output):
    - Glass card, same style, ~35% screen height
    - Header: chat-bubble SF symbol in Neon Cyan (#00E5FF), label "Standard English" in Space Mono 11px, neon cyan with glow
    - Placeholder: "Translation will appear here..." in tertiary color, italic
    - When empty, show a subtle dashed-border inner placeholder rectangle, suggesting where text will flow in

BOTTOM DECORATIVE ELEMENT (below both panels, above tab bar):
    - Small centered text in tertiary color: "✦  Gen Z ↔ English  ✦" with sparkle characters
    - Makes it feel alive even when empty

TAB BAR: Translator tab active (neon primary), glass blur background

VIBE: Feels like a holographic translation terminal from a sci-fi anime. Clean, spacious, premium. The cyan accent on "Standard English" differentiates the two language modes visually.
```

---

### Screen 05 — Games Hub: Aura Banner + Game Cards — DARK MODE

**Reference:** `05_games-hub-aura-banner-dark.png`

```
Design the DARK MODE Games hub screen for SlangCheck (Neon Tokyo cyberpunk theme). This is the main Games tab showing the user's Aura rank banner and the two game mode entry cards.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS.

SCREEN STRUCTURE:
- Navigation bar title: "Games" in Space Grotesk Bold, with a tiny ✦ sparkle before it
- Background: #060612 with a radial gradient bloom — neon primary at 5% top-center, fading to pure black

AURA BANNER (top card, spans full width minus horizontal padding):
    - Glass card: dark navy, border 1px neon cyan (#00E5FF) at 25% opacity, corner radius 20px
    - box-shadow includes a very faint cyan glow: 0 4px 24px rgba(0,229,255,0.10)
    - LEFT: Avatar circle 52px — the user's profile photo in a circle, surrounded by a neon cyan ring border (2px), with a subtle cyan glow halo
    - CENTER-LEFT text column:
        - Top line: Aura tier name "Unc" in Space Grotesk SemiBold 17px, #F0F0FF
        - Bottom line: Tier subtitle "Just getting started" in text secondary, 13px
    - RIGHT: Points display "648 pts" in Syne Bold 20px, neon cyan (#00E5FF) color, with cyan text-glow
    - Below the banner: small centered link "⬆ Share Aura Card" in neon primary, 13px Space Mono, with arrow icon — styled like a glowing CTA chip

GAME MODE CARDS (two large tappable cards, stacked vertically):

  QUIZ CARD:
    - Full width minus padding, glass card 20px radius
    - LEFT: 64×64 icon container — neon primary filled background with inner glow, trophy icon (SF symbol "trophy.fill") in white
    - CENTER text: "Quiz" in Space Grotesk Bold 22px, white. Below: "Test your slang knowledge" in text secondary 14px
    - RIGHT: chevron.right in muted lavender
    - Card border: 1px solid rgba(155,77,255,0.25) — subtle neon primary glow border
    - box-shadow: 0 6px 24px rgba(155,77,255,0.15)

  CROSSWORD CARD:
    - Same structure, but accent color is neon cyan (#00E5FF)
    - Icon: grid/squareshape symbol in neon cyan on dark teal background
    - "Daily Crossword" title, "A new puzzle every morning at 7 AM" subtitle
    - Border and shadow in neon cyan tones

BETWEEN CARDS: 16px gap

TAB BAR: Games tab active, glass blur

VIBE: Feels like a neon arcade lobby. You can almost hear the synth music. The game cards should make you want to tap them immediately.
```

---

### Screen 06 — Games Hub: Quiz Loading State — DARK MODE

**Reference:** `06_games-hub-quiz-loading-dark.png`

```
Design the DARK MODE Games hub screen showing the QUIZ CARD in a loading state for SlangCheck (Neon Tokyo theme). Everything else stays the same as Screen 05, but the Quiz card shows a loading state.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS plus Screen 05 layout.

LOADING STATE ON QUIZ CARD:
    - The trophy icon area (64×64 container) is replaced by a custom loading indicator:
        - A neon primary (#9B4DFF) spinning arc ring — 40px diameter, 3px stroke, 270° arc with a bright head and fading tail (like a comet trailing)
        - Behind the ring: a gentle radial glow pulse, rgba(155,77,255,0.20), animates: 0.8s ease-in-out infinite
    - The card title text "Quiz" remains, but "Test your slang knowledge" is replaced by a FUNNY LOADING MESSAGE in text secondary, italic, 13px. Rotate randomly through these messages (show one per Stitch frame):
        - "Consulting the Rizzler Oracle... 🔮"
        - "Asking the Ohio Sigma to review your IQ..."
        - "The Aura Farmer is manifesting questions..."
        - "NPC loading... please hold while we charge your rizz"
        - "Bro said no cap and walked into the question generator"
    - The card's border subtly pulses between neon primary at 20% and 50% opacity

    - The card's chevron.right on the right is replaced by the spinner arc matching the card's loading state (smaller, 18px)
    - The card itself is slightly dimmed (85% opacity) and NOT tappable during this state
    - A small "Hang tight..." label in Space Mono 10px appears below the loading text, in tertiary color — like a status indicator

VIBE: The loading state should feel fun, not frustrating. The funny message is the entertainment while the quiz generates. Like the app is ACTUALLY consulting a Gen Z council.
```

---

### Screen 07 — Quiz: Active Question, No Answer Selected — DARK MODE

**Reference:** `07_quiz-active-question-unanswered-dark.png`

```
Design the DARK MODE active quiz question screen for SlangCheck (Neon Tokyo theme). This is a multiple-choice question with no answer selected yet.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS.

SCREEN STRUCTURE:
- No navigation bar — this is a full-screen quiz mode. Status bar only.
- Background: #060612 with a very faint neon primary bloom in the top-center (6% opacity)

TOP HEADER ROW (below status bar, horizontal):
    - LEFT: "Question 1 of 10" in Space Mono 13px, text secondary
    - CENTER: TIMER RING — circular countdown, 42px outer diameter
        - Background ring: #161636 (dark)
        - Progress arc: starts neon green (#39FF85), transitions to neon amber (#FFB800) at 50%, transitions to neon pink (#FF2D78) at 20%
        - Current time number "26" in Space Mono Bold 14px, same color as the arc, centered inside ring
        - The ring itself should have a soft glow matching the current arc color
    - RIGHT: HINT button — lightbulb SF symbol + "Hint" label in neon amber (#FFB800) with amber glow, 13px Space Mono

PROGRESS BAR (below header):
    - Full width, 4px height, rounded ends
    - Background: #161636
    - Fill: neon primary gradient (10% completion shown), with a bright head dot at the fill endpoint
    - The progress bar glows: box-shadow 0 0 8px rgba(155,77,255,0.50)

QUESTION CARD (main content, ~30% screen height):
    - Glass card: #0F0F2A, 20px radius, 1px border rgba(155,77,255,0.20)
    - TOP of card: small badge chip "Definition" — Space Mono, 10px, neon primary text, neon primary border, glass fill
    - QUESTION TEXT: 'What does "Zesty" mean?' in Space Grotesk SemiBold 20px, #F0F0FF. Line height 1.4.

ANSWER OPTIONS (4 choices, stacked vertically, 12px gap between each):
    - Each option: full-width pill/card, corner radius 16px
    - Default (unselected) state: background #0F0F2A, border 1px rgba(139,92,246,0.15), text #F0F0FF in Inter Regular 16px, left-aligned, inner padding 18px vertical / 20px horizontal
    - NO answer is highlighted (this is the unanswered state)
    - Each option has a subtle left-edge accent: 3px vertical bar in rgba(155,77,255,0.30)
    - On the right side of each option: a faint circle (radio button outline) in tertiary color — not filled

The 4 options are:
    1. "Being very formal or uptight in your behavior."
    2. "Lively, bold, or flamboyant; can also refer to something dramatic or cheeky."
    3. "Having a high level of acidity or sourness."
    4. "Having a strong immune system."

VIBE: Intense focus mode. The countdown timer is the heartbeat of this screen — it creates urgency without being stressful. Dark, focused, cyberpunk classroom energy.
```

---

### Screen 08 — Quiz: Correct Answer Selected — DARK MODE

**Reference:** `08_quiz-active-question-correct-answer-dark.png`

```
Design the DARK MODE quiz screen showing a CORRECT answer selected for SlangCheck (Neon Tokyo theme). Same layout as Screen 07 but with the correct answer highlighted and the Next button revealed.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS plus Screen 07 layout.

CHANGES FROM SCREEN 07:
- Timer ring at 19 seconds remaining — arc in neon amber (mid-range) with amber glow
- "Hint Used" label replaces "Hint" in header — lightbulb icon, same amber, text changed to "Hint Used", slightly dimmed/disabled look

ANSWER OPTIONS — CORRECT ANSWER STATE:
    Option 2 ("Lively, bold, or flamboyant...") is the correct selected answer:
    - Background: rgba(57,255,133,0.12) — neon green tint fill
    - Border: 1.5px solid #39FF85 (neon green, full opacity)
    - box-shadow: 0 0 16px rgba(57,255,133,0.25) — neon green card glow
    - Text color: #39FF85 neon green
    - Left accent bar: 3px solid neon green, full height
    - Right: filled checkmark circle icon in neon green (SF symbol: checkmark.circle.fill)
    - The entire card pulses ONCE with a brief scale animation (1.0 → 1.02 → 1.0) when selected
    - A brief particle burst of small ✦ sparkles in neon green appears around the card edges (3–5 particles, 300ms animation)

    All other 3 options (wrong ones):
    - Dimmed to 40% opacity
    - Remain in their default dark style

NEXT BUTTON (appears below answer options, slide-up animation):
    - Full width, 56px height, corner radius 16px
    - Background: neon primary (#9B4DFF) with a subtle linear gradient to #7B2FE0
    - Text: "Next →" in Space Grotesk SemiBold 17px, white
    - box-shadow: 0 6px 24px rgba(155,77,255,0.45) — strong neon glow lift
    - On the right side of the button: subtle → arrow icon

VIBE: The green explosion of correct feedback is deeply satisfying. The sparkle burst is the app giving you a high-five.
```

---

### Screen 09 — Quiz Result: Session Complete — DARK MODE

**Reference:** `09_quiz-result-session-complete-dark.png`

```
Design the DARK MODE quiz result / session complete screen for SlangCheck (Neon Tokyo theme). The user just completed a perfect 10/10 quiz.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS.

SCREEN STRUCTURE:
- Full screen, no navigation bar, status bar only
- Background: #060612 with a triumphant radial neon gradient — neon amber (#FFB800) at 8% opacity centered in the top third (where the star is), fading down to pure black. Below the fold, a faint neon cyan bloom. This creates a warm-top, cool-bottom dramatic effect.

TOP CELEBRATION AREA (~25% screen):
    - Large star icon (⭐ or SF symbol "star.fill"): 72px, neon amber (#FFB800), with a strong amber glow: 0 0 30px rgba(255,184,0,0.60), 0 0 60px rgba(255,184,0,0.25)
    - Around the star: 8 tiny sparkle particles (✦) orbiting at various distances in neon amber and neon primary — gives confetti/fireworks energy
    - Below star: "Session Complete" in Syne Bold 28px, white with very subtle white text-glow
    - Below that: "10/10 Correct" in Space Grotesk 16px, neon green (#39FF85) with green glow

AURA EARNED CARD (prominent, center):
    - Glass card: #0F0F2A, corner 20px, border 1px rgba(0,229,255,0.30) — neon cyan border (feels special, different from normal neon primary)
    - box-shadow: 0 0 30px rgba(0,229,255,0.15) — cyan glow card
    - CENTER: "+1,050 Aura" in Syne Bold 38px, neon cyan (#00E5FF) with strong cyan text-glow (0 0 20px rgba(0,229,255,0.70))
    - Below: "100% Accuracy" in Space Mono 13px, neon cyan at 70% opacity

SCORE BREAKDOWN (below Aura card):
    - Three rows, each with label left + value right:
        - "Base Score" — "+1000" in neon primary
        - "Category Bonus" — "+50" in neon cyan
        - "Total Earned" — "+1050" in neon green, Bold, with a thin divider line above it
    - Row text: Space Grotesk 15px
    - Each row has a very subtle left-edge 2px accent line matching the value color

TIER PROGRESS CARD (below breakdown):
    - Glass card, same style
    - Top row: "Lurk" in Space Grotesk SemiBold 16px white · "Learning the lingo" in secondary text
    - Progress bar: 12px height, neon cyan fill (current progress ~8%), rounded ends, glowing fill: box-shadow 0 0 10px rgba(0,229,255,0.50)
    - Below: "3,302 pts to next tier" in Space Mono 12px, tertiary text

ACTION BUTTONS:
    - "Share Aura Card" — outlined style, full width, border 1px neon primary, text neon primary, share icon, glass background
    - "Play Again" — filled neon primary, full width, white text, neon glow shadow
    - "Done" — text-only link, center, secondary text

VIBE: THIS IS THE DOPAMINE HIT. The screen should feel like winning an arcade round. Warm on top (achievement glow), cool on the bottom (calm CTA area). The user should feel genuinely proud.
```

---

### Screen 10 — Crossword: Grid Active, Clue Bar Collapsed — DARK MODE

**Reference:** `10_crossword-grid-clue-bar-collapsed-dark.png`

```
Design the DARK MODE Daily Crossword screen with the clue bar COLLAPSED for SlangCheck (Neon Tokyo theme). The crossword grid is the hero.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS.

SCREEN STRUCTURE:
- Navigation bar: back chevron (neon primary) + "Daily Crossword" title centered, Space Grotesk SemiBold
- Background: #060612

CLUE BAR (collapsed, top of content):
    - Full width minus padding, glass card 16px radius
    - Shows "Tap a cell to see its clue" in secondary text, italic, Space Mono 13px, left-aligned
    - RIGHT: chevron.up icon in neon primary — tapping expands the panel
    - Card: subtle neon primary border 1px at 15% opacity

CROSSWORD GRID (hero element, square, full width minus padding):
    - BLOCKED CELLS (black squares): background #0F0F2A (dark navy), no border — they recede into the background
    - EMPTY LETTER CELLS: background #161636, border 1px rgba(139,92,246,0.20), 4px corner radius each cell
    - FILLED/TYPED CELLS: letter inside in Space Mono SemiBold 16px, white #F0F0FF
    - REVEALED CELLS (correct hints): letter in neon cyan (#00E5FF) with subtle cyan glow, cell border 1px neon cyan at 50%
    - CELL NUMBERS (clue starters): Space Mono 9px, neon primary (#9B4DFF) at 80% opacity, top-left corner of cell
    - Grid overall: a very subtle neon grid-line glow — the borders between cells shimmer like a holographic game board. The whole grid has a slight elevation: box-shadow 0 8px 32px rgba(155,77,255,0.08)
    - Preserve the partial fill shown in the reference: "COTTAGE MEMER" filled across, "G L H I" partially filled column, some revealed cells in neon cyan

BOTTOM ACTION ROW (Reveal + Submit buttons, full width, horizontal split):
    REVEAL BUTTON (left half):
        - Outlined style: border 1.5px neon cyan (#00E5FF), corner 16px, glass background
        - Icon (eye.fill) + "Reveal" label in neon cyan, Space Grotesk SemiBold 15px
        - box-shadow: 0 0 12px rgba(0,229,255,0.20)
        - Height: exactly matching the Submit button height (56px total)

    SUBMIT BUTTON (right half):
        - Filled: background neon primary (#9B4DFF) gradient to #7B2FE0, corner 16px
        - "Submit" in white, Space Grotesk SemiBold 15px, centered
        - box-shadow: 0 4px 20px rgba(155,77,255,0.40)
        - Same 56px height as Reveal

Both buttons: equal width (50/50 split of available width), equal height (56px)

VIBE: The crossword grid should look like a glowing holographic puzzle board. Each cell is a little window into the puzzle. Solving it should feel like hacking a neon matrix.
```

---

### Screen 11 — Crossword: Full Clue Panel Expanded — DARK MODE

**Reference:** `11_crossword-grid-clue-panel-expanded-dark.png`

```
Design the DARK MODE Daily Crossword screen with the CLUE PANEL FULLY EXPANDED for SlangCheck (Neon Tokyo theme).

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS plus Screen 10's grid style.

CHANGES FROM SCREEN 10:
The clue bar at the top expands into a scrollable panel:
    - Glass card: full width, corner 20px, background #0F0F2A, border 1px neon primary at 20%
    - TWO COLUMNS inside the panel: "Across" (left) and "Down" (right)
    - Column headers: "Across" and "Down" in Space Grotesk SemiBold 14px, neon primary color, with a 1px neon primary underline glow
    - Each clue row: number in Space Mono Bold 11px neon primary + clue text in Inter 13px secondary text, 8px gap between clues
    - The clues from the reference:
        Across: 5. "Summer vibe that's all about embracing the chaos with neon hues and carefree attitude" / 6. "If you're in on the inside, this is a phrase you'll know"
        Down: 1. "Mystery text message that hits you out of nowhere." / 2. "When your look is lit AF, you're probably getting this compliment." / 3. "When life feels like a viral TikTok dance-off, it's definitely 'lit'."
    - Chevron.down icon top-right: neon primary, tapping collapses panel
    - Panel scrollable if clues overflow
    - The grid below the expanded panel scales down proportionally — still visible and partially interactive below the expanded clue panel

GRID BELOW (partially visible, same style as Screen 10):
    - Slightly dimmed when clue panel is fully expanded (~80% opacity), like a focused overlay state
    - Still shows the letter fills

VIBE: The clue panel feels like a mission briefing screen. Two-column layout is clean and information-dense without being overwhelming. Neon primary number labels make scanning clues fast.
```

---

### Screen 12 — Crossword: Active Cell Selected — DARK MODE

**Reference:** `12_crossword-grid-active-cell-selected-dark.png`

```
Design the DARK MODE Daily Crossword screen with an ACTIVE CELL SELECTED and the clue bar showing the active clue, for SlangCheck (Neon Tokyo theme). This is the in-progress solving state.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS.

SCREEN STRUCTURE:
- Navigation: back chevron + "Daily Crossword" title. TAB BAR visible at bottom (Games tab active).

ACTIVE CLUE BAR (top):
    - Glass card, expanded to show the active clue
    - Shows "5 Across ▸" label: "5" in Space Mono Bold neon primary, "Across" in Space Mono neon primary, "▸" chevron
    - Below: clue text "Summer vibe that's all about embracing the chaos with neon hues..." in Inter 14px, white, wraps to 2 lines
    - The entire bar has a neon primary border glowing slightly stronger: 1px rgba(155,77,255,0.50)

CROSSWORD GRID — HIGHLIGHTED STATE:
    The ACTIVE CELL (letter B in column 8, row 5 area based on reference):
        - Background: neon primary (#9B4DFF) fill, solid
        - Border: 1.5px neon primary, box-shadow 0 0 12px rgba(155,77,255,0.70) — strong neon cursor glow
        - The cursor cell pulses: gentle scale 1.0→1.05→1.0 every 1.2s (breathing effect)

    THE ACTIVE WORD HIGHLIGHT (all cells in "BUSSIN" column — the word being currently entered):
        - Background: rgba(155,77,255,0.18) — soft neon primary tint fill
        - Border: 1px rgba(155,77,255,0.35)
        - Letters already filled ("B", "U", "S", "S", "I", "N") shown in white, same Space Mono style

    ALL OTHER FILLED CELLS: white text, #161636 background
    BLOCKED CELLS: #0F0F2A, recede

KEYBOARD TOOLBAR (above system keyboard, if keyboard is shown):
    - Delete icon on left (SF symbol "delete.backward"), neon primary
    - "Reveal (4)" label on right: "Reveal" in neon cyan + "(4)" in Space Mono small — shows credits remaining
    - Remaining credits shown as 4 of 5 filled dots in neon cyan, 1 empty dot in separator color

VIBE: When a cell is selected, the grid comes ALIVE. The active word glows like a chosen path in a holographic maze. The cursor cell is the brightest point on the entire screen — a neon beacon.
```

---

### Screen 13 — More Menu — DARK MODE

**Reference:** `13_more-menu-dark.png`

```
Design the DARK MODE "More" tab menu screen for SlangCheck (Neon Tokyo theme). This is a minimal list screen with Glossary and Profile as navigation entries.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS.

SCREEN STRUCTURE:
- Navigation bar: large title "More" in Syne Bold 34px, left-aligned, white with a very subtle purple glow
- Background: #060612 full bleed — this screen should feel spacious, not cramped

MENU LIST CARD (the grouped list):
    - Single glass card, 20px corner radius, containing two rows separated by a 1px divider
    - Card background: #0F0F2A, border 1px rgba(139,92,246,0.15)

    GLOSSARY ROW:
        - LEFT: Icon container 40×40, corner 12px, background rgba(155,77,255,0.15), icon "books.vertical.fill" in neon primary (#9B4DFF) with purple glow
        - CENTER text column: "Glossary" in Space Grotesk SemiBold 17px white; "Browse all Gen Z slang" in secondary text 13px below
        - RIGHT: chevron.right in muted color (44446A)
        - Row has 16px vertical padding, 20px horizontal padding
        - On hover/tap: a brief neon primary glow sweeps across the row from left to right (shimmer animation)

    THIN DIVIDER: 1px, gradient from neon primary at 0% → 20% → 0% (center glow), horizontal

    PROFILE ROW:
        - LEFT: Icon container 40×40, corner 12px, background rgba(0,229,255,0.12), icon "person.fill" in neon cyan (#00E5FF) with cyan glow
        - CENTER text column: "Profile" in Space Grotesk SemiBold 17px white; "11 terms saved" (or "Your Aura rank & saved terms") in secondary text
        - RIGHT: chevron.right muted

BELOW THE CARD: Generous empty space — this screen intentionally breathes.

DECORATIVE ELEMENT: In the bottom third of the empty space (above tab bar), show a very faint watermark / ambient decoration — tiny Japanese katakana characters (スラング — "slang" in Japanese) in rgba(139,92,246,0.06), 72px, center-aligned. This adds Tokyo atmosphere without visual noise.

TAB BAR: "More" tab active (ellipsis icon + neon primary capsule)

VIBE: Simple, premium, breathing. Like the lobby of a very cool Tokyo hotel. The katakana watermark is a secret easter egg for the attentive user.
```

---

### Screen 14 — Glossary: Alphabetical List — DARK MODE

**Reference:** `14_glossary-alphabetical-list-dark.png`

```
Design the DARK MODE Glossary screen for SlangCheck (Neon Tokyo theme). This is an alphabetically organized, searchable dictionary of Gen Z slang terms.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS.

SCREEN STRUCTURE:
- Navigation: back chevron (neon primary) + "Glossary" title centered, Space Grotesk SemiBold

STICKY HEADER AREA (safeAreaInset top, stays fixed while list scrolls):
    SEARCH BAR:
        - Glass container: #0F0F2A, border 1px rgba(155,77,255,0.20), corner 14px, 48px height
        - LEFT: magnifyingglass SF symbol in neon primary (#9B4DFF), slightly glowing
        - INPUT: "Search slang..." placeholder, Inter 16px, tertiary text
        - When focused: border brightens to 1.5px rgba(155,77,255,0.60), inner glow rgba(155,77,255,0.06)
        - RIGHT (when text entered): xmark.circle.fill in neon primary — clear button

    CATEGORY FILTER BAR (horizontal scrollable, below search bar):
        - Horizontally scrollable row of pill chips: "All", "Descriptors", "Brainrot", "Archetypes", "Relationships", "Gaming", "Emoji", "Aesthetics", "Emerging"
        - SELECTED CHIP ("All" active): background neon primary (#9B4DFF), white text Space Mono SemiBold 12px, neon glow box-shadow
        - UNSELECTED CHIPS: background rgba(155,77,255,0.10), border 1px rgba(155,77,255,0.25), text in secondary color
        - Chips: 10px vertical padding, 14px horizontal, 20px corner radius

ALPHABETICAL SECTION LIST:
    SECTION HEADER (e.g. "A", "B"):
        - Row: letter in Space Grotesk Bold 16px, neon primary with purple glow, left-aligned with padding
        - Background: matches screen background (sticky as scrolled)
        - A thin neon primary gradient divider line below each header

    TERM ROWS (grouped per letter, glass card container per group):
        - Group card: #0F0F2A background, 16px corner radius, 1px rgba(139,92,246,0.12) border
        - Each row: term name in Space Grotesk SemiBold 16px, white. Below: definition preview truncated to 1 line, in secondary text Inter 13px.
        - RIGHT: chevron.right muted
        - Rows separated by 1px gradient dividers
        - On each row, a LEFT accent: 2px vertical neon primary bar, height proportional to row, at 30% opacity — visible only on terms with saved state

RIGHT-EDGE ALPHABET SCRUBBER:
        - Thin vertical list of A–Z letters (and #), Space Mono Bold 10px
        - Active/scrolled-to letter: neon primary color, slightly larger (12px), with a small neon dot beside it
        - Other letters: tertiary color
        - Touch target: 20px wide strip on the far right edge

VIBE: This is the ultimate slang dictionary, themed like a cyberpunk Pokédex. Each term is a collectible. The alphabetical scrubber on the right is like tuning into a neon radio station.
```

---

### Screen 15 — Profile: Lurk Tier — DARK MODE

**Reference:** `15_profile-lurk-tier-dark.png`

```
Design the DARK MODE Profile screen for SlangCheck (Neon Tokyo theme). Shows the user "Daddy421" at Lurk tier with their stats and navigation rows.

APPLY ALL GLOBAL DESIGN SYSTEM TOKENS.

SCREEN STRUCTURE:
- Navigation: back chevron + large title "Profile" in Syne Bold 34px, left-aligned with subtle neon glow
- Background: #060612

PROFILE HEADER CARD (glass card, full width, 20px radius):
    - AVATAR: 88px circle. User photo clipped to circle. Ring border: 2.5px neon primary gradient (purple → cyan), with a neon glow halo: box-shadow 0 0 20px rgba(155,77,255,0.40)
    - USERNAME: "Daddy421" in Syne Bold 22px, white with very subtle white glow
    - HANDLE: "@user_dnm43jhx" in secondary text, Space Mono 13px
    - TIER BADGE: pill chip "Lurk" — neon primary border, background rgba(155,77,255,0.15), text neon primary Space Mono SemiBold 12px, with neon glow. Like an XP rank badge.

STAT TILES (3 equal columns, below header card):
    Each tile: glass card, corner 16px, border 1px rgba(155,77,255,0.12)
    - WORDS SAVED tile: bookmark.fill icon in neon primary, "11" in Syne Bold 26px white, "Words Saved" in secondary text Space Mono 11px
    - DAY STREAK tile: flame.fill icon in neon amber (#FFB800) with amber glow, "0" in Syne Bold 26px, "Day Streak" in secondary
    - AURA POINTS tile: sparkles icon in neon cyan, "1,698" in Syne Bold 26px neon cyan with glow, "Aura Points" in secondary

AURA PROGRESS CARD (glass card, between stat tiles and nav section):
    - TOP ROW: "Lurk" in Space Grotesk SemiBold 17px white · dot separator · "Learning the lingo" in secondary text 13px | RIGHT: "1,698 pts" in Syne Bold 17px neon cyan with glow
    - PROGRESS BAR: 10px height, rounded ends, neon cyan fill (~30% progress), glowing: box-shadow 0 0 12px rgba(0,229,255,0.50). Behind fill: dark #161636 track
    - BELOW BAR: "3,302 pts to next tier" in Space Mono 12px, tertiary

NAVIGATION ROWS CARD (glass card, 20px radius):
    MY LEXICON ROW:
        - bookmark.fill icon neon primary with glow
        - "My Lexicon" in Space Grotesk SemiBold 16px
        - BADGE: "11" in a neon primary filled circle badge, white text, 22px diameter
        - chevron.right muted

    THIN NEON GRADIENT DIVIDER

    SETTINGS ROW:
        - gearshape.fill icon in neon primary
        - "Settings" in Space Grotesk SemiBold 16px
        - chevron.right muted

TAB BAR: "More" tab active, glass blur background

VIBE: The profile should feel like a player card in a cyberpunk RPG. Your stats, your rank, your collection — all in one place. The Lurk tier badge should make you want to grind to become a Rizzler.
```

---

## LIGHT MODE PROMPTS

> Light mode has the same all data and layout. The vibe shifts from "Akihabara at 2 AM" to "Harajuku at golden hour" — still vibrant and bold, but warm, airy, and joyful. Neon accents become jewel-toned and punchy rather than glowing.

---

### Light Mode Base Modifier

> Append this to any of the above prompts to generate the Light Mode variant:

```
CONVERT THE ABOVE TO LIGHT MODE ("Harajuku Daylight" theme):

PALETTE SWAP:
    Background:        #FDF6FF  (warm white with barely-there lavender whisper)
    Surface/Card:      #FFFFFF with rgba(139,92,246,0.05) tint — bright, clean, barely tinted
    Surface Elevated:  #F5EEFF  (soft lavender blush)
    Border/Separator:  rgba(139,92,246,0.18)

    Neon Primary:      #7B2FE0  (deep violet — bold on white, readable, still punchy)
    Neon Cyan:         #0099BB  (ocean teal, strong contrast on light)
    Neon Pink:         #D90060  (deep hot pink — vivid, not blinding)
    Neon Green:        #1A9940  (deep neon-leaf green — readable on light)
    Neon Amber:        #C47800  (rich amber, accessible)

    Text Primary:      #1A0A2E  (near-black with violet undertone)
    Text Secondary:    #6A5A8A  (medium lavender-grey)
    Text Tertiary:     #B0A0CC  (light lavender, for placeholders)

EFFECT ADJUSTMENTS FOR LIGHT MODE:
    Glass Card: background rgba(255,255,255,0.75), backdrop blur 20px, border 1px rgba(139,92,246,0.15), box-shadow 0 4px 24px rgba(155,77,255,0.08)
    Text shadows/glows: REMOVE all neon text-glows (they're invisible on light). Instead, use a very subtle rgba(0,0,0,0.08) text-shadow for depth.
    Card shadows: Use rgba(139,92,246,0.10) tinted shadows instead of dark shadows.
    Neon Glow border: Replace rgba(X,Y,Z,0.50) glow box-shadows with clean 1.5px colored borders + rgba(X,Y,Z,0.10) spread.

BACKGROUND TREATMENTS FOR LIGHT MODE:
    - Where dark mode had neon bloom overlays: replace with soft watercolor-style washes in the same hue at 6-8% opacity
    - The overall feel: clean, bright, energetic — like a Japanese pop-art poster in pastel
    - Subtle dot-grid pattern on background: dots rgba(139,92,246,0.06), 24px spacing — gives it a notebook/sticker book feel

TYPOGRAPHY: Same fonts, but titles can be slightly bolder (Font weight +100 where applicable) since there's no neon glow to make them pop.

TAB BAR LIGHT: frosted white glass, subtle bottom shadow, neon primary active indicator.

CARD STYLE LIGHT: White cards with very gentle purple-tinted shadows. Borders are colored (not glow, just colored). Active states use solid colored fills rather than glow fills.

KEEP ALL LAYOUT, DATA, AND INTERACTIVE ELEMENTS IDENTICAL. Only the visual treatment changes.
```

---

### Light Mode Specific Notes Per Screen

```
LEARN / SWIPER (Light):
    - Flashcard: White card with soft lavender inner shadow (inset 0 1px 0 rgba(255,255,255,1.0) top, 0 4px 20px rgba(155,77,255,0.10) outer)
    - Category chip: solid deep violet background, white text
    - Slang term: near-black #1A0A2E, large and punchy, no glow needed (it's on white)
    - SAVE button: neon green border, deep green text, soft green fill on press
    - SKIP button: hot pink border, deep pink text, soft pink fill on press
    - Background: warm white #FDF6FF with a very faint pastel rainbow gradient in the far background, like sunshine through crystals

TRANSLATOR (Light):
    - Top panel: white glass card with soft lavender border
    - Direction toggle: solid deep violet circle with white icon — pops against the white background
    - Bottom panel: very light cyan tint #F0FAFF as background, teal border

GAMES HUB (Light):
    - Background: light #FDF6FF with confetti dot pattern
    - Aura banner: white card with teal (neon cyan) left border accent (4px solid) instead of full glow
    - Game cards: white with colored left border accents — purple for Quiz, teal for Crossword
    - Aura pts value: deep violet, bold

QUIZ ACTIVE (Light):
    - Question card: white, gentle violet border, violet badge chip
    - Answer options: white cards, violet left accent bar, deep-color text
    - Correct answer: bright neon green fill (#D4FFE8) background, deep green text, green border
    - Timer ring: same color progression (green → amber → pink), but no glow — just the arc color itself

QUIZ RESULT (Light):
    - Star: deep amber, no glow — but surrounded by pastel confetti dots (pink, purple, cyan, yellow) scattered around it
    - Aura card: light cyan tint card #E8FAFF, deep teal text for the aura earned number
    - Progress bar: solid teal fill on a lavender track

CROSSWORD (Light):
    - Grid cells: white, with 1px rgba(139,92,246,0.20) borders — clean and graph-paper-like
    - Blocked cells: #DDD6EE (soft lavender-grey) — softer than pure black, like crossword paper
    - Active cell: solid deep violet fill, white letter inside
    - Highlighted word: rgba(155,77,255,0.12) tint
    - Cell numbers: deep violet, small, corner-positioned

GLOSSARY (Light):
    - Search bar: white with violet border, soft violet focus state
    - Category chips: selected = solid deep violet + white text; unselected = lavender fill + violet text
    - Section headers: deep violet, clean, no glow
    - Term rows: white cards, violet left accent bars for saved terms

PROFILE (Light):
    - Avatar ring: gradient violet-to-teal, 2.5px, clean (no glow box-shadow)
    - Stat tiles: white cards with soft violet tinted shadows
    - Aura progress bar: solid teal fill, lavender track
    - Tier badge: deep violet fill, white text
    - Nav rows: white card, colored icon fills
```

---

## ANIMATION PROMPTS (Lottie)

> These are prompts for generating Lottie animation concepts. Use with your motion designer or LottieFiles generator. Export as `.json` for use in the app.

---

### Animation 01 — Quiz Loading State (Lottie)

```
Create a Lottie animation for a "quiz generating" loading screen for a Gen Z slang learning app (Neon Tokyo cyberpunk theme). Duration: 3-4 seconds, looping.

ANIMATION CONCEPT: "The Rizzler Council is Deliberating"

SCENE: A round council table viewed from above (top-down perspective), with 5 tiny cartoon character silhouettes seated around it — each one represents a Gen Z archetype:
  - The Sigma (stoic, arms crossed, sunglasses emoji head)
  - The Rizzler (leans back confidently, crown emoji head)
  - The Ohio Dweller (confused, question mark head)
  - The NPC (standing rigid, loading bar over face)
  - The Aura Farmer (meditating, sparkles orbiting head)

CENTER of table: A glowing quiz paper / scroll, floating and rotating slowly.

ANIMATION SEQUENCE:
  0s–0.5s: Characters pop in one by one with springy bounce entrances from off-screen
  0.5s–2.0s: Characters animate in discussion — heads bob, arms gesture, speech bubbles pop in with "...", question marks, lightbulbs
  2.0s–3.0s: A lightbulb appears above the Rizzler, grows bright, then — FLASH — the quiz paper on the table glows neon purple, then bounces upward toward camera
  3.0s–3.5s: Everything resets for loop

COLOR PALETTE: Background transparent (app provides bg). Neon purple (#9B4DFF), neon cyan (#00E5FF), neon green (#39FF85). Characters are simple flat shapes, bold outlines, vibrant fills.

OUTPUT: Lottie JSON, 390×300px canvas, 60fps
```

---

### Animation 02 — Crossword Loading State (Lottie)

```
Create a Lottie animation for a "crossword loading" screen for a Gen Z slang app (Neon Tokyo theme). Duration: 4 seconds, looping.

ANIMATION CONCEPT: "The Neon Grid Assembles Itself"

SCENE: A crossword grid (5×5 mini version) assembles itself cell-by-cell from empty chaos into an ordered grid.

ANIMATION SEQUENCE:
  0s–0.5s: Individual cell squares rain down from the top of the frame, bouncing and tumbling
  0.5s–2.0s: Cells land and snap into a grid formation, one-by-one with satisfying "click" bounce animations. Each cell has a brief neon glow on landing. Cells alternate between blocked (dark) and letter (light) in the correct crossword pattern.
  2.0s–2.8s: Letters begin appearing in cells — they type themselves in, one by one, in neon cyan, each letter arriving with a tiny sparkle burst
  2.8s–3.5s: The completed mini grid pulses with a full neon purple glow across all borders simultaneously, like it's alive
  3.5s–4.0s: Grid shrinks to center point and disappears (exit), then reset for loop

LETTER CONTENT (the fun part): the letters spell "SLAY" across and "RIZZ" down — intersecting at the "R/A" crossover. Pure Gen Z Easter egg.

COLOR PALETTE: Transparent background. Grid lines neon primary (#9B4DFF). Blocked cells dark navy #0F0F2A. Letter cells off-white. Letter text neon cyan (#00E5FF). Landing burst particles neon green (#39FF85).

OUTPUT: Lottie JSON, 390×390px canvas, 60fps
```

---

### Animation 03 — Correct Answer Celebration (Lottie)

```
Create a Lottie animation for a correct quiz answer celebration micro-interaction for a Gen Z app. Duration: 0.8 seconds, plays ONCE (no loop).

SCENE: Particle burst from the center of the selected answer card.

ANIMATION:
  0s–0.2s: 12–16 small particles shoot outward from the center in a radial burst pattern. Particle shapes: mix of ✦ sparkles (4-pointed stars), tiny circles, and mini lightning bolts. Colors: neon green (#39FF85), neon cyan (#00E5FF), white.
  0.2s–0.5s: Particles travel outward, scale up slightly, then fade out along their trajectory
  0.5s–0.8s: 3–4 larger sparkle shapes (✦) appear at random positions around the card and fade out with a pop
  Simultaneously: The answer card itself scales 1.0 → 1.03 → 1.0 with an elastic spring easing

FEEL: Like popping champagne in slow motion — joyful, punchy, brief. Not over the top.

OUTPUT: Lottie JSON, 390×100px canvas (fits over answer card), 60fps
```

---

### Animation 04 — Wrong Answer Shake (Lottie)

```
Create a Lottie animation for a wrong quiz answer micro-interaction. Duration: 0.6 seconds, plays ONCE.

ANIMATION: The selected answer card shakes horizontally (like a "no no no" head shake):
  0s–0.1s: Card translates right +8px
  0.1s–0.2s: Card snaps left -12px
  0.2s–0.3s: Card right +8px
  0.3s–0.4s: Card left -6px
  0.4s–0.5s: Card right +4px
  0.5s–0.6s: Card returns to 0 (elastic ease-out)

Simultaneously: 3 small neon pink (FF2D78) X marks pop out from the card edges and fade — like a cartoon "wrong!" indicator. Each X scales from 0→1.2→1.0 and then fades.

The card border briefly flashes neon pink (#FF2D78) for the entire duration.

FEEL: Playful wrong, not harsh. Like the app is teasing you. Think Super Mario "boing" energy, not a buzzer.

OUTPUT: Lottie JSON, 390×100px canvas, 60fps
```

---

### Animation 05 — Aura Points Counter (Lottie)

```
Create a Lottie animation for the Aura Points display on the quiz result screen. Duration: 1.5 seconds, plays ONCE.

ANIMATION CONCEPT: Numbers cascade upward and "charge" into their final value, surrounded by neon energy.

SEQUENCE:
  0s–0.3s: A small energy orb (neon cyan circle, 20px) appears at the number's start position and expands outward
  0.3s–1.2s: The number counts up rapidly (like an odometer): 0 → 1050, with the digits flying upward as they change. Each digit transition has a brief neon cyan streak going upward
  1.0s–1.3s: At the final number "+1,050 Aura," 4–6 small sparkle particles (✦) orbit the text once and disperse
  1.3s–1.5s: Text settles, a gentle neon cyan underline sweeps left-to-right beneath the number

BACKGROUND EFFECT: A soft neon cyan radial pulse (circle expands from center, fades) happens at the 1.0s mark (when number lands)

OUTPUT: Lottie JSON, 390×120px canvas, 60fps
```

---

### Animation 06 — Quiz Timer Warning Pulse (Lottie)

```
Create a Lottie animation for when the quiz timer drops below 10 seconds. Duration: 1 second, looping until timer hits 0.

ANIMATION:
  The timer ring (circular arc) pulses with urgency:
  0s–0.5s: The ring glow expands — box-shadow/glow from 8px to 20px neon pink (#FF2D78) and back
  0s–0.5s: The number inside the ring blinks: full opacity → 60% → full opacity
  0.5s–1.0s: Repeat

  Simultaneously: 2 tiny neon pink lightning bolt shapes (⚡) appear beside the timer at 0s and fade by 0.5s

  The ring arc itself has a "panic" shimmer — a bright white highlight orbits the arc tip continuously (like a comet on the ring)

FEEL: Urgent but fun. Like a video game countdown — stressful in a good way. Not a heart attack machine.

OUTPUT: Lottie JSON, 60×60px canvas (fits over timer ring), 60fps
```

---

### Animation 07 — Streak Break Sadness (Lottie)

```
Create a Lottie animation for when a user's streak resets to 0. Duration: 2 seconds, plays ONCE.

ANIMATION CONCEPT: The flame goes out.

SCENE: A medium-sized flame icon (neon amber, matching the streak flame in the app).

SEQUENCE:
  0s–0.5s: Flame flickers anxiously (scale oscillates ±5%, opacity dips to 70% twice)
  0.5s–1.0s: Flame shrinks downward from top (scale Y collapses toward base)
  1.0s–1.3s: A tiny puff of grey smoke (3 soft circles, light grey, rising upward) replaces the flame
  1.3s–1.6s: Smoke dissipates. A tiny sad face emoji (😔) appears where the flame was, in the same amber color, scales up from 0 to full size with elastic bounce
  1.6s–2.0s: Sad face fades out gently

BACKGROUND: Transparent

FEEL: Sympathetic, not punishing. The sad face turns it into a moment of comedy, not shame. The app is sad WITH you, not at you.

OUTPUT: Lottie JSON, 80×80px canvas, 60fps
```

---

### Animation 08 — Tier Promotion Celebration (Lottie)

```
Create a Lottie animation for when a user levels up to a new Aura tier. Duration: 3 seconds, plays ONCE. This is the biggest celebration in the app.

ANIMATION CONCEPT: "LEVEL UP" arcade screen

SCENE: Full-screen canvas.

SEQUENCE:
  0s–0.5s: Screen flashes bright neon primary, then fades back to transparent (like a camera flash)
  0.5s–1.2s: From the center, a neon crown icon (crown.fill) shoots upward from below, trails neon fire behind it (neon primary → neon cyan → neon green gradient trail)
  1.0s–1.5s: Text appears in the center: "LEVEL UP!" in bold retro arcade font, neon primary, outlined in white — it scales from 200% down to 100% with heavy bounce easing
  1.2s–2.2s: Confetti explosion from the center: 30–40 particles in neon primary, cyan, pink, green, amber — mix of ✦ sparkles, tiny rectangles, circles — they travel outward at various velocities and spin
  1.8s–2.5s: New tier name text (e.g. "AURA FARMER") slides up from below, neon cyan, Space Mono Bold uppercase
  2.5s–3.0s: All elements fade out smoothly except a lingering glow that fades last

FEEL: This should feel like hitting a jackpot on an arcade machine. The best 3 seconds of the user's day.

OUTPUT: Lottie JSON, 390×844px full screen canvas, 60fps
```

---

## FUNNY LOADING MESSAGES BANK

> Rotate through these randomly in all loading states. Display one message at a time, cycling every 3–4 seconds. Use a typewriter-style reveal animation (characters appear left-to-right at 30ms per character) for each new message.

### Quiz Generation Loading Messages
```
- "Consulting the Rizzler Oracle... 🔮"
- "Asking the Ohio Sigma to peer-review your IQ"
- "The Aura Farmer is plowing through the question fields rn"
- "NPC loading... please hold while we charge your rizz"
- "Bro said 'no cap' and walked straight into the question generator"
- "The slay council is in session. Results pending."
- "Manifesting 10 questions that will actually slap"
- "The main character is generating your plot arc"
- "Decrypting the NPC's entire vocabulary. This takes a sec."
- "Your delulu is becoming your tulu... question by question"
- "We told Goon to generate your quiz. He said 'bet.' That was 20 seconds ago."
- "Running a vibe check on each answer option"
- "The Glazer is glazing the questions rn, back off"
- "Summoning main character energy for Question 1..."
- "Low-key preparing a high-key certified slay of a quiz"
```

### Crossword Puzzle Loading Messages
```
- "The Ohio Rizzler was caught having a Sneaky Link with the Fanux Taxer"
- "Bro really said 'no cap' to 47 Down and kept it moving"
- "The crossword grid is doing its Roman Empire thing"
- "Your Aura Farmer is tilling the letter fields. Patience."
- "Sigma grindset: puzzle generation edition 💪"
- "The crossword clues are bussin fr fr (still loading tho)"
- "Low-key mid grid assembling... high-key slay incoming"
- "The NPC is placing the black squares. It's their only job. They're trying."
- "BUSSIN loading... RIZZ loading... SLAY loading..."
- "We asked the Glazer to write today's clues. He did not disappoint."
- "Manifesting a W-tier crossword into existence"
- "The Unc is confused by all 23 clues. Grid loading regardless."
- "Certified brainrot puzzle incoming (this is a good thing)"
- "Today's theme: words your parents pretend to understand"
- "One does not simply generate a crossword. Unless you have rizz."
```

### General App Loading Messages (splash / initial load)
```
- "Waking up the slang dictionary. It was sleeping, bestie."
- "Loading your rizz reserves..."
- "Syncing with the Aura Council servers"
- "Checking if you're still a Lurk (you're working on it 🤙)"
- "The dictionary is bussin itself into existence"
- "Fetching all the slay from the cloud"
- "Your main character arc starts in 3... 2..."
- "Summoning Gen Z vocabulary from the void"
- "Asking the algorithm what the kids are saying these days"
```

---

## Stitch Workflow Notes

1. **Always upload the reference screenshot alongside each prompt** — Stitch uses it as a layout anchor. The prompt defines the *visual language*, the screenshot defines the *structure*.
2. **Generate dark mode first**, then use the Light Mode Modifier prompt on the same base.
3. **For crossword and glossary**, request that Stitch export a component library of the cell/row types separately — this makes engineering handoff faster.
4. **For animations**, use the Lottie prompts in LottieFiles' community builder or with a motion designer. Request 1x, 2x, and 3x exports.
5. **Naming convention for exports:** `SC_[screen-number]_[screen-name]_[dark|light]_[v1].png`

---

*SlangCheck — Where Gen Z vocabulary meets neon Tokyo design. No cap.*
