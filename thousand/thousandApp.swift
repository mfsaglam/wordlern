//
//  thousandApp.swift
//  thousand
//
//  Created by Fatih Sağlam on 19.09.2024.
//

import SwiftUI
import LeitnerSwift

extension LeitnerSystem: LeitnerSystemProtocol { }

@main
struct thousandApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: WordViewModel(
                    cacheService: AnyCacheService(),
                    leitnerSystem: setupLeitnerSystem()
                )
            )
        }
    }
    
    func setupLeitnerSystem() -> LeitnerSystem {
        let system = LeitnerSystem()
        
        if !hasInitialCardsAdded() {
            addAllGermanWords(to: system)
            markInitialSetupComplete()
        }
        
        return system
    }
    
    func addAllGermanWords(to system: LeitnerSystem) {
        let germanWords = [
            ("Haus", "House"),
            ("Baum", "Tree"),
            ("ich", "i"),
            ("seine", "his"),
            ("dass", "that"),
            ("Er", "he"),
            ("war", "was"),
            // Add more words here
        ]
        
        germanWords.forEach { word, meaning in
            let word = Word(word: word, languageCode: "", meaning: meaning, exampleSentence: nil)
            let card = Card(id: UUID(), word: word)
            system.addCard(card)
        }
        print("all cards added to the system")
    }
    
    func hasInitialCardsAdded() -> Bool {
        // Check persistent storage (e.g., UserDefaults) if setup is done
        return UserDefaults.standard.bool(forKey: "InitialCardsAdded")
    }
    
    func markInitialSetupComplete() {
        // Mark initial setup as complete
        UserDefaults.standard.set(true, forKey: "InitialCardsAdded")
    }
}
