# Word list source — step 03

Deliverable of step 03 in `docs/PLAN.md`: a real German frequency list to replace the
word-by-word machine translation in `thousand/de.json`, with its licence pinned down.

- **List:** [`tools/de_frequency_top2000.tsv`](../tools/de_frequency_top2000.tsv) — 2000 lemmas.
- **Script:** [`tools/build_frequency_list.py`](../tools/build_frequency_list.py).

2000 rather than 1000, because steps 04 and 05 will throw entries away (proper nouns,
abbreviations, lemmatiser slips) and need somewhere to backfill from.

## Source: Leipzig Corpora Collection

Three corpora, 300K sentences each, one per register, ~13.3M tokens in total:

| Corpus | Register | Tokens kept |
|---|---|---|
| `deu_news_2024_300K` | newspaper, 2024 | 4,479,882 |
| `deu-de_web-public_2019_300K` | German web, 2019 | 4,503,581 |
| `deu_wikipedia_2021_300K` | Wikipedia, 2021 | 4,359,138 |

Downloaded from `https://downloads.wortschatz-leipzig.de/corpora/<name>.tar.gz`; only the
`-words.txt` file of each archive is used.

### Licence

Leipzig draws a line between the two halves of their service, and only one of them is usable
here. From their [terms of usage](https://wortschatz.uni-leipzig.de/en/usage):

> Any data and applications provided by Projekt Deutscher Wortschatz are subject to copyright.
> Permission for use is granted free of charge solely for non-commercial personal and
> scientific purposes licensed under the Creative Commons License CC BY-NC. Any use that
> exceeds the means of query provided by the WWW-Interface, any automated queries (except
> using our RESTful Webservices) and any commercial use of the data obtained is forbidden
> without explicit written permission by the copyright owner.
> **All corpora provided for download are licensed under CC BY.**
> […] Please include the following copyright notice:
> © 2024 Universität Leipzig / Sächsische Akademie der Wissenschaften / InfAI.

So the **downloadable corpora** — which is what this list is built from — are CC BY, with no
non-commercial clause. The CC BY-NC restriction applies to the web interface and its query
API, which this project does not touch.

Two caveats worth knowing:

- The terms page says "CC BY" without a version number. Treat it as CC BY 4.0 and attribute
  in full. If WordLern ever becomes a paid app, it is worth one email to Leipzig asking them
  to confirm the version in writing.
- Attribution is a licence condition, not a nicety. The app has to carry the notice.

### Attribution the app must show

To go on an About / Credits screen (step 12 territory, not yet built):

> German word frequencies derived from the Leipzig Corpora Collection
> (`deu_news_2024`, `deu-de_web-public_2019`, `deu_wikipedia_2021`).
> © 2024 Universität Leipzig / Sächsische Akademie der Wissenschaften / InfAI.
> Licensed under CC BY 4.0.

Leipzig also asks — separately from the licence — that work using the corpora cites:

> D. Goldhahn, T. Eckart & U. Quasthoff: Building Large Monolingual Dictionaries at the
> Leipzig Corpora Collection: From 100 to 200 Languages. In: Proceedings of the 8th
> International Language Resources and Evaluation (LREC'12), 2012.

## Why this source and not the others

| Candidate | Lemmatised | Licence | Verdict |
|---|---|---|---|
| **Leipzig Corpora Collection** | no | **CC BY** on downloads | **chosen** |
| DeReWo (IDS Mannheim) | yes, gold | CC BY-NC | rejected — non-commercial |
| SUBTLEX-DE | no | research use only, no redistribution grant | rejected |
| OpenSubtitles lists (OPUS, hermitdave) | no | MIT on the list, upstream subtitles unclear | rejected — unclear chain |
| Universal Dependencies German-HDT / GSD | yes, gold + POS | CC BY-SA 4.0 | fallback — share-alike would follow the list |
| Google Books Ngrams | no | CC BY | rejected — book- and history-biased |

DeReWo is the best German lemma list in existence and is exactly the wrong licence. UD-HDT is
the strongest runner-up: gold lemmas and gold POS tags, which would have removed the need for
a lemmatiser entirely and fed step 04 for free. It lost on CC BY-SA — share-alike would attach
to the derived word list, and the point of this step was to end up with something clean to
ship. Leipzig's plain CC BY costs one attribution line and nothing else.

Leipzig's weakness is that it ships word *forms*, not lemmas, so the folding is ours to do and
ours to get wrong. See the defects below.

## How the list is built

1. Read the three `-words.txt` files (`rank <TAB> form <TAB> absolute frequency`).
2. Drop anything that is not letters, optionally with one internal hyphen or apostrophe. That
   removes digits, punctuation and mixed tokens.
3. Lemmatise each form with [simplemma](https://github.com/adbar/simplemma) (MIT) and sum the
   frequencies per lemma.
4. Fold a narrow class of past participles onto their infinitive (see below).
5. Convert to per-million within each corpus, then rank by the **geometric mean** across the
   three. A word therefore has to be common in all three registers to rank highly, which pushes
   down single-register topic words. `Prozent` still lands at 132 — it really is that common —
   but Wikipedia's `Gemeinde` and news' `Landkreis` end up where they belong.
6. Write the top 2000 with the per-corpus numbers kept alongside, so step 05 can see register
   skew per word.

`capital_share` is the fraction of a lemma's tokens that were written with a capital letter.
German capitalises nouns, so ≥0.9 means noun and ≈0 means everything else — a free part-of-speech
hint for step 04. 376 of the top 1000 are nouns by that measure.

Reproduce it with the commands in [`tools/README.md`](../tools/README.md).

### Participle folding

simplemma files `erklärt`, `bedeutet`, `entwickelt` and friends as adjectives, so they survive
as lemmas next to `erklären`, `bedeuten`, `entwickeln`. In a corpus those forms are mostly the
finite verb, so the split is wrong and burns two slots on one word.

The rule is deliberately narrow, because a silent bad merge is worse than a visible duplicate:
lowercase `-t` forms only, never one carrying the `ge-` participle marker, and only when the
candidate infinitive is both known to simplemma and already present in the shortlist. It fires
134 times in the top 4000 and the full log is printed on every run. Three of the 134 are
arguably wrong and are in the defect list below.

Strong participles (`gefunden`, `verloren`, `gebracht`, `gegeben`) have no regular rule and
were left alone.

## Known defects — the step 05 checklist

The list is a *candidate* list. These are the things the editorial pass has to deal with, all
of them found by reading the top 1000:

**Proper nouns (30 in the top 1000).** `Deutschland` 98, `Berlin` 214, `Europa` 336,
`München` 380, `USA` 389, `Bayern` 572, `Hamburg` 592, `Österreich` 614, `Frankfurt` 628,
`Frankreich` 667, `Berliner` 735, `Schweiz` 736, `Leipzig` 784, `China` 795, `Köln` 802,
`Stuttgart` 828, `Wien` 979, `Russland` 994, plus first names `Michael` 762, `Peter` 878,
`Martin` 917 and the truncation `Thoma` 756 (from *Thomas*). Drop all of them; `Deutschland`
is the only arguable keep.

**Foreign and abbreviation residue.** `of` 412, `The` 434, `de` 447, `GmbH` 610, `Bad` 690
(from place names like *Bad Homburg*), `A` 677, `m` 783, `New` 788, `FC` 807, `SPD` 893.
`Media` 643 is not English — it is simplemma folding *Medien* onto *Medium*, so the entry is
real but is written wrong.

**Adjective and pronoun stems.** simplemma returns bare stems where a dictionary would give a
citation form: `dies` 19 → *dieser*, `ander` 53 → *andere*, `jed` 217 → *jeder*,
`besonder` 503 → *besondere*, `beid` 791 → *beide*, `welch` 410 → *welche*, `zweit` 143,
`letzt` 188, `dritter` 479, `viert` 881. Also the truncation `zuminde` 806 → *zumindest*.

**Noun/verb homographs merged.** Case folding puts `Leben`/`leben` (99), `Mal`/`mal` (138),
`Essen`/`essen` (708) and `Treffen`/`treffen` (200) in one bucket. `capital_share` shows it:
anything between 0.2 and 0.9 is a homograph, not a clean noun. Step 05 should split the ones
that matter.

**`sie` and `Sie` are one entry** (rank 15, capital_share 0.45). For a learner these are two
different words — *she/they* and formal *you*. Split them.

**Preposition + article contractions** get their own slots: `im` 10, `am` 26, `zum` 31,
`zur` 38, `vom` 59, `beim` 74, `ins` 152. They are genuinely worth teaching, but they are
seven slots and their parts are already in the list. A call for step 05.

**`sein` at rank 4** folds the verb *to be* and the possessive *his*. Same word form, two
entries' worth of meaning.

**Bad participle merges (3 of 134).** `beliebt → belieben` (rank 720 — *beliebt* is the
adjective *popular*; *belieben* is archaic and should not be in the list at all),
`doppelt → doppeln`, and arguably `vertraut → vertrauen`. `fällen` at 822 is a separate
lemmatiser slip for *fallen*.

**Months are in, weekdays mostly are not.** All twelve months make the top 350; only
`Sonntag` 814 and `Samstag` 974 make the top 1000. Teaching seven weekdays and twelve months
is probably right even though frequency alone does not put them there — a curriculum decision
for step 05.

## What this says about the current `de.json`

Only **385 of the current 909 unique words** appear in the new top 1000, and only **533** in
the top 2000. Nearly half of what the app teaches today is not common German at all — which
is what you would expect from an English frequency list translated word by word. This is the
evidence that steps 04 and 05 are worth doing rather than patching the existing file.
