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
| 43 | `step/43-screenshot-mode` | Debug screenshot mode | sonnet | done |
| 44 | `step/44-listing-and-licence` | Finish the listing, decide the licence | sonnet | done |
| 45 | `step/45-site-gallery` | Screenshot gallery on the site | sonnet | done |
| 46 | `step/46-store-images` | App Store marketing images | opus | done |
| 47 | `refactor/use-library-due-api` | Use LeitnerSwift's own due query | sonnet | done |
| 48 | `feat/persist-card-review-date` | Persist each card's own review date | sonnet | done |
| 49 | — | Merge into `main`: the 2.0 release | — | done |
| 50 | `step/50-release-xcode` | Build the release with a non-beta Xcode | opus | todo |

Order is numeric. 41 before 42 because the site needs the icon; 45 was held back until step 43
made it possible to take a screenshot worth showing.

47 and 48 are recorded after the fact: they were found and fixed outside the plan, on branches
named for the work rather than a step number. The numbers are theirs now so the record is whole;
the branch column keeps the names that actually exist in the history.

49 is the release. Everything before it is reversible.

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

Done: `thousand/Support/DemoContent.swift`, the whole file inside `#if DEBUG`, triggered by a
`-demoContent` launch argument set on the Run scheme. It wipes the store and loads a fixed
distribution into the Leitner system in memory only — `WordViewModel` loads cached boxes just when
the store has some, so an empty store leaves the demo standing and nothing touches disk until a
card is answered.

The distribution is forced, not chosen. Box 1 has a zero-day review interval, so it is due every
day whatever its last-reviewed date; and the mastered count only moves when cards leave box 2 for
box 3, so box 2 has to be due too or the session-end screen shows its bar not growing at all. That
makes `due = box1 + box2` and `mastered = the rest` — the two always sum to 1000, so a modest
mastered count would force an enormous due count. Hence an advanced learner:
`[60, 140, 300, 300, 200]`, 800 mastered, 200 due, and a session of ten from box 2 ending
`800 → 807` at seven correct.

`das Haus`, `die Zeit`, `das Kind`, `die Frau`, `der Mann` and `das Wasser` are pushed to the head
of box 2 — `dueForReview` walks the boxes backwards, so that is the box a session draws from, and
those six all carry a short example sentence. Without it a session opens on whatever the frequency
list starts with.

The `SummaryScreen` and `SessionEndScreen` previews that disagreed (700 mastered against
`247 → 254`) are replaced by one `demo — for screenshots` preview each, carrying these numbers.

Still open: the screenshot gallery on `site/index.html`. The screenshots now exist on the user's
machine but are not in the repository.

Note for whoever takes the screenshots: capture from the simulator with ⌘S, not from the Xcode
preview canvas. App Store wants 1320×2868 for the 6.9" slot, which an iPhone 16 Pro Max simulator
produces exactly; a canvas screenshot is scaled by the Mac's display and will be the wrong size.
The widget shot does not come from this mode — the widget reads the snapshot file, not the demo
state — but it does come from the simulator: add the widget to the simulator's home screen and
capture that.

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

Done. The listing copy now lives in `docs/RELEASE.md` — name, subtitle, keywords, promotional text,
the full description, the 2.0 "what's new" and a TestFlight note — with the character counts and
the reasoning beside each, so an edit later knows what it is trading away. The three URLs from
step 42 are recorded against the fields that require them.

The licence turned out to be settled already: step 33 did write a `License` section into the
README (all rights reserved, public to read, no reuse granted). This plan's claim that it did not
was wrong. No `LICENSE` file was added — a section saying the same thing is enough for a repository
nobody is being invited to fork.

What did need fixing was a second privacy policy. The README carried a full one dated 18.01.2025,
from before step 42 put the canonical page on the site. Two policies at two addresses, free to
drift, with the App Store listing pointing at only one of them. The README now links to the site
page instead.

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

## 45 — Screenshot gallery on the site

Carried over from step 42, which left the gallery out rather than fill it with placeholders, and
from 43, which was what made a presentable screenshot possible. `site/index.html` currently goes
from the App Store badge straight to the feature list; the gallery belongs between them.

Source material: the screenshots the user captured from the iPhone 16 Pro Max simulator in the
`-demoContent` state — card front, card back, summary, session end. Four is enough. The page
already explains the features in words, so the gallery is there to show the app has a face, not to
re-argue the pitch.

Use the raw screenshots, not the App Store versions. The captions in `docs/RELEASE.md` are burned
into the store images and would fight the page's own copy.

Watch the weight. Each capture is 1320×2868 and a PNG of that size runs to a megabyte or more; four
of them would make this the heaviest page in a site that is otherwise three HTML files and a
stylesheet. Downscale to something a phone-shaped column actually needs and re-encode — `sips` is
on the machine and no dependency is needed. Keep the originals out of the repository.

Required of the markup:

- `width` and `height` on every image, so the page does not reflow as they load.
- `loading="lazy"` on all but the first.
- Real `alt` text describing the screen, not "screenshot 1".
- The layout has to survive a narrow viewport; four phone shots in a row will not.

