# Release checklist — 2.0

The pipeline (steps 29–31) can build and upload a binary. It cannot write the App Store
listing. This is the remaining non-code work between a TestFlight build and submitting 2.0 for
review. Tick these off together before step 35.

## Device support

- [x] `thousand` and `WordLernWidget` ship as iPhone **and** iPad (`TARGETED_DEVICE_FAMILY = 1,2`),
      the same as the published 1.0. Dropping iPad was tried in step 34 and rejected by App Store
      Connect at upload: *"This bundle does not support one or more of the devices supported by the
      previous app version"* (error 90101). Device support can never be narrowed once a version is
      live, so iPad stays. See step 37.
- [ ] Open the app on an iPad before submitting. It runs the iPhone layout scaled up; make sure
      nothing is broken or unreadable enough to draw a rejection.

## Screenshots

Every screen changed for 2.0, so the screenshots on the current (1.0) listing show an app that no
longer exists. Required sizes only — do not hand-decorate them, and use whatever sizes App Store
Connect actually asks for at upload time (Apple has changed the required set before; do not trust
a number written down here without checking Connect first).

- [ ] Capture fresh screenshots for the required iPhone size(s) in App Store Connect's Media
      Manager. Source material: card screen, summary screen, session-end screen,
      "how it works" screen, and the widget (if widgets get their own App Store Connect gallery
      slot).
- [ ] Capture iPad screenshots too — unavoidable now that the app declares iPad support. The 1.0
      listing already has a set; new ones are needed because every screen changed for 2.0.

Launch with the `-demoContent` argument on the Run scheme first (step 43), or the screenshots show
`mastered 0 / 1000` over five empty bars. It puts the app at 800 mastered with 200 cards due; a
session of ten answered seven-correct ends on `800 → 807`, which is what the session-end shot
should show. Turn the argument back off afterwards — it wipes local data on every launch. The
widget shot cannot come from it at all: widgets live on the home screen, so that one comes off a
real device.

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

## Description and "what's new"

- [ ] Write the 2.0 description. Honest framing, per `docs/PLAN-2.0.md` step 34: a new word list
      (steps 03–07), example sentences, pronunciation (step 17/19), widgets (prior widget step),
      and reminders (step 23).
- [ ] Write the "What's New in This Version" text for the 2.0 release — same framing, shorter.
- [ ] Write the TestFlight "what to test" note for the build testers install before release, so
      they know what changed since 1.0.

## App Privacy (App Store Connect)

- [ ] Set App Privacy answers to **"Data Not Collected"**. This must agree with
      `thousand/PrivacyInfo.xcprivacy` (step 21): `NSPrivacyCollectedDataTypes` is empty, the app
      makes no network calls, and the only required-reason API used is `UserDefaults`
      (`NSPrivacyAccessedAPICategoryUserDefaults`, reason `CA92.1`). If Connect's questionnaire
      asks about data collection beyond what the manifest declares, something drifted — fix the
      mismatch before submitting, don't paper over it.

## Export compliance

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
