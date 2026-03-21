# Questions & Answers Log — SlangCheck

---

## Q-001 — Additional OAuth Providers Beyond Sign in with Apple

**Asked:** 2026-03-19
**Answered:** 2026-03-20
**Step:** Step 1.8 — App Shell & Navigation (pre-Iteration 2 auth planning)
**Status:** ✅ Answered

**Question:**
FR-O-009 flags this as requiring developer input:
> Determine if email/password or other OAuth providers (Google) are also required in addition to Sign in with Apple.

Per NF-S-014: "Sign in with Apple shall be the only OAuth provider unless the developer explicitly approves additional providers."

Do you want Google Sign-In or email/password authentication in addition to Sign in with Apple? Note: If any other OAuth provider is added, Sign in with Apple is mandatory alongside it per App Store guidelines.

**Developer Answer:**
Sign in with Apple only. No additional OAuth providers at this time.

**Action Taken:**
Decision recorded. Auth is deferred to Iteration 3 (Aura sync). When auth work begins, only Sign in with Apple will be implemented per NF-S-014.

---

## Q-003 — Offline Aura Points Sync Conflict Resolution

**Asked:** 2026-03-21
**Answered:** 2026-03-21
**Step:** Step 3.3 — Persistence & Sync
**Status:** ✅ Answered

**Question:**
When a user earns Aura Points offline and those points are later synced to Firebase, what is the conflict resolution strategy?
Options: (A) last-write-wins, (B) server-authoritative, (C) client delta accumulation.

**Developer Answer:**
Server-authoritative. Firebase is always the source of truth. The client writes its local state to Firestore and must accept the server's value on any conflict.

**Action Taken:**
`AuraSyncService` will write the local `AuraProfile` snapshot to Firestore and merge the server value back on any conflict. The `AuraProfile` CoreData entity will cache the last-confirmed-server value so reads never stall. No optimistic counters will be kept client-side beyond the cache.

---

## Q-004 — Aura Card User Identifier

**Asked:** 2026-03-21
**Answered:** 2026-03-21
**Step:** Step 3.5 — Aura Cards (Social Sharing)
**Status:** ✅ Answered

**Question:**
Should the shareable Aura Card image contain any unique user identifier (username, display name, user ID), or only rank/tier visuals?

**Developer Answer:**
Yes — include the user's display name or username on the card.

**Action Taken:**
`AuraCardView` will render the user's display name prominently alongside the tier badge and point total. No internal user ID or email will appear on the card. The display name is sourced from the authenticated user profile (Sign in with Apple display name or a user-set username stored in Firestore).

---

## Q-002 — Translation Engine: Local vs. Remote API

**Asked:** 2026-03-20
**Answered:** 2026-03-20
**Step:** Step 2.1 — Translation Service Protocol
**Status:** ✅ Answered

**Question:**
Per CLAUDE.md Step 2.1: Will translation be handled locally (dictionary lookup) or via a remote API? If remote: what API? What is the data retention policy for user-input text?

**Developer Answer:**
Local only. User types text and the app returns the best possible match from the local slang dictionary. No network calls, no data retention concerns.

**Action Taken:**
Implemented `LocalTranslationService` backed by `TranslateTextUseCase`. Algorithm uses greedy longest-match-first regex substitution against the CoreData term dictionary. The `TranslationService` protocol is still defined so a `RemoteTranslationService` can be added in a future iteration without ViewModel changes.

---
