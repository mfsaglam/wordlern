# WordLern

**WordLern** teaches the 1,000 most common German words using the Leitner system, a
flashcard method that schedules review intervals based on how well you know each word.

---

## Features

- **1000-word German list**: lemmas drawn from the Leipzig Corpora Collection's word
  frequency data, each with a single hand-picked English meaning and an A1-level example
  sentence.
- **Leitner system**: cards move through five boxes as you answer; a correct answer
  promotes a card to a longer review interval, an incorrect one sends it back to box 1.
  Swipe left/right or shake the phone to undo the last answer.
- **Pronunciation**: the app speaks the German word aloud using the best-quality German
  voice installed on the device, with a button to go download a better one.
- **Progress tracking**: a summary screen shows words mastered out of 1000 and the five
  boxes' current counts; a session-end screen recaps what just happened.
- **Daily reminder**: one local notification, rescheduled to the moment your next card
  comes due — no fixed daily nag, no server, no push entitlement.
- **Home screen and lock screen widgets**: the same progress at a glance, without opening
  the app.
- **"How it works" screen**: explains the five boxes and what moves a card between them.

---

## Technologies

- **SwiftUI**, MVVM. State lives in `@Observable` view models — no Combine.
- **SwiftData** for local persistence. No server, no sync, no analytics, no network calls
  at all.
- **WidgetKit** extension (`WordLernWidget`) reading a small JSON snapshot written by the
  app via an App Group — the widget never touches SwiftData directly.
- **AVSpeechSynthesis** for pronunciation.
- English only. The project previously declared twelve supported languages with nothing
  translated into any of them; that claim was dropped rather than shipped.

---

## Leitner System Overview

- **Box 1**: newly added or recently missed words, reviewed frequently.
- **Box 2–5**: words you know better, reviewed at increasing intervals.
- A correct answer moves a card up one box; a card answered correctly out of box 5 is
  retired and still counts toward "mastered". A wrong answer sends a card back to box 1.

---

## Word list and attribution

The German word list and example sentences are built, not licensed off the shelf — see
[`docs/WORDLIST.md`](docs/WORDLIST.md) for the full sourcing and editorial process. In
short:

German word frequencies derived from the Leipzig Corpora Collection
(`deu_news_2024`, `deu-de_web-public_2019`, `deu_wikipedia_2021`).
© 2024 Universität Leipzig / Sächsische Akademie der Wissenschaften / InfAI.
Licensed under CC BY 4.0.

> D. Goldhahn, T. Eckart & U. Quasthoff: Building Large Monolingual Dictionaries at the
> Leipzig Corpora Collection: From 100 to 200 Languages. In: Proceedings of the 8th
> International Language Resources and Evaluation (LREC'12), 2012.

English meanings were drafted from Wiktionary's German entries (CC BY-SA) as a starting
point, then hand-edited to a single sense per word — what ships is an editorial choice,
not a copy of Wiktionary.

The app credits all of this, plus its one dependency
([`LeitnerSwift`](https://github.com/mfsaglam/LeitnerSwift), MIT), on an in-app About
screen.

---

## Building

Open `thousand.xcodeproj` in Xcode and run the `thousand` scheme. The project file is in
Xcode's JSON project format, which needs a recent Xcode (27+). `fastlane/` holds the
release pipeline (`bundle exec fastlane beta`), which needs App Store Connect API
credentials this repository does not ship.

---

## License

All rights reserved. This repository is public so the code can be read, but no licence is
granted to reuse, modify, or redistribute it.

---

## Contact

- **Email**: mfsaglam1@icloud.com

---

## Privacy

WordLern collects nothing: no account, no analytics, no network calls at all. The policy the App
Store listing points at lives at
[mfsaglam.github.io/wordlern/privacy](https://mfsaglam.github.io/wordlern/privacy/), and that page
is the only copy. A second one here would be free to drift out of step with it.
