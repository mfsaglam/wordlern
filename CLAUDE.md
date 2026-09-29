# WordLern — working agreement

Read `docs/PLAN.md` for the step list and `docs/DESIGN.md` for the agreed UI direction before starting work.

Reply to the user in Turkish.

## Workflow — follow this for every task, without being asked

1. Each step of the plan is one task. Start it on a new branch cut from `feature/gamify`, named `step/NN-slug` (e.g. `step/01-card-screen`). The `NN` comes from `docs/PLAN.md`.
2. Never commit to `main`. Never merge into `feature/gamify` — the user does the merge.
3. Stay inside the step's scope as defined in `docs/PLAN.md`. If the work needs a change outside that scope, stop and ask instead of widening it.
4. When the work is done, verify the build:
   `xcodebuild -project thousand.xcodeproj -scheme thousand -destination 'platform=iOS Simulator,name=iPhone 16' build`
5. If the build succeeds, commit. If it fails, do not commit — report the failure with the compiler output.
6. Mark the step `done` in `docs/PLAN.md` in the same commit.
7. Close with a short report: branch name, what changed, build status, and whether it is ready to merge.

## Project facts

- The app has effectively no users. Wiping and re-seeding local data is always acceptable — never write migrations, backwards-compatible fallbacks, or "your data changed" notices.
- `thousand/de.json` is a word-by-word machine translation of an English frequency list (909 unique words out of 1000 rows). It is being replaced in steps 03–05; do not build on top of its current contents.
- Word content is copied into Realm at first seed, so edits to `de.json` are invisible on an installed app until the `contentVersion` counter from step 02 exists.
- `LeitnerSwift` is the user's own package (github.com/mfsaglam/LeitnerSwift), pinned to a version. Changing it is a separate conversation — do not assume you can edit it.

## Code style

- SwiftUI, MVVM. Views hold no persistence or Leitner logic.
- Keep views small and previewable — every new view gets a `#Preview`.
- UI strings go through `LocalizedStringKey`; the app's UI language is English.
- No new third-party dependencies without asking.
