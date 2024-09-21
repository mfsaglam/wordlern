//
//  ContentView.swift
//  thousand
//
//  Created by Fatih Sağlam on 19.09.2024.
//

import SwiftUI
import LeitnerSwift

import Foundation

class WordViewModel: ObservableObject {
    @Published var currentCard: Card?  // The current card to display
    @Published var showMeaning: Bool = false  // Controls whether the word meaning is visible
    @Published var isEmpty: Bool = false  // Indicates if there are no more cards in the set

    private var leitnerSystem: LeitnerSystem
    private var cardSet: [Card] = []
    private var currentIndex: Int = 0
    private let cacheKey = "userProgress"

    init(leitnerSystem: LeitnerSystem) {
        self.leitnerSystem = leitnerSystem
        loadCachedProgress()
    }

    func onAppear() {
        if cardSet.isEmpty {
            fetchFirstSet()
        } else {
            loadNextCard()
        }
    }

    // Fetches the first set of cards from the Leitner system
    private func fetchFirstSet() {
        let dueCards = leitnerSystem.dueForReview(limit: 10)
        if dueCards.isEmpty {
            isEmpty = true
        } else {
            cardSet = dueCards
            currentIndex = 0
            loadNextCard()
        }
    }

    // Loads the next card in the set
    private func loadNextCard() {
        guard currentIndex < cardSet.count else {
            isEmpty = true
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
        var updatedCard = card
        leitnerSystem.updateCard(updatedCard, correct: correct)
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


struct ContentView: View {
    @ObservedObject var viewModel = WordViewModel(leitnerSystem: LeitnerSystem())
    
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
                Text("No words to review.")
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

#Preview {
    ContentView()
}

