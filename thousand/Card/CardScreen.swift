//
//  CardScreen.swift
//  thousand
//
//  Created by Fatih Sağlam on 29.09.2026.
//

import Foundation
import LeitnerSwift
import SwiftUI

/// Screens 1 and 2 of `docs/DESIGN.md`: header and progress bar on top, the
/// flippable card in the middle, ✗/✓ at the bottom.
struct CardScreen: View {
    /// Identity of the card on screen. It scopes the flip state to one card, so
    /// the next card is built fresh, front up, instead of animating back from
    /// the face the previous card was left on.
    let cardID: UUID
    let word: Word
    let boxNumber: Int?
    let position: Int
    let total: Int
    let isFlipped: Bool
    let onFlip: () -> Void
    let onAnswer: (Bool) -> Void
    var canUndo: Bool = false
    var onUndo: () -> Void = {}

    /// Shake has no on-screen affordance, so it needs its own confirmation —
    /// without one the user cannot tell whether the gesture registered or the
    /// app ignored them. The button needs none: it is visible, and the card
    /// behind it changes.
    @StateObject private var undoneToast = ToastFlash()

    var body: some View {
        VStack(spacing: 0) {
            SessionHeader(
                boxNumber: boxNumber,
                position: position,
                total: total,
                canUndo: canUndo,
                onUndo: onUndo
            )
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer(minLength: 24)

            // The ZStack is what makes the arrival animation possible: it holds
            // the stable `.animation` the id change is read against, and it lets
            // the outgoing and incoming card overlap instead of briefly
            // stacking and shoving the layout around.
            ZStack {
                CardView(word: word, isFlipped: isFlipped, onTap: onFlip, onSwipe: onAnswer)
                    .id(cardID)
                    // The answered card leaves without a transition. It has
                    // already taken itself off screen under the swipe, and
                    // keeping it around to fade would let it reappear: it resets
                    // its drag offset once the answer lands, which on a fading
                    // view reads as the old card flashing back into place.
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .identity
                        )
                    )
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.9), value: cardID)
            .padding(.horizontal, 20)
            .overlay(alignment: .top) {
                if undoneToast.isVisible {
                    ToastPill(text: "undone")
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            Spacer(minLength: 24)

            AnswerButtons(onAnswer: onAnswer)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        // Zero-size and behind everything, so it can never intercept a tap or
        // a swipe meant for the card.
        .background(ShakeDetector(onShake: shakeToUndo).frame(width: 0, height: 0))
        // Keyed on `cardID`, not `isFlipped`: flipping, undoing back to a card
        // already seen, or returning from a sheet must not speak again, but
        // undo stepping to a different card should — the user is seeing it fresh.
        .task(id: cardID) {
            GermanSpeaker.shared.speak(word.word)
        }
    }

    /// A shake with nothing to take back does nothing at all — no haptic, no
    /// toast, no error. It has to be indistinguishable from not shaking.
    private func shakeToUndo() {
        guard canUndo else { return }
        Haptics.undo()
        onUndo()
        undoneToast.flash()
    }
}

#Preview("front") {
    CardScreen(
        cardID: UUID(),
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
        cardID: UUID(),
        word: .init(word: "die Zeit", languageCode: "de", meaning: "time", exampleSentence: "Ich habe keine Zeit."),
        boxNumber: 3,
        position: 7,
        total: 10,
        isFlipped: true,
        onFlip: {},
        onAnswer: { _ in },
        canUndo: true,
        onUndo: {}
    )
}
