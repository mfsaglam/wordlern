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
| 25 | `step/25-widget` | Summary widget | opus | done |
| 26 | `step/26-lock-screen-widget` | Lock screen widgets | sonnet | done |
| 27 | `step/27-widget-countdown-localization` | The widget's countdown string is not localized | sonnet | done |
| 28 | `step/28-release-hygiene` | Release hygiene before any pipeline | sonnet | done |
| 29 | `step/29-fastlane` | Fastlane, proven from the laptop | opus | done |
| 30 | `step/30-testflight-pipeline` | GitHub Actions: main → TestFlight | opus | todo |
| 31 | `step/31-pr-check` | Build + test check on pull requests | sonnet | todo |
| 32 | `step/32-shake-undo` | Shake to undo | opus | todo |
| 33 | `step/33-readme` | The README describes an app that no longer exists | sonnet | todo |
| 34 | `step/34-store-listing` | App Store listing for 2.0 | sonnet | todo |

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

Done: no new target and no new file — `.accessoryCircular` and `.accessoryRectangular` joined
`supportedFamilies` on the existing `SummaryWidget`, and `SummaryWidgetView` grew two cases.

The content does survive, but only after dropping almost everything. Circular is a
`Gauge` at `mastered / total` in `.accessoryCircularCapacity` with the count in the ring and
nothing else — the due count alongside it was unreadable, so it lives on the rectangular family
instead. Rectangular is an `.accessoryLinearCapacity` gauge whose label is the one line the plan
asked for, `700/1000 mastered` on the left and the home screen widget's `WidgetStatusLine` —
`12 cards due` / the live countdown / `all caught up` — on the right; the style puts the bar under
that label on its own, which is why there is no separate bar view. The five box bars and
`BoxPalette` are not used at all: the lock screen renders monochrome, so colour carries nothing
and five bars at that height is noise.

Two things the families force: `containerBackground` must be empty for them, or the opaque
`systemBackground` from step 25 punches a card-shaped hole into the lock screen, so it is now
applied conditionally inside `SummaryWidgetView`. And the nil-snapshot branch needs a circular
case of its own — `open WordLern to start` does not fit in the ring, so it shows an empty gauge.

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

Done — and both of the premises above turned out to be wrong, so nothing was added to the catalog.

The key **is** extracted, as `next review in %@`. It entered `Localizable.xcstrings` in `0f512b7`,
the step 26 build; it was absent in step 25's commit. So a `Text.DateStyle` interpolation does
extract, exactly as `%@`, and step 25's note that two builds produced no key described a build
that had not settled rather than a limitation. No fallback needed: the interpolation stays and the
countdown stays live.

The second premise — "falls back to English while the widget's other five strings translate
normally" — was wrong in the other direction. Nothing translates. All 45 keys in the catalog are
untranslated (zero `localizations` blocks, zero `stringUnit`s), while the project declared twelve
supported languages. The build proves it: `thousand.app` and `WordLernWidget.appex` contain no
`.lproj` directory at all, because with no translations the compiler emits no
`Localizable.strings`. That countdown line was never the odd one out.

So there was no value to add by hand, and the real defect was the twelve-language claim. On the
user's call, `localizations.supported` in `project.xcproj` is now `["en"]` alone — `Base` went
with them, since the app has no xib or storyboard to base-localize. `LocalizedStringKey` and the
catalog stay exactly as they are: the working agreement is that UI strings go through the catalog
and the UI language is English, which is now what the project actually says. Re-adding a language
is one entry in that list plus filling the catalog in, whenever that becomes a real step.

## 28 — Release hygiene before any pipeline

Small settings changes that have to be right before automation is worth building. No fastlane, no
CI in this step.

- `ITSAppUsesNonExemptEncryption` is not set anywhere. The app target generates its Info.plist, so
  add `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` to its build settings (and the widget's
  `WordLernWidget/Info.plist`). Without it every single TestFlight build stops and waits for the
  export-compliance question to be answered by hand, which defeats the point of a pipeline. The
  app makes no network calls and uses no encryption beyond what Apple exempts.
