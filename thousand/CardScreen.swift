//
//  CardScreen.swift
//  thousand
//
//  Created by Fatih Sağlam on 29.09.2026.
//

import LeitnerSwift
import SwiftUI

/// Screens 1 and 2 of `docs/DESIGN.md`: header and progress bar on top, the
/// flippable card in the middle, ✗/✓ at the bottom.
struct CardScreen: View {
    let word: Word
    let boxNumber: Int?
    let position: Int
    let total: Int
    let isFlipped: Bool
    let onFlip: () -> Void
    let onAnswer: (Bool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            SessionHeader(boxNumber: boxNumber, position: position, total: total)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            Spacer(minLength: 24)

            CardView(word: word, isFlipped: isFlipped, onTap: onFlip)
                .padding(.horizontal, 20)

            Spacer(minLength: 24)

            AnswerButtons(onAnswer: onAnswer)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview("front") {
    CardScreen(
        word: .init(word: "das Haus", languageCode: "de", meaning: "house", exampleSentence: "Das Haus ist groß."),
        boxNumber: 2,
        position: 4,
        total: 10,
        isFlipped: false,
        onFlip: {},
        onAnswer: { _ in }
    )
}

#Preview("back") {
    CardScreen(
        word: .init(word: "die Zeit", languageCode: "de", meaning: "time", exampleSentence: "Ich habe keine Zeit."),
        boxNumber: 3,
        position: 7,
        total: 10,
        isFlipped: true,
        onFlip: {},
        onAnswer: { _ in }
    )
}
