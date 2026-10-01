//
//  thousandApp.swift
//  thousand
//
//  Created by Fatih Sağlam on 19.09.2024.
//

import SwiftUI
import LeitnerSwift
import SwiftData

@main
struct thousandApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: StoredBox.self, StoredCard.self)
        } catch {
            fatalError("Could not create the SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        let languageData = loadLanguageData()
        WindowGroup {
            ContentView(
                viewModel: WordViewModel(
                    cardStore: SwiftDataCardStore(container: container),
                    leitnerSystem: setupLeitnerSystem(with: languageData),
                    totalWordCount: languageData?.words.count ?? 0
                )
            )
        }
    }

    func setupLeitnerSystem(with languageData: LanguageData?) -> LeitnerSystem {
        let system = LeitnerSystem()

        if let languageData, languageData.contentVersion > seededContentVersion() {
            wipeStoredContent()
            addAllGermanWords(to: system, from: languageData)
            markSeeded(contentVersion: languageData.contentVersion)
        }

        #if DEBUG
        if DemoContent.isRequested, let languageData {
            applyDemoContent(to: system, from: languageData)
        }
        #endif

        return system
    }

    #if DEBUG
    /// Replaces whatever is stored with `DemoContent`'s fixed distribution.
    ///
    /// The store is emptied rather than rewritten: `WordViewModel` only loads
    /// cached boxes when the store has some, so leaving it empty lets the demo
    /// state stand and keeps it off disk until a card is actually answered.
    func applyDemoContent(to system: LeitnerSystem, from languageData: LanguageData) {
        wipeStoredContent()
        system.loadBoxes(
            boxes: DemoContent.boxes(
                from: languageData.words,
                languageCode: languageData.languageCode,
                matching: system.allBoxes
            )
        )
    }
    #endif

    func addAllGermanWords(to system: LeitnerSystem, from languageData: LanguageData) {
        languageData.words.forEach { entry in
            let word = Word(
                word: entry.targetWord,
                languageCode: languageData.languageCode,
                meaning: entry.englishWord,
                exampleSentence: entry.exampleSentence
            )
            let card = Card(id: UUID(), word: word)
            system.addCard(card)
        }
    }

    /// Deletes every stored box and card so the fresh seed from `addAllGermanWords`
    /// is what the app loads next, with no leftover progress from the old content.
    func wipeStoredContent() {
        let context = container.mainContext
        do {
            try context.delete(model: StoredBox.self)
            try context.delete(model: StoredCard.self)
        } catch {
            print("Error wiping stored content: \(error)")
        }
    }

    func seededContentVersion() -> Int {
        UserDefaults.standard.integer(forKey: "seededContentVersion")
    }

    func markSeeded(contentVersion: Int) {
        UserDefaults.standard.set(contentVersion, forKey: "seededContentVersion")
    }

    func loadLanguageData() -> LanguageData? {
        guard let url = Bundle.main.url(forResource: "de", withExtension: "json") else {
            print("Error: JSON file not found.")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(LanguageData.self, from: data)
        } catch {
            print("Error loading or parsing JSON: \(error)")
            return nil
        }
    }
}

struct LanguageData: Codable {
    let languageCode: String
    let contentVersion: Int
    let languageName: String
    let languageNativeName: String
    let words: [WordToLearn]
}

struct WordToLearn: Codable {
    let rank: Int
    let targetWord: String
    let englishWord: String
    /// Absent for any word whose example sentence has not been written yet; the card
    /// then draws without the sentence box.
    let exampleSentence: String?
}
