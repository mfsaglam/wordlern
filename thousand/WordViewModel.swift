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

    private var leitnerSystem: LeitnerSystem
    private(set) var cardSet: [Card] = []
    private var currentIndex: Int = 0
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

    // Fetches the next set of cards from the Leitner system
    func fetchNextSet() {
        do {
            let dueCards = try leitnerSystem.dueForReview(limit: 10)
            (print(dueCards.count))
            
            cardSet = dueCards
            currentIndex = 0
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
        do {
            try leitnerSystem.updateCard(card, correct: correct)
            print("------------\(leitnerSystem.cardCountsPerBox)")
            saveProgress()
            
            currentIndex += 1
            loadNextCard()
        } catch {
            print(error)
        }
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
