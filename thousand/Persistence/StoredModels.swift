//
//  StoredModels.swift
//  thousand
//
//  Created by Fatih Sağlam on 29.09.2026.
//

import Foundation
import SwiftData

/// A Leitner box. `LeitnerSystem` boxes have no identity of their own — they
/// are an ordered, fixed-size array — so the position in that array is the key.
@Model
final class StoredBox {
    @Attribute(.unique) var index: Int
    var reviewInterval: TimeInterval
    var lastReviewedDate: Date?

    init(index: Int, reviewInterval: TimeInterval, lastReviewedDate: Date?) {
        self.index = index
        self.reviewInterval = reviewInterval
        self.lastReviewedDate = lastReviewedDate
    }
}

/// Cards are stored flat and point at their box by index. Keeping them out of
/// a relationship is what makes a move between boxes a single field write
/// instead of a rewrite of both boxes' card lists.
@Model
final class StoredCard {
    @Attribute(.unique) var id: UUID
    var boxIndex: Int
    var word: String
    var languageCode: String
    var meaning: String
    var exampleSentence: String?

    init(
        id: UUID,
        boxIndex: Int,
        word: String,
        languageCode: String,
        meaning: String,
        exampleSentence: String?
    ) {
        self.id = id
        self.boxIndex = boxIndex
        self.word = word
        self.languageCode = languageCode
        self.meaning = meaning
        self.exampleSentence = exampleSentence
    }
}
