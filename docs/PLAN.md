# Plan — gamify / UI overhaul

Target branch for all of this: `feature/gamify`. One step = one branch = one task.
Status values: `todo`, `in progress`, `done`.

`Model` is a suggestion, not a rule: steps needing design or language judgement are worth the
bigger model, mechanical steps are not.

| # | Branch | Step | Model | Status |
|---|--------|------|-------|--------|
| 01 | `step/01-card-screen` | Card screen redesign | opus | done |
| 02 | `step/02-content-version` | `contentVersion` counter | sonnet | done |
| 03 | `step/03-word-source` | Pick a real German frequency list | opus | done |
| 04 | `step/04-dictionary-merge` | Merge frequency list with a dictionary | sonnet | done |
| 05 | `step/05-word-list-editorial` | Editorial pass over the 1000 words | opus | done |
| 06 | `step/06-sentence-pilot` | Example sentence pilot (50 words) | opus | done |
| 07 | `step/07-sentences` | Remaining example sentences | opus | done |
| 08 | `step/08-swiftdata` | Replace Realm with SwiftData | opus | done |
| 09 | `step/09-swipe-undo` | Swipe gesture + undo | opus | done |
| 10 | `step/10-summary-screen` | Summary screen redesign | opus | todo |
| 11 | `step/11-session-end` | Session end screen | opus | todo |
| 12 | `step/12-cleanup` | Cleanup | sonnet | todo |
| 13 | `step/13-attribution` | Attribution / About screen | sonnet | todo |

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

Done: `tools/de_frequency_top2000.tsv`, built by `tools/build_frequency_list.py` from three
Leipzig corpora (news / web / Wikipedia, ~13.3M tokens). `docs/WORDLIST.md` records the
licence, the attribution the app has to show, why the alternatives were rejected, and the
defect list that step 05 has to work through.

## 04 — Merge frequency list with a dictionary

Write a script (Python, kept in `tools/`) that joins the frequency list with a Wiktionary-derived
German→English dictionary. For each word, output the candidate English senses, the part of
speech, and the article for nouns.

Input is `tools/de_frequency_top2000.tsv` from step 03. The dictionary side is
`https://kaikki.org/dictionary/German/kaikki.org-dictionary-German.jsonl` — the wiktextract
dump of English Wiktionary's German entries, 1.0 GB, one JSON object per sense, carrying the
English gloss, the POS and the noun gender. Stream it, do not load it; keep it out of the repo.

Licence: Wiktionary is CC BY-SA, which is the share-alike this project dodged for the
frequency list. The dump is therefore a *candidate generator only* — step 05 picks and writes
the final one-sense gloss by hand, so what ships is the editorial choice rather than a copy
of Wiktionary. Credit Wiktionary in step 13 regardless; it is free to do and settles the
question.

Deliverable: `de_draft.json` plus a report of words that found no dictionary match.

Done: `tools/build_dictionary_draft.py` streams the kaikki dump and joins it with
`de_frequency_top2000.tsv`. `tools/de_draft.json` has candidate glosses, POS and (for nouns)
the article for all 1000 words — 991 matched directly, 9 fell back to no candidates (frequency-
list stems like `jed`, `besonder`, `beid`, `zuminde`, and non-German corpus noise: `of`, `The`,
`de`, `New`, `Thoma`). `tools/de_draft_report.md` lists the 9 misses for step 05 to resolve by
hand. The kaikki dump itself (1GB) is not committed.

## 05 — Editorial pass over the 1000 words

Go through `de_draft.json` in batches of 100, presenting each batch to the user for approval.
For every word pick exactly one, most common English sense. Prefix nouns with their article
(`das Haus`), put verbs in the infinitive (`gehen`).

Deliverable: the final `thousand/de.json`, same schema as today plus `contentVersion`.

Done: `tools/de_editorial.tsv` is the hand-written result, `tools/editorial.py` turns it into
`thousand/de.json` at `contentVersion` 2. 1000 words, every one with a single English gloss,
nouns carrying their article and verbs in the infinitive.

55 of the draft's 1000 entries were thrown away, and the list was filled back up with 51 words
from ranks 1001–1057 of the frequency list plus `Sie` and three weekdays. What went: corpus
noise (`of`, `The`, `de`, `New`, `A`, `m`, `II`), initialisms and organisation names
(`FC`, `SPD`, `EU`, `AG`, `Union`), every proper noun including `Deutschland`, personal names,
lemmatiser stems (`ander`, `jed`, `beid`, `zuminde`, `viert` …, restored to their citation
forms instead of dropped), bare participles (`gefunden`, `gebracht`, `verloren`, `gebaut` …)
and three lemmatiser slips where the stem is a rare word the corpus never used —
`feilbieten`, `belieben`, `fällen`.

Three calls from the `docs/WORDLIST.md` defect list went the way that file recommended:
proper nouns are all gone, `sie` and `Sie` are two cards, and the four missing weekdays were
added against frequency (`Dienstag` is rank 1836 in the corpus) because teaching five of
seven is worse than teaching all of them. The preposition contractions (`im`, `am`, `zum`,
`zur`, `vom`, `beim`, `ins`) were kept — they are worth a card each. Where two German words
would have collided on one English gloss, the rarer one was given a narrower gloss
(`schon` = "already" vs `bereits` = "already (formal)"); `build` fails if any collision is
left.

