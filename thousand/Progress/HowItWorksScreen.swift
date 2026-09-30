//
//  HowItWorksScreen.swift
//  thousand
//
//  Created by Fatih Sağlam on 30.09.2026.
//

import SwiftUI

/// Step 16: the app never explained the Leitner system, so a word coming back —
/// or the `mastered` figure moving — had no visible cause. One sheet of plain
/// text, same shape as `AboutScreen`: no onboarding flow, no illustrations.
///
/// The intervals below are `LeitnerSystem`'s defaults for five boxes
/// (0, 3, 7, 14, 30 days). If the box count ever changes, this copy has to
/// change with it.
struct HowItWorksScreen: View {
    /// Opens the app's own Settings page — the closest thing to a deep link
    /// into Spoken Content › Voices that public API allows (step 17).
    var onOpenSettings: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(LocalizedStringKey("How it works"))
                    .font(.system(size: 28, weight: .semibold))

                Section(title: "The five boxes") {
                    Text(verbatim: "Every word sits in one of five boxes, and the box decides how often you see it again:")
                    BoxIntervals()
                    Text(verbatim: "A word you keep getting right climbs towards box 5 and slowly gets out of your way. A word you keep missing stays in box 1, where you see it every day.")
                }

                Section(title: "Answering a card") {
                    Text(verbatim: "Got it moves the word up one box, so the next wait is longer.")
                    Text(verbatim: "Missed it sends the word all the way back to box 1, whichever box it came from.")
                    Text(verbatim: "Box 5 is the end of the line. Get a word right there and it leaves the rotation for good.")
                }

                Section(title: "What mastered counts") {
                    Text(verbatim: "The mastered figure on the home screen is boxes 3, 4 and 5 added together — every word you now see a week or more apart.")
                    Text(verbatim: "It goes down as well as up: missing a word in box 3 or higher drops it back to box 1.")
                }

                Section(title: "Pronunciation") {
                    Text(verbatim: "Tapping the speaker on a card reads the German out loud with the best German voice installed on your device.")

                    if let currentVoice = GermanSpeaker.shared.currentVoiceDescription {
                        HStack(spacing: 6) {
                            Text(LocalizedStringKey("Currently using"))
                                .foregroundStyle(.secondary)
                            Text(verbatim: currentVoice)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                    }

                    Text(verbatim: "The built-in voice is fairly flat. A much better one is a free download in Settings › Accessibility › Spoken Content › Voices › German — once it is installed the app picks it up on its own.")

                    Button(action: onOpenSettings) {
                        Text(LocalizedStringKey("Open Settings"))
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 2)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

/// The box-to-interval table, the one piece of structure on the screen. A row
/// each so the growing wait is visible at a glance instead of buried in prose.
private struct BoxIntervals: View {
    private let rows: [(box: LocalizedStringKey, interval: LocalizedStringKey)] = [
        ("box 1", "every day"),
        ("box 2", "every 3 days"),
        ("box 3", "every week"),
        ("box 4", "every 2 weeks"),
        ("box 5", "every month")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: 12) {
                    Text(rows[index].box)
                        .frame(width: 56, alignment: .leading)
                    Text(rows[index].interval)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.subheadline)
        .padding(.vertical, 2)
    }
}

/// A heading and its body text, stacked — the same unit `AboutScreen` uses.
private struct Section<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    init(title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .font(.subheadline)
            .foregroundStyle(.primary)
        }
    }
}

#Preview {
    HowItWorksScreen()
}
