//
//  CardView.swift
//  thousand
//
//  Created by Fatih Sağlam on 29.09.2026.
//

import LeitnerSwift
import SwiftUI
import UIKit

/// The card itself. Tapping it flips between the word and its meaning; the
/// card is the only control, there is no show/hide button. Dragging it
/// sideways answers: right is correct, left is incorrect — a shortcut for the
/// ✓/✗ buttons, which stay.
struct CardView: View {
    let word: Word
    let isFlipped: Bool
    let onTap: () -> Void
    /// `nil` leaves the card drag-inert, for previews and other read-only uses.
    var onSwipe: ((Bool) -> Void)?

    /// How far the card has to travel before the release counts as an answer.
    private let commitDistance: CGFloat = 96

    @State private var dragWidth: CGFloat = 0
    /// Set while the card flies off screen, so a second drag cannot answer twice.
    @State private var isLeaving = false
    /// Whether the drag is currently far enough to answer, so the haptic fires
    /// on the crossing rather than on every frame beyond it.
    @State private var isArmed = false

    /// Drives the "Copied" pill.
    @StateObject private var copiedToast = ToastFlash()

    /// 0 at rest, 1 once the drag is far enough to commit.
    private var swipeProgress: CGFloat {
        min(abs(dragWidth) / commitDistance, 1)
    }

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
        .overlay(swipeHint)
        // After the rotation, not before: attaching it here keeps the pill
        // upright through the flip instead of mirroring with the card.
        .overlay(alignment: .top) {
            if copiedToast.isVisible {
                ToastPill(text: "copied")
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .opacity(isLeaving ? 0 : 1)
        .offset(x: dragWidth)
        .rotationEffect(.degrees(Double(dragWidth) / 28), anchor: .bottom)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture(perform: onTap)
        .gesture(swipe)
        .accessibilityAddTraits(.isButton)
    }

    /// Tap-to-copy on the word and meaning texts (and, in `SentenceBox`, the
    /// example sentence).
    private func copy(_ text: String) {
        UIPasteboard.general.string = text
        Haptics.copied()
        // Shown for both this view's own copies and `SentenceBox`'s, via its
        // `onCopy` callback — one pill, regardless of which of the three texts
        // was tapped.
        copiedToast.flash()
    }

    /// The card borrows the answer buttons' colours as it travels, so the
    /// direction reads before the finger lifts.
    private var swipeHint: some View {
        let correct = dragWidth > 0
        let tint: Color = correct ? .green : .red
        return RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(tint, lineWidth: 2)
            .overlay(alignment: correct ? .topTrailing : .topLeading) {
                Image(systemName: correct ? "checkmark" : "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .padding(20)
            }
            .opacity(Double(swipeProgress))
            .allowsHitTesting(false)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard onSwipe != nil, !isLeaving else { return }
                if dragWidth == 0 {
                    Haptics.prepareForDrag()
                }
                dragWidth = value.translation.width

                let armed = abs(value.translation.width) >= commitDistance
                if armed != isArmed {
                    isArmed = armed
                    Haptics.swipeArmingChanged()
                }
            }
            .onEnded { value in
                guard let onSwipe, !isLeaving else { return }
                isArmed = false
                if abs(value.translation.width) >= commitDistance {
                    flyOff(correct: value.translation.width > 0, then: onSwipe)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        dragWidth = 0
                    }
                }
            }
    }

    private func flyOff(correct: Bool, then onSwipe: @escaping (Bool) -> Void) {
        let duration = 0.22
        // On release, not when the card lands: the tap has to belong to the
        // finger's last moment of contact, or it feels like a separate event.
        Haptics.answer(correct: correct)
        withAnimation(.easeOut(duration: duration)) {
            isLeaving = true
            dragWidth = correct ? 700 : -700
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            onSwipe(correct)
            // The next card arrives under a new `.id` and so starts clean; this
            // only matters if the answer did not take and this same card stays,
            // in which case it has to come back from off screen. It must not be
            // animated, and the answered card must leave with no transition, or
            // this snap-back is visible on the way out.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                dragWidth = 0
                isLeaving = false
            }
        }
    }

    private var front: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            Text(verbatim: word.word)
                .font(.system(size: 44, weight: .medium))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .textSelection(.enabled)
                // Sits on the word itself, not the card, so it wins the hit
                // test over the card-level tap-to-flip.
                .onTapGesture { copy(word.word) }
                // `.textSelection` keeps a long-press selection alive as long
                // as this view stays mounted, and front/back never unmount —
                // only their opacity toggles. Rekeying on `isFlipped` forces a
                // fresh instance on every flip, which is the only reliable way
                // to drop a selection stuck from the face just left.
                .id(isFlipped)

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
                .onTapGesture { copy(word.meaning) }
                .id(isFlipped)

            if let sentence = word.exampleSentence, !sentence.isEmpty {
                SentenceBox(sentence: sentence, targetWord: word.word, onCopy: { copiedToast.flash() })
                    .padding(.top, 4)
                    // Same reasoning as the word/meaning texts above: the
                    // sentence's own selection would otherwise survive a flip.
                    .id(isFlipped)
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

#Preview("swipe — drag the card sideways") {
    CardView(
        word: .init(word: "das Haus", languageCode: "de", meaning: "house", exampleSentence: "Das Haus ist groß."),
        isFlipped: false,
        onTap: {},
        onSwipe: { print("answered \($0)") }
    )
    .padding(20)
    .background(Color(uiColor: .systemGroupedBackground))
}
