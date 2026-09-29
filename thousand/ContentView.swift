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
    ]

    init(viewModel: WordViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if let card = viewModel.currentCard {
                CardScreen(
                    word: card.word,
                    boxNumber: viewModel.currentBoxNumber,
                    position: viewModel.sessionPosition,
                    total: viewModel.sessionTotal,
                    isFlipped: viewModel.showMeaning,
                    onFlip: { viewModel.toggleMeaning() },
                    onAnswer: { viewModel.markCard(correct: $0) }
                )
            } else {
                BoxesOverview(
                    boxLabels: boxLabels,
                    progress: viewModel.progress
                ) {
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