## 06 — Example sentence pilot

Write a validation script (`tools/`) that checks each sentence: the target word appears in it,
it is at most 5 words long, and every word in it is either an earlier-ranked word or a member of
a small core allow-list (~40 basic words needed to form any sentence at all).

Then write sentences for the first 50 words and present them to the user before going further.
German only, A1 level, no English translation.

Done: `tools/validate_sentences.py` enforces the three rules, comparing lemmas with simplemma
(`ist` counts as `sein`, `Kinder` as `Kind`), so the same `.venv` as the frequency list is
needed. `tools/de_sentences.tsv` holds the first 50 sentences, all passing.

The allow-list ended up at ~50 words rather than 40: rank 3 has two earlier words to build
from, so the floor has to carry the pronouns, `sein/haben/werden`, ten everyday nouns and nine
verbs. Two sentences are stilted because the natural wording is not unlocked yet — `an` gets
"an dem Tisch" because `am` is rank 27, and `zur` gets "zur Stadt" because Arbeit and Schule
are not in the list. `sie`/`Sie` are checked case-sensitively and must appear mid-sentence,
where the capital still carries information.

No app code: writing the sentences into `de.json` and bumping `contentVersion` is step 07.

## 07 — Remaining example sentences

Same rules as step 06, in batches of 50, each batch passing the validation script.
Bump `contentVersion` so the new sentences actually appear on device.

The pipeline half is done ahead of the sentences: `WordToLearn` carries an optional
`exampleSentence`, seeding passes it through instead of the hardcoded `nil`, and
`editorial.py build` folds `de_sentences.tsv` into `thousand/de.json` at `contentVersion` 3,
keyed by the shipped rank and refusing to attach a sentence written for a different word.
A word with no sentence yet ships without the field, so the card draws without the box.

Done: `tools/de_sentences.tsv` now carries all 1000 sentences, written 50 at a time and
revalidated after every batch. `thousand/de.json` is at `contentVersion` 3 with an example
sentence on every word.

Four words needed an escape hatch in the validator. simplemma lemmatises their citation form
to something their own inflected forms never reach — `gesamt` to `samen`, `vergangen` to
`vergehen`, `folgend`/`kommend` to the plain verb — so the only token the lemma rules would
accept reads badly in an A1 sentence. `INFLECTIONS` in `validate_sentences.py` lists the four
declension paradigms by hand; each set counts as the target word and as an allowed token, for
that target word only. The sentences are the natural attributive ones ("Das vergangene Jahr
war gut.").

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

Done: `CardView` takes an optional `onSwipe`; a drag past 96pt flies the card off in 0.22s and
answers, anything shorter springs back. While the finger is down the card carries the answer
colour — a green or red border plus the matching ✓/✗ glyph, fading in with the distance. The
✓/✗ buttons are untouched.

The card is keyed on the card's id, because the usual flow is flip-then-swipe: without the key
the next card inherits the previous card's flipped view and animates back to its front. With it
every card is built fresh, front up. Its arrival is a fade from 96% scale over a ~0.3s spring —
enough to read as a new card, too small to be a choreography. The answered card leaves with no
transition at all: it is already off screen, and a fading exit gave it time to snap its drag
offset back to centre — the old card visibly flashing in before the new one faded up.

`Haptics` holds the four taps, primed generators so the first one of a drag is not late. One per
thing the user did, at the moment they did it: a selection tick as the drag crosses the commit
distance and again if it comes back under, then the answer on release — `.rigid` for correct,
`.soft` for incorrect, told apart by texture rather than strength so neither is a reward or a
reprimand. The ✓/✗ buttons give the same answer tap; undo gets a lighter one. Nothing fires on
the new card's arrival: it lands 0.22s after the answer tap, and two taps per card is chatter.

Undo is one level deep and lives only inside a session. `LeitnerSystem` has no reverse of
`updateCard`, so `WordViewModel` snapshots `allBoxes` plus the session index before each answer
and restores it through `loadBoxes`. The control is a small muted arrow left of the box badge,
per the user's call — the ✓/✗ row stays exactly as `docs/DESIGN.md` specifies. It appears only
when there is an answer to take back, and the last card of a session clears it, since finishing
leaves the card screen.

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

## 13 — Attribution / About screen

Not optional: CC BY is a licence *condition*, so the app may not ship the Leipzig-derived
word list without carrying the notice. Step 03 established the debt, this pays it.

A plain About screen reachable from the summary screen. Content:

- the Leipzig copyright notice and CC BY line, verbatim from `docs/WORDLIST.md`
- the Goldhahn/Eckart/Quasthoff citation Leipzig asks for
- Wiktionary (CC BY-SA) as the source the meanings were drafted from, per step 04
- `LeitnerSwift` and any other package licences

Keep it one scrollable `Text` stack with a `#Preview`. No web view, no bundled HTML.