The Pages workflow checks that every local `href` and `src` resolves to a committed file, so a
missing image fails the build rather than reaching the site — but check the page at a phone width
by eye anyway, since nothing automated can see a broken column.

Out of scope: device frames, the widget shot (a home screen is not in the same visual family as
the app's own screens), and any carousel or lightbox. Static images in a grid.

Done. The four raw captures (1320×2868, 148–487 KB each) landed in `site/screenshot/` as
untracked files at the start of this step — `.gitignore` now excludes the `*_raw.png` names so
they can't be committed by accident, and the originals stay on disk rather than being deleted.

Downscaled each to 640×1391 with `sips` and committed those under plain names (`card-front.png`,
`card-back.png`, `summary.png`, `session-end.png`): 640 is 2x the ~320px column a two-up grid
gives each image inside the page's 42rem measure, so retina stays sharp without shipping
full-resolution capture. The four together come to 388 KB, against 1.2 MB raw.

A new `<ul class="gallery">` sits in `index.html` between the App Store badge and "What it does",
with `width`/`height` on every `<img>`, `loading="lazy"` on all but the first, and `alt` text
describing each screen rather than numbering them. `.gallery` in `style.css` is a two-column grid
at every width — two-up already reads fine at 375px CSS width in preview, so no separate
single-column breakpoint was needed.

Order follows the plan's own phrasing — card front, card back, summary, session end — which
maps to the capture filenames as `card_faceup` (front, not yet flipped) and `card_facedown`
(flipped, showing the English meaning and example sentence).

## 46 — App Store marketing images

The twelve raw captures exist — six screens at 1320×2868 (iPhone) and 2064×2752 (iPad), covering
card front, card back, summary, session end, how it works and the widget. What goes to App Store
Connect is those with a caption above them, per the table in `docs/RELEASE.md`.

Build them with a script, not by hand. `tools/make_icon.swift` already established the pattern —
`swift tools/make_icon.swift`, AppKit and CoreGraphics, no dependency added — and the same approach
gives `tools/make_store_images.swift`: read a raw capture, compose it on the required canvas, write
the PNG. Re-runnable, so a changed screenshot or a reworded caption is one command rather than an
afternoon in a design tool.

Composition, matching the icon and the site so the listing, the store page and the app read as one
thing:

- Canvas at the exact required size. No resampling of the capture itself beyond a uniform scale.
- Background `#15181D`, caption `#F7F5F0` — the icon's two colours.
- Caption at the top, same baseline in every image, centred, one line where it fits and two where
  it does not. Identical size and position across the set matters more than any single image.
- The capture below it, scaled to leave the caption room, with its corners rounded to the device's
  own radius. No drawn device frame, no shadow, no gradient.

Required of the result:

- Six iPhone images and six iPad images, written somewhere gitignored. The raw captures stay out of
  the repository as well; both are build inputs, not source.
- Legible at the size App Store actually shows them, which is a thumbnail in a scrolling row. Check
  one at thumbnail size before accepting the set.
- Apple rejects listings whose images are mostly marketing rather than the app. A caption strip over
  a real screen is well inside the line; drifting towards illustration is not.

Done. `tools/make_store_images.swift` composes all twelve in one run — `swift
tools/make_store_images.swift`, AppKit and CoreText, no dependency added. The raws were on the
user's Desktop rather than in the repository, so the script defaults to `~/Desktop` and takes
`--in <dir>`; output goes to `build/store/`, which `build/` already ignores.

Every measurement is a fraction of the canvas height, so the sets are one composition at several
sizes rather than several compositions. The capture is scaled once (~0.81) to clear the caption
band, the bottom margin and the side margins, and its corners are rounded to the display's own
radius — 55pt at @3x, 30pt at @2x. No frame, no shadow, no gradient.

Eighteen images, not twelve. Connect rejected the first upload — *"Screenshots dimensions should
be: 1242 × 2688px, 2688 × 1242px, 1284 × 2778px or 2778 × 1284px"* — because this listing's iPhone
slot is the 6.5", which 1.0 shipped, and not the 6.9" the captures were taken at. So the canvas is
no longer assumed to be the capture's own size: a device now carries a capture size and a canvas
size separately, and the 6.5" set is composed from the same 6.9" raws onto a 1284×2778 canvas. One
capture, two slots, nothing re-shot. The 6.9" output is unchanged, since on a canvas the capture's
own shape the height is still what binds.

The caption band always reserves two lines even when the caption needs one, which is what keeps
the first baseline on the same pixel row across the set. Wrapping picks the balanced break rather
than the greedy one: greedy leaves a stub second line that reads as an accident. It falls out that
all six iPhone captions take two lines and all six iPad captions take one — the iPad canvas is
wider relative to its height — so each set is internally consistent without the font size having to
change between images.

The script writes a 300px proof of each image beside the full set, which is roughly the width App
Store gives a thumbnail in its scrolling row. Checked there before accepting: the captions hold up,
and `how it works` reads as a dense reference screen rather than legible text — which is what it
is, and the caption carries that image rather than the body copy.

Not in scope and deliberately left: the iPad captures are the iPhone layout scaled up, so those six
are mostly empty space. Fixing that is an iPad layout, not a marketing image.

## 47 — Use LeitnerSwift's own due query

Found outside the plan. `WordViewModel` carried its own copy of the box-level due calculation for
`dueCount`, `nextReviewDate` and `nextReview` — written in step 22, when the library had no such
API. LeitnerSwift 1.4.0 exposes the same calculation, so the app defers to it rather than keeping a
second implementation in step with the first.

Two implementations of one rule is the kind of thing that stays correct right up until the library
changes its mind about what "due" means.

## 48 — Persist each card's own review date

Found outside the plan, and a real bug rather than a tidy-up. LeitnerSwift 1.5.0 schedules a card
from its own `lastReviewedDate`, but `StoredCard` never kept that date. Every launch handed the
library cards with no date, it fell back to the box's date, and answered cards came back early —
the card-level fix in the library had no effect on the app until the date round-tripped through
storage.

`StoredCard` gains an optional `lastReviewedDate` (a lightweight SwiftData migration, no
`MigrationPlan`), `CardSnapshot` carries it into the writer, and updating an existing record now
writes the date alongside `boxIndex`. Covered by new cases in `SwiftDataCardStoreTests`.

Worth remembering when a scheduling bug next looks like a library problem: the library can only
schedule from what the store gives it back.

## 49 — Merge into `main`: the 2.0 release

Not a development step and not done on a branch. `main` still holds the published 1.0 and is 27
commits behind; this is the moment that changes.

Do it after 46 and after the App Store Connect items in `docs/RELEASE.md` are ticked off.

1. Confirm `develop` builds clean and the app runs on a device.
2. Merge `develop` into `main`. That push fires `.github/workflows/testflight.yml`, which runs the
   `beta` lane and uploads to TestFlight.
3. Watch that run, but it is no longer the unknown it was. The workflow was run from `develop` by
   hand first, through its `workflow_dispatch` trigger, and it built, signed and uploaded to App
   Store Connect. The runner image, `match` and the API key are all proven. A failure on the `main`
   push now points at something about `main` itself rather than a broken lane — and step 29 proved
   the lane works from the laptop, so the laptop is still the fallback.
4. Install the TestFlight build and use it for a day before promoting it. There is no rollback once
   a version is released.
5. Submit for review with the listing from `docs/RELEASE.md`.

The 1.0 upload attempt already failed once on device family (archived step 37), so watch the run
rather than merging and walking away.

Keep `workflow_dispatch` in the workflow for the reason it paid off here: it exercises the whole
pipeline from a branch, before the one push that cannot be taken back.

Done. `develop` is merged into `main` (PR #21), the pipeline ran on the push, and the build reached
TestFlight. The merge was the irreversible part and it is behind us.

Step 5, the submission, is not done and is not this step's any more: review refused the binary, and
that is step 50. Read `done` here as "`main` is 2.0", not "2.0 is on the App Store".

Two things the merge turned up, neither of them the app:

- The `Pages` run on the same push **failed**: *"Branch `main` is not allowed to deploy to
  github-pages due to environment protection rules."* The site itself is live — all three URLs
  answer 200, published earlier by `workflow_dispatch` from `develop` — so nothing is broken for
  the submission. But every future push to `main` that touches `site/` will fail the same way until
  the `github-pages` environment's allowed deployment branches include `main`. That is a repository
  setting, not a file in here.
- The release Xcode problem, step 50.

## 50 — Build the release with a non-beta Xcode

Submitting 2.0 for review failed. The binary was built with the Xcode 27.2 beta, and App Store
review does not accept a beta-built binary.

The failure is not where it looks. `.github/workflows/testflight.yml` pinned
`/Applications/Xcode_27.2_beta.app` — on purpose, back when the JSON `project.xcproj` format looked
like it needed the beta that introduced it. It does not: the format is readable by any Xcode 27, and
the runner image's own default was already the release 27.0. So the pin bought nothing and cost the
submission.

What makes this worth writing down is the shape of the failure, not the fix. **TestFlight accepts a
beta-built binary; review rejects it.** Every cheap signal said the pipeline was healthy — it built,
it signed, it uploaded, the build installed and ran. The one gate that cares came last, after the
irreversible merge. A check that only fires at the end of the pipeline is not a check.

The fix:

1. Point `XCODE_APP` at the release Xcode 27.0 on the runner image.
2. Fail the `Pin Xcode` step outright if the pinned path looks like a beta, before the twenty
   minutes of building. It matches on the name only, which is enough — the path is written in the
   workflow, not discovered at runtime.
3. Re-run the lane. It takes a fresh build number from App Store Connect, so the rejected build
   does not have to be cleaned up first; leave it, and pick the new build in the submission.

If the runner image has renamed the release Xcode, the `Pin Xcode` step prints every installed
`/Applications/Xcode*.app` and stops — read the list and correct the path rather than reaching for
the beta again.

Nothing has to be installed locally. The laptop's Xcode 27.2 beta is fine for development and for
previews; only the archive that goes to review has to come from a release Xcode, and that archive
is built on the runner.
