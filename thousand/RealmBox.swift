//
//  RealmBox.swift
//  thousand
//
//  Created by Fatih Sağlam on 9.11.2024.
//

import LeitnerSwift
import RealmSwift
import Foundation

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

// Convert RealmBox to Box
extension RealmBox {
    func toBox() -> Box {
        let cards: [Card] = self.cards.map { $0.toCard() }
        return Box(cards: cards, reviewInterval: self.reviewInterval, lastReviewedDate: self.lastReviewedDate)
    }
}
