//
//  ContentView.swift
//  thousand
//
//  Created by Fatih Sağlam on 19.09.2024.
//

import SwiftUI

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

