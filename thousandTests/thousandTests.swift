////
////  thousandTests.swift
////  thousandTests
////
////  Created by Fatih Sağlam on 19.09.2024.
////
//
//import XCTest
//import LeitnerSwift
//@testable import thousand
//
//final class thousandTests: XCTestCase {
//    func test_onAppear_withCachedData_shouldLoadCachedData() {
//        // Given
//        let cachedCards = [makeCard(), makeCard()]
//        let mockCache = MockCacheService(storedCards: cachedCards)
//        let sut = WordViewModel(cacheService: mockCache, leitnerSystem: MockLeitnerSystem())
//        
//        // When
//        sut.onAppear()
//        
//        // Then
//        XCTAssertEqual(sut.cardSet, cachedCards, "Expected to load cached data on appear.")
//        XCTAssertFalse(sut.cardSet.isEmpty, "Cards should not be empty if cache is available.")
//    }
//    
//    class MockCacheService: CacheService {
//        let storedCards: [Card]
//        init(storedCards: [Card]) {
//            self.storedCards = storedCards
//        }
//    }
//    
//    class MockLeitnerSystem: LeitnerSystemProtocol {
//        func updateCard(_ card: LeitnerSwift.Card, correct: Bool) {
//            
//        }
//        
//        func dueForReview(limit: Int) -> [LeitnerSwift.Card] {
//            return []
//        }
//        
//        func loadBoxes(boxes: [LeitnerSwift.Box]) {
//            
//        }
//    }
//    
//    private func makeCard(id: UUID = UUID()) -> Card {
//        Card(id: id, word: anyWord)
//    }
//    
//    private var anyWord: Word {
//        Word(word: "any word", languageCode: "any", meaning: "any meaning", exampleSentence: nil)
//    }
//}
//
//extension Card: Equatable {
//    public static func == (lhs: LeitnerSwift.Card, rhs: LeitnerSwift.Card) -> Bool {
//        lhs.id == rhs.id
//    }
//}
