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

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        if let siriVoice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_female_de-DE_compact") {
            utterance.voice = siriVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "de")
        }
        utterance.rate = 0.4
        synthesizer.speak(utterance)
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
