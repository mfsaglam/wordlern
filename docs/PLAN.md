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
| 10 | `step/10-summary-screen` | Summary screen redesign | opus | done |
| 11 | `step/11-session-end` | Session end screen | opus | done |
| 12 | `step/12-cleanup` | Cleanup | sonnet | done |
| 13 | `step/13-attribution` | Attribution / About screen | sonnet | done |
| 14 | `step/14-file-layout` | Group the source files by screen | sonnet | done |
| 15 | `step/15-launch-on-summary` | Launch on the summary screen | sonnet | done |
| 16 | `step/16-how-it-works` | "How it works" screen | opus | done |
| 17 | `step/17-voice-quality` | Pick the best installed German voice | sonnet | done |
| 18 | `step/18-retired-words` | Retired words must keep counting as mastered | sonnet | done |
| 19 | `step/19-autoplay-word` | Speak the word once when a card appears | sonnet | done |
| 20 | `step/20-tap-to-copy` | Tap word / meaning / sentence to copy | sonnet | done |
| 21 | `step/21-privacy-manifest` | Privacy manifest | sonnet | done |
| 22 | `step/22-nothing-due` | Say so when nothing is due | sonnet | done |
| 23 | `step/23-daily-reminder` | Daily reminder notification | opus | done |
| 24 | `step/24-progress-snapshot` | App Group + progress snapshot | sonnet | done |
| 25 | `step/25-widget` | Summary widget | opus | todo |
| 26 | `step/26-lock-screen-widget` | Lock screen widgets | sonnet | todo |

Step 14 was added and done after 09, out of numeric order: the flat `thousand/` directory had to be
sorted before 10 and 11 pour new screen files into it.

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

Done: `languageCode` now comes from `languageData.languageCode` ("de") instead of `""`. Word
meanings are not localized — `Localizable.xcstrings` never carried word-meaning keys, so the
`NSLocalizedString` call was always a no-op passthrough to `entry.englishWord`; the call is
gone and `meaning` is assigned directly. `thousandTests.swift`'s old test targeted a
`CacheService`/`LeitnerSystemProtocol` pair that no longer exists; replaced with a test of the
same intent (cached boxes load into the Leitner system on init) against the current `CardStore`
interface. The three unused `CardStore` methods are dropped from the protocol and both
conformances (`SwiftDataCardStore`, `AnyCardStore`).

## 13 — Attribution / About screen

Not optional: CC BY is a licence *condition*, so the app may not ship the Leipzig-derived
word list without carrying the notice. Step 03 established the debt, this pays it.

A plain About screen reachable from the summary screen. Content:

- the Leipzig copyright notice and CC BY line, verbatim from `docs/WORDLIST.md`
- the Goldhahn/Eckart/Quasthoff citation Leipzig asks for
- Wiktionary (CC BY-SA) as the source the meanings were drafted from, per step 04
- `LeitnerSwift` and any other package licences

Keep it one scrollable `Text` stack with a `#Preview`. No web view, no bundled HTML.

Done: `AboutScreen.swift` in `Progress/` — three sections (word list, word meanings, software),
all legal text as `Text(verbatim:)` so translation can never touch it. Reached from a quiet
`info.circle` button in the top-trailing corner of `SummaryScreen`, opening as a sheet from
`ContentView`. `LeitnerSwift` is the only third-party dependency the app ships (MIT, the user's
own package); it is credited alongside Leipzig and Wiktionary.

## 14 — Group the source files by screen

Added after 09, done before 10: all 14 Swift files sat flat in `thousand/`, and steps 10 and 11
were about to add a screen each.

Grouped by screen rather than by layer — `App/`, `Card/`, `Progress/`, `Persistence/`, `Support/`
— so everything one screen needs sits together, including its view model. A `Views/` folder holding
seven files would flatten back out the moment the summary and session-end screens landed. Step 10
gets `Summary/`, step 11 `SessionEnd/`.

`Assets.xcassets`, `Preview Content`, `Localizable.xcstrings` and `de.json` stayed at the target
root: the first two are where Xcode expects them and `Preview Content`'s path is baked into the
`DEVELOPMENT_ASSET_PATHS` build setting.

