//
//  Box+Extension.swift
//  thousand
//
//  Created by Fatih Sağlam on 9.11.2024.
//

import LeitnerSwift

// Convert Box to RealmBox
extension Box {
    func toRealmBox() -> RealmBox {
        let realmCards = self.cards.map { $0.toRealmCard() }
        return RealmBox(cards: realmCards, reviewInterval: self.reviewInterval, lastReviewedDate: self.lastReviewedDate)
    }
}
