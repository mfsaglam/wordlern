//
//  ContentView.swift
//  thousand
//
//  Created by Fatih Sağlam on 19.09.2024.
//

import SwiftUI
import LeitnerSwift

import Foundation

protocol CardStore {
    func saveBoxes(_ box: [Box]) throws
    func fetchBoxes() -> [Box]
    func fetchBox(byId id: String) -> Box?
    func updateBox(_ box: Box) throws
    func deleteBox(_ box: Box) throws
}

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
        leitnerSystem.loadBoxes(boxes: cached)
        // Implement loading logic from cache
    }
}

import RealmSwift

// Realm model for Box
class RealmBox: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString // Primary key
    @Persisted var cards: RealmSwift.List<RealmCard>
    @Persisted var reviewInterval: TimeInterval
    @Persisted var lastReviewedDate: Date?
    
    convenience init(cards: [RealmCard], reviewInterval: TimeInterval, lastReviewedDate: Date?) {
        self.init()
        self.cards.append(objectsIn: cards)
        self.reviewInterval = reviewInterval
        self.lastReviewedDate = lastReviewedDate
    }
}

class RealmCard: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var word: RealmWord? // Now it holds the RealmWord object
    
    convenience init(id: UUID, word: Word) {
        self.init()
        self.id = id.uuidString
        self.word = RealmWord(word: word) // Convert Word to RealmWord
    }
}

// Realm model for Word
class RealmWord: Object {
    @Persisted var word: String = ""
    @Persisted var languageCode: String = ""
    @Persisted var meaning: String = ""
    @Persisted var exampleSentence: String?

    convenience init(word: Word) {
        self.init()
        self.word = word.word
        self.languageCode = word.languageCode
        self.meaning = word.meaning
        self.exampleSentence = word.exampleSentence
    }

    // Convert from RealmWord to Word
    func toWord() -> Word {
        return Word(
            word: self.word,
            languageCode: self.languageCode,
            meaning: self.meaning,
            exampleSentence: self.exampleSentence
        )
    }
}

// Convert RealmCard to Card
extension RealmCard {
    func toCard() -> Card {
        return Card(
            id: UUID(uuidString: self.id)!,
            word: self.word!.toWord() // Convert RealmWord back to Word
        )
    }
}

// Convert Card to RealmCard
extension Card {
    func toRealmCard() -> RealmCard {
        return RealmCard(id: self.id, word: self.word)
    }
}

// Convert RealmBox to Box
extension RealmBox {
    func toBox() -> Box {
        let cards: [Card] = self.cards.map { $0.toCard() }
        return Box(cards: cards, reviewInterval: self.reviewInterval, lastReviewedDate: self.lastReviewedDate)
    }
}

// Convert Box to RealmBox
extension Box {
    func toRealmBox() -> RealmBox {
        let realmCards = self.cards.map { $0.toRealmCard() }
        return RealmBox(cards: realmCards, reviewInterval: self.reviewInterval, lastReviewedDate: self.lastReviewedDate)
    }
}


class RealmCardStore: CardStore {
    private let realm: Realm

    init(realm: Realm = try! Realm()) {
        self.realm = realm
    }

    // Save all boxes
    func saveBoxes(_ boxes: [Box]) throws {
        let realmBoxes = boxes.map { $0.toRealmBox() }
        try realm.write {
            realm.delete(realm.objects(RealmBox.self)) // Delete all existing RealmBox objects
            realm.add(realmBoxes) // Add new RealmBox objects
        }
    }

    // Read all Boxes
    func fetchBoxes() -> [Box] {
        let realmBoxes = realm.objects(RealmBox.self)
        return realmBoxes.map { $0.toBox() }
    }

    // Read a Box by ID (for single Box fetch)
    func fetchBox(byId id: String) -> Box? {
        if let realmBox = realm.object(ofType: RealmBox.self, forPrimaryKey: id) {
            return realmBox.toBox()
        }
        return nil
    }

    // Update a Box
    func updateBox(_ box: Box) throws {
        let realmBox = box.toRealmBox()
        try realm.write {
            if let existingBox = realm.object(ofType: RealmBox.self, forPrimaryKey: realmBox.id) {
                existingBox.cards.removeAll()
                existingBox.cards.append(objectsIn: realmBox.cards)
                existingBox.reviewInterval = box.reviewInterval
                existingBox.lastReviewedDate = box.lastReviewedDate
            }
        }
    }

    // Delete a Box
    func deleteBox(_ box: Box) throws {
        let realmBox = box.toRealmBox()
        try realm.write {
            if let existingBox = realm.object(ofType: RealmBox.self, forPrimaryKey: realmBox.id) {
                realm.delete(existingBox)
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: WordViewModel
    
    init(viewModel: WordViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            if let card = viewModel.currentCard {
                Text(card.word.word)
                    .font(.largeTitle)
                    .padding()

                if viewModel.showMeaning {
                    Text(card.word.meaning)
                        .font(.title)
                        .padding()
                }
                
                Button(viewModel.showMeaning ? "Hide Translation" : "Show Translation") {
                    viewModel.toggleMeaning()
                }
                .padding()
                
                HStack {
                    Button("Correct") {
                        viewModel.markCard(correct: true)
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button("Incorrect") {
                        viewModel.markCard(correct: false)
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                VStack {
                    Text("No words to review.")
                    Button("Load next set of cards") {
                        viewModel.fetchNextSet()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
//
//#Preview {
//    ContentView(viewModel: .forPreview())
//}
//
//extension WordViewModel {
//    static func forPreview() -> WordViewModel {
//        .init(cacheService: AnyCacheService, leitnerSystem: LeitnerSystem())
//    }
//}

