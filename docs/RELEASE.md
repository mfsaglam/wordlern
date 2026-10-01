# Release checklist — 2.0

The pipeline (steps 29–31) can build and upload a binary. It cannot write the App Store
listing. This is the remaining non-code work between a TestFlight build and submitting 2.0 for
review. Tick these off together before step 35.

## Device support

- [x] `thousand` and `WordLernWidget` are now iPhone-only (`TARGETED_DEVICE_FAMILY = 1`). The app
      was never designed or tested for iPad — every screen in `docs/DESIGN.md` assumes an iPhone
      layout — so claiming iPad support in the listing would be dishonest. Decided 2026-10-01.
      This also means no iPad screenshots are required below.

## Screenshots

Every screen changed for 2.0, so the screenshots on the current (1.0) listing show an app that no
longer exists. Required sizes only — do not hand-decorate them, and use whatever sizes App Store
Connect actually asks for at upload time (Apple has changed the required set before; do not trust
a number written down here without checking Connect first).

- [ ] Capture fresh screenshots from the **iPhone-only** required size(s) in App Store Connect's
      Media Manager. Source material: card screen, summary screen, session-end screen,
      "how it works" screen, and the widget (if widgets get their own App Store Connect gallery
      slot).
- [ ] No iPad screenshots — the device support decision above removed the requirement.

## Description and "what's new"

- [ ] Write the 2.0 description. Honest framing, per `docs/PLAN.md` step 34: a new word list
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