No code changed — folders carry no meaning in Swift, so no import needed touching. The moves were
`git mv`, and `project.xcproj`'s flat file list became nested `group` nodes by hand, since this
project format does not pick files up off disk.

## 15 — Launch on the summary screen

Today `ContentView.onAppear` calls through to `fetchNextSet()`, so opening the app drops the user
straight into a review session. Opening the app should land on `SummaryScreen`; a session starts
only when the user taps `start session`.

Scope: `WordViewModel.onAppear` and `ContentView` only. Do not change how a session behaves once
started, and do not touch the session-end flow — returning from `SessionEndScreen` already lands
on the summary.

Watch for: `onAppear` fires again when the About sheet is dismissed, so it must be idempotent and
must not restart a session that is in progress.

## 16 — "How it works" screen

The app never explains the Leitner system. Users have no way to learn why a word came back, what
`box 3` means, or that the `mastered` figure on the summary screen is boxes 3+4+5 combined.

One screen, reachable from a quiet `questionmark.circle` button on `SummaryScreen`, presented as
a sheet next to the existing About sheet. Sections:

- What the five boxes are, and why the interval grows as a card moves up.
- What a correct answer does (card moves up one box) and what a wrong answer does.
- What `mastered` counts.
- Pronunciation: the app uses the best German voice installed on the device, and a better one can
  be downloaded in Settings. Ships with step 17's copy and button — write the section, leave the
  button wiring to 17 if 17 is not done yet.

Plain `Text` stack with a `#Preview`, same shape as `AboutScreen`. No onboarding flow, no
multi-page tutorial, no illustrations. It may be shown automatically on first launch at most once.

## 17 — Pick the best installed German voice

`GermanSpeaker` in `Card/SpeakerButton.swift` asks for `siri_female_de-DE_compact`, which is
Apple's lowest-quality variant, and falls back to any `de` voice. Instead, enumerate
`AVSpeechSynthesisVoice.speechVoices()`, keep the German ones, and pick the highest
`AVSpeechSynthesisVoiceQuality` available (premium > enhanced > default).

Also add the button behind step 16's pronunciation section that sends the user to Settings so they
can download a better voice.

Caveat to respect: there is no public deep link to Settings → Accessibility → Spoken Content →
Voices. `UIApplication.openSettingsURLString` only opens this app's own settings page, and
`App-Prefs:` style URLs are private API and risk App Store rejection. So the section must spell the
path out in words; the button is a convenience that opens Settings, not a shortcut to the exact
pane. Do not ship a private URL scheme.

Done: `GermanSpeaker` drops the hardcoded `siri_female_de-DE_compact` identifier and instead
filters `AVSpeechSynthesisVoice.speechVoices()` to German voices, picking the highest
`AVSpeechSynthesisVoiceQuality` (premium > enhanced > default), re-read on every `speak(_:)`
call so a voice downloaded mid-session is picked up without a relaunch. `ContentView` wires
`HowItWorksScreen`'s `onOpenSettings` to `UIApplication.openSettingsURLString`, per the caveat
above — no private URL scheme.

Also added, at the user's request after the step's original scope: the Pronunciation section
now shows which voice and quality tier is currently in use (`GermanSpeaker.currentVoiceDescription`),
so "a better one can be downloaded" has something concrete to compare against. New
`Localizable.xcstrings` key: `Currently using`.

## 18 — Retired words must keep counting as mastered

Found while writing step 16's copy. `LeitnerSystem.updateCard` removes a card from the system
outright when it is answered correctly in the last box — it is retired, not promoted. So box 5's
count drops, and because `masteredCount` is boxes 3+4+5, the `mastered` headline goes *down* when
the user does the single best thing they can do. The session-end screen's `masteredAfter` has the
same problem.

Scope: the app side only — `LeitnerSwift` is not to be edited (see `CLAUDE.md`). Options to weigh:
count retired cards by subtracting the live total from the seeded word count, or track retirements
in the store. Decide in the step, and keep the summary screen's five bars as they are.

