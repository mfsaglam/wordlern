//
//  thousandTests.swift
//  thousandTests
//
//  Created by Fatih Sağlam on 19.09.2024.
//

import XCTest
import LeitnerSwift
@testable import thousand

final class thousandTests: XCTestCase {
    func test_init_withCachedBoxes_loadsCachedDataIntoLeitnerSystem() {
        // Given
        let cachedCard = makeCard()
        let cachedStore = FakeCardStore(boxes: [
            Box(cards: [cachedCard], reviewInterval: 1, lastReviewedDate: nil)
        ])

        // When
        let sut = WordViewModel(cardStore: cachedStore, leitnerSystem: LeitnerSystem())

        // Then
        XCTAssertEqual(sut.progress.first, 1, "Expected the cached card to be loaded into the first box.")
    }

    private func makeCard(id: UUID = UUID()) -> Card {
        Card(id: id, word: anyWord)
    }

    private var anyWord: Word {
        Word(word: "any word", languageCode: "any", meaning: "any meaning", exampleSentence: nil)
    }
}

private class FakeCardStore: CardStore {
    private let boxes: [Box]

    init(boxes: [Box]) {
        self.boxes = boxes
    }

    func saveBoxes(_ box: [Box]) throws {}
    func fetchBoxes() -> [Box] { boxes }
}
