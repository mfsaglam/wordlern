//
//  ProgressBars.swift
//  thousand
//
//  Created by Fatih Sağlam on 30.09.2026.
//

import SwiftUI

/// Boxes 3, 4 and 5 combined — a word counts as mastered once it has survived
/// three rounds. Shared so the summary and session end screens cannot drift
/// apart on what the headline number means.
func masteredCount(in progress: [Int]) -> Int {
    progress.dropFirst(2).reduce(0, +)
}

/// The one bar shape in the app: a track with a capsule fill that grows once
/// `filled` flips. Used for the mastered headline and for the per-box rows.
struct Bar: View {
    /// Where the fill ends up, 0...1.
    let fraction: Double
    /// Where the fill starts from before it animates. The session end screen
    /// uses it to grow the mastered bar from its pre-session value.
    var start: Double = 0
    let height: CGFloat
    let fill: Color
    /// Set by the owning screen in `onAppear`, which is what drives the fill.
    let filled: Bool
    var delay: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.06))
                Capsule()
                    .fill(fill)
                    .frame(width: geometry.size.width * (filled ? clamp(fraction) : clamp(start)))
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.55, dampingFraction: 0.85).delay(delay), value: filled)
    }

    private func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

enum BoxPalette {
    static let mastered = Color(red: 0.13, green: 0.45, blue: 0.29)

    /// Neutral grey at box 1 through to a deep green at the last box, so
    /// progress reads as the screen getting deeper rather than fuller.
    static func fill(depth: Double) -> Color {
        let t = min(max(depth, 0), 1)
        return Color(
            red: 0.62 - 0.49 * t,
            green: 0.64 - 0.19 * t,
            blue: 0.66 - 0.37 * t
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        Bar(fraction: 0.25, height: 10, fill: BoxPalette.mastered, filled: true)
        Bar(fraction: 0.6, start: 0.4, height: 10, fill: BoxPalette.mastered, filled: true)
        ForEach(0..<5) { index in
            Bar(
                fraction: 0.8,
                height: 8,
                fill: BoxPalette.fill(depth: Double(index) / 4),
                filled: true
            )
        }
    }
    .padding()
}
