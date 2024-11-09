//
//  RealmCard.swift
//  thousand
//
//  Created by Fatih Sağlam on 9.11.2024.
//

import LeitnerSwift
import Foundation
import RealmSwift

class RealmCard: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var word: RealmWord? // Now it holds the RealmWord object
    
    convenience init(id: UUID, word: Word) {
        self.init()
        self.id = id.uuidString
        self.word = RealmWord(word: word) // Convert Word to RealmWord
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
