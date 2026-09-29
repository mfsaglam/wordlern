# Plan — gamify / UI overhaul

Target branch for all of this: `feature/gamify`. One step = one branch = one task.
Status values: `todo`, `in progress`, `done`.

`Model` is a suggestion, not a rule: steps needing design or language judgement are worth the
bigger model, mechanical steps are not.

| # | Branch | Step | Model | Status |
|---|--------|------|-------|--------|
| 01 | `step/01-card-screen` | Card screen redesign | opus | done |
| 02 | `step/02-content-version` | `contentVersion` counter | sonnet | todo |
| 03 | `step/03-word-source` | Pick a real German frequency list | opus | todo |
| 04 | `step/04-dictionary-merge` | Merge frequency list with a dictionary | sonnet | todo |
| 05 | `step/05-word-list-editorial` | Editorial pass over the 1000 words | opus | todo |
| 06 | `step/06-sentence-pilot` | Example sentence pilot (50 words) | opus | todo |
| 07 | `step/07-sentences` | Remaining example sentences | opus | todo |
| 08 | `step/08-swiftdata` | Replace Realm with SwiftData | opus | done |
| 09 | `step/09-swipe-undo` | Swipe gesture + undo | opus | todo |
| 10 | `step/10-summary-screen` | Summary screen redesign | opus | todo |
| 11 | `step/11-session-end` | Session end screen | opus | todo |
| 12 | `step/12-cleanup` | Cleanup | sonnet | todo |

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
bundled version is higher than the stored one, wipe the SwiftData store and re-seed from
scratch, then store the new version.

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

## 08 — Replace Realm with SwiftData

Done out of order, ahead of steps 02–07: `realm-core 14.13.1` does not compile against the
iOS 27 SDK (`'is_pod' cannot be specialized`), which blocked every build.

Realm is gone — package reference, `RealmBox/RealmCard/RealmWord/RealmCardStore` and the two
`toRealm…` extensions with it. `StoredBox`/`StoredCard` are the SwiftData models; cards are flat
and point at their box by index, so moving a card between boxes is one field write.

This absorbs the old "persistence performance" step: `saveBoxes` no longer deletes and rewrites
all 1000 cards, `try!` is gone, and writes run on a background `@ModelActor`, chained so they
land in call order. The `CardStore` protocol and `WordViewModel` are untouched.

`fetchBox(byId:)`, `updateBox` and `deleteBox` are dead API — nothing but the preview stub
calls them. See step 12.

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
- Meanings are looked up with `NSLocalizedString(englishWord)`, but `Localizable.xcstrings`
  only holds the eight UI strings — no word meanings. So the call is a no-op passthrough today,
  and duplicate English words would collide as keys if it were ever populated. Decide whether
  word meanings are localised at all, and drop the mechanism if not.
- The test files are entirely commented out; restore what still applies.
  (`SwiftDataCardStoreTests` from step 08 is live and should stay.)
- `CardStore.fetchBox(byId:)`, `updateBox` and `deleteBox` have no callers. Drop them.
