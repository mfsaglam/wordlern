#!/usr/bin/env python3
"""Build a lemmatised German frequency list from Leipzig Corpora Collection word lists.

Input:  the `*-words.txt` files from one or more Leipzig corpus archives
        (format: rank <TAB> word form <TAB> absolute frequency).
Output: a TSV of the top N lemmas, ranked by the geometric mean of their
        per-million frequency across the input corpora.

Using the geometric mean rather than a plain sum means a word has to be common
in *every* register to rank highly, which pushes down topic words that only one
corpus loves ("Prozent" in news, "Gemeinde" in Wikipedia).

Lemmatisation uses simplemma (MIT). It runs at build time only; nothing it
produces ends up in the app beyond the lemma strings themselves.

Usage:
    python3 -m venv venv && ./venv/bin/pip install simplemma
    ./venv/bin/python tools/build_frequency_list.py \
        --out tools/de_frequency_top2000.tsv \
        --top 2000 \
        path/to/*-words.txt
"""

import argparse
import math
import re
import sys
from collections import defaultdict

try:
    import simplemma
except ImportError:  # pragma: no cover - guidance only
    sys.exit("simplemma is missing. See the usage block at the top of this file.")

LANG = "de"

# A word is letters, optionally with one internal hyphen or apostrophe.
# Anything with a digit, or made of punctuation, is not vocabulary.
WORD_RE = re.compile(r"^[A-Za-zÄÖÜäöüßÀ-ÿ]+(?:[-'’][A-Za-zÄÖÜäöüßÀ-ÿ]+)?$")

# Smoothing added to every per-million value so that a word missing from one
# corpus is penalised hard but not annihilated by the geometric mean.
SMOOTHING_PM = 0.05


def read_leipzig_words(path):
    """Yield (word form, absolute frequency) from a Leipzig `-words.txt` file."""
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            parts = line.rstrip("\n").split("\t")
            if len(parts) != 3:
                continue
            _, word, freq = parts
            try:
                yield word, int(freq)
            except ValueError:
                continue


def lemmatise_corpus(path, cache):
    """Fold one corpus' word forms into lemma counts.

    Returns (lemma_counts, casing_counts, kept_tokens) where casing_counts maps
    the lowercased lemma to a {lemma_as_written: token count} breakdown.
    """
    lemma_counts = defaultdict(int)
    casing_counts = defaultdict(lambda: defaultdict(int))
    kept_tokens = 0

    for word, freq in read_leipzig_words(path):
        if not WORD_RE.match(word):
            continue
        if word not in cache:
            # simplemma returns ambiguous results as "er|es|sie"; keep the
            # first candidate and let the editorial pass sort the pronouns out.
            cache[word] = simplemma.lemmatize(word, lang=LANG).split("|")[0]
        lemma = cache[word]
        key = lemma.lower()
        lemma_counts[key] += freq
        casing_counts[key][lemma] += freq
        kept_tokens += freq

    return lemma_counts, casing_counts, kept_tokens


def participle_merge_map(pool, capital_share):
    """Fold past participles that simplemma leaves standing onto their infinitive.

    simplemma files "erklärt", "bedeutet" or "entwickelt" as adjectives, so they
    survive as lemmas of their own next to "erklären", "bedeuten", "entwickeln".
    In a corpus those forms are overwhelmingly the finite verb, so the split is
    wrong and it wastes two slots on one word.

    The rule is deliberately narrow, because a wrong merge is worse than a
    visible duplicate: only a lowercase `-t` form, never one carrying the `ge-`
    participle marker (that pattern produces nonsense like "abgelegt" ->
    "abgelegen"), only when the candidate infinitive is a word simplemma knows
    *and* is already in `pool`. Strong participles ("gefunden", "verloren") have
    no regular rule and are left for the editorial pass.

    `pool` is the shortlist the list is actually drawn from, not every lemma in
    the corpus, so the merge log stays short enough to read.
    """
    merges = {}
    for lemma in pool:
        if not lemma.endswith("t") or len(lemma) < 5:
            continue
        if capital_share.get(lemma, 0.0) >= 0.5:  # a noun, e.g. "Abfahrt"
            continue
        if re.match(r"^(?:[a-zäöüß]{2,6})?ge[a-zäöüß]+t$", lemma):
            continue
        for candidate in (lemma[:-1] + "en", lemma[:-1] + "n"):
            if candidate in pool and simplemma.is_known(candidate, LANG):
                merges[lemma] = candidate
                break
    return merges


def combined_score(corpora, lemma):
    """Geometric mean of a lemma's per-million frequency across the corpora."""
    values = [
        corpus["per_million"].get(lemma, 0.0) + SMOOTHING_PM for corpus in corpora
    ]
    return math.exp(sum(math.log(value) for value in values) / len(values))


