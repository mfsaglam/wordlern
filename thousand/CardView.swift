//
//  CardView.swift
//  thousand
//
//  Created by Fatih Sağlam on 29.09.2026.
//

import LeitnerSwift
import SwiftUI

/// The card itself. Tapping it flips between the word and its meaning; the
/// card is the only control, there is no show/hide button.
struct CardView: View {
    let word: Word
    let isFlipped: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            front
                .opacity(isFlipped ? 0 : 1)
            back
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .frame(minHeight: 320)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
        )
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: isFlipped)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture(perform: onTap)
        .accessibilityAddTraits(.isButton)
    }

    private var front: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            Text(verbatim: word.word)
                .font(.system(size: 44, weight: .medium))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .textSelection(.enabled)

            SpeakerButton(text: word.word)

            Spacer(minLength: 0)

            Text(LocalizedStringKey("tap the card to flip"))
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
    }

    private var back: some View {
        VStack(spacing: 16) {
            Text(verbatim: word.word)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)

            Text(verbatim: word.meaning)
                .font(.system(size: 34, weight: .medium))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .textSelection(.enabled)

            if let sentence = word.exampleSentence, !sentence.isEmpty {
                SentenceBox(sentence: sentence, targetWord: word.word)
                    .padding(.top, 4)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("front") {
    CardView(
        word: .init(word: "das Haus", languageCode: "de", meaning: "house", exampleSentence: "Das Haus ist groß."),
        isFlipped: false,
        onTap: {}
    )
    .padding(20)
    .background(Color(uiColor: .systemGroupedBackground))
}

#Preview("back — with sentence") {
    CardView(
        word: .init(word: "das Haus", languageCode: "de", meaning: "house", exampleSentence: "Das Haus ist groß."),
        isFlipped: true,
        onTap: {}
    )
    .padding(20)
    .background(Color(uiColor: .systemGroupedBackground))
}

#Preview("back — no sentence") {
    CardView(
        word: .init(word: "gehen", languageCode: "de", meaning: "to go", exampleSentence: nil),
        isFlipped: true,
        onTap: {}
    )
    .padding(20)
    .background(Color(uiColor: .systemGroupedBackground))
}
