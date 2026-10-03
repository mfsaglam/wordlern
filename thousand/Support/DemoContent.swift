//
//  DemoContent.swift
//  thousand
//

#if DEBUG
import Foundation
import LeitnerSwift

/// One fixed, believable progress state, for taking App Store screenshots.
///
/// A fresh install shows `mastered 0 / 1000` over five empty bars, which sells
/// nothing. Launching with `-demoContent` puts the app halfway through the list
/// instead. The previews use the same numbers, so the card, the summary and the
/// session-end screenshots all belong to one story rather than three.
///
/// DEBUG only — the release binary does not contain this file.
enum DemoContent {
    /// Pass in the scheme's run arguments, or `xcrun simctl launch … -demoContent`.
    static let launchArgument = "-demoContent"

    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    /// Cards per box, summing to the whole list.
    ///
    /// The shape is forced by two facts about `LeitnerSystem`. Box 1 has a review
    /// interval of zero days, so it is due every day no matter what. And a
    /// session can only raise the mastered count — boxes 3, 4 and 5 — by
    /// promoting cards out of box 2, so box 2 has to be due as well for the
    /// session-end screen to show its bar growing at all.
    ///
    /// That makes `due` exactly `boxCounts[0] + boxCounts[1]`, and mastered the
    /// rest: the two always add up to 1000, so a low mastered count would force a
    /// huge due count. Hence an advanced learner — 800 mastered, 200 due.
    static let boxCounts = [60, 140, 300, 300, 200]

    /// Box 2. `dueForReview` walks the boxes from last to first, so the highest
    /// due box is what a session draws from, and that is where the opening words
    /// have to sit.
    static let sessionBoxIndex = 1

    /// Words put at the head of the box a session draws from, so the first card
    /// is one worth photographing instead of whatever the frequency list starts
    /// with. Each has a short example sentence, which is what the back of the
    /// card is meant to show off.
    static let openingWords = [
        "das Haus",
        "die Zeit",
        "das Kind",
        "die Frau",
        "der Mann",
        "das Wasser"
    ]

    /// Boxes 3, 4 and 5 — the same definition `WordViewModel.masteredWordCount`
    /// uses. Nothing is retired in the demo state.
    static var masteredCount: Int {
        boxCounts.dropFirst(2).reduce(0, +)
    }

    /// Boxes 1 and 2. Boxes 3 to 5 are left reviewed today, so their next review
    /// is a week or more away.
    static var dueCount: Int {
        boxCounts[0] + boxCounts[1]
    }

    /// Builds the demo distribution out of the real word list.
    ///
    /// - Parameter template: a freshly built `LeitnerSystem`'s boxes, used only
    ///   for their review intervals. Reading them beats hard-coding the
    ///   package's schedule, which would quietly drift if it ever changed.
    static func boxes(
        from words: [WordToLearn],
        languageCode: String,
        matching template: [Box]
    ) -> [Box] {
        var pool = words
        let opening = openingWords.compactMap { word in
            pool.firstIndex { $0.targetWord == word }.map { pool.remove(at: $0) }
        }

        var remaining = pool[...]
        return template.indices.map { index in
            let isSessionBox = index == sessionBoxIndex
            let wanted = index < boxCounts.count ? boxCounts[index] : 0
            let fromPool = isSessionBox ? max(0, wanted - opening.count) : wanted
            let taken = remaining.prefix(fromPool)
            remaining = remaining.dropFirst(fromPool)

            let entries = isSessionBox ? opening + Array(taken) : Array(taken)
            let interval = template[index].reviewInterval
            return Box(
                cards: entries.map { card(from: $0, languageCode: languageCode) },
                reviewInterval: interval,
                // The session box is backdated past its own interval so it comes
                // up due; every other box was reviewed today. Box 1 ignores this
                // either way — a zero-day interval is always due.
                lastReviewedDate: isSessionBox
                    ? Calendar.current.date(byAdding: .day, value: -Int(interval) - 1, to: Date())
                    : Date()
            )
        }
    }

    private static func card(from entry: WordToLearn, languageCode: String) -> Card {
        Card(
            id: UUID(),
            word: Word(
                word: entry.targetWord,
                languageCode: languageCode,
                meaning: entry.englishWord,
                exampleSentence: entry.exampleSentence
            )
        )
    }
}
#endif
