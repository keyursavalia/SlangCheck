# DATABASE.md — SlangCheck Lexicographical Database
### Comprehensive Sociolinguistic Mapping for Iteration-1

> This document is the **seed data reference** for the SlangCheck app's Iteration-1 dictionary.
> Every `SlangTerm` entry seeded into the bundled JSON must trace back to a category defined here.
> The database is organized by thematic cluster to support the bi-directional translation engine
> planned for Iteration-2. Each entry carries a Gen Z form, a Standard English output, and a
> contextual nuance field — the three-column schema that drives both the Swiper UX and the Translator.

---

## Context: The Linguistic Landscape

Language among **Generation Z** (born c. 1997–2012) and **Generation Alpha** (born c. 2013–2024)
no longer evolves through geographical proximity or traditional media. It mutates at the velocity
of a TikTok algorithm, driven by niche internet subcultures, gaming environments, and social
media dynamics.

The SlangCheck database must catalog:
- **High-frequency terminology** in current everyday use.
- **Emerging "brainrot" lexicon** — absurdist, meme-driven Gen Alpha dialect.
- **"Algo-speak"** — coded language developed to navigate platform censorship.
- **Emoji as second language** — visual shorthand with meanings invisible to non-natives.
- **Aesthetic "Cores"** — lifestyle and visual identity subcategories.
- **Emerging 2025–2026 terminology** — forward-looking entries for the Dynamic Dictionary.

### Data Schema (per entry)

Every term in the bundled `slang_seed.json` must conform to this shape:

```json
{
  "id": "uuid-v4",
  "term": "No Cap",
  "definition": "An intensifier meaning 'for real' or 'honestly'; used to assert that the speaker is telling the truth.",
  "standardEnglish": "Honestly / I'm not lying",
  "exampleSentence": "He said he won the lottery, but I think he's capping.",
  "category": "foundational_descriptor",
  "origin": "African American Vernacular English (AAVE), popularized via hip-hop and social media.",
  "usageFrequency": "high",
  "generationTag": ["genZ", "genAlpha"],
  "addedDate": "2025-01-01",
  "isBrainrot": false,
  "isEmojiTerm": false
}
```

---

## Category 1 — Foundational Descriptors & Adjectives

> Core adjectives that define the quality, authenticity, or status of an object, person, or situation.

| Term | Definition & Nuance | Standard English | Contextual Example |
|---|---|---|---|
| **Ate** | To perform a task or present oneself exceptionally well; often paired as "ate and left no crumbs." | Nailed it / Excelled | "She absolutely ate that presentation — professor was speechless." |
| **Basic** | Mainstream, unoriginal, or uncool; a mild insult toward someone who follows trends without originality. | Unoriginal / Mainstream | "Let's get out of here. This party is basic." |
| **Based** | Authentically and unapologetically oneself, especially when holding a controversial or unpopular opinion. | Authentic / Principled | "You brought your own snacks to the cinema? Based behavior." |
| **Bussin'** | Extremely good or delicious; primarily used in the context of food. | Delicious / Amazing | "These tacos are bussin', I need another plate!" |
| **Cap** | A lie or exaggeration. | Lie / Falsehood | "He said he won the lottery, but I think he's capping." |
| **No Cap** | Intensifier meaning "for real" or "honestly"; asserts truthfulness. | Honestly / For real | "No cap, that was the best movie I've ever seen." |
| **Cheugy** | Outdated, uncool, or trying too hard to be trendy; specifically targets aesthetics from the early 2010s. | Outdated / Try-hard | "I can't believe she's still wearing skinny jeans, that's so cheugy." |
| **Dank** | High quality, excellent, or impressive; originally rooted in cannabis culture, now applied broadly. | Excellent / High quality | "The party last night was dank!" |
| **Extra** | Over-the-top, dramatic, or excessive behavior that is often unnecessary. | Excessive / Dramatic | "Her outfit for the party was extra with all the sequins and feathers." |
| **Fire** | Amazing, impressive, or exceptionally good; synonymous with "lit." | Amazing / Excellent | "That new song is fire 🔥." |
| **Lit** | Exciting, fun, or amazing; describes a high-energy situation or object. | Exciting / Amazing | "This party is lit! The music is great and everyone is having a good time." |
| **Mid** | Mediocre, average, or underwhelming; used to describe something that fails to meet expectations. | Average / Mediocre | "That movie was hyped up but ended up being very mid." |
| **Salty** | Bitter, annoyed, or upset, typically over a minor or trivial matter. | Bitter / Upset | "I lost the game to my friend. That's why I'm just a little salty about it." |
| **Snatched** | Looking flawless, stylish, or physically fit; frequently used to compliment an outfit or appearance. | Flawless / Stylish | "Her outfit for the party was snatched. Everyone was talking about it." |
| **Sus** | Short for "suspicious"; refers to someone or something that appears sketchy or untrustworthy. | Suspicious / Sketchy | "Why is he acting so sus? What are you hiding?" |
| **Valid** | Cool, acceptable, or logically sound; used to validate an opinion or feeling. | Acceptable / Understandable | "That opinion is valid." |
| **Zesty** | Lively, bold, or flamboyant; can also refer to something dramatic or cheeky. | Flamboyant / Bold | "That outfit is zesty." |