Done: went with subtracting the live total from the seeded word count — no new persistence, and it
stays correct for free across undo (which just restores `allBoxes`). `thousandApp` reads
`de.json`'s word count at every launch, re-seed or not, and hands it to `WordViewModel` as
`totalWordCount`. `WordViewModel.retiredCount` is `totalWordCount` minus the live sum of
`progress`; `masteredWordCount` is boxes 3–5 plus `retiredCount`, and both session-start and
session-end figures use it instead of the bare `masteredCount(in:)`. `SummaryScreen` gets a
`retiredCount` parameter it adds to its own headline; the five per-box bars are untouched, as
asked. No change to `SessionEndScreen` — it already took its numbers from the view model.

## 19 — Speak the word once when a card appears

Reaching for the speaker button on every card is friction. When a card's front appears, speak the
word once by itself.

Scope: `CardScreen` and `GermanSpeaker` in `Card/SpeakerButton.swift`. The speaker buttons stay —
auto-play is in addition to them, not a replacement, and the sentence on the back is never spoken
automatically.

Rules:

- Exactly once per card. `CardScreen` already keys its transition on `cardID`, so drive the
  playback off that (`.task(id: cardID)`) — flipping the card, undoing and redrawing, or returning
  from a sheet must not make it speak again.
- Undo steps back to a different `cardID`, so that card speaks again. That is correct: the user is
  seeing it fresh.
- Never override the ringer switch. Do not set the audio session to `.playback`. Audio the user did
  not ask for must stay silent when the phone is muted.
- Set the audio session category to `.ambient` before speaking. The default `.soloAmbient` stops
  whatever the user was already listening to; with auto-play that would kill their music on every
  single card, which a manual button press never did.

Open question, decide while building: there is no settings screen, so shipping this means the user
cannot turn it off. Ship it without a toggle first and see whether it is annoying in practice —
adding a settings screen for one switch is worse than the problem it solves. If it does turn out to
need one, that is its own step.

## 20 — Tap word / meaning / sentence to copy

Tapping the German word on the front, the English meaning on the back, or the example sentence on
the back copies that text to the clipboard. No confirmation UI beyond what the tap already implies
is out of scope for this step unless it turns out silent copying is confusing to test.

Scope: `Card/CardView.swift` and `Card/SentenceBox.swift` only. The front and back of the card
already flip on any tap via the card-level `onTapGesture`; the copy tap has to sit on the specific
`Text` and take priority over that without disabling the flip elsewhere on the card.

Done: `.onTapGesture` added directly to the German word `Text` (front), the English meaning `Text`
(back), and the token `HStack` in `SentenceBox` (whole sentence, not per-token). Sitting on the
specific view rather than the card wins the hit test, so the rest of the card still flips as
before. Each writes to `UIPasteboard.general` and fires a new `Haptics.copied()` (reuses the
`undo` generator's `.light` style).

It turned out silent copying was confusing to test, per the option the step left open. `CardView`
now shows a small "Copied" pill (`.overlay(alignment: .top)`, added after the flip's
`.rotation3DEffect` so it stays upright through the animation instead of mirroring with the card),
fading in on any of the three taps and out ~1.1s later; `SentenceBox` reports its own copy up
through a new `onCopy` closure so all three routes through one pill instead of three.

Also found while testing: `.textSelection(.enabled)` (kept from step 01, and worth keeping — the
user wants the long-press selection, not just the tap-to-copy) left a selection stuck on screen
with no way to clear it, because front and back never unmount — only their opacity toggles — so
the underlying selection host stays alive across a flip. Both selectable `Text` views are now
keyed `.id(isFlipped)`, forcing a fresh instance whenever the face changes and dropping whatever
selection the previous face was left in.

One more round: the example sentence itself was tap-to-copy only, not selectable, unlike the word
and meaning. `SentenceBox` renders it as one `Text` per token so the target word can sit in its own
accent-tinted pill (`docs/DESIGN.md`'s highlight, kept as-is rather than swapped for a selection-
friendlier style) — `.textSelection(.enabled)` on the token `HStack` covers the whole row, letting
a long-press drag select across tokens as one continuous span instead of one word at a time.
`SentenceBox`'s call site in `CardView` gets the same `.id(isFlipped)` treatment as the two `Text`
views, for the same reason.

## 21 — Privacy manifest

The app has no `PrivacyInfo.xcprivacy`, but it calls `UserDefaults` in `App/thousandApp.swift`
(`seededContentVersion`) and `Card/WordViewModel.swift`. `UserDefaults` is on Apple's
required-reason API list, so an App Store submission without a manifest declaring it is rejected.

Add `thousand/PrivacyInfo.xcprivacy` and register it as a resource of the `thousand` target.
Contents:

- `NSPrivacyAccessedAPITypes`: `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`
  (access to data stored by this app only).
- `NSPrivacyCollectedDataTypes`: empty. The app collects nothing — no analytics, no crash
  reporter, no network calls at all.
- `NSPrivacyTracking`: `false`. No `NSPrivacyTrackingDomains`.

Check `LeitnerSwift` while here: a dependency ships its own manifest, and if it does not use any
required-reason API there is nothing to do, but confirm rather than assume.

Remember `project.xcproj` is the JSON project format — a new file has to be added to the file
list and the resources phase by hand, it is not picked up off disk.

Done: `thousand/PrivacyInfo.xcprivacy` declares `NSPrivacyAccessedAPICategoryUserDefaults` with
reason `CA92.1`, empty `NSPrivacyCollectedDataTypes`, and `NSPrivacyTracking` false with no
tracking domains. Registered as a `thousand/resources` entry in `project.xcproj`, alongside
`Localizable.xcstrings` and `de.json`. `LeitnerSwift`'s checked-out source (under
`SourcePackages/checkouts` in DerivedData) carries no privacy manifest of its own and uses none
of the required-reason APIs (`UserDefaults`, `FileManager` timestamps, etc.), so there is
nothing for it to declare. `WordViewModel.swift`'s `UserDefaults` mention that motivated this
step is a stale comment, not a call — the only real usage is `thousandApp.swift`'s
`seededContentVersion`.

