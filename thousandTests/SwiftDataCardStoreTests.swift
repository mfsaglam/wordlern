//
//  SwiftDataCardStoreTests.swift
//  thousandTests
//
//  Created by Fatih Sağlam on 29.09.2026.
//

import LeitnerSwift
import SwiftData
import XCTest
@testable import thousand

final class SwiftDataCardStoreTests: XCTestCase {
    func test_fetchBoxes_onEmptyStore_returnsNothing() throws {
        let sut = try makeSUT()

        XCTAssertTrue(sut.store.fetchBoxes().isEmpty)
    }

    func test_saveBoxes_thenFetch_roundTripsCardsIntoTheRightBoxes() async throws {
        let sut = try makeSUT()
        let first = makeCard(word: "das Haus", meaning: "house")
        let second = makeCard(word: "gehen", meaning: "to go")

        try sut.store.saveBoxes([
            makeBox(cards: [first], reviewInterval: 1),
            makeBox(cards: [second], reviewInterval: 2)
        ])
        await sut.store.waitForWrites()

        let boxes = readBack(sut)
        XCTAssertEqual(boxes.count, 2)
        XCTAssertEqual(boxes[0].cards.map(\.id), [first.id])
        XCTAssertEqual(boxes[0].cards.first?.word.word, "das Haus")
        XCTAssertEqual(boxes[0].reviewInterval, 1)
        XCTAssertEqual(boxes[1].cards.map(\.id), [second.id])
        XCTAssertEqual(boxes[1].cards.first?.word.meaning, "to go")
    }

    func test_saveBoxes_movingACard_doesNotDuplicateOrLoseIt() async throws {
        let sut = try makeSUT()
        let card = makeCard(word: "die Zeit", meaning: "time")

        try sut.store.saveBoxes([makeBox(cards: [card]), makeBox(cards: [])])
        await sut.store.waitForWrites()
        try sut.store.saveBoxes([makeBox(cards: []), makeBox(cards: [card])])
        await sut.store.waitForWrites()

        let boxes = readBack(sut)
        XCTAssertEqual(boxes[0].cards.count, 0)
        XCTAssertEqual(boxes[1].cards.map(\.id), [card.id])
        XCTAssertEqual(try sut.context.fetch(FetchDescriptor<StoredCard>()).count, 1)
    }

    func test_saveBoxes_droppingACard_deletesIt() async throws {
        let sut = try makeSUT()
        let kept = makeCard(word: "und", meaning: "and")
        let dropped = makeCard(word: "oder", meaning: "or")

        try sut.store.saveBoxes([makeBox(cards: [kept, dropped])])
        await sut.store.waitForWrites()
        try sut.store.saveBoxes([makeBox(cards: [kept])])
        await sut.store.waitForWrites()

        XCTAssertEqual(try sut.context.fetch(FetchDescriptor<StoredCard>()).map(\.id), [kept.id])
    }

    func test_saveBoxes_calledRepeatedly_landsInCallOrder() async throws {
        let sut = try makeSUT()
        let card = makeCard(word: "sehen", meaning: "to see")

        for index in 0..<5 {
            try sut.store.saveBoxes([
                makeBox(cards: index == 0 ? [card] : []),
                makeBox(cards: index == 1 ? [card] : []),
                makeBox(cards: index >= 2 ? [card] : [])
            ])
        }
        await sut.store.waitForWrites()

        // The last call put the card in box 3; an out-of-order write would
        // leave it somewhere else.
        XCTAssertEqual(try sut.context.fetch(FetchDescriptor<StoredCard>()).map(\.boxIndex), [2])
    }

    // MARK: - Card-level review dates

    func test_saveBoxes_thenFetch_roundTripsTheCardsOwnReviewDate() async throws {
        let sut = try makeSUT()
        let reviewedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let reviewed = makeCard(word: "lesen", meaning: "to read", lastReviewedDate: reviewedAt)
        let neverReviewed = makeCard(word: "neu", meaning: "new")

        try sut.store.saveBoxes([makeBox(cards: [reviewed, neverReviewed], lastReviewedDate: Date())])
        await sut.store.waitForWrites()

        let cards = readBack(sut)[0].cards
        XCTAssertEqual(cards.first { $0.id == reviewed.id }?.lastReviewedDate, reviewedAt)
        XCTAssertNil(
            cards.first { $0.id == neverReviewed.id }?.lastReviewedDate,
            "A card that was never answered must come back without a date so the library treats it as due."
        )
    }

