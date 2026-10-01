# WordLern — working agreement

Read `docs/PLAN.md` for the step list and `docs/DESIGN.md` for the agreed UI direction before starting work.

Reply to the user in Turkish.

## Workflow — follow this for every task, without being asked

1. Each step of the plan is one task. Start it on a new branch cut from `develop`, named `step/NN-slug` (e.g. `step/01-card-screen`). The `NN` comes from `docs/PLAN.md`.
2. Never commit to `main` or `develop`. Never merge into either — the user opens the pull request and merges. Both branches are protected on GitHub (step 38): no direct pushes, no deletion, no force-push, and a passing `build-and-test` check is required.
3. Stay inside the step's scope as defined in `docs/PLAN.md`. If the work needs a change outside that scope, stop and ask instead of widening it.
4. When the work is done, verify the build:
   `xcodebuild -project thousand.xcodeproj -scheme thousand -destination 'generic/platform=iOS Simulator' build`
   Do not select a simulator by name. Several runtimes are installed, so `name=iPhone 16` matches
   more than one device and the command fails before compiling anything.
5. If the build succeeds, commit. If it fails, do not commit — report the failure with the compiler output.
6. Mark the step `done` in `docs/PLAN.md` in the same commit.
7. Close with a short report: branch name, what changed, build status, and whether it is ready to merge.

## Project facts

- The app has effectively no users. Wiping and re-seeding local data is always acceptable — never write migrations, backwards-compatible fallbacks, or "your data changed" notices.
- `thousand/de.json` holds 1000 hand-checked words derived from the Leipzig corpora, each with one English gloss and one German example sentence. `docs/WORDLIST.md` records where it came from and the attribution the app must show. It is not the machine-translated list the app shipped with in 1.0.
- Word content is copied into SwiftData at first seed, so edits to `de.json` are invisible on an installed app until `contentVersion` is bumped — then the store is wiped and re-seeded. It is at 3.
- `LeitnerSwift` is the user's own package (github.com/mfsaglam/LeitnerSwift), pinned to a version. Changing it is a separate conversation — do not assume you can edit it.
- Persistence is SwiftData. Realm was removed in step 08 and realm-core will not build against the current iOS SDK — do not reintroduce it.

## Keep sessions cheap

- Never read `thousand/de.json` in full — it is ~91KB / 1000 entries. Query it with `python3` or
  `jq` and read only what you need.
- Verify UI with SwiftUI previews. Do not boot the simulator and take screenshots unless asked.
- Prefer a reusable script in `tools/` over doing repetitive data work token by token.
- Paste only the failing lines of a build log, never the whole thing.

## Code style

- SwiftUI, MVVM. Views hold no persistence or Leitner logic.
- Keep views small and previewable — every new view gets a `#Preview`.
- UI strings go through `LocalizedStringKey`; the app's UI language is English.
- No new third-party dependencies without asking.