---

## Category 2 — The "Brainrot" Spectrum: Gen Alpha & Meme-Driven Dialect

> "Brainrot" encompasses absurd, repetitive, and often nonsensical phrases that have emerged
> from Gen Alpha's immersion in specific YouTube and TikTok subcultures. These terms are
> characterized by high velocity and context-dependent meanings, often serving as filler words
> or linguistic markers of "being in on the joke."

| Term | Origin | Meaning & Usage |
|---|---|---|
| **Skibidi** | Alexey Gerasimov's "Skibidi Toilet" YouTube series — heads in toilets singing a repetitive song. | An absurdist adjective or filler word that can mean good, bad, cool, or evil depending on context and speaker's intent. |
| **Ohio** | "Only in Ohio" meme depicting the US state as a site of supernatural or chaotic events. | A descriptor for anything strange, weird, or cringe-worthy. |
| **Fanum Tax** | Streamer Kai Cenat and his friend Fanum, who frequently "taxed" Kai's food on stream. | The act of stealing or taking a portion of a friend's food. |
| **Brainrot** | Concept: mental decline from consuming excessive low-quality digital content. | Used both as a cultural critique and as a self-aware label for excessive social media usage. |
| **What the Sigma?** | A play on the "Sigma" male archetype meme. | A nonsensical exclamation used in place of "What the heck?" or to express general confusion. |
| **Baby Gronk** | Youth football prodigy Madden San Miguel, who went viral for his football skills. | Used to describe someone with massive potential; also a humorous marker of niche internet celebrity. |
| **Grimace Shake** | McDonald's 2023 promotional campaign for the Grimace birthday milkshake. | A reference to a viral horror-themed trend involving the purple milkshake. |
| **Mewing** | An orthodontic technique for jawline definition popularized by Dr. Mike Mew. | A gesture (finger to lips, tracing the jaw) signifying one is working on their appearance and cannot speak. |
| **Goofy Ahh** | Phonetic variation of "Goofy ass." | Describes something or someone ridiculous, silly, or funny in an absurd way. |
| **Crash Out** | Internet vernacular describing an intense emotional outburst. | To lose control, have a meltdown, or act recklessly due to frustration. |

---

## Category 3 — Identity, Social Hierarchy & Archetypes

> The SlangCheck Aura System maps explicitly onto the social hierarchies that exist in digital
> spaces. These archetypes are borrowed from evolutionary psychology (Alpha/Beta/Sigma)
> and gaming culture (NPC), repurposed as tools for social signaling.

| Term | Social Standing / Definition | Contextual Example |
|---|---|---|
| **Alpha** | The most dominant, powerful, or assertive person in a group; sometimes used mockingly. | "He thinks he's the alpha of the friend group, but it's just cringe." |
| **Beta** | A person perceived as weak, timid, or submissive. | "He's such a beta, always following whatever the others do." |
| **Sigma** | A "lone wolf" leader who is successful and independent, existing outside the traditional Alpha/Beta hierarchy. | "He has major sigma energy — he doesn't care what anyone thinks." |
| **Rizzler** | Someone with a high degree of "rizz" (charisma); the top tier in the SlangCheck app. | "He's the ultimate rizzler; he can talk to anyone." |
| **NPC** | "Non-Player Character" — someone who lacks originality and seems to follow a pre-set script. | "I felt like an NPC in that meeting, just nodding along." |
| **Unc** | Short for "Uncle"; refers to an older person or someone out of touch with modern trends. | "I couldn't figure out how to repost on TikTok — I feel so unc." |
| **Chad** | A stereotypically hyper-masculine, confident male; often used humorously. | "He's such a Chad with that workout routine." |
| **Karen** | An entitled woman who uses her privilege to get her way, often by complaining to management. | "Don't be a Karen about the slow service." |
| **Pick-Me** | Someone who seeks validation from the opposite sex by putting down others of their own gender. | "She's such a pick-me girl, always claiming she's 'not like other girls'." |
| **Pookie** | A term of endearment for a loved one or best friend. | "That's my pookie — we go everywhere together." |
| **Opp** | Short for "opposition"; an enemy, rival, or someone the speaker dislikes. | "He hangs out with the opps now? Wild." |
| **Stan** | An obsessive or highly dedicated fan; portmanteau of "stalker" and "fan." | "I stan Beyoncé — she's the queen of everything." |

