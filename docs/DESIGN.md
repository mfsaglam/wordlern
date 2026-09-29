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

## Copy

UI strings are English, sentence case, lower case for small labels (`mastered`, `moved up`).