## 22 — Say so when nothing is due

Tapping `start session` when no card is due does nothing visible. `fetchNextSet()` gets an empty
list, `loadNextCard()` correctly declines to show a `0 cards reviewed` celebration, and the user is
left on the summary screen with no feedback. This happens every day, by design of the Leitner
system — it is the normal state, not an edge case.

On `SummaryScreen`:

- Show how many cards are due right now, next to or under the button.
- When that count is zero, disable `start session` and say when the next card comes due —
  "next review in about 5 hours". Derive it from the earliest `lastReviewedDate + reviewInterval`
  across the boxes; expose it from `WordViewModel` as a date, and let the view do the formatting.
- Keep it one quiet line. No illustration, no empty-state artwork.

Also in this step: delete the stray `print(dueCards.count)` at `WordViewModel.swift:123`.

Out of scope: changing the session size, changing what `dueForReview` returns.

Done: `WordViewModel.dueCount` counts cards across every box whose `nextReviewDate` has passed —
the same check `LeitnerSystem.dueForReview` makes internally, but counting instead of throwing
when there are none. `nextReviewDate` is nil once `dueCount` is positive, otherwise the earliest
`nextReviewDate` among boxes that still hold cards. `SummaryScreen` shows "N cards due" under the
box bars when `dueCount > 0`; at zero it disables `start session` (50% opacity) and shows "next
review …" instead, formatted by `RelativeDateTimeFormatter` in the view, per the view model only
exposing a date. The stray `print(dueCards.count)` in `fetchNextSet()` is gone.

## 23 — Daily reminder notification

Spaced repetition only works if the user comes back, and nothing in the app asks them to. Add a
local notification — `UNUserNotificationCenter` only, no server, no push entitlement.

- Ask for permission after the user finishes their first session, from `SessionEndScreen`. Never
  at launch: a permission prompt before the app has shown its worth gets denied, and a denial is
  permanent unless the user digs into Settings.
- Schedule one notification for the moment the next card comes due — the same date step 22
  computes. Reschedule it whenever the app goes to the background, so it always reflects the
  current state.
- Do not schedule a fixed daily repeat. A reminder that fires when nothing is due trains the user
  to ignore it.
- Cancel and reschedule rather than stacking requests; there should never be more than one pending.
- No in-app toggle. iOS Settings is the off switch, and a settings screen for one boolean is not
  worth it — same call as step 19.

Copy should say what is waiting, not nag: "12 words are ready to review".

