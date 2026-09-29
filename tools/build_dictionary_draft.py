#!/usr/bin/env python3
"""Join tools/de_frequency_top2000.tsv with a kaikki.org German Wiktionary dump.

For each of the top-N frequency lemmas, streams the (uncommitted, ~1GB) kaikki
JSONL dump and collects candidate English senses per part of speech, plus the
article for nouns. Output is a draft for the editorial pass in plan step 05 --
it is not a finished word list.

Usage:
    python3 tools/build_dictionary_draft.py --dictionary /path/to/kaikki.org-dictionary-German.jsonl

The dictionary dump itself is never written into the repo; download it from
https://kaikki.org/dictionary/German/kaikki.org-dictionary-German.jsonl and
point --dictionary at wherever you saved it.
"""

import argparse
import json
import sys
from collections import defaultdict

GENDER_TO_ARTICLE = {"m": "der", "f": "die", "n": "das"}
GENDER_TAGS = {"masculine": "der", "feminine": "die", "neuter": "das"}

PROGRESS_EVERY = 500_000


def load_frequency_list(path, top_n):
    ranked_words = []
    with open(path, encoding="utf-8") as f:
        next(f)  # header
        for line in f:
            rank_str, lemma = line.rstrip("\n").split("\t")[:2]
            rank = int(rank_str)
            if rank > top_n:
                break
            ranked_words.append((rank, lemma))
    return ranked_words


def extract_article(entry):
    for ht in entry.get("head_templates", []):
        code = ht.get("args", {}).get("1", "").split(",")[0].strip()
        if code in GENDER_TO_ARTICLE:
            return GENDER_TO_ARTICLE[code]
    for sense in entry.get("senses", []):
        for tag in sense.get("tags", []):
            if tag in GENDER_TAGS:
                return GENDER_TAGS[tag]
    return None


def extract_glosses(senses, limit):
    glosses = []
    fallback_glosses = []
    for sense in senses:
        is_form_of = "form_of" in sense or "alt_of" in sense or "form-of" in sense.get("tags", [])
        target = fallback_glosses if is_form_of else glosses
        for gloss in sense.get("glosses", []):
            if gloss and gloss not in target:
                target.append(gloss)
    # wiktextract tags some agent-noun lemmas (e.g. "Spieler") as form-of their
    # root verb even though the word is its own headword; fall back to those
    # glosses rather than dropping the word entirely.
    result = glosses or fallback_glosses
    return result[:limit] if limit else result


def stream_dictionary(path, wanted_lemmas, gloss_limit):
    matches = defaultdict(list)
    with open(path, encoding="utf-8") as f:
        for i, line in enumerate(f, 1):
            if i % PROGRESS_EVERY == 0:
                print(f"...{i:,} dictionary lines scanned", file=sys.stderr)
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            if entry.get("lang_code") != "de":
                continue
            word = entry.get("word")
            if word not in wanted_lemmas:
                continue
            glosses = extract_glosses(entry.get("senses", []), gloss_limit)
            if not glosses:
                continue
            pos = entry.get("pos")
            article = extract_article(entry) if pos == "noun" else None
            matches[word].append({"pos": pos, "article": article, "glosses": glosses})
    return matches


def write_report(path, total, unmatched):
    with open(path, "w", encoding="utf-8") as f:
        f.write("# de_draft.json build report\n\n")
        f.write(f"{total} words processed, {len(unmatched)} with no dictionary match.\n\n")
        if unmatched:
            f.write("| rank | lemma |\n|---|---|\n")
            for rank, lemma in unmatched:
                f.write(f"| {rank} | {lemma} |\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--frequency-list", default="tools/de_frequency_top2000.tsv")
    parser.add_argument("--dictionary", required=True, help="Path to the kaikki.org German JSONL dump")
    parser.add_argument("--top-n", type=int, default=1000)
    parser.add_argument("--gloss-limit", type=int, default=10, help="Max glosses kept per pos candidate (0 = unlimited)")
    parser.add_argument("--out", default="tools/de_draft.json")
    parser.add_argument("--report", default="tools/de_draft_report.md")
    args = parser.parse_args()

    ranked_words = load_frequency_list(args.frequency_list, args.top_n)
    wanted_lemmas = {lemma for _, lemma in ranked_words}
    matches = stream_dictionary(args.dictionary, wanted_lemmas, args.gloss_limit)

    words_out = []
    unmatched = []
    for rank, lemma in ranked_words:
        candidates = matches.get(lemma, [])
        if not candidates:
            unmatched.append((rank, lemma))
        words_out.append({"rank": rank, "lemma": lemma, "candidates": candidates})

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump({"words": words_out}, f, ensure_ascii=False, indent=2)
        f.write("\n")

    write_report(args.report, len(ranked_words), unmatched)

    print(
        f"Wrote {args.out}: {len(words_out)} words, {len(unmatched)} unmatched "
        f"(see {args.report}).",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
