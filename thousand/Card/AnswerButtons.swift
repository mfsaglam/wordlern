//
//  AnswerButtons.swift
//  thousand
//
//  Created by Fatih Sağlam on 29.09.2026.
//

import SwiftUI

/// ✗ on the left, ✓ on the right. They stay in place across the flip.
struct AnswerButtons: View {
    let onAnswer: (Bool) -> Void

    var body: some View {
        HStack(spacing: 44) {
            AnswerButton(symbol: "xmark", tint: .red) { answer(false) }
            AnswerButton(symbol: "checkmark", tint: .green) { answer(true) }
        }
    }

    /// The same tap the swipe gives, so the two ways of answering feel alike.
    private func answer(_ correct: Bool) {
        Haptics.answer(correct: correct)
        onAnswer(correct)
    }
}

private struct AnswerButton: View {
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 52, height: 52)
                .background(Circle().fill(tint.opacity(0.12)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AnswerButtons { _ in }
        .padding()
}
