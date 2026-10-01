# Plan

One step = one branch = one task. Branch from `develop`, named `step/NN-slug`. `develop` and `main`
are protected: the user opens the pull request and merges. Status values: `todo`, `in progress`,
`done`.

`Model` is a suggestion, not a rule: steps needing design or language judgement are worth the
bigger model, mechanical steps are not.

Steps 01–38 built and shipped 2.0 — the rewritten word list, the screens, the widgets, the
TestFlight pipeline. They are archived in `docs/PLAN-2.0.md`, which is worth opening when a
decision looks arbitrary; the rationale is recorded under each step. Numbering continues from
there so no branch name is ever reused.

| # | Branch | Step | Model | Status |
|---|--------|------|-------|--------|
| 39 | `step/39-working-agreement` | Make the working agreement match reality | sonnet | done |
| 40 | `step/40-plan-reset` | Archive the 2.0 plan, start a clean one | sonnet | done |
| 41 | `step/41-app-icon` | New app icon | opus | done |
| 42 | `step/42-website` | GitHub Pages site | opus | done |
| 43 | `step/43-screenshot-mode` | Debug screenshot mode | sonnet | todo |
| 44 | `step/44-listing-and-licence` | Finish the listing, decide the licence | sonnet | todo |

Order is numeric. 41 before 42 because the site needs the icon.

---

## 39 — Make the working agreement match reality

Done. `CLAUDE.md`'s build command selected a simulator by name; with several runtimes installed
`name=iPhone 16` matches more than one device and `xcodebuild` fails before compiling. Replaced
with `-destination 'generic/platform=iOS Simulator'`, plus a line saying why not to go back.

Its project facts also still described 1.0: the machine-translated word list "being replaced in
steps 03–05", and word content copied into Realm. Both rewritten — the list is the Leipzig-derived
one at `contentVersion` 3 with a sentence on all 1000 words, persistence is SwiftData, and Realm
must not come back because realm-core will not build against the current iOS SDK.

The GitHub default branch was `main`, so new pull requests opened against the branch the App Store
build comes from. The user switched it to `develop`. It does not affect the TestFlight workflow
(which triggers on `main`) or the step 38 rulesets — only the base a new pull request picks and the
README shown on the repository home page.

## 40 — Archive the 2.0 plan, start a clean one

Done. The 2.0 plan reached 1112 lines and `CLAUDE.md` has every session read it, so it had become a
standing cost on every task. Moved to `docs/PLAN-2.0.md` rather than deleted — the "Done:" notes
under each step are the only record of why the word list dropped 55 entries, why Leipzig over
OpenSubtitles, why the CI runner is pinned to `xcode-27`.

Steps 37 and 38 were finished but never written into the table; added to the archive so the record
is complete.

## 41 — New app icon

The shipped icon is a stack of cards in perspective inside a blue circle, on a grey-blue square.
Four problems: iOS already masks icons into a squircle, so a circle inside wastes a third of the
canvas; the perspective stack turns to mush at 60×60, which is the size that matters; the saturated
blue belongs to no part of the app; and the file is a 456 KB JPEG, so hard colour edges carry
compression artefacts.

Replace it with concept C, agreed with the user: a near-black squircle (`#15181D`), a large
off-white `ß` (`#F7F5F0`) centred, and a three-segment rule beneath it in black, red and gold
(`#D8232A`, `#F0C419`). The `ß` is the point — a flag says *Germany*, which Austrian and Swiss
users notice, while `ß` says *German* and exists in no other language. It also survives 60×60,
which neither card concept did.

Deliverables:

- `assets/icon.svg` — the source, used by the website in step 42 as well as the app.
- A 1024×1024 PNG in `AppIcon.appiconset`, replacing `wordlern_icon.jpg`. No alpha channel, no
  rounded corners baked in (iOS masks them), PNG not JPEG.
- The user converts the SVG; there is no rasteriser installed on this machine and none should be
  added for one file.

Check the result at 60×60 before calling it done, not just at full size. Out of scope: iOS 26
layered icon variants (light / dark / tinted) — a single 1024 PNG is still accepted, and that is a
separate decision.

Done. `tools/make_icon.swift` draws the icon and writes both deliverables, so the SVG and the PNG
cannot drift apart — the step assumed a hand conversion, but CoreGraphics is already on this
machine and no dependency was added for it. `assets/icon.svg` 1.9 KB, `icon-1024.png` 33 KB and
opaque (`hasAlpha: no`), replacing the 445 KB JPEG. The script also drops 60×60 and 120×120 proofs
in `build/` (gitignored) — that is where the geometry was settled.

Two judgements the concept left open:

- The flag's black band is `#3C434D`, not black. On a `#15181D` background a true black segment is
  invisible and the rule reads as two colours, not three.
- The three segments meet edge to edge, like the flag's bands. Gaps between them closed into mush
  at 60×60. The rule ended up 46pt tall rather than a hairline for the same reason: at 60×60 it is
  2.7px, and anything thinner greyed out into one muddy line.

The ß comes from the system font at semibold and is written out as an outline, so nothing depends
on a font being installed — the website in step 42 can use the same file.

## 42 — GitHub Pages site

App Store Connect requires a working privacy policy URL and a support URL for every app, and
neither exists. A one-page site covers both and doubles as the app's marketing page.

