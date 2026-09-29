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
            AnswerButton(symbol: "xmark", tint: .red) { onAnswer(false) }
            AnswerButton(symbol: "checkmark", tint: .green) { onAnswer(true) }
        }
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
