# Release checklist — 2.0

The pipeline (steps 29–31) can build and upload a binary. It cannot write the App Store
listing. This is the remaining non-code work between a TestFlight build and submitting 2.0 for
review. Tick these off together before step 49, the merge into `main`.

## Device support

- [x] `thousand` and `WordLernWidget` ship as iPhone **and** iPad (`TARGETED_DEVICE_FAMILY = 1,2`),
      the same as the published 1.0. Dropping iPad was tried in step 34 and rejected by App Store
      Connect at upload: *"This bundle does not support one or more of the devices supported by the
      previous app version"* (error 90101). Device support can never be narrowed once a version is
      live, so iPad stays. See step 37.
- [x] Open the app on an iPad before submitting. It runs the iPhone layout scaled up; make sure
      nothing is broken or unreadable enough to draw a rejection. Checked by the user; the iPad
      screenshots were captured from the same run.

## Screenshots

Every screen changed for 2.0, so the screenshots on the current (1.0) listing show an app that no
longer exists. Required sizes only — do not hand-decorate them, and use whatever sizes App Store
Connect actually asks for at upload time (Apple has changed the required set before; do not trust
a number written down here without checking Connect first).

- [x] Capture the raw screenshots. Six screens — card front, card back, summary, session end,
      how it works, widget — at both sizes: 1320×2868 (iPhone 16 Pro Max) and 2064×2752 (13" iPad).
      Twelve files, all off a simulator.
- [ ] Compose the captioned versions (step 46) and upload them in App Store Connect's Media
      Manager, both device sizes.

Launch with the `-demoContent` argument on the Run scheme first (step 43), or the screenshots show
`mastered 0 / 1000` over five empty bars. It puts the app at 800 mastered with 200 cards due; a
session of ten answered seven-correct ends on `800 → 807`, which is what the session-end shot
should show. Turn the argument back off afterwards — it wipes local data on every launch. The
widget shot comes from the simulator too: add the widget to the simulator's own home screen and
capture that, the same as any other screen.

### Captions

One line burned into each screenshot, above the device.

| # | Screen | Caption |
|---|--------|---------|
| 1 | Card, front | The words that actually come up |
| 2 | Card, back | See it used, not just translated |
| 3 | Summary | Know exactly where you stand |
| 4 | Session end | Small sessions, every day |
| 5 | How it works | Spaced repetition, not willpower |
| 6 | Widget | Progress on your home screen |

Shots 1 and 2 carry the sell — most people never scroll past them — which is why the example
sentence, the thing no competitor offers, takes slot 2.

Two of the six are "X, not Y" constructions and that is the limit. A third was drafted for the
widget ("A nudge, not a notification") and dropped: read as a set, the repeated syntax starts to
look like a tic rather than a voice.

Same typeface, size and position in every shot — six captions that work as a set beat six that
each work alone. Background `#15181D` with `#F7F5F0` text, matching the icon and the site, so the
app, the store page and the website read as one thing.

## Listing

Agreed in conversation; written down here so it is not retyped from memory at submission time.
Character limits are App Store Connect's and are not negotiable.

**Name** (30) — `WordLern: 1000 German Words` (27)

The shipped name is the brand alone, which nobody searches for. The name field is the strongest
ASO lever there is, so it carries the two words a learner would actually type.

**Subtitle** (30) — `Spaced repetition flashcards` (28)

Carries the method, which the name does not. Name and subtitle read together: what it teaches, how
much of it, by what means.

**Keywords** (100) — no spaces after the commas, and nothing already in the name or subtitle;
Connect indexes those anyway and a repeat wastes the budget.

```
deutsch,vocabulary,vocab,a1,beginner,leitner,srs,language,study,pronunciation,offline,frequency
```

**Promotional text** (170) — editable without review, so it is the place for anything seasonal.

```
The 1000 words that make up most of everyday German - with a real example sentence for every one.
No account, no ads, works offline.
```

**URLs** — both mandatory fields, both live from step 42.

- Marketing: `https://mfsaglam.github.io/wordlern/`
- Privacy policy: `https://mfsaglam.github.io/wordlern/privacy/`
- Support: `https://mfsaglam.github.io/wordlern/support/`

**Category** — Education primary, Reference secondary. **Age rating** 4+.

## Description

Only the first three lines show before someone taps "more", so they carry the whole pitch.

```
Learn the 1000 German words that cover most of everyday speech. Every word comes with a
simple German example sentence, so you meet it in context instead of memorising a bare
translation.

HOW IT WORKS

WordLern uses the Leitner system, a flashcard method built on spaced repetition. Every word
lives in one of five boxes. Answer correctly and it moves up a box and comes back later;
answer wrong and it drops back and returns sooner. The words you find hard come around
often, the ones you know get out of your way.

A session is ten cards. That is all it takes.

WHAT YOU GET

- 1000 words, chosen from real German corpora - not translated from an English list
- A simple German example sentence for every word
- Pronunciation in the best German voice your device has installed
- Nouns with their articles (das Haus) and verbs in the infinitive
- Home screen and lock screen widgets showing your progress
- A reminder that arrives when cards are actually due, not on a timer

WHAT IT DOESN'T DO

No account. No ads. No subscription. No analytics, no tracking, no data collected - the app
makes no network calls at all. Everything stays on your device and works offline.
```

The closing section is the real differentiator in this category and should survive any edit: every
competitor asks for an account and most ask for a subscription.

## What's new in 2.0

The last line is not optional. Replacing the word list bumped `contentVersion`, which wipes the
store and re-seeds — so a 1.0 user's progress is gone on update. Almost nobody is affected, but
saying nothing would be worse than saying it.

```
WordLern 2.0 is a rebuild.

- A new word list. The old one was an English frequency list translated word by word, with
  duplicates and wrong senses. This one comes from German corpora, hand-checked, one meaning
  per word.
- A German example sentence for every word.
- Redesigned cards: tap to flip, swipe to answer, shake to undo.
- A progress screen that shows where your words actually sit.
- Home screen and lock screen widgets.
- Reminders that fire when cards come due.
- Pronunciation now uses the highest-quality German voice on your device.

Because the word list was replaced, progress from version 1.0 does not carry over and starts
fresh.
```

## TestFlight "what to test"

```
This is a rebuild, so everything is worth a look. Most useful: whether the example sentences
read naturally, whether pronunciation sounds right on your device, and whether the widget
keeps up with your progress.

Note that progress from 1.0 does not carry over.
```

## App Privacy (App Store Connect)

- [ ] Set App Privacy answers to **"Data Not Collected"**. This must agree with
      `thousand/PrivacyInfo.xcprivacy` (step 21): `NSPrivacyCollectedDataTypes` is empty, the app
      makes no network calls, and the only required-reason API used is `UserDefaults`
      (`NSPrivacyAccessedAPICategoryUserDefaults`, reason `CA92.1`). If Connect's questionnaire
      asks about data collection beyond what the manifest declares, something drifted — fix the
      mismatch before submitting, don't paper over it.

## Export compliance

A 2.0 build from `develop` is already in App Store Connect, uploaded by the pipeline through its
`workflow_dispatch` trigger. The three checks below can be answered against that build now, well
before the merge — they are the cheapest place to find a problem.

- [ ] Confirm no build is sitting in "Waiting for Export Compliance" in App Store Connect before
      submitting. Step 28 already set `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` on both
      the `thousand` and `WordLernWidget` targets, so new builds should answer this
      automatically — this check is to catch an older build uploaded before that setting existed.

## App Store Connect record

- [ ] Confirm the widget's bundle id (`com.mfsaglam.thousand.WordLernWidget`) is registered and an
      App Group is set up for both `com.mfsaglam.thousand` and the widget (step 28 flagged this as
      a console-only check outside the repo).

## Version

- [ ] Confirm `MARKETING_VERSION` reads `2.0` in App Store Connect's version field before
      submitting (already `2.0` in the project per step 28).
