//
//  ContentView.swift
//  thousand
//
//  Created by Fatih Sağlam on 19.09.2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: WordViewModel
    @State private var showingAbout = false

    let boxLabels = [
        LocalizedStringKey("box 1"),
        LocalizedStringKey("box 2"),
        LocalizedStringKey("box 3"),
        LocalizedStringKey("box 4"),
        LocalizedStringKey("box 5")
    ]

    init(viewModel: WordViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if let card = viewModel.currentCard {
                CardScreen(
                    cardID: card.id,
                    word: card.word,
                    boxNumber: viewModel.currentBoxNumber,
                    position: viewModel.sessionPosition,
                    total: viewModel.sessionTotal,
                    isFlipped: viewModel.showMeaning,
                    onFlip: { viewModel.toggleMeaning() },
                    onAnswer: { viewModel.markCard(correct: $0) },
                    canUndo: viewModel.canUndo,
                    onUndo: { viewModel.undoLastAnswer() }
                )
            } else if let finished = viewModel.finishedSession {
                SessionEndScreen(summary: finished) {
                    viewModel.dismissSessionEnd()
                }
            } else {
                SummaryScreen(
                    boxLabels: boxLabels,
                    progress: viewModel.progress,
                    buttonAction: { viewModel.fetchNextSet() },
                    onAbout: { showingAbout = true }
                )
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .sheet(isPresented: $showingAbout) {
            AboutScreen()
        }
    }
}

#Preview {
    ContentView(viewModel: .forPreview())
}
