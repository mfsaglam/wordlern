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
        utterance.voice = AVSpeechSynthesisVoice(language: "de")
        
        // Set the rate to a slower value
        utterance.rate = 0.3 // Lower values make it slower (range is from 0.0 to 1.0)
        
        // You can also adjust pitch or volume if needed
        utterance.pitchMultiplier = 1.0  // Normal pitch (range: 0.5 to 2.0)
        utterance.volume = 1.0  // Volume (range: 0.0 to 1.0)
        
        synthesizer.speak(utterance)
    }
    
    var body: some View {
        VStack {
            if let card = viewModel.currentCard {
                HStack {
                    Text(card.word.word)
                        .font(.largeTitle)
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
                        .padding()
                }
                
                Button(viewModel.showMeaning ? LocalizedStringKey("Hide Translation") : LocalizedStringKey("Show Translation")) {
                    viewModel.toggleMeaning()
                }
                .padding()
                
                HStack {
                    Button(LocalizedStringKey("Correct")) {
                        viewModel.markCard(correct: true)
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button(LocalizedStringKey("Incorrect")) {
                        viewModel.markCard(correct: false)
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                VStack {
                    Text(LocalizedStringKey("No words to review."))
                    Button(LocalizedStringKey("Load next set of cards")) {
                        viewModel.fetchNextSet()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    VStack {
                        ForEach(viewModel.progress.indices, id: \.self) { index in
                            VStack(alignment: .leading) {
                                Text(boxLabels[index])
                                    .font(.headline)
                                HStack {
                                    Text(LocalizedStringKey("\(viewModel.progress[index]) cards"))
                                        .font(.subheadline)
                                    Spacer()
                                    ProgressView(value: Float(viewModel.progress[index]), total: 1000)
                                        .frame(width: 200)
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
//
//#Preview {
//    ContentView(viewModel: .forPreview())
//}
//
//extension WordViewModel {
//    static func forPreview() -> WordViewModel {
//        .init(cacheService: AnyCacheService, leitnerSystem: LeitnerSystem())
//    }
//}

