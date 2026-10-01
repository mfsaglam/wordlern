#!/usr/bin/env python3
"""Steps 05/07 helpers: read `de_draft.json` in batches, then build `thousand/de.json`.

Two modes.

    python3 tools/editorial.py show 1 100      # compact candidate view for editing
    python3 tools/editorial.py build           # de_editorial.tsv -> thousand/de.json

`de_editorial.tsv` is the editorial output: one row per word, tab separated,
`rank<TAB>targetWord<TAB>englishWord`. It is the hand-written half of step 05.

`de_sentences.tsv` (step 06/07) is the other hand-written input: the example sentence for
each *shipped* rank. Words with no sentence yet simply ship without one. `build` does not
check the sentences — `validate_sentences.py` does, and it reads the `de.json` this writes.
"""

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DRAFT = ROOT / "tools" / "de_draft.json"
EDITORIAL = ROOT / "tools" / "de_editorial.tsv"
SENTENCES = ROOT / "tools" / "de_sentences.tsv"
OUT = ROOT / "thousand" / "de.json"

CONTENT_VERSION = 3
LANGUAGE = {
    "languageCode": "de",
    "languageName": "German",
    "languageNativeName": "Deutsch",
}

# POS tags collapsed to something short enough to scan in a table.
POS_SHORT = {
    "noun": "n",
    "verb": "v",
    "adj": "adj",
    "adv": "adv",
    "prep": "prep",
    "conj": "conj",
    "pron": "pron",
    "art": "art",
    "article": "art",
    "num": "num",
    "intj": "intj",
    "name": "name",
    "particle": "part",
    "det": "det",
}


def show(start: int, end: int) -> None:
    words = json.loads(DRAFT.read_text())["words"]
    for w in words:
        if not (start <= w["rank"] <= end):
            continue
        parts = []
        seen = set()
        for c in w["candidates"]:
            pos = POS_SHORT.get(c["pos"], c["pos"])
            art = c.get("article") or ""
            for g in c["glosses"][:2]:
                g = g.strip()
                # inflection notes are noise for a one-sense pick
                if g.startswith(("inflection of", "genitive", "dative", "nominative",
                                 "accusative", "plural of", "singular of", "past ")):
                    continue
                key = (pos, g.lower())
                if key in seen:
                    continue
                seen.add(key)
                parts.append(f"{pos}{'/' + art if art else ''}: {g[:60]}")
            if len(parts) >= 6:
                break
        print(f'{w["rank"]}\t{w["lemma"]}\t' + " | ".join(parts[:6]))


def read_sentences() -> dict[int, tuple[str, str]]:
    """rank -> (sentence, the word it was written for)."""
    if not SENTENCES.exists():
        return {}
    out = {}
    for line in SENTENCES.read_text().splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        rank, target, sentence = line.rstrip("\n").split("\t")
        out[int(rank)] = (sentence, target)
    return out


def build() -> None:
    sentences = read_sentences()
    rows = []
    for line in EDITORIAL.read_text().splitlines():
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        rank, target, english = line.split("\t")
        rows.append({"rank": int(rank), "targetWord": target, "englishWord": english})
    rows.sort(key=lambda r: r["rank"])

    # `sie` and `Sie` are deliberately two cards, so the German side is compared
    # case-sensitively; the English side is not, because it doubles as a lookup key.
    for field, fold in (("targetWord", False), ("englishWord", True)):
        seen = {}
        for r in rows:
            key = r[field].lower() if fold else r[field]
            if key in seen:
                sys.exit(f'duplicate {field} "{r[field]}": ranks {seen[key]} and {r["rank"]}')
            seen[key] = r["rank"]

    # Draft ranks carry gaps where a word was dropped (corpus noise, lemmatiser
    # duplicates), so the shipped rank is the position in the edited list.
    for i, r in enumerate(rows, start=1):
        r["rank"] = i

    # Sentences are keyed by the shipped rank, so they attach after the renumbering.
    for r in rows:
        sentence = sentences.get(r["rank"])
        if sentence:
            if sentence[1] != r["targetWord"]:
                sys.exit(
                    f'sentence for rank {r["rank"]} is written for "{sentence[1]}", '
                    f'but that rank is "{r["targetWord"]}"'
                )
            r["exampleSentence"] = sentence[0]

    doc = dict(LANGUAGE)
    doc["contentVersion"] = CONTENT_VERSION
    doc["words"] = rows
    OUT.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n")
    with_sentence = sum(1 for r in rows if "exampleSentence" in r)
    print(
        f"wrote {len(rows)} words to {OUT.relative_to(ROOT)} "
        f"at contentVersion {CONTENT_VERSION}, {with_sentence} with an example sentence"
    )


if __name__ == "__main__":
    if len(sys.argv) >= 2 and sys.argv[1] == "show":
        show(int(sys.argv[2]), int(sys.argv[3]))
    elif len(sys.argv) == 2 and sys.argv[1] == "build":
        build()
    else:
        sys.exit(__doc__)