---

## Category 4 — Interpersonal Dynamics & Relationship Slang

> Gen Z and Alpha have developed a complex vocabulary to describe the nuances of modern
> attraction and dating that often avoids the finality of traditional labels. Critical for the
> Bi-Directional Translator in Iteration-2.

| Term | Functional Definition | Usage Context |
|---|---|---|
| **Situationship** | A romantic or sexual relationship that lacks clear labels or commitment; "more than friends, less than a relationship." | "We don't see other people but we aren't official… it's a situationship." |
| **The Ick** | A sudden, irreversible feeling of disgust toward a romantic interest triggered by a minor habit or trait. | "He chewed with his mouth open and I got the ick immediately." |
| **Ghosting** | Suddenly and completely ending communication with someone without explanation. | "He ghosted me after our first date — so rude!" |
| **Soft Launch** | Subtly introducing a new partner on social media (e.g., posting a picture of their hand or shoes) without showing their face. | "She posted his shoes in her story — classic soft launch." |
| **Hard Launch** | The definitive, public reveal of a relationship through clear social media posts. | "Two weeks after the soft launch, she finally hard launched him on IG." |
| **Simp** | Someone who displays excessive affection or submissiveness to a crush, often without reciprocation. | "Stop simping for her — she's not even interested." |
| **Rizz** | Truncated from "charisma"; refers to one's ability to charm or flirt successfully. | "He's got mad rizz — everyone loves him." |
| **Sneaky Link** | A secret romantic or casual relationship. | "They've been a sneaky link for months now." |
| **Cringe** | A feeling of intense embarrassment or awkwardness, often in response to someone else's social failure. | "Watching him try to flirt was pure cringe." |
| **Bae** | An acronym for "Before Anyone Else"; a significant other or crush. | "Bae is calling me." |
| **Main Squeeze** | A person's primary significant other. | "She's been my main squeeze since sophomore year." |

---

## Category 5 — Gaming, Internet Culture & Communication Shorthand

> Terms originating in competitive gaming (Among Us, Fortnite, League of Legends) and
> internet culture that have transitioned into everyday vernacular.

| Term / Acronym | Full Form / Origin | Definition & Usage |
|---|---|---|
| **W / L** | Win / Loss | Used to rate an action, person, or event. A "W" is a success; an "L" is a failure. |
| **Sus** | Suspicious (Among Us) | Originates from the game Among Us; used to call out sketchy behavior. |
| **GG** | Good Game | Said at the end of a match; can also be used sarcastically to mean "it's over." |
| **Ratioed** | N/A | Occurs when a reply to a post gets more likes than the original post, indicating widespread disagreement. |
| **Noob** | Newbie | An inexperienced or unskilled player; used as a mild insult. |
| **Clout Chaser** | N/A | Someone who does things solely to gain fame or social media influence. |
| **Receipts** | N/A | Proof or evidence of a claim, typically in the form of screenshots or text messages. |
| **FOMO** | Fear Of Missing Out | The anxiety that others are having rewarding experiences from which one is absent. |
| **IYKYK** | If You Know You Know | Indicates an inside joke understood only by a specific group. |
| **BFFR** | Be For F**king Real | A demand for honesty or a call-out of someone's delusional or over-the-top behavior. |
| **POV** | Point Of View | Used to describe a scene from a specific perspective; common in TikTok skits. |
| **FYP** | For You Page | The personalized content feed on TikTok; used as a hashtag to gain views. |
| **AF** | As F**k | An intensifier used to emphasize a quality (e.g., "lit AF"). |
| **Deadass** | Seriously | Used to emphasize that one is telling the absolute truth. |
| **Finna** | Fixing to | Short for "about to" or "preparing to do something." |
| **Say Less** | N/A | Indicates that the speaker has understood the point and no further explanation is needed. |

---

## Category 6 — Visual Language: Emoji Slang

> Gen Z and Alpha use emojis as a "second language" to communicate messages subtly —
> often with hidden meanings related to sexuality, substances, or social status, designed to
> bypass platform moderation or parental monitoring.
>
> ⚠️ **Implementation note for Claude Code:** The emoji category requires careful handling.
> Display definitions factually and educationally. Do not render these entries in the Swiper
> flashcard mode with the emoji as the primary visual without design approval.

### Coded & Symbolic Emojis

