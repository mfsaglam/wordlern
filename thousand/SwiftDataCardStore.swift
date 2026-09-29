//
//  SwiftDataCardStore.swift
//  thousand
//
//  Created by Fatih Sağlam on 29.09.2026.
//

import Foundation
import LeitnerSwift
import SwiftData

/// Sendable copies of what a save needs. `Box` and `Card` come from
/// LeitnerSwift and are not Sendable, so they never cross into the writer.
private struct BoxSnapshot: Sendable {
    let index: Int
    let reviewInterval: TimeInterval
    let lastReviewedDate: Date?
}

private struct CardSnapshot: Sendable {
    let id: UUID
    let boxIndex: Int
    let word: String
    let languageCode: String
    let meaning: String
    let exampleSentence: String?
}

/// Writes happen here, on the actor's own background context, never on main.
@ModelActor
private actor CardWriter {
    func save(boxes: [BoxSnapshot], cards: [CardSnapshot]) throws {
        var staleBoxes = Dictionary(
            try modelContext.fetch(FetchDescriptor<StoredBox>()).map { ($0.index, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        for box in boxes {
            if let existing = staleBoxes.removeValue(forKey: box.index) {
                if existing.reviewInterval != box.reviewInterval {
                    existing.reviewInterval = box.reviewInterval
                }
                if existing.lastReviewedDate != box.lastReviewedDate {
                    existing.lastReviewedDate = box.lastReviewedDate
                }
            } else {
                modelContext.insert(
                    StoredBox(
                        index: box.index,
                        reviewInterval: box.reviewInterval,
                        lastReviewedDate: box.lastReviewedDate
                    )
                )
            }
        }
        staleBoxes.values.forEach(modelContext.delete)

        var staleCards = Dictionary(
            try modelContext.fetch(FetchDescriptor<StoredCard>()).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        for card in cards {
            if let existing = staleCards.removeValue(forKey: card.id) {
                // Only the box can change while a session runs; word content
                // is replaced wholesale by a re-seed, never edited in place.
                if existing.boxIndex != card.boxIndex {
                    existing.boxIndex = card.boxIndex
                }
            } else {
                modelContext.insert(
                    StoredCard(
                        id: card.id,
                        boxIndex: card.boxIndex,
                        word: card.word,
                        languageCode: card.languageCode,
                        meaning: card.meaning,
                        exampleSentence: card.exampleSentence
                    )
                )
            }
        }
        staleCards.values.forEach(modelContext.delete)

        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
}

/// SwiftData-backed `CardStore`.
///
/// Reads run on the caller's thread — they happen once, at launch. Writes are
/// handed to a background `CardWriter` and chained so they land in call order.
final class SwiftDataCardStore: CardStore {
    private let context: ModelContext
    private let writer: CardWriter
    private var pendingWrite: Task<Void, Never>?

    init(container: ModelContainer) {
        self.context = ModelContext(container)
        self.writer = CardWriter(modelContainer: container)
    }

    func saveBoxes(_ boxes: [Box]) throws {
        let boxSnapshots = boxes.enumerated().map { index, box in
            BoxSnapshot(
                index: index,
                reviewInterval: box.reviewInterval,
                lastReviewedDate: box.lastReviewedDate
            )
        }
        let cardSnapshots = boxes.enumerated().flatMap { index, box in
            box.cards.map { card in
                CardSnapshot(
                    id: card.id,
                    boxIndex: index,
                    word: card.word.word,
                    languageCode: card.word.languageCode,
                    meaning: card.word.meaning,
                    exampleSentence: card.word.exampleSentence
                )
            }
        }

        let previous = pendingWrite
        pendingWrite = Task { [writer] in
            await previous?.value
            do {
                try await writer.save(boxes: boxSnapshots, cards: cardSnapshots)
            } catch {
                print("SwiftDataCardStore save failed: \(error)")
            }
        }
    }

    /// Waits for every queued write to land. Tests only — the app never needs
    /// to know when a save finishes.
    func waitForWrites() async {
        await pendingWrite?.value
    }

    func fetchBoxes() -> [Box] {
        do {
            let storedBoxes = try context.fetch(
                FetchDescriptor<StoredBox>(sortBy: [SortDescriptor(\.index)])
            )
            guard !storedBoxes.isEmpty else { return [] }

            let cardsByBox = Dictionary(grouping: try context.fetch(FetchDescriptor<StoredCard>())) {
                $0.boxIndex
            }
            return storedBoxes.map { box in
                Box(
                    cards: (cardsByBox[box.index] ?? []).map { $0.toCard() },
                    reviewInterval: box.reviewInterval,
                    lastReviewedDate: box.lastReviewedDate
                )
            }
        } catch {
            print("SwiftDataCardStore fetch failed: \(error)")
            return []
        }
    }

    /// `id` is the box's position in the Leitner array — boxes have no other
    /// identity. Unused today; see the cleanup step.
    func fetchBox(byId id: String) -> Box? {
        guard let index = Int(id) else { return nil }
        let boxes = fetchBoxes()
        guard boxes.indices.contains(index) else { return nil }
        return boxes[index]
    }

    func updateBox(_ box: Box) throws {
        // A Box carries no identity, so there is nothing to address it by.
        // `saveBoxes` is the only write path the app uses.
    }

    func deleteBox(_ box: Box) throws {
        // Same as `updateBox`.
    }

}

private extension StoredCard {
    func toCard() -> Card {
        Card(
            id: id,
            word: Word(
                word: word,
                languageCode: languageCode,
                meaning: meaning,
                exampleSentence: exampleSentence
            )
        )
    }
}
