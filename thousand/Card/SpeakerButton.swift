//
//  SpeakerButton.swift
//  thousand
//
//  Created by Fatih Sağlam on 29.09.2026.
//

import AVFoundation
import SwiftUI

/// Speaks German text with the best voice the device has installed.
final class GermanSpeaker {
    static let shared = GermanSpeaker()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    /// Every installed German voice, best quality first. Re-read on each call
    /// instead of cached, since a voice download while the app is open should
    /// take effect without a relaunch.
    private var bestGermanVoice: AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("de") }
            .max { $0.quality.rank < $1.quality.rank }
    }

    /// Name and quality of the voice a `speak(_:)` call would use right now —
    /// for `HowItWorksScreen` to show the user what they currently have installed.
    var currentVoiceDescription: String? {
        guard let voice = bestGermanVoice else { return nil }
        return "\(voice.name) (\(voice.quality.label))"
    }

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = bestGermanVoice ?? AVSpeechSynthesisVoice(language: "de")
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
}

private extension AVSpeechSynthesisVoiceQuality {
    /// `AVSpeechSynthesisVoiceQuality`'s raw values already sort
    /// default < enhanced < premium, but that's an implementation detail —
    /// spell the order out so a future SDK change can't silently flip it.
    var rank: Int {
        switch self {
        case .premium: return 2
        case .enhanced: return 1
        default: return 0
        }
    }

    var label: String {
        switch self {
        case .premium: return "Premium"
        case .enhanced: return "Enhanced"
        default: return "Default"
        }
    }
}

/// A circular, outlined speaker button.
struct SpeakerButton: View {
    let text: String
    var diameter: CGFloat = 44

    var body: some View {
        Button {
            GermanSpeaker.shared.speak(text)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: diameter * 0.36, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: diameter, height: diameter)
                .overlay(
                    Circle()
                        .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1.5)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(LocalizedStringKey("pronounce"))
    }
}

#Preview {
    VStack(spacing: 24) {
        SpeakerButton(text: "das Haus")
        SpeakerButton(text: "Das Haus ist groß.", diameter: 32)
    }
    .padding()
}
