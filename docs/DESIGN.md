# Design direction

Agreed with the user on 2026-09-29 after a mockup review. If a change would contradict anything
here, ask first.

## Direction

Calm premium — the Apple / Things end of the spectrum. Soft depth, spring animations, typography
carries the screen. Fun comes from motion and clarity, not from colour noise.

Explicitly rejected: gamified Duolingo styling, mascots, confetti, badges, a skeuomorphic
physical Leitner box. Animations stay simple; no elaborate choreography.

## Screen 1 — card, front

- Top row: box badge (`box 2`) on the left, session position (`4 / 10`) on the right. Both are
  quiet — small, muted, no colour.
- Directly under it, a thin session progress bar that advances one notch per answer.
- Centre: the word, large (~44pt) and medium weight, as the single focus of the screen.
  A circular, outlined speaker button sits below it, not beside it.
- Below centre: one muted line of guidance, `tap the card to flip`.
- Bottom: ✓ and ✗ as 52pt circles, tinted green and red, ✗ on the left.
- The old "Show / Hide Translation" button is gone. The card itself is the control.
- Gestures are shortcuts layered on top of visible controls, never replacements for them.
  Swiping the card right answers ✓ and left answers ✗; shaking the phone undoes the last answer,
  the same as the muted arrow left of the box badge. A shake with nothing to take back does
  nothing. Because shake has no on-screen affordance, it confirms itself with a haptic and a
  brief `undone` pill.

## Screen 2 — card, back

Reached by tapping the card, with a flip animation.

- The top row and progress bar are unchanged — they do not move during the flip.
- The word shrinks and moves up, muted; the meaning takes its place, large.
- Below, on its own light surface with 12pt corners: the label `in a sentence`, then a German
  example sentence at ~19pt with the target word highlighted in an accent-tinted pill, then the
  sentence's own speaker button.
- Sentences are German only — no English translation. A1 level, at most 4–5 words, built from
  words the learner has already met. The point is repeated exposure to known vocabulary.
- When `exampleSentence` is nil, the whole surface is absent — no empty state, no placeholder.
- The ✓/✗ buttons are unchanged and stay in place across the flip.
- Swipe and shake work exactly as on the front — the flip changes nothing about them.

## Screen 3 — summary

- Headline metric at the top: `mastered`, then the count over `/ 1000 words`, then a thicker
  progress bar. Mastered means boxes 3, 4 and 5 combined.
- Below a hairline divider, five rows: box label, bar, count.
- The bars are scaled relative to each other, not against 1000. The current `total: 1000`
  makes the screen look emptier the more the user learns.
- Each bar's fill darkens as the box number rises — box 1 neutral grey through to a deep green
  at box 5. Progress reads as the screen getting deeper, not fuller.
- Bars fill from zero on appear, staggered by ~100ms. Once per appearance, not looping.
- Bottom: a single filled pill button, `start session`.

## Screen 4 — session end

Its own screen, deliberately plain. Today the app falls back to the summary screen, which makes
finishing a session feel like nothing happened.

- A green check in a soft circle, `session complete`, and `10 cards reviewed`.
- Two flat stat tiles side by side: `moved up` and `to review`.
- One emotional beat: the mastered bar growing, labelled with the before and after
  (`247 → 254`).
- Bottom: an outlined pill button, `see progress`.
- No confetti, no badges, no streak counter.

## Home screen widget

Screen 3 reduced to what fits. The widget is ambient presence, not a second interface: no
animation (widgets do not get any), no audio, no interaction beyond tapping through to the app —
which lands on the summary screen on its own, so there is no deep link.

- `systemSmall`: the `mastered` caption, the count over `/ 1000`, the one thick mastered bar, and
  a single status line at the bottom.
- `systemMedium`: the same block on the left, the five box bars on the right. The bars are
  labelled with bare digits `1`–`5` — `box 1` does not survive at that width, and the column
  already reads top to bottom.
- Same palette and same relative bar scaling as the summary screen, reusing `Bar` and
  `BoxPalette` directly so the two cannot drift.
- The status line, in order: `12 cards due` when something is due, `next review in 5 hours` with
  a live countdown when nothing is, `all caught up` when the list is empty, and
  `open WordLern to start` before the app has ever run.
- Background is `systemBackground` rather than the translucent widget fill: the bar tracks are
  faint by design and need a solid surface to read against.

## Lock screen widgets

Same widget, same snapshot, two more families. These render monochrome and are a fraction of the
size, so the palette and the box bars are dropped entirely — what survives is the mastered
fraction.

- `accessoryCircular`: a capacity ring at `mastered / 1000` with the count in the middle, and
  nothing else. The due count does not fit next to it, and progress is what a glance is for.
- `accessoryRectangular`: one line — `700/1000 mastered` on the left, the same status line as the
  home screen widget on the right — with the bar underneath. That is
  `accessoryLinearCapacity`'s own layout, label above the track.
- No background: the lock screen supplies its own, and an opaque one would punch a card-shaped
  hole in it.
- With no snapshot yet, circular shows an empty ring rather than a sentence it cannot fit;
  rectangular keeps `open WordLern to start`.

## Copy

UI strings are English, sentence case, lower case for small labels (`mastered`, `moved up`).