- Decide the version. `MARKETING_VERSION` is `1.0` and that is what is on the App Store; what is
  on `feature/gamify` is a rewrite, not a patch. `2.0` is the honest number.
- Decide where the build number comes from. `CURRENT_PROJECT_VERSION` is `1` and TestFlight
  rejects a build number it has seen before. Pick one rule and write it down: either the CI run
  number, or `latest_testflight_build_number + 1` looked up at build time. Do not bump it by hand.
- Check the App Store Connect record actually has the widget's bundle id
  (`com.mfsaglam.thousand.WordLernWidget`) and an App Group registered for both targets. A missing
  identifier surfaces as an opaque signing failure later.

Done. `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` is now on the `thousand` target's build
settings and, since the widget ships a literal `Info.plist` rather than a fully generated one, on
both the `WordLernWidget` target's build settings and `WordLernWidget/Info.plist` directly.
`MARKETING_VERSION` is `2.0` on both targets.

Build number rule: `CURRENT_PROJECT_VERSION` is set at build time in the fastlane lane (step 29) to
`latest_testflight_build_number + 1`, looked up via `app_store_connect_api_key` +
`latest_testflight_build_number`. Not the CI run number — App Store Connect is the source of truth
for what's already been uploaded, and a CI run number has no relationship to it if a build is ever
uploaded by hand or a workflow is re-run. Do not bump `CURRENT_PROJECT_VERSION` by hand in the
project file.

The App Store Connect record check (widget bundle id `com.mfsaglam.thousand.WordLernWidget` and an
App Group registered for both targets) is a console check outside this repo — the user needs to
confirm it in App Store Connect / the Apple Developer portal before step 29.

## 29 — Fastlane, proven from the laptop

Set up fastlane and get one build to TestFlight **from the user's machine**, with a human watching.
Do not write any GitHub Actions yet.

Debugging code signing inside a CI runner is miserable — the feedback loop is ten minutes long and
the errors are opaque. Everything that can be proven locally should be proven locally first.

- `fastlane init`, then a single `beta` lane: bump the build number per step 28's rule, build the
  archive, upload to TestFlight.
- Authentication: an App Store Connect API key (`.p8` + key id + issuer id), not an Apple ID. The
  user has to create it in App Store Connect; it cannot be generated from here. API keys have no
  two-factor prompt, which is the whole reason CI can use them.
- Code signing: this app now needs **two** provisioning profiles — the app and the widget
  extension — both carrying the App Group entitlement. Use `match` with a private certificates
  repo. Automatic signing works in Xcode because a human is logged in; CI has no such luxury, and
  `match` is the thing that makes signing reproducible.
- Deliverable: a build visible in TestFlight, installed on the user's own device, and a `Fastfile`
  committed. Keep the `.p8` and the match passphrase out of the repo.

Note: this first upload ships the entire rewrite. Better that a human watches it land than that a
pipeline does it unattended.

Done. Version 2.0 build 1 was archived, signed and uploaded to TestFlight from the laptop on
2026-09-30.

`fastlane/Fastfile` has one `beta` lane: authenticate with an App Store Connect API key, read
`latest_testflight_build_number + 1`, run `match(type: "appstore")` for both bundle ids, archive,
export, upload. The build number is passed to the archive as
`xcargs: "CURRENT_PROJECT_VERSION=…"` — the lane never writes to the project file. `setup_ci` runs
only under CI so step 30 gets a temporary keychain for free.

`fastlane/Matchfile` points at `git@github.com:mfsaglam/ios-certificates.git` (private) and lists
both `com.mfsaglam.thousand` and `com.mfsaglam.thousand.WordLernWidget`.