    func test_saveBoxes_answeringACard_persistsItsNewReviewDate() async throws {
        let sut = try makeSUT()
        let firstAnswer = Date(timeIntervalSince1970: 1_700_000_000)
        let secondAnswer = Date(timeIntervalSince1970: 1_700_600_000)
        let card = makeCard(word: "schreiben", meaning: "to write", lastReviewedDate: firstAnswer)

        try sut.store.saveBoxes([makeBox(cards: [card]), makeBox(cards: [])])
        await sut.store.waitForWrites()

        // The same card is answered again and promoted: both the box and the
        // date have to be written to the existing record.
        let answeredAgain = Card(id: card.id, word: card.word, lastReviewedDate: secondAnswer)
        try sut.store.saveBoxes([makeBox(cards: []), makeBox(cards: [answeredAgain])])
        await sut.store.waitForWrites()

        let stored = try sut.context.fetch(FetchDescriptor<StoredCard>())
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored.first?.lastReviewedDate, secondAnswer, "An update used to write boxIndex only, leaving the date stale.")
        XCTAssertEqual(readBack(sut)[1].cards.first?.lastReviewedDate, secondAnswer)
    }

    /// What the whole step is for: a card answered correctly must not come back
    /// early after a relaunch, even when its new box was reviewed long ago.
    func test_answeredCard_survivesARelaunch_withoutBecomingDueEarly() async throws {
        let sut = try makeSUT()
        let now = Date()
        let staleBoxDate = Calendar.current.date(byAdding: .day, value: -10, to: now)!
        let card = makeCard(word: "verstehen", meaning: "to understand", lastReviewedDate: now)

        // Box 1 has a 3 day interval and was last touched 10 days ago.
        try sut.store.saveBoxes([
            makeBox(cards: [], reviewInterval: 0, lastReviewedDate: now),
            makeBox(cards: [card], reviewInterval: 3, lastReviewedDate: staleBoxDate)
        ])
        await sut.store.waitForWrites()

        // Relaunch: a fresh system loads what was persisted.
        let system = LeitnerSystem(boxAmount: 2)
        system.loadBoxes(boxes: readBack(sut))

        XCTAssertEqual(system.dueCount, 0, "The persisted card date keeps the card scheduled 3 days out.")
        XCTAssertThrowsError(try system.dueForReview())
    }

    // MARK: - Helpers

    private struct SUT {
        let store: SwiftDataCardStore
        let container: ModelContainer
        let context: ModelContext
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> SUT {
        let container = try ModelContainer(
            for: StoredBox.self, StoredCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let store = SwiftDataCardStore(container: container)
        addTeardownBlock { [weak store] in
            XCTAssertNil(store, "SwiftDataCardStore leaked", file: file, line: line)
        }
        return SUT(store: store, container: container, context: ModelContext(container))
    }

    /// Reads through a fresh store so the assertions see what was persisted,
    /// not a context that happens to be holding the objects already.
    private func readBack(_ sut: SUT) -> [Box] {
        SwiftDataCardStore(container: sut.container).fetchBoxes()
    }

    private func makeBox(
        cards: [Card],
        reviewInterval: TimeInterval = 1,
        lastReviewedDate: Date? = nil
    ) -> Box {
        Box(cards: cards, reviewInterval: reviewInterval, lastReviewedDate: lastReviewedDate)
    }

    private func makeCard(word: String, meaning: String, lastReviewedDate: Date? = nil) -> Card {
        Card(
            word: Word(
                word: word,
                languageCode: "de",
                meaning: meaning,
                exampleSentence: nil
            ),
            lastReviewedDate: lastReviewedDate
        )
    }
}