| Emoji | Digital Meaning | Cultural Nuance |
|---|---|---|
| 🍆 | Male genitalia | The universal surrogate; widely understood across age groups. |
| 🍑 | Buttocks | Represents a large or attractive bottom. |
| 🌽 | Pornography | "Corn" rhymes with "porn," used to bypass content filters. |
| 🧠 | Oral sex | Referred to colloquially as "giving brain." |
| 💦 | Sexual desire / ejaculation | Used in sexualized contexts or to signal extreme attraction. |
| 🍝 | Nude photos | A play on "noods" (noodles) as a substitute for the word "nudes." |
| 🍃 | Marijuana | A common code for cannabis; often paired with 💨. |
| 🥴 | Drunk or aroused | Used to signify intoxication or sexual interest. |
| 🤡 | Fraud or fool | Used to mock someone for a mistake or "clown-like" behavior. |
| 🧢 | Lie | Visual shorthand for "capping" (lying). |
| 💀 | Dying of laughter | Has largely replaced 😂 to signal something was "deadly" funny. |
| 👉👈 | Shy or flirtatious | Shows nervousness, typically when asking a favor or flirting. |
| 💅 | Sassy or unbothered | Signals confidence; "slaying" while ignoring critics. |
| 💯 | Full agreement | Indicates 100% support or "facts." |
| 💳 | Wanting to buy / desire | Used when someone sees something they want. |

---

## Category 7 — Aesthetic Subcultures & "Cores"

> The "Core" suffix is added to any word to name a specific aesthetic, lifestyle, or vibe.
> This trend originated in niche internet style communities and has expanded to encompass
> virtually any visual or behavioral theme. The app's category filter should include "Aesthetics"
> as a dedicated tag.

| Aesthetic | Description |
|---|---|
| **Cottagecore** | Centered on simple, rural living, traditional crafts, and harmony with nature. |
| **Barbiecore** | Hyper-feminine aesthetic dominated by vibrant pinks and inspired by the Barbie franchise. |
| **Goblincore** | Celebrates "unconventional" aspects of nature — mud, moss, snails, and "ugly" animals. |
| **Librarycore / Fall-semester-core** | Hyper-specific academic aesthetics focusing on cozy, studious vibes. |
| **E-boy / E-girl** | Social media-driven alternative aesthetic featuring heavy eyeliner, dyed hair, and 90s/emo influences. |
| **Preppy** | Refined, bright-colored aesthetic involving popular brands like Lululemon and Stanley. |
| **Soft Girl / Soft Life** | Embracing a gentle, relaxed, aesthetically pleasing lifestyle; often a rejection of "hustle culture." |

---

## Category 8 — Emerging Terminology for 2026

> These are forward-looking entries anticipated to peak in the 2025–2026 period.
> They should be seeded in the initial database and are prime candidates for the
> Dynamic Dictionary's first weekly update batch.

| Term | Definition |
|---|---|
| **Rich in Life** | A shift in the definition of wealth away from monetary assets toward experiences, health, and curiosity. |
| **404 Coded** | Describing someone who is mentally absent, clueless, or checked out — referencing the HTTP "Not Found" error. |
| **Side Quest** | Framing unexpected detours or minor tasks as adventures in the "game" of real life. |
| **Zang** | A versatile remix of "dang" used as a fun exclamation of surprise or disappointment. |
| **Aura Farming** | Criticizing those who performatively curate their vibe or image to gain "aura points" rather than being authentic. |
| **Canon Event** | A defining life moment — often chaotic or difficult — viewed as essential to one's personal development. |
| **Brat Summer** | A 2024–2025 aesthetic trend defined by unapologetic messy behavior and lime-green visuals. |

---

## Implementation Notes for Claude Code

### Seed File Structure

The bundled `slang_seed.json` must be stored in `Resources/Data/slang_seed.json`. It is **read-only** and serves as the factory reset state for the local CoreData store. Never modify it at runtime.

### Category Tags (use these exact strings as enum cases)

```swift
enum SlangCategory: String, Codable, CaseIterable {
    case foundationalDescriptor  = "foundational_descriptor"
    case brainrot                = "brainrot"
    case socialArchetype         = "social_archetype"
    case relationship            = "relationship"
    case gamingInternet          = "gaming_internet"
    case emojiSlang              = "emoji_slang"
    case aesthetic               = "aesthetic"
    case emerging2026            = "emerging_2026"
}
```

### Usage Frequency Tags

```swift
enum UsageFrequency: String, Codable {
    case high    // Core vocabulary; used daily
    case medium  // Widely understood; used regularly
    case low     // Niche; context-specific
    case emerging // Trending; not yet mainstream
}
```

### Bi-Directional Translation Schema

Every term must be usable in both translation directions (Iteration-2):

- **GenZ → Standard English:** `term` + `definition` → `standardEnglish`
- **Standard English → GenZ:** `standardEnglish` as input → suggest `term`

The `contextualNuance` field is displayed as a secondary hint in the Translator view.

---

*Reference documents: `CLAUDE.md`, `PROPOSAL.md`, `DESIGN_SYSTEM.md`, `FUNCTIONAL_REQUIREMENTS.md`*
