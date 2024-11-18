//
//  thousandApp.swift
//  thousand
//
//  Created by Fatih Sağlam on 19.09.2024.
//

import SwiftUI
import LeitnerSwift

@main
struct thousandApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: WordViewModel(
                    cardStore: RealmCardStore(),
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
        let germanWords = loadGermanWords()
        
        germanWords.forEach { word, meaning in
            let word = Word(word: word, languageCode: "", meaning: meaning, exampleSentence: nil)
            let card = Card(id: UUID(), word: word)
            system.addCard(card)
        }
    }
    
    func hasInitialCardsAdded() -> Bool {
        // Check persistent storage (e.g., UserDefaults) if setup is done
        return UserDefaults.standard.bool(forKey: "InitialCardsAdded")
    }
    
    func markInitialSetupComplete() {
        // Mark initial setup as complete
        UserDefaults.standard.set(true, forKey: "InitialCardsAdded")
    }
    
    func loadGermanWords() -> [(String, String)] {
        guard let url = Bundle.main.url(forResource: "de", withExtension: "json") else {
            print("Error: JSON file not found.")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            
            let languageData = try JSONDecoder().decode(LanguageData.self, from: data)
            
            let wordsArray = languageData.words.map { ($0.targetWord, NSLocalizedString($0.englishWord, comment: "")) }
            return wordsArray
            
        } catch {
            print("Error loading or parsing JSON: \(error)")
            return []
        }
    }
}

struct LanguageData: Codable {
    let languageCode: String
    let languageName: String
    let languageNativeName: String
    let words: [WordToLearn]
}

struct WordToLearn: Codable {
    let rank: Int
    let targetWord: String
    let englishWord: String
}
