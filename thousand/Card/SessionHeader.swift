//
//  SessionHeader.swift
//  thousand
//
//  Created by Fatih Sağlam on 29.09.2026.
//

import SwiftUI

/// Quiet top row of the card screen: which box the card lives in, how far the
/// session has come, and a thin bar that advances one notch per answer.
struct SessionHeader: View {
    let boxNumber: Int?
    /// 1-based position of the card currently on screen.
    let position: Int
    let total: Int
    /// The undo control only appears once there is an answer to take back.
    var canUndo: Bool = false
    var onUndo: () -> Void = {}

    private var answered: Double {
        guard total > 0 else { return 0 }
        return Double(position - 1) / Double(total)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                if canUndo {
                    UndoButton(action: onUndo)
                        .transition(.opacity)
                }
                if let boxNumber {
                    Text(LocalizedStringKey("box \(boxNumber)"))
                }
                Spacer()
                Text(verbatim: "\(position) / \(total)")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .animation(.easeInOut(duration: 0.2), value: canUndo)

            SessionProgressBar(value: answered)
        }
    }
}

/// Small muted arrow to the left of the box badge — the least noisy place to
/// put undo without disturbing the ✓/✗ row at the bottom.
private struct UndoButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.undo()
            action()
        } label: {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.primary.opacity(0.06)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(LocalizedStringKey("undo"))
    }
}

private struct SessionProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 3)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: value)
    }
}

#Preview {
    VStack(spacing: 40) {
        SessionHeader(boxNumber: 1, position: 1, total: 10)
        SessionHeader(boxNumber: 2, position: 4, total: 10, canUndo: true, onUndo: {})
        SessionHeader(boxNumber: nil, position: 10, total: 10)
    }
    .padding()
}
