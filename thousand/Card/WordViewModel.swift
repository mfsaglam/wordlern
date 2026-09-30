//
//  WordViewModel.swift
//  thousand
//
//  Created by Fatih Sağlam on 9.11.2024.
//

import LeitnerSwift
import SwiftUI

class WordViewModel: ObservableObject {
    @Published var currentCard: Card?  // The current card to display
    @Published var showMeaning: Bool = false  // Controls whether the word meaning is visible
    /// True while the last answer can still be taken back.
    @Published private(set) var canUndo: Bool = false
    /// Set when a session runs out of cards, and held until the user leaves the
    /// session end screen. Nil at every other moment.
    @Published private(set) var finishedSession: SessionSummary?

    /// What one finished session did, for screen 4 of `docs/DESIGN.md`.
    struct SessionSummary: Equatable {
        let reviewed: Int
        /// Cards answered correctly. A correct answer is what moves a card up a
        /// box; cards already in the last box stay there, but the answer still
        /// counts as a win.
        let movedUp: Int
        let masteredBefore: Int
        let masteredAfter: Int

        var toReview: Int {
            reviewed - movedUp
        }
    }

    /// Everything needed to put the session back the way it was before one answer.
    /// The whole box layout is kept rather than the single move, because
    /// `LeitnerSystem` exposes no reverse of `updateCard` — only `loadBoxes`.
    /// The session counters ride along so undo does not leave the end screen
    /// reporting an answer the user took back.
    private struct UndoState {
        let boxes: [Box]
        let index: Int
        let reviewed: Int
        let movedUp: Int
    }

    private var leitnerSystem: LeitnerSystem
    private(set) var cardSet: [Card] = []
    private var currentIndex: Int = 0
    private var undoState: UndoState?
    private var reviewed: Int = 0
    private var movedUp: Int = 0
    private var masteredAtSessionStart: Int = 0
    private let cardStore: CardStore
    /// Size of the whole word list, read from `de.json` at launch regardless of
    /// whether a re-seed happened. The denominator `retiredCount` needs, since a
    /// card that reaches box 5 on a correct answer is removed from the Leitner
    /// system (and the store) outright rather than staying there.
    private let totalWordCount: Int

    init(cardStore: CardStore, leitnerSystem: LeitnerSystem, totalWordCount: Int = 1000) {
        self.cardStore = cardStore
        self.leitnerSystem = leitnerSystem
        self.totalWordCount = totalWordCount
        loadCachedProgress()
        writeProgressSnapshot()
    }

    func onAppear() {
        // A finished session owns the screen until the user asks for progress,
        // so a re-appearance must not start the next one over it.
        if finishedSession != nil {
            return
        }
        // Opening the app (or re-appearing, e.g. after the About sheet is
        // dismissed) should never start a session on its own — only restore
        // one already in progress. With no session running this is a no-op,
        // which leaves `currentCard` and `finishedSession` both nil and the
        // summary screen on screen.
        guard !cardSet.isEmpty else { return }
        loadNextCard()
    }
    
    var progress: [Int] {
        leitnerSystem.cardCountsPerBox
    }

    /// `LeitnerSystem.updateCard` removes a card outright once it is answered
    /// correctly in the last box — retired, not promoted — so it stops showing
    /// up in `progress` at all. The word list only shrinks by a re-seed, never
    /// by review, so whatever `progress` no longer accounts for has retired.
    var retiredCount: Int {
        max(0, totalWordCount - progress.reduce(0, +))
    }

    /// Boxes 3–5 plus every retired word — see `retiredCount`. The one number
    /// both the summary and session-end screens must agree on.
    var masteredWordCount: Int {
        masteredCount(in: progress) + retiredCount
    }

