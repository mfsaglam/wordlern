//
//  SentenceBox.swift
//  thousand
//
//  Created by Fatih Sağlam on 29.09.2026.
//

import SwiftUI

/// The `in a sentence` surface on the back of the card. German only — the
/// target word sits in an accent-tinted pill so it is easy to spot.
struct SentenceBox: View {
    let sentence: String
    let targetWord: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey("in a sentence"))
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 5) {
                ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                    Text(verbatim: token.text)
                        .font(.system(size: 19))
                        .padding(.horizontal, token.isTarget ? 7 : 0)
                        .padding(.vertical, token.isTarget ? 2 : 0)
                        .background {
                            if token.isTarget {
                                Capsule().fill(Color.accentColor.opacity(0.15))
                            }
                        }
                        .foregroundStyle(token.isTarget ? Color.accentColor : Color.primary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            SpeakerButton(text: sentence, diameter: 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    private struct Token {
        let text: String
        let isTarget: Bool
    }

    /// Nouns are stored with their article (`das Haus`), so only the last
    /// component is matched against the sentence.
    private var tokens: [Token] {
        let needle = (targetWord.split(separator: " ").last.map(String.init) ?? targetWord).lowercased()
        return sentence.split(separator: " ").map { raw in
            let cleaned = raw
                .trimmingCharacters(in: .punctuationCharacters)
                .lowercased()
            return Token(text: String(raw), isTarget: cleaned == needle)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SentenceBox(sentence: "Das Haus ist groß.", targetWord: "das Haus")
        SentenceBox(sentence: "Wir gehen nach Hause.", targetWord: "gehen")
        SentenceBox(sentence: "Ich habe keine Zeit heute.", targetWord: "die Zeit")
    }
    .padding()
}
