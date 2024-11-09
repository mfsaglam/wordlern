//
//  Card.swift
//  thousand
//
//  Created by Fatih Sağlam on 9.11.2024.
//

import LeitnerSwift

// Convert Card to RealmCard
extension Card {
    func toRealmCard() -> RealmCard {
        return RealmCard(id: self.id, word: self.word)
    }
}