    /// How many cards are due for review right now, across every box. Mirrors
    /// `LeitnerSystem.dueForReview`'s own due check, but counts instead of
    /// throwing when there are none.
    var dueCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return leitnerSystem.allBoxes.reduce(0) { count, box in
            Calendar.current.startOfDay(for: box.nextReviewDate) <= today
                ? count + box.cards.count
                : count
        }
    }

    /// The earliest moment a card next becomes due, across every box that
    /// still holds cards. Nil once `dueCount` is positive — there is nothing
    /// to wait for — or if the word list is empty outright.
    var nextReviewDate: Date? {
        guard dueCount == 0 else { return nil }
        return leitnerSystem.allBoxes
            .filter { !$0.cards.isEmpty }
            .map(\.nextReviewDate)
            .min()
    }

    /// When the next card comes due and how many will be waiting then — all the
    /// reminder notification needs. Nil whenever `nextReviewDate` is.
    var nextReview: NextReview? {
        guard let date = nextReviewDate else { return nil }
        let count = leitnerSystem.allBoxes.reduce(0) { count, box in
            box.nextReviewDate <= date ? count + box.cards.count : count
        }
        return NextReview(date: date, count: count)
    }

    /// What `nextReview` reports. Kept as a value so `ReminderScheduler` never
    /// touches the Leitner system itself.
    struct NextReview: Equatable {
        let date: Date
        let count: Int
    }

    /// 1-based box the card on screen currently lives in, for the header badge.
    var currentBoxNumber: Int? {
        guard let currentCard else { return nil }
        guard let index = leitnerSystem.allBoxes.firstIndex(where: { box in
            box.cards.contains { $0.id == currentCard.id }
        }) else { return nil }
        return index + 1
    }

    /// 1-based position of the card on screen within the current session.
    var sessionPosition: Int {
        currentIndex + 1
    }

    var sessionTotal: Int {
        cardSet.count
    }

    // Fetches the next set of cards from the Leitner system
    func fetchNextSet() {
        do {
            let dueCards = try leitnerSystem.dueForReview(limit: 10)
            cardSet = dueCards
            currentIndex = 0
            reviewed = 0
            movedUp = 0
            masteredAtSessionStart = masteredWordCount
            finishedSession = nil
            clearUndo()
            loadNextCard()
        } catch {
            print(error)
        }
    }

    // Loads the next card in the set
    private func loadNextCard() {
        guard currentIndex < cardSet.count else {
            cardSet.removeAll()
            currentCard = nil
            // The session is over and the card screen is gone, so there is
            // nothing left to undo onto.
            clearUndo()
            // An empty due set is not a finished session — with nothing to
            // review the user belongs on the summary screen, not on a
            // `0 cards reviewed` celebration.
            if reviewed > 0 {
                finishedSession = SessionSummary(
                    reviewed: reviewed,
                    movedUp: movedUp,
                    masteredBefore: masteredAtSessionStart,
                    masteredAfter: masteredWordCount
                )
            }
            return
        }
        currentCard = cardSet[currentIndex]
        showMeaning = false
    }

    // Toggles the meaning visibility
    func toggleMeaning() {
        showMeaning.toggle()
    }

    // Handles marking a card as correct or incorrect
    func markCard(correct: Bool) {
        guard let card = currentCard else { return }
        let snapshot = UndoState(
            boxes: leitnerSystem.allBoxes,
            index: currentIndex,
            reviewed: reviewed,
            movedUp: movedUp
        )
        do {
            try leitnerSystem.updateCard(card, correct: correct)
            saveProgress()

            reviewed += 1
            if correct {
                movedUp += 1
            }
            currentIndex += 1
            loadNextCard()
            // After the last card `loadNextCard` clears the undo state again.
            if currentCard != nil {
                undoState = snapshot
                canUndo = true
            }
        } catch {
            print(error)
        }
    }

    /// Takes back the last answer and puts its card back on screen. Only the
    /// most recent answer can be undone, and only while the session is running.
    func undoLastAnswer() {
        guard let undoState else { return }
        leitnerSystem.loadBoxes(boxes: undoState.boxes)
        currentIndex = undoState.index
        reviewed = undoState.reviewed
        movedUp = undoState.movedUp
        clearUndo()
        saveProgress()
        loadNextCard()
    }

    /// Leaves the session end screen for the summary. The next session starts
    /// only when the user asks for it there.
    func dismissSessionEnd() {
        finishedSession = nil
    }

    private func clearUndo() {
        undoState = nil
        canUndo = false
    }

    // Caches user progress
    private func saveProgress() {
        try! cardStore.saveBoxes(leitnerSystem.allBoxes)
        // Implement saving logic (e.g., UserDefaults, file storage)
        writeProgressSnapshot()
    }

    /// The six numbers the widget needs, from the same values `SummaryScreen`
    /// shows, so the two can never disagree. Called wherever progress
    /// changes, plus once at launch so the file exists before any answer.
    private func writeProgressSnapshot() {
        ProgressSnapshot(
            boxCounts: progress,
            mastered: masteredWordCount,
            total: totalWordCount,
            dueCount: dueCount,
            nextDue: nextReviewDate,
            updated: Date()
        ).write()
    }

    // Loads cached progress if available
    private func loadCachedProgress() {
        let cached = cardStore.fetchBoxes()
        if !cached.isEmpty {
            leitnerSystem.loadBoxes(boxes: cached)
        }
    }
}

extension WordViewModel {
    static func forPreview() -> WordViewModel {
        .init(cardStore: AnyCardStore(), leitnerSystem: .forPreview())
    }
}

class AnyCardStore: CardStore {
    func saveBoxes(_ box: [Box]) throws {}
    func fetchBoxes() -> [Box] {
        [.forPreview()]
    }
}

extension Box {
    static func forPreview() -> Box {
        .init(
            cards: [.forPreview()],
            reviewInterval: 1,
            lastReviewedDate: nil
        )
    }
}

extension Card {
    static func forPreview() -> Card {
        .init(word: .forPreview())
    }
}

extension Word {
    static func forPreview() -> Word {
        .init(word: "sample word", languageCode: "de", meaning: "sample meaning", exampleSentence: nil)
    }
}

extension LeitnerSystem {
    static func forPreview() -> LeitnerSystem {
        .init()
    }
}
