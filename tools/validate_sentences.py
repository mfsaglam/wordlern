#!/usr/bin/env python3
"""Steps 06–07: validate the German example sentences.

    ./.venv/bin/python tools/validate_sentences.py              # all of de_sentences.tsv
    ./.venv/bin/python tools/validate_sentences.py 1 50         # one batch

`tools/de_sentences.tsv` is the hand-written half: one row per sentence, tab separated,
`rank<TAB>targetWord<TAB>sentence`. The rank and the word must match `thousand/de.json`.

Three rules, from `docs/PLAN.md` step 06:

1. the target word appears in the sentence,
2. the sentence is at most 5 words long,
3. every word in it is either an earlier-ranked word of the list, the target word itself,
   or a member of `CORE` below.

Rules 1 and 3 compare lemmas, so `ist` counts as `sein` and `Kinder` as `Kind`. simplemma
does the lemmatising — build-time only, same dependency as `build_frequency_list.py`.
"""

import json
import pathlib
import re
import sys

from simplemma import lemmatize

ROOT = pathlib.Path(__file__).resolve().parent.parent
WORDS = ROOT / "thousand" / "de.json"
SENTENCES = ROOT / "tools" / "de_sentences.tsv"

MAX_WORDS = 5

# The floor of the language: without these, rank 3 has two words to build a sentence from.
# Function words, the handful of nouns and verbs any A1 sentence needs, and nothing else —
# every other word has to be earned by rank.
CORE = """
ich du er sie es wir ihr
der ein mein dein kein
sein haben werden
nicht und ja nein
was wer wo wie
hier da heute jetzt sehr auch
gut schön groß klein neu
Haus Mann Frau Kind Tag Buch Auto Tisch Stadt Wasser
kommen gehen machen sehen sagen essen trinken arbeiten wohnen
""".split()

ARTICLES = {"der", "die", "das"}
TOKEN = re.compile(r"[^\W\d_]+", re.UNICODE)

# simplemma lemmatises these four citation forms to something their own inflected forms never
# reach — `gesamt` to `samen`, `vergangen` to `vergehen`, `folgend`/`kommend` to the verb. The
# only token the lemma rules would accept is one that reads badly in an A1 sentence, so the
# inflections are listed by hand instead. Each set counts as the target word and as an allowed
# token, for that target word only.
INFLECTIONS = {
    "gesamt": {"gesamte", "gesamten", "gesamter", "gesamtes"},
    "vergangen": {"vergangene", "vergangenen", "vergangener", "vergangenes"},
    "folgend": {"folgende", "folgenden", "folgender", "folgendes"},
    "kommend": {"kommende", "kommenden", "kommender", "kommendes"},
}


def lemma(word: str) -> str:
    return lemmatize(word, lang="de").lower()


def lemmas(word: str) -> set[str]:
    """Both casings: a sentence-initial capital throws simplemma off (`Alle` -> `all`)."""
    return {lemma(word), lemma(word.lower())}


def target_lemma(target_word: str) -> str:
    """`das Jahr` is one card but two tokens; the article is not the word being taught."""
    parts = target_word.split()
    if len(parts) == 2 and parts[0] in ARTICLES:
        return lemma(parts[1])
    return lemma(target_word)


def load_words() -> list[dict]:
    return json.loads(WORDS.read_text())["words"]


def load_sentences() -> list[tuple[int, str, str]]:
    rows = []
    for n, line in enumerate(SENTENCES.read_text().splitlines(), start=1):
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) != 3:
            sys.exit(f"{SENTENCES.name}:{n}: expected 3 tab-separated fields, got {len(parts)}")
        rows.append((int(parts[0]), parts[1], parts[2]))
    return rows


def check(rank: int, target: str, sentence: str, by_rank: dict[int, str]) -> list[str]:
    errors = []
    if by_rank.get(rank) != target:
        errors.append(f'word is "{by_rank.get(rank)}" in de.json, not "{target}"')
        return errors

    tokens = TOKEN.findall(sentence)
    if len(tokens) > MAX_WORDS:
        errors.append(f"{len(tokens)} words, max is {MAX_WORDS}")

    inflections = INFLECTIONS.get(target, set())

    # `sie` (she/they) and `Sie` (formal you) are two different cards, so the pilot sentence
    # has to show which one it is teaching — case-sensitively, and not at the start of the
    # sentence where the capital says nothing.
    if target in ("sie", "Sie"):
        if not any(t == target for t in tokens[1:]):
            errors.append(f'"{target}" must appear mid-sentence, spelled exactly that way')
    elif not any(
        target_lemma(target) in lemmas(t) or t.lower() in inflections for t in tokens
    ):
        errors.append(f'target word "{target}" does not appear')

    allowed = {lemma(w) for r, w in by_rank.items() if r < rank for w in w.split()}
    allowed |= {lemma(w) for w in CORE}
    allowed |= {target_lemma(target)}
    for token in tokens:
        if not (lemmas(token) & allowed) and token.lower() not in inflections:
            errors.append(f'"{token}" is not allowed yet (rank {rank})')
    return errors


def main(argv: list[str]) -> int:
    words = load_words()
    by_rank = {w["rank"]: w["targetWord"] for w in words}
    rows = load_sentences()

    if len(argv) == 2:
        start, end = int(argv[0]), int(argv[1])
        rows = [r for r in rows if start <= r[0] <= end]
    elif argv:
        sys.exit(__doc__)

    seen = set()
    failures = 0
    for rank, target, sentence in rows:
        if rank in seen:
            print(f"{rank}\t{target}\tFAIL: duplicate row")
            failures += 1
            continue
        seen.add(rank)
        errors = check(rank, target, sentence, by_rank)
        if errors:
            failures += 1
            print(f"{rank}\t{target}\t{sentence}")
            for e in errors:
                print(f"\tFAIL: {e}")

    print(f"{len(rows)} sentences, {failures} failing")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
