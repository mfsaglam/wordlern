//
//  SummaryWidget.swift
//  WordLernWidget
//
//  Created by Fatih Sağlam on 30.09.2026.
//

import SwiftUI
import WidgetKit

/// Step 25 of `docs/PLAN.md`: the summary screen at a glance. Reads the App
/// Group snapshot written by the app — no SwiftData, no `LeitnerSwift` here.
struct SummaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SummaryWidget", provider: SummaryProvider()) { entry in
            SummaryWidgetView(entry: entry)
                .containerBackground(Color(uiColor: .systemBackground), for: .widget)
        }
        .configurationDisplayName(LocalizedStringKey("progress"))
        .description(LocalizedStringKey("how many words you have mastered, and what is due."))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SummaryEntry: TimelineEntry {
    let date: Date
    let snapshot: ProgressSnapshot?
    /// Set on the entry scheduled at `nextDue`: cards have come due since the
    /// snapshot was written, so its `dueCount` of zero no longer holds. The
    /// snapshot does not say how many, so the widget stops naming a number.
    var dueSinceSnapshot = false
}

struct SummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> SummaryEntry {
        SummaryEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SummaryEntry) -> Void) {
        let snapshot: ProgressSnapshot? = context.isPreview
            ? .placeholder
            : ProgressSnapshot.read()
        completion(SummaryEntry(date: Date(), snapshot: snapshot))
    }

    /// Two entries at most: now, and the moment the first card comes due. The
    /// app reloads the timeline on every write, so between those there is
    /// nothing to refresh — hence `.never` rather than a polling interval.
    func getTimeline(in context: Context, completion: @escaping (Timeline<SummaryEntry>) -> Void) {
        let now = Date()
        let snapshot = ProgressSnapshot.read()
        var entries = [SummaryEntry(date: now, snapshot: snapshot)]

        if let nextDue = snapshot?.nextDue, nextDue > now {
            entries.append(SummaryEntry(date: nextDue, snapshot: snapshot, dueSinceSnapshot: true))
            completion(Timeline(entries: entries, policy: .atEnd))
        } else {
            completion(Timeline(entries: entries, policy: .never))
        }
    }
}

private extension ProgressSnapshot {
    /// What the widget gallery and the redacted placeholder show.
    static var placeholder: ProgressSnapshot {
        ProgressSnapshot(
            boxCounts: [120, 180, 240, 260, 200],
            mastered: 700,
            total: 1000,
            dueCount: 24,
            nextDue: nil,
            updated: Date()
        )
    }
}

struct SummaryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SummaryEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemMedium:
                HStack(alignment: .top, spacing: 16) {
                    WidgetHeadline(snapshot: snapshot, entry: entry)
                    WidgetBoxBars(boxCounts: snapshot.boxCounts)
                        .frame(maxWidth: .infinity)
                }
            default:
                WidgetHeadline(snapshot: snapshot, entry: entry)
            }
        } else {
            // Before the app's first launch the snapshot does not exist yet.
            Text(LocalizedStringKey("open WordLern to start"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

/// `mastered` over the list size and the one thick bar, then the status line —
/// the small widget in full, and the left half of the medium one.
private struct WidgetHeadline: View {
    let snapshot: ProgressSnapshot
    let entry: SummaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey("mastered"))
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(verbatim: "\(snapshot.mastered)")
                    .font(.system(size: 34, weight: .medium))
                Text(verbatim: "/ \(snapshot.total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Bar(
                fraction: snapshot.total > 0
                    ? Double(snapshot.mastered) / Double(snapshot.total)
                    : 0,
                height: 8,
                fill: BoxPalette.mastered,
                filled: true
            )

            Spacer(minLength: 4)

            WidgetStatusLine(snapshot: snapshot, entry: entry)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// The due count, or how long until something is. Widgets do not get to
/// recompute, so the countdown is left to `Text`'s own relative style.
private struct WidgetStatusLine: View {
    let snapshot: ProgressSnapshot
    let entry: SummaryEntry

    var body: some View {
        Group {
            if snapshot.dueCount > 0 {
                Text(LocalizedStringKey("\(snapshot.dueCount) cards due"))
            } else if entry.dueSinceSnapshot {
                Text(LocalizedStringKey("review ready"))
            } else if let nextDue = snapshot.nextDue {
                // One key, whole sentence — a bare "next review in" fragment
                // is not something a translator can place. The interpolated
                // date style is what keeps the countdown live without the
                // widget being reloaded. Note that Xcode does not extract a
                // `\(date, style:)` interpolation into the string catalog, so
                // this one line stays English until the key is added by hand.
                Text(LocalizedStringKey("next review in \(nextDue, style: .relative)"))
            } else {
                Text(LocalizedStringKey("all caught up"))
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

/// The five box bars, medium only. The labels are bare digits — `box 1` does
/// not survive at this width, and the column already reads top to bottom.
private struct WidgetBoxBars: View {
    let boxCounts: [Int]

    /// Scaled against each other, the way `SummaryScreen` does it, so the
    /// shape holds as counts move between boxes instead of emptying out.
    private var scale: Int {
        max(boxCounts.max() ?? 0, 1)
    }

    var body: some View {
        VStack(spacing: 7) {
            ForEach(boxCounts.indices, id: \.self) { index in
                HStack(spacing: 8) {
                    Text(verbatim: "\(index + 1)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 8, alignment: .leading)

                    Bar(
                        fraction: Double(boxCounts[index]) / Double(scale),
                        height: 6,
                        fill: BoxPalette.fill(depth: Double(index) / Double(max(boxCounts.count - 1, 1))),
                        filled: true
                    )

                    Text(verbatim: "\(boxCounts[index])")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

#Preview("small", as: .systemSmall) {
    SummaryWidget()
} timeline: {
    SummaryEntry(
        date: Date(),
        snapshot: ProgressSnapshot(
            boxCounts: [900, 60, 30, 10, 0],
            mastered: 40,
            total: 1000,
            dueCount: 12,
            nextDue: nil,
            updated: Date()
        )
    )
    SummaryEntry(
        date: Date(),
        snapshot: ProgressSnapshot(
            boxCounts: [120, 180, 240, 260, 200],
            mastered: 700,
            total: 1000,
            dueCount: 0,
            nextDue: Calendar.current.date(byAdding: .hour, value: 5, to: Date()),
            updated: Date()
        )
    )
    SummaryEntry(date: Date(), snapshot: nil)
}

#Preview("medium", as: .systemMedium) {
    SummaryWidget()
} timeline: {
    SummaryEntry(
        date: Date(),
        snapshot: ProgressSnapshot(
            boxCounts: [120, 180, 240, 260, 200],
            mastered: 700,
            total: 1000,
            dueCount: 24,
            nextDue: nil,
            updated: Date()
        )
    )
    SummaryEntry(
        date: Date(),
        snapshot: ProgressSnapshot(
            boxCounts: [900, 60, 30, 10, 0],
            mastered: 40,
            total: 1000,
            dueCount: 0,
            nextDue: Calendar.current.date(byAdding: .hour, value: 5, to: Date()),
            updated: Date()
        )
    )
}
