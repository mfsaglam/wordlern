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
