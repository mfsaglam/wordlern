//
//  SessionEndScreen.swift
//  thousand
//
//  Created by Fatih Sağlam on 30.09.2026.
//

import SwiftUI

/// Screen 4 of `docs/DESIGN.md`, deliberately plain: what just happened, two
/// stat tiles, and the mastered bar growing by what the session added. No
/// confetti, no badges, no streak.
struct SessionEndScreen: View {
    let summary: WordViewModel.SessionSummary
    /// Size of the whole word list, the denominator of the mastered bar.
    var wordCount: Int = 1000
    let onSeeProgress: () -> Void

    @State private var grown = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            SessionCheck(landed: grown)

            Text(LocalizedStringKey("session complete"))
                .font(.system(size: 24, weight: .semibold))
                .padding(.top, 20)

            Text(LocalizedStringKey("\(summary.reviewed) cards reviewed"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 6)

            HStack(spacing: 12) {
                StatTile(value: summary.movedUp, label: "moved up")
                StatTile(value: summary.toReview, label: "to review")
            }
            .padding(.top, 32)

            MasteredGrowth(
                before: summary.masteredBefore,
                after: summary.masteredAfter,
                wordCount: wordCount,
                grown: grown
            )
            .padding(.top, 28)

            Spacer(minLength: 24)

            Button(action: onSeeProgress) {
                Text(LocalizedStringKey("see progress"))
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear { grown = true }
    }
}

/// The check settles in once: the soft circle eases open, then the mark springs
/// to size just behind it. One beat, no looping — the bar growth further down
/// is the screen's other, later beat.
private struct SessionCheck: View {
    let landed: Bool

    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(BoxPalette.mastered)
            .scaleEffect(landed ? 1 : 0.4)
            .opacity(landed ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1), value: landed)
            .frame(width: 64, height: 64)
            .background(
                Circle()
                    .fill(BoxPalette.mastered.opacity(0.12))
                    .scaleEffect(landed ? 1 : 0.8)
                    .opacity(landed ? 1 : 0)
                    .animation(.easeOut(duration: 0.3), value: landed)
            )
    }
}

/// Flat tile, one number over one label. Two of them sit side by side.
private struct StatTile: View {
    let value: Int
    let label: LocalizedStringKey

    var body: some View {
        VStack(spacing: 4) {
            Text(verbatim: "\(value)")
                .font(.system(size: 28, weight: .medium))
                .monospacedDigit()
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}

/// The session's one emotional beat: the same mastered bar as the summary
/// screen, starting at its pre-session width and growing to the new one.
private struct MasteredGrowth: View {
    let before: Int
    let after: Int
    let wordCount: Int
    let grown: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStringKey("mastered"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 6) {
                    Text(verbatim: "\(before)")
                        .foregroundStyle(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(verbatim: "\(after)")
                        .foregroundStyle(BoxPalette.mastered)
                }
                .font(.footnote)
                .monospacedDigit()
            }

            Bar(
                fraction: fraction(after),
                start: fraction(before),
                height: 10,
                fill: BoxPalette.mastered,
                filled: grown,
                delay: 0.35
            )
        }
    }

    private func fraction(_ count: Int) -> Double {
        guard wordCount > 0 else { return 0 }
        return Double(count) / Double(wordCount)
    }
}

#Preview("a good session") {
    SessionEndScreen(
        summary: .init(reviewed: 10, movedUp: 7, masteredBefore: 247, masteredAfter: 254),
        onSeeProgress: { }
    )
}

#Preview("a hard session") {
    SessionEndScreen(
        summary: .init(reviewed: 10, movedUp: 1, masteredBefore: 31, masteredAfter: 31),
        onSeeProgress: { }
    )
}
