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
