//
//  SummaryScreen.swift
//  thousand
//
//  Created by Fatih Sağlam on 18.11.2024.
//

import SwiftUI

/// Screen 3 of `docs/DESIGN.md`: the mastered headline over the whole word list,
/// then one row per box with bars scaled against each other.
struct SummaryScreen: View {
    let boxLabels: [LocalizedStringKey]
    /// Card count per box, box 1 first.
    let progress: [Int]
    /// Size of the whole word list, the denominator of the headline metric.
    var wordCount: Int = 1000
    let buttonAction: () -> Void
    var onAbout: () -> Void = {}
    var onHowItWorks: () -> Void = {}

    private var mastered: Int {
        masteredCount(in: progress)
    }

    /// The longest bar defines the scale, so the screen keeps its shape as the
    /// counts move between boxes instead of emptying out against 1000.
    private var scale: Int {
        max(progress.max() ?? 0, 1)
    }

    /// Set once the view is on screen, which is what drives the bars out from
    /// zero. Staggering happens per row, in `BoxRow`.
    @State private var filled = false

    var body: some View {
        VStack(spacing: 0) {
            MasteredHeadline(mastered: mastered, wordCount: wordCount, filled: filled)
                .padding(.horizontal, 24)
                .padding(.top, 32)

            Divider()
                .padding(.horizontal, 24)
                .padding(.vertical, 28)

            VStack(spacing: 18) {
                ForEach(progress.indices, id: \.self) { index in
                    BoxRow(
                        label: boxLabels[index],
                        count: progress[index],
                        fraction: Double(progress[index]) / Double(scale),
                        depth: Double(index) / Double(max(progress.count - 1, 1)),
                        filled: filled,
                        delay: 0.1 * Double(index)
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 32)

            Button(action: buttonAction) {
                Text(LocalizedStringKey("start session"))
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color.accentColor))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .systemGroupedBackground))
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 0) {
                Button(action: onHowItWorks) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                        .padding(12)
                }
                .buttonStyle(.plain)

                Button(action: onAbout) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                        .padding(12)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear { filled = true }
    }
}

/// `mastered`, the count over the list size, and a thicker bar — the one number
/// the screen is about.
private struct MasteredHeadline: View {
    let mastered: Int
    let wordCount: Int
    let filled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey("mastered"))
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: "\(mastered)")
                    .font(.system(size: 44, weight: .medium))
                    .contentTransition(.numericText())
                Text(LocalizedStringKey("/ \(wordCount) words"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Bar(
                fraction: wordCount > 0 ? Double(mastered) / Double(wordCount) : 0,
                height: 10,
                fill: BoxPalette.mastered,
                filled: filled,
                delay: 0
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// One box: label, bar, count. The bar darkens with the box number, so progress
/// reads as the screen getting deeper rather than fuller.
private struct BoxRow: View {
    let label: LocalizedStringKey
    let count: Int
    let fraction: Double
    /// 0 for box 1, 1 for the last box — position along the grey-to-green ramp.
    let depth: Double
    let filled: Bool
    let delay: Double

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            Bar(
                fraction: fraction,
                height: 8,
                fill: BoxPalette.fill(depth: depth),
                filled: filled,
                delay: delay
            )

            Text(verbatim: "\(count)")
                .font(.system(.subheadline, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
    }
}

#Preview("early") {
    SummaryScreen(
        boxLabels: ["box 1", "box 2", "box 3", "box 4", "box 5"],
        progress: [900, 60, 30, 10, 0],
        buttonAction: { }
    )
}

#Preview("advanced") {
    SummaryScreen(
        boxLabels: ["box 1", "box 2", "box 3", "box 4", "box 5"],
        progress: [120, 180, 240, 260, 200],
        buttonAction: { }
    )
}
