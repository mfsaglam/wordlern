//
//  ContentView.swift
//  thousand
//
//  Created by Fatih Sağlam on 19.09.2024.
//

import SwiftUI
import LeitnerSwift

import Foundation

protocol CacheService { }
protocol LeitnerSystemProtocol { 
    func updateCard(_ card: Card, correct: Bool)
    func dueForReview(limit: Int) -> [Card]
    func loadBoxes(boxes: [Box])
}

class WordViewModel: ObservableObject {
    @Published var currentCard: Card?  // The current card to display
    @Published var showMeaning: Bool = false  // Controls whether the word meaning is visible

    private var leitnerSystem: LeitnerSystemProtocol
    private(set) var cardSet: [Card] = []
    private var currentIndex: Int = 0
    private let cacheService: CacheService

    init(cacheService: CacheService, leitnerSystem: LeitnerSystemProtocol) {
        self.cacheService = cacheService
        self.leitnerSystem = leitnerSystem
        loadCachedProgress()
        print("viewModel initialized")
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
        let dueCards = leitnerSystem.dueForReview(limit: 10)
        
        cardSet = dueCards
        currentIndex = 0
        loadNextCard()
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
        leitnerSystem.updateCard(card, correct: correct)
        saveProgress()

        currentIndex += 1
        loadNextCard()
    }

    // Caches user progress
    private func saveProgress() {
        // Implement saving logic (e.g., UserDefaults, file storage)
    }

    // Loads cached progress if available
    private func loadCachedProgress() {
        // Implement loading logic from cache
    }
}

class AnyCacheService: CacheService { }

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