Signing is now manual in the **Release** configuration only, written directly into
`project.xcproj` per target via the setting-condition syntax:
`CODE_SIGN_STYLE[config=Debug] = Automatic` / `CODE_SIGN_STYLE[config=Release] = Manual`,
`CODE_SIGN_IDENTITY[config=Release] = Apple Distribution`,
`PROVISIONING_PROFILE_SPECIFIER[config=Release] = match AppStore <bundle id>`. Debug keeps
automatic signing, so day-to-day work in Xcode is unchanged. Fastlane's
`update_code_signing_settings` was not used: it goes through the `xcodeproj` gem, which cannot
parse the JSON `project.xcproj` format.

Two things about that format that cost a build each, and that step 30 must not undo:
- A conditional setting does **not** override its unconditional sibling. Leaving
  `CODE_SIGN_STYLE = Automatic` in place next to `CODE_SIGN_STYLE[config=Release] = Manual` left
  the target automatically signed and the archive failed with "conflicting provisioning
  settings". Both configurations have to be spelled out as conditions. Verify with
  `xcodebuild -showBuildSettings -target <t> -configuration Release`, not by reading the file.
- `build_app` is pointed at `thousand.xcodeproj/project.xcworkspace`, **not** at the `.xcodeproj`.
  gym asks the `xcodeproj` gem for the project's build configurations; on the project path that
  raises (no `project.pbxproj`) and the lane dies before compiling. On the workspace path the same
  failure is rescued into an empty list, the explicit `configuration: "Release"` survives, and
  scheme and build settings come from `xcodebuild` instead. `output_name` is set explicitly
  because gym's app-name lookup returns the "App" default here.

Ruby: `.ruby-version` pins 3.2.2 and a `Gemfile`/`Gemfile.lock` pin fastlane. Two environment
traps on this machine, worth knowing before step 30:
- The rbenv Rubies are x86_64 builds, but gem native extensions compile as arm64 by default and
  then fail to load. Reinstalling a gem needs
  `gem install <name> -- --with-cflags="-arch x86_64" --with-ldflags="-arch x86_64"`.
- `json` 2.8+ will not compile against these Ruby 3.2 headers, so the `Gemfile` pins `~> 2.7.0`.
Neither applies to a GitHub runner, which ships a native Ruby — do not carry these pins into the
workflow without checking.

To run it, with the `.p8` kept outside the repo:

```
export LANG=en_US.UTF-8
export ASC_KEY_ID=…
export ASC_ISSUER_ID=…
export ASC_KEY_FILEPATH=~/…/AuthKey_XXXXXXXX.p8
bundle exec fastlane beta
```

`ASC_KEY_CONTENT` is the CI alternative: base64 instead of a path, and
`is_key_content_base64` follows whichever of the two is set. Setting it unconditionally makes
fastlane base64-decode the PEM it read from disk and fail with "string contains null byte".

`.gitignore` now excludes `*.p8`, `*.p12`, `*.mobileprovision`, `*.cer` and fastlane's generated
output.

Two one-off cleanups the first run needed, recorded so they are not mistaken for bugs later:
- GitHub SSH. match clones the certificates repo in a subprocess that cannot be prompted, so a
  passphrase-protected key that is not in the agent fails as `Permission denied (publickey)`. The
  ed25519 key was added to the GitHub account and `~/.ssh/config` given `AddKeysToAgent` +
  `UseKeychain` for `github.com`.
- `ios-certificates` was not an empty repo — it held match material from earlier CI experiments
  (`GithubActionsDemo`, `cicdTestApp`) including an expired distribution certificate, which match
  refused with "certificate is not valid". `certs/distribution/BVXB724S9Q.{cer,p12}` were deleted
  from that repo and match issued a fresh Apple Distribution certificate (`TA3N4XQ6DD`, valid to
  2027-09-30) plus both `match AppStore …` profiles. The stale demo profiles were left alone.

Still open for step 30: the GitHub runner needs its own read access to the private certificates
repo — a deploy key or an HTTPS token — and `match` must run with `readonly: true` there, which
the lane already does via `is_ci`.

## 30 — GitHub Actions: main → TestFlight

Only once step 29 has produced a real TestFlight build. The workflow runs the `beta` lane on every
push to `main`.

