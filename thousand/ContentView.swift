//
//  ContentView.swift
//  thousand
//
//  Created by Fatih Sağlam on 19.09.2024.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @ObservedObject var viewModel: WordViewModel
    let boxLabels = [
        LocalizedStringKey("Box 1"),
        LocalizedStringKey("Box 2"),
        LocalizedStringKey("Box 3"),
        LocalizedStringKey("Box 4"),
        LocalizedStringKey("Box 5")
    ] // Labels for each box
    
    init(viewModel: WordViewModel) {
        self.viewModel = viewModel
    }
    
    @State private var synthesizer = AVSpeechSynthesizer()
    
    private func speakWord(_ word: String) {
        let utterance = AVSpeechUtterance(string: word)
        if let highQualityVoice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.siri_female_de-DE_compact") {
            utterance.voice = highQualityVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "de")
        }
        utterance.rate = 0.4
        synthesizer.speak(utterance)
    }
    
    var body: some View {
        VStack {
            if let card = viewModel.currentCard {
                Spacer()
                HStack {
                    Text(card.word.word)
                        .font(.largeTitle)
                        .bold()
                        .textSelection(.enabled)
                        .padding()
                    
                    Button(action: {
                        speakWord(card.word.word)
                    }) {
                        Image(systemName: "speaker.3.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .padding(.leading, 10)
                }

                if viewModel.showMeaning {
                    Text(card.word.meaning)
                        .font(.title)
                        .textSelection(.enabled)
                        .padding()
                }
                
                Button(viewModel.showMeaning ? LocalizedStringKey("Hide Translation") : LocalizedStringKey("Show Translation")) {
                    viewModel.toggleMeaning()
                }
                .padding()
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.markCard(correct: true)
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.green))
                    }
                    
                    Button(action: {
                        viewModel.markCard(correct: false)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.pink))
                    }
                }
            } else {
                BoxesOverview(
                    boxLabels: boxLabels,
                    progress: viewModel.progress) {
                        viewModel.fetchNextSet()
                    }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

#Preview {
    ContentView(viewModel: .forPreview())
}

