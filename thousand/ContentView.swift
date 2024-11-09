//
//  ContentView.swift
//  thousand
//
//  Created by Fatih Sağlam on 19.09.2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: WordViewModel
    let boxLabels = ["Box 1", "Box 2", "Box 3", "Box 4", "Box 5"] // Labels for each box
    
    init(viewModel: WordViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            if let card = viewModel.currentCard {
                Text(card.word.word)
                    .font(.largeTitle)
                    .padding()

                if viewModel.showMeaning {
                    Text(card.word.meaning)
                        .font(.title)
                        .padding()
                }
                
                Button(viewModel.showMeaning ? "Hide Translation" : "Show Translation") {
                    viewModel.toggleMeaning()
                }
                .padding()
                
                HStack {
                    Button("Correct") {
                        viewModel.markCard(correct: true)
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button("Incorrect") {
                        viewModel.markCard(correct: false)
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                VStack {
                    Text("No words to review.")
                    Button("Load next set of cards") {
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
                                    Text("\(viewModel.progress[index]) cards")
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