- Static HTML, no build tooling, no framework. Match `docs/DESIGN.md` — calm, typographic, dark.
- Pages: a landing page (what the app is, a few features, screenshots, Apple's official "Download
  on the App Store" badge linking to the listing), `/privacy`, `/support`.
- The privacy page is short because nothing is collected: no account, no analytics, no network
  calls. It must agree with `PrivacyInfo.xcprivacy` and the App Privacy answers.
- The badge artwork has to come from Apple's Marketing Resources and follow their guidelines; do
  not draw a lookalike.
- Deploy with GitHub Actions from a `site/` directory. Pages can only serve a repository root or
  `/docs`, and `/docs` holds the planning files — so the artifact-upload workflow, not the
  branch-folder setting.
- Keep a `workflow_dispatch` trigger. The privacy URL has to be live *before* 2.0 is submitted, and
  waiting on a merge to `main` would be the wrong order.

Out of scope: a blog, analytics of any kind, a contact form.

Done. `site/` holds three pages — landing, `/privacy`, `/support` — one stylesheet and no build
step. `.github/workflows/pages.yml` uploads the directory as an artifact on a push to `main` that
touches `site/`, and on `workflow_dispatch` from any branch, so the privacy URL can go live before
2.0 is submitted.

Settled along the way:

- The App Store link is `apps.apple.com/app/id6740728130`, the 1.0 listing. The numeric id was
  nowhere in the repository; it came from Apple's lookup API for `com.mfsaglam.thousand`.
- The badge is Apple's own artwork from the marketing toolbox, unmodified, vendored as
  `site/app-store-badge.svg`. The white variant, because the site's background is the icon's
  near-black.
- `tools/make_icon.swift` now also writes `site/icon.svg` and `site/icon-512.png` (link previews:
  no scraper renders SVG). Pages serves `site/` alone, so it cannot reach `assets/`, and one
  script writing both copies is what stops them drifting.
- The workflow checks that every local `href` and `src` resolves to a committed file. There is no
  build to fail, so a dead link is the only way this site can break.

Not done here, deliberately: the landing page has no screenshot gallery, because there are no
screenshots worth showing until step 43. Added to that step.

The README carries its own copy of the privacy policy, which is now a second source of truth for
the same text. Left alone — step 44 already opens the README for the licence, and that is the
place to replace the section with a link.

Needs a hand in GitHub settings before anything publishes: Settings → Pages → Source must be set
to **GitHub Actions**. The site lands at `https://mfsaglam.github.io/wordlern/`, which is the URL
the `og:` tags and step 44's App Store fields assume.

## 43 — Debug screenshot mode

A fresh install shows `mastered 0 / 1000` and five empty bars. Screenshots of that would sell
nothing, so the simulator needs a way into a believable state before the user captures the store
screenshots by hand.

- A launch argument the app reads **only** under `#if DEBUG`, so the code is absent from release
  builds entirely.
- It seeds a demo distribution and leaves the app on a card worth photographing — `das Haus` over
  `die Zeit`, a word with a short sentence.
- One demo state, used everywhere. The previews currently disagree with each other: `SummaryScreen`
  shows 700 mastered while `SessionEndScreen` shows `247 → 254`, and screenshots taken from both
  would not belong to the same story. Pick one set of numbers and make the previews match it too.

Also in this step, added by 42: once the screenshots exist, put a gallery on the landing page at
`site/index.html`. It was left out rather than filled with placeholders — the page currently goes
from the badge straight to the feature list, and the gallery belongs between them.

Note for whoever takes the screenshots: capture from the simulator with ⌘S, not from the Xcode
preview canvas. App Store wants 1320×2868 for the 6.9" slot, which an iPhone 16 Pro Max simulator
produces exactly; a canvas screenshot is scaled by the Mac's display and will be the wrong size.
The widget shot cannot come from this mode at all — widgets live on the home screen, so that one
has to be taken on a real device.

## 44 — Finish the listing, decide the licence

`docs/RELEASE.md` covers screenshots, App Privacy, export compliance and versioning, but the
listing text itself was agreed in conversation and never written down. Record it, so it is not
retyped from memory at submission time:

- App name, 30 characters: `WordLern: 1000 German Words`. The current name is the brand alone,
  which nobody searches for; the name field is the strongest ASO lever there is.
- Subtitle, 30: `Spaced repetition flashcards`.
- Keywords, 100, comma-separated with no spaces, not repeating the name or subtitle.
- Promotional text, 170 — editable without review, so it is the place for anything seasonal.
- Description, with the first three lines carrying the whole pitch; the rest is only seen by
  someone who taps "more". The closing section — no account, no ads, no subscription, no tracking,
  works offline — is the real differentiator in this category and should stay.
- "What's new" for 2.0 must say that progress from 1.0 does not carry over. The word list was
  replaced, so `contentVersion` wipes the store. Few users are affected, but not saying it is worse
  than saying it.
- Privacy policy URL and support URL from step 42 — both mandatory fields, neither currently in the
  checklist.
- Category: Education primary, Reference secondary. Age rating 4+.

Also in this step: there is no `LICENSE` file. On a public repository that legally means all rights
reserved while reading as an oversight. Either add a licence or state in the README that the code
is not offered for reuse. Step 33 was meant to settle this and did not.

---

## Later — agreed as worth doing, not scheduled

- `WordViewModel` has no tests. It is the brain of the app — sessions, undo, retired words, the
  mastered count — and it has been rewritten repeatedly across 2.0 with no safety net.
- No Dynamic Type or VoiceOver pass. The card screen uses fixed point sizes and has never been
  opened at a large text setting.
- Reverse mode, English → German. Recognition is the easy direction; production is where the skill
  is, and the card machinery already exists.
- An interactive card widget. Possible since iOS 17 via `AppIntent`, deferred in favour of the
  summary widget.
- Pre-rendered pronunciation audio. The corpus is fixed at 1000 words and 1000 sentences, so
  shipping real audio would beat any on-device synthesiser — at the cost of app size and a licence
  check on the voice.
- `WordViewModel` swallows errors with `print(error)` in two places. A failed save loses progress
  silently.