def refresh_rates(corpora):
    """Recompute per-million frequencies and per-corpus ranks from raw counts."""
    for corpus in corpora:
        corpus["per_million"] = {
            lemma: count / corpus["tokens"] * 1_000_000
            for lemma, count in corpus["counts"].items()
        }
        corpus["ranks"] = {
            lemma: index + 1
            for index, lemma in enumerate(
                sorted(
                    corpus["per_million"], key=corpus["per_million"].get, reverse=True
                )
            )
        }


def merge_casings(corpora, lemma):
    """Total token counts per written form of a lemma, across all corpora."""
    merged = defaultdict(int)
    for corpus in corpora:
        for written, count in corpus["casings"].get(lemma, {}).items():
            merged[written] += count
    return merged


def canonical_casing(variants):
    """Pick how a lemma should be written: the casing that carries most tokens.

    German capitalises nouns, so a lemma whose tokens are overwhelmingly
    capitalised is a noun; function words and verbs only get a capital at the
    start of a sentence, which is a small share of their occurrences.
    """
    return max(variants.items(), key=lambda item: (item[1], item[0]))[0]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("words_files", nargs="+", help="Leipzig *-words.txt files")
    parser.add_argument("--out", required=True, help="output TSV path")
    parser.add_argument("--top", type=int, default=2000, help="how many lemmas to keep")
    parser.add_argument(
        "--min-length", type=int, default=1, help="drop lemmas shorter than this"
    )
    args = parser.parse_args()

    cache = {}
    corpora = []
    for path in args.words_files:
        name = path.split("/")[-1].replace("-words.txt", "")
        counts, casings, tokens = lemmatise_corpus(path, cache)
        corpora.append(
            {"name": name, "counts": counts, "casings": casings, "tokens": tokens}
        )
        print(f"{name}: {tokens:,} tokens kept, {len(counts):,} lemmas", file=sys.stderr)

    all_lemmas = {
        lemma
        for corpus in corpora
        for lemma in corpus["counts"]
        if len(lemma) >= args.min_length
    }
    refresh_rates(corpora)

    # Merging is restricted to the shortlist the final list is drawn from, so
    # the merge log is short enough for a human to check.
    pool_size = args.top * 2
    pool = set(sorted(all_lemmas, key=lambda l: -combined_score(corpora, l))[:pool_size])
    shares = {}
    for lemma in pool:
        casings = merge_casings(corpora, lemma)
        shares[lemma] = sum(
            count for form, count in casings.items() if form[:1].isupper()
        ) / max(1, sum(casings.values()))

    merges = participle_merge_map(pool, shares)
    for corpus in corpora:
        for source, target in merges.items():
            if source not in corpus["counts"]:
                continue
            corpus["counts"][target] += corpus["counts"].pop(source)
            for written, count in corpus["casings"].pop(source, {}).items():
                key = target.capitalize() if written[:1].isupper() else target
                corpus["casings"][target][key] += count
    all_lemmas -= set(merges)
    refresh_rates(corpora)
    print(
        f"merged {len(merges)} participles in the top {pool_size} "
        "onto their infinitive:",
        file=sys.stderr,
    )
    for source, target in sorted(merges.items()):
        print(f"  {source} -> {target}", file=sys.stderr)

    scored = []
    for lemma in all_lemmas:
        casings = merge_casings(corpora, lemma)
        capital_share = sum(
            count for form, count in casings.items() if form[:1].isupper()
        ) / max(1, sum(casings.values()))
        scored.append(
            (combined_score(corpora, lemma), canonical_casing(casings), lemma, capital_share)
        )

    scored.sort(key=lambda row: (-row[0], row[1]))

    headers = ["rank", "lemma", "score_pm", "capital_share"]
    for corpus in corpora:
        headers += [f"{corpus['name']}_pm", f"{corpus['name']}_rank"]

    with open(args.out, "w", encoding="utf-8") as handle:
        handle.write("\t".join(headers) + "\n")
        for index, (score, written, lemma, capital_share) in enumerate(
            scored[: args.top], start=1
        ):
            row = [str(index), written, f"{score:.2f}", f"{capital_share:.2f}"]
            for corpus in corpora:
                row.append(f"{corpus['per_million'].get(lemma, 0.0):.2f}")
                row.append(str(corpus["ranks"].get(lemma, "")))
            handle.write("\t".join(row) + "\n")

    print(f"wrote {min(args.top, len(scored)):,} lemmas to {args.out}", file=sys.stderr)


if __name__ == "__main__":
    main()
