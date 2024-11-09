//
//  RealmWord.swift
//  thousand
//
//  Created by Fatih Sağlam on 9.11.2024.
//

import RealmSwift
import Foundation
import LeitnerSwift

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