Check before writing anything: the project uses the JSON `project.xcproj` format, which needs a
recent Xcode. Confirm the runner image actually ships it and pin the version explicitly with
`xcode-select` — do not rely on the image default, which changes without warning.

- Secrets: the API key `.p8` (base64), key id, issuer id, team id, the match git url and its
  passphrase. Nothing else belongs in the repo.
- Trigger on `push` to `main` only. Not on pull requests, not on `feature/gamify`.
- Keep a `workflow_dispatch` trigger so a release can be re-run without an empty commit.

Cost: none. This repository is public, and GitHub Actions standard runners — macOS included — are
free and unmetered for public repositories. The ten-times macOS multiplier only applies to private
repositories. Do not switch to a larger runner, though: those are billed even on public repos, and
the standard macOS runner is enough here.

Because the repository is public, never use `pull_request_target`, and never echo a secret into the
log. Secrets are not exposed to workflows triggered by pull requests from forks, which is the
behaviour we want — keep it that way.

Done (workflow committed; the first real run happens when this reaches `main`).
`.github/workflows/testflight.yml` runs `bundle exec fastlane beta` on `push` to `main` and on
`workflow_dispatch`, with `permissions: contents: read` and a `concurrency` group so two runs cannot
claim the same build number.

Runner image: **`xcode-27`**, not `macos-latest`. The check the step asked for came back negative —
`macos-26` (which `macos-latest` points at) ships Xcode 26.0.1–26.6 only, none of which can read the
JSON `project.xcproj` format. The `xcode-27` image carries 27.0 (default), 27.1 and 27.2 beta; the
workflow pins `/Applications/Xcode_27.2_beta.app` via `sudo xcode-select`, which is the closest
match to the laptop's 27.2 (27B5028f vs the image's 27B5019j). Two consequences worth remembering:
- `xcode-27` is a **preview** image. If a run never starts, check the label still exists at
  `actions/runner-images` before suspecting the lane.
- The pinned path contains `_beta` and will change when 27.2 goes final. The "Pin Xcode" step fails
  loudly with a listing of `/Applications/Xcode*.app` instead of silently falling back to 27.0.
Not `xcode-27-xlarge`: larger runners are billed even on a public repository.

A `xcodebuild -list -project thousand.xcodeproj` step runs before anything expensive, so an Xcode
that cannot parse the project file fails in seconds rather than after a ten-minute archive.

Ruby is `ruby/setup-ruby@v1` with `ruby-version: "3.2"` (cached on the image) and
`bundler-cache: true`. The step 29 laptop workarounds do not cross over: the runner's Ruby is native
arm64, so the `-arch x86_64` gem flags are unnecessary, and the `json ~> 2.7.0` pin in the `Gemfile`
is kept because it is what 3.2 headers want anyway.

Certificates access — the item step 29 left open. The runner has no SSH key and `match` clones in a
subprocess that cannot be prompted, so CI uses HTTPS: `MATCH_GIT_URL` (https clone url) plus
`MATCH_GIT_BASIC_AUTHORIZATION` (base64 of `<user>:<token>`, read-only). `readonly: is_ci` was
already in the lane. The `Fastfile` now passes `git_url:` explicitly, defaulting to the SSH url, and
the `Matchfile` keeps its SSH `git_url` for `fastlane match` on the command line — a Matchfile value
wins over the environment, so the url cannot be overridden by `MATCH_GIT_URL` alone.

Secrets the repository needs (all of them, nothing else): `ASC_KEY_ID`, `ASC_ISSUER_ID`,
`ASC_KEY_CONTENT` (base64 of the `.p8`), `MATCH_GIT_URL`, `MATCH_GIT_BASIC_AUTHORIZATION`,
`MATCH_PASSWORD`. The team id is not a secret — it is already committed in `fastlane/Appfile`.
Nothing in the workflow echoes a secret; `xcodebuild -version` is the only thing it prints.