Done: `ReminderScheduler` (in `Support/`) owns the whole thing — `requestAuthorization()` and
`reschedule(for:)`, both static, both against `UNUserNotificationCenter.current()` only. One
identifier, `next-review`, removed before every add, so a second request can never pile up.
`WordViewModel.nextReview` pairs step 22's `nextReviewDate` with the number of cards that will be
waiting at that moment, as a plain `NextReview` value, so the scheduler never touches the Leitner
system. `SessionEndScreen` takes an `onReminderOpportunity` closure and calls it 1.2s after the
screen lands, past the check and the bar animation; `ContentView` wires it to ask for permission
and then schedule at once, and reschedules again on `scenePhase == .background`. `reschedule`
declines to schedule when authorization is not granted, and a nil `nextReview` — cards already due,
or an empty list — just clears the pending request: a user with cards waiting is not reminded of
work they can do right now, and gets a reminder again as soon as they next finish a session.

## 24 — App Group + progress snapshot

Groundwork for the widget, app side only. Nothing visible changes; the step is done when the
snapshot file exists on disk with the right numbers in it.

A widget extension cannot read the app's private container, so the two need an App Group. The
widget, however, only needs six numbers — it does not need the cards. So **do not move the
SwiftData store into the group.** Leave `ModelContainer(for: StoredBox.self, StoredCard.self)` in
`thousandApp.swift` exactly where it is, and instead write a small snapshot the widget can read:

```
struct ProgressSnapshot: Codable {
    let boxCounts: [Int]      // five entries
    let mastered: Int         // boxes 3+4+5, matching SummaryScreen
    let total: Int            // 1000
    let dueCount: Int
    let nextDue: Date?
    let updated: Date
}
```

Written as JSON to the App Group container. Rewrite it whenever progress changes — after each
answer and at the end of a session — from the same values `SummaryScreen` already shows, so the
two can never disagree.

Why not share the store: a widget extension gets a much smaller memory budget than the app, and
standing up SwiftData inside it means the model types, the store code and every future schema
change have to be shared with a second target. Six numbers in a JSON file cost nothing and cannot
break the app if the widget is ever removed.

Caveat worth checking first: an App Group identifier has to be registered on the Apple developer
account and the provisioning profile regenerated. If that is not available, this step stalls — find
out before writing code. Use `group.` + the app's bundle identifier.

New file: `thousand/Support/ProgressSnapshot.swift`, plus an entitlements file for the app target
(none exists today). `project.xcproj` is the JSON project format — the entitlements file has to be
wired into the build settings by hand.

Done: `group.com.mfsaglam.thousand` registered on the developer account and the app's App ID; the
App Group capability was added through Xcode's own Signing & Capabilities UI, which wrote
`thousand/thousand.entitlements` (the `com.apple.security.application-groups` array) and updated
`project.xcproj`'s build settings (`CODE_SIGN_ENTITLEMENTS`, `REGISTER_APP_GROUPS`) by hand for this
project format — carried over from an in-progress state on `feature/gamify` onto this step's branch.

`ProgressSnapshot` is a plain `Codable` struct matching the plan exactly, with a `write()` method
that resolves the App Group container via `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`
and does nothing if it is unavailable — a stale widget is not worth crashing the app over.
`WordViewModel.writeProgressSnapshot()` builds one from the same `progress`, `masteredWordCount`,
`totalWordCount`, `dueCount` and `nextReviewDate` the summary screen already reads, so the two can
never disagree. It runs at the end of `saveProgress()` (after every answer and every undo, since
both call it) and once at `init`, so the file exists on disk from first launch rather than only
after the first answer.

## 25 — Summary widget

A widget extension target with one widget: the summary screen, at a glance, on the home screen.
The point is ambient presence — seeing the progress bar sitting there is the nudge to come back.

- New target, `WordLernWidget`, embedded in the app. This is the fiddly part: in the JSON project
  format the target, its build phases and the embed-extension step all have to be written by hand.
  Do this first and get an empty widget rendering before designing anything.
- The timeline provider reads the JSON from step 24. No SwiftData, no `LeitnerSwift` import.
- `systemSmall`: the mastered count over 1000, a single progress bar, and the due count.
- `systemMedium`: the same, plus the five box bars from `ProgressBars`.
- Call `WidgetCenter.shared.reloadAllTimelines()` from the app wherever the snapshot is written.
- Add one timeline entry at `nextDue` so the due count refreshes itself when cards come due, even
  if the app is not opened.
