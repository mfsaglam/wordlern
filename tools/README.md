# tools

Build-time scripts for the word list. Nothing in here ships in the app.

See [`docs/WORDLIST.md`](../docs/WORDLIST.md) for the source, the licence and the known
defects of the generated list.

## Rebuilding the frequency list

Python 3.9+. simplemma is the only dependency and is used at build time only — it is not an
app dependency.

```sh
# 1. Fetch the three Leipzig corpora (~200 MB, CC BY — see docs/WORDLIST.md).
mkdir -p /tmp/leipzig && cd /tmp/leipzig
for c in deu_news_2024_300K deu-de_web-public_2019_300K deu_wikipedia_2021_300K; do
  curl -O "https://downloads.wortschatz-leipzig.de/corpora/$c.tar.gz"
  tar -xzf "$c.tar.gz" "$c/$c-words.txt"
done

# 2. Set up the lemmatiser.
cd -                       # back to the repo root
python3 -m venv .venv
./.venv/bin/pip install simplemma

# 3. Build. The merge log on stderr is worth reading.
./.venv/bin/python tools/build_frequency_list.py \
  --out tools/de_frequency_top2000.tsv \
  --top 2000 \
  /tmp/leipzig/*/*-words.txt
```

Takes about a minute. The output is deterministic, so a rerun on the same corpora should
produce no diff.

## `de_frequency_top2000.tsv`

Tab separated, one lemma per row, ranked best first.

| Column | Meaning |
|---|---|
| `rank` | position in this list |
| `lemma` | the lemma, cased the way the corpus mostly writes it |
| `score_pm` | geometric mean of the per-million rates below |
| `capital_share` | fraction of tokens written capitalised — ≥0.9 means noun |
| `<corpus>_pm` | occurrences per million tokens in that corpus |
| `<corpus>_rank` | rank within that corpus alone |

## `build_dictionary_draft.py` — step 04

Streams the wiktextract dump of English Wiktionary's German entries and joins it with
`de_frequency_top2000.tsv`, producing `de_draft.json` (candidate glosses, POS, noun article)
and `de_draft_report.md` (the words that found no match). The dump is 1 GB and is not
committed.

```sh
curl -O https://kaikki.org/dictionary/German/kaikki.org-dictionary-German.jsonl
python3 tools/build_dictionary_draft.py --dictionary kaikki.org-dictionary-German.jsonl
```

## `editorial.py` — step 05

The editorial pass that turns candidates into the shipped word list.

```sh
python3 tools/editorial.py show 1 100   # compact candidate view for one batch
python3 tools/editorial.py build        # de_editorial.tsv -> thousand/de.json
```

`de_editorial.tsv` is the hand-written half and the real deliverable of step 05: one row per
word, `rank<TAB>targetWord<TAB>englishWord`. The rank column keeps the *draft* rank, so it has
gaps where a word was dropped and repeats where one was inserted (`Sie` next to `sie`, the
three missing weekdays next to `Freitag`). `build` sorts by that column and renumbers 1..1000,
so the shipped rank is the position in the edited list.

`build` refuses to write if two rows share an English gloss — the gloss doubles as a lookup
key in the app — or if two rows share a German word. `sie`/`Sie` are the one deliberate
case-only pair, so the German side is compared case-sensitively.

## `validate_sentences.py` — steps 06–07

Checks the hand-written example sentences in `de_sentences.tsv` against the three rules of
step 06: the target word appears, the sentence is at most 5 words, and every word is either
an earlier-ranked word of `thousand/de.json`, the target word itself, or one of the ~50 words
in the `CORE` allow-list at the top of the script.

```sh
./.venv/bin/python tools/validate_sentences.py          # everything
./.venv/bin/python tools/validate_sentences.py 1 50     # one batch
```

Needs the same `.venv` with simplemma as the frequency list: rules 1 and 3 compare lemmas, so
`ist` counts as `sein` and `Kinder` as `Kind`. Exits non-zero on the first batch that fails.

`de_sentences.tsv` is the hand-written half: `rank<TAB>targetWord<TAB>sentence`, the rank and
the word matching `thousand/de.json`. Sentences are German only, no translation. `sie` and
`Sie` are checked case-sensitively and must appear mid-sentence, where the capital carries
information.