All six are set on `mfsaglam/wordlern` as of 2026-10-01. `MATCH_GIT_BASIC_AUTHORIZATION` holds a
fine-grained token scoped to `mfsaglam/ios-certificates` with `Contents: Read-only` — enough because
`match` runs `readonly: true` under CI. Fine-grained tokens expire: when a run starts failing at the
match step with a 403 or a clone error, that is the first thing to check, not the lane.

## 31 — Build + test check on pull requests

A cheap guard so a broken branch cannot reach `main`: build the app and run `thousandTests` on
pull requests targeting `feature/gamify` and `main`.

Build and test only — no archive, no signing, no upload. That is what keeps it inexpensive, and it
is also what makes it reliable, since signing is the part that breaks.

Runner minutes are free on this public repository, so there is no reason to hold back here. This
check needs no secrets, which is also what lets it run safely on pull requests from forks.

## 32 — Shake to undo

One addition, nothing moves. `UndoButton` stays exactly where it is, at the top-leading corner of
`SessionHeader`, at its current size. Shake is a shortcut layered on top of it, the same way swipe
was layered on top of ✓/✗ in step 09.

**Shake.** Shaking the phone undoes the last answer. Bridge `UIEventSubtypeMotionShake` —
`motionEnded(_:with:)` fires on the responder chain, so catch it in a `UIWindow` subclass or a
small `UIViewRepresentable` and post it into SwiftUI. Only act when `canUndo` is true; a shake with
nothing to take back must do nothing at all, not flash an error.

Confirm it happened: the existing `Haptics.undo()` plus a brief `undone` toast. Shake has no
on-screen affordance, so without feedback the user cannot tell whether the gesture registered or
the app ignored them.

Mention shake in `HowItWorksScreen`. A gesture nobody can see is a gesture nobody will find.

**Why the button stays** — settled with the user, do not revisit:

- Without it, undo is undiscoverable. Nothing on screen would suggest an answer can be taken back,
  and nobody thinks to shake a phone on a hunch.
- Shake alone would be an accessibility regression. A user with limited hand mobility, a phone in a
  stand, or VoiceOver running cannot shake a device. iOS also has a system "Shake to Undo" toggle
  that some users switch off, and they would reasonably expect ours to be dead too.

Out of scope: moving or resizing `UndoButton`, and any other change to `SessionHeader`'s layout.
The user looked at the placement and is happy with it.

Add the shake gesture to `docs/DESIGN.md` under screens 1 and 2 — the card screen's description
should mention it alongside swipe.

## 33 — The README describes an app that no longer exists

The repository is public, so the README is the front door, and it is wrong. It claims
"Core Data/Realm" for persistence (Realm was removed in step 08), "Combine" for state management
(the app uses `@Observable`), and localisation readiness that step 27 explicitly dropped. The
roadmap still lists gamification and pronunciation as future work — both shipped.

Rewrite it against what actually exists: SwiftUI + SwiftData, the Leipzig-derived word list with
its CC BY attribution, example sentences, the widgets, the daily reminder. Keep the Leitner
explanation — that part is still true and it is the clearest thing in the file.

While here, decide the licence question. There is no `LICENSE` file, which legally means all rights
reserved. That may well be deliberate for a commercial app, but on a public repository it reads as
an oversight, and people will assume they may reuse the code. Either add a licence or add one line
to the README saying the code is not open for reuse.

## 34 — App Store listing for 2.0

The pipeline can deliver a build; it cannot write the listing. This is the remaining work between a
TestFlight build and a release, and none of it is code.

- New screenshots. Every screen changed — the current store screenshots show an app that no longer
  exists. Required sizes only; do not hand-decorate them.
- Description and "what's new" text. The honest framing for 2.0 is a new word list, example
  sentences, pronunciation, widgets and reminders.
- App Privacy answers in App Store Connect: "Data Not Collected", matching the privacy manifest
  from step 21. The two must agree, or review will ask why.
- Export compliance is already answered by step 28's Info.plist key; confirm no build is sitting in
  "Waiting for Export Compliance" before submitting.
- TestFlight "what to test" note, so testers know what is new.

Deliver this as a checklist in `docs/RELEASE.md` rather than as code, and tick it off together.