- Tapping the widget opens the app, which lands on the summary screen already (step 15). No
  `widgetURL` and no deep-link routing needed.

Constraints to design within: widgets do not animate, so the bars are static — the appear
animation from step 10 does not apply. No audio, no interaction in this step. Text is small; do
not try to fit all five box labels into `systemSmall`.

Add a widget section to `docs/DESIGN.md` describing what shipped.

Done: `WordLernWidget`, an `app-extension` target written into `project.xcproj` by hand, embedded
by an `Embed Foundation Extensions` copy phase on the app with
`bundle-base-path: plugins-directory`. Three things about the JSON project format that cost time
and are worth writing down.

A build phase reference in `target-membership` is `<target>/<kind>`, and for kinds a target can
hold more than one of — `copy` — a third component disambiguates by the phase's `name`:

```
"target-membership": [
  { "build-phase": "thousand/copy/Embed Foundation Extensions", "code-sign-on-copy": true },
]
```

Bare `thousand/copy` fails to load with "Could not uniquely resolve the build phase name",
*even when the target has only one copy phase*, so the phase must be named. Object ids cannot be
referenced at all. `code-sign-on-copy` only survives on that object form of a membership entry,
not as a sibling of `path`.

And `xcprojformatter` is not a trustworthy validator: it rejects the `copy/<name>` form that
Xcode itself requires, silently drops keys it does not recognise, and `--update` deletes
`project.xcworkspace/xcshareddata/swiftpm/Package.resolved`. Use
`xcodebuild -list -project thousand.xcodeproj` instead — it loads the project and reports exactly
the error Xcode would, without building anything.

`ProgressSnapshot.swift` gained a `read()` and is compiled into both targets, as is
`ProgressBars.swift`, so the widget's bars are literally the summary screen's `Bar` and
`BoxPalette`. `Localizable.xcstrings` is a resource of both targets. The timeline is two entries
at most — now, and `nextDue` — with policy `.never` when there is no future `nextDue`, since
`WordViewModel.writeProgressSnapshot()` now calls `WidgetCenter.shared.reloadAllTimelines()` on
every write. The entry at `nextDue` carries `dueSinceSnapshot` and shows `review ready` rather
than a count: the snapshot records *when* the next card comes due, not how many will be waiting.

## 26 — Lock screen widgets

`accessoryCircular` and `accessoryRectangular` variants of the same widget, reading the same
snapshot. Circular shows the mastered fraction as a gauge; rectangular shows mastered plus the due
count on one line.

Small step, worth doing only after 25 is proven. These render monochrome and are tiny — if the
content does not survive at that size, say so and drop the step rather than shipping something
unreadable.

## 27 — The widget's countdown string is not localized

Left behind by step 25, deliberately. The widget's `next review in 5 hours` line is
`Text(LocalizedStringKey("next review in \(nextDue, style: .relative)"))` in
`WordLernWidget/SummaryWidget.swift` — a `Text.DateStyle` interpolation, which is what keeps the
countdown ticking without the widget being reloaded. Xcode does **not** extract that
interpolation into `Localizable.xcstrings`: two builds, with both `Text("…")` and
`Text(LocalizedStringKey("…"))`, produced no key. So this one line falls back to its English
literal in all twelve languages while the widget's other five strings translate normally.

The fix is presumably to add the key by hand to the catalog, but the runtime lookup key has to be
confirmed first — a `Date` + `style` interpolation is *assumed* to render as `%@`, and an entry
under the wrong key is worse than none, because it looks translated and silently never applies.
So: confirm the key, then add it.

How to confirm: build, then read the compiled `Localizable.strings` out of the built widget for a
language that has a translation, or set one language's value by hand and run the widget in the
simulator under that language. Do not guess.

If the key turns out not to be addressable at all, the fallback is to drop the interpolation and
pass the whole sentence as a pre-formatted string, accepting that the countdown then only updates
when the timeline reloads — which for this line means at `nextDue`, i.e. it would read
`next review in 5 hours` for five hours. Say so and let the user choose; do not make that
trade quietly.
