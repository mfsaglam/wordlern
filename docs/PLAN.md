# Plan — gamify / UI overhaul

Target branch for all of this: `feature/gamify`. One step = one branch = one task.
Status values: `todo`, `in progress`, `done`.

| # | Branch | Step | Status |
|---|--------|------|--------|
| 01 | `step/01-card-screen` | Card screen redesign | todo |
| 02 | `step/02-content-version` | `contentVersion` counter | todo |
| 03 | `step/03-word-source` | Pick a real German frequency list | todo |
| 04 | `step/04-dictionary-merge` | Merge frequency list with a dictionary | todo |
| 05 | `step/05-word-list-editorial` | Editorial pass over the 1000 words | todo |
| 06 | `step/06-sentence-pilot` | Example sentence pilot (50 words) | todo |
| 07 | `step/07-sentences` | Remaining example sentences | todo |
| 08 | `step/08-persistence` | Persistence performance | todo |
| 09 | `step/09-swipe-undo` | Swipe gesture + undo | todo |
| 10 | `step/10-summary-screen` | Summary screen redesign | todo |
| 11 | `step/11-session-end` | Session end screen | todo |
| 12 | `step/12-cleanup` | Cleanup | todo |

---

## 01 — Card screen redesign

Implement screens 1 and 2 of `docs/DESIGN.md`: tap-to-flip, box badge and `n / 10` session
indicator at the top, word + speaker on the front, meaning + example sentence box on the back.
The sentence box is hidden entirely when `exampleSentence` is nil. Keep the ✓/✗ buttons.

Out of scope: swipe (step 09), any ViewModel or data-layer behaviour change.
Touch `ContentView.swift` and new view files only.

## 02 — `contentVersion` counter

Add `"contentVersion": 1` to `thousand/de.json`. Replace the `InitialCardsAdded: Bool`
UserDefaults flag in `thousandApp.swift` with `seededContentVersion: Int`. On launch, if the
bundled version is higher than the stored one, wipe Realm and re-seed from scratch, then store
the new version.

No progress preservation, no matching, no user-facing notice — see `CLAUDE.md`.

## 03 — Pick a real German frequency list

Source a lemmatised German frequency list with a licence that allows commercial redistribution.
Leading candidate: Leipzig Corpora Collection (CC BY 4.0). Extract the top 1000 lemmas.
Record the licence and the attribution text the app will have to show.

Deliverable: the raw list plus a short note on why this source was chosen.
No app code changes in this step.

## 04 — Merge frequency list with a dictionary

Write a script (Python, kept in `tools/`) that joins the frequency list with a Wiktionary-derived
German→English dictionary. For each word, output the candidate English senses, the part of
speech, and the article for nouns.

Deliverable: `de_draft.json` plus a report of words that found no dictionary match.

## 05 — Editorial pass over the 1000 words

Go through `de_draft.json` in batches of 100, presenting each batch to the user for approval.
For every word pick exactly one, most common English sense. Prefix nouns with their article
(`das Haus`), put verbs in the infinitive (`gehen`).

Deliverable: the final `thousand/de.json`, same schema as today plus `contentVersion`.

## 06 — Example sentence pilot

Write a validation script (`tools/`) that checks each sentence: the target word appears in it,
it is at most 5 words long, and every word in it is either an earlier-ranked word or a member of
a small core allow-list (~40 basic words needed to form any sentence at all).

Then write sentences for the first 50 words and present them to the user before going further.
German only, A1 level, no English translation.

## 07 — Remaining example sentences

Same rules as step 06, in batches of 50, each batch passing the validation script.
Bump `contentVersion` so the new sentences actually appear on device.

## 08 — Persistence performance

`RealmCardStore.saveBoxes` currently deletes every box and rewrites all 1000 cards on every
answer, called with `try!` on the main thread. Make it incremental, remove the `try!`, and move
it off the main thread. Needed before swipe, or every gesture will stutter.

## 09 — Swipe gesture + undo

Add swipe as a shortcut on top of the ✓/✗ buttons: swipe toward ✓ is correct, toward ✗ is
incorrect. The buttons stay. Ship undo in the same step — a mis-swipe must be recoverable.

## 10 — Summary screen redesign

Screen 3 of `docs/DESIGN.md`. Headline `mastered` metric over 1000, then five bars scaled
relative to each other, animating in on appear. Replaces the current `total: 1000` bars.

## 11 — Session end screen

Screen 4 of `docs/DESIGN.md`, as its own view. Requires a session summary in the ViewModel
(cards reviewed, moved up, to review). Today the app falls back to the summary screen, which
conflates three different moments.

## 12 — Cleanup

- `Word.languageCode` is seeded as `""` in `thousandApp.swift`.
- Meanings are looked up with `NSLocalizedString(englishWord)`, so duplicate English words
  collide as translation keys.
- The test files are entirely commented out; restore what still applies.
