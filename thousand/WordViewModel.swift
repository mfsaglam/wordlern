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

    /// Everything needed to put the session back the way it was before one answer.
    /// The whole box layout is kept rather than the single move, because
    /// `LeitnerSystem` exposes no reverse of `updateCard` — only `loadBoxes`.
    private struct UndoState {
        let boxes: [Box]
        let index: Int
    }

    private var leitnerSystem: LeitnerSystem
    private(set) var cardSet: [Card] = []
    private var currentIndex: Int = 0
    private var undoState: UndoState?
    private let cardStore: CardStore

    init(cardStore: CardStore, leitnerSystem: LeitnerSystem) {
        self.cardStore = cardStore
        self.leitnerSystem = leitnerSystem
        loadCachedProgress()
    }

    func onAppear() {
        if cardSet.isEmpty {
            fetchNextSet()
        } else {
            loadNextCard()
        }
    }
    
    var progress: [Int] {
        leitnerSystem.cardCountsPerBox
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
            (print(dueCards.count))
            
            cardSet = dueCards
            currentIndex = 0
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
        let snapshot = UndoState(boxes: leitnerSystem.allBoxes, index: currentIndex)
        do {
            try leitnerSystem.updateCard(card, correct: correct)
            saveProgress()

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
        clearUndo()
        saveProgress()
        loadNextCard()
    }

    private func clearUndo() {
        undoState = nil
        canUndo = false
    }

    // Caches user progress
    private func saveProgress() {
        try! cardStore.saveBoxes(leitnerSystem.allBoxes)
        // Implement saving logic (e.g., UserDefaults, file storage)
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
    func fetchBox(byId id: String) -> Box? {
        .forPreview()
    }
    func updateBox(_ box: Box) throws {}
    func deleteBox(_ box: Box) throws {}
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
