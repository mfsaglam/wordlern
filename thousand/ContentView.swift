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
        NSLocalizedString("Box 1", comment: ""),
        NSLocalizedString("Box 2", comment: ""),
        NSLocalizedString("Box 3", comment: ""),
        NSLocalizedString("Box 4", comment: ""),
        NSLocalizedString("Box 5", comment: "")
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
                
                Button(viewModel.showMeaning ? NSLocalizedString("Hide Translation", comment: "") : NSLocalizedString("Show Translation", comment: "")) {
                    viewModel.toggleMeaning()
                }
                .padding()
                
                HStack {
                    Button(NSLocalizedString("Correct", comment: "")) {
                        viewModel.markCard(correct: true)
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button(NSLocalizedString("Incorrect", comment: "")) {
                        viewModel.markCard(correct: false)
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            } else {
                VStack {
                    Text(NSLocalizedString("No words to review.", comment: ""))
                    Button(NSLocalizedString("Load next set of cards", comment: "")) {
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
                                    Text(NSLocalizedString("\(viewModel.progress[index]) cards", comment: ""))
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

