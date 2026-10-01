//
//  ContentView.swift
//  thousand
//
//  Created by Fatih Sağlam on 19.09.2024.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject var viewModel: WordViewModel

    /// One sheet modifier for both screens — stacking two `.sheet`s on the same
    /// view only ever presents one of them.
    private enum Sheet: Identifiable {
        case about
        case howItWorks

        var id: Self { self }
    }

    @State private var sheet: Sheet?

    @Environment(\.scenePhase) private var scenePhase

    /// The how-it-works sheet is offered once, unasked, on the very first launch.
    @AppStorage("hasSeenHowItWorks") private var hasSeenHowItWorks = false

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
                SessionEndScreen(
                    summary: finished,
                    onReminderOpportunity: {
                        await ReminderScheduler.requestAuthorization()
                        // Schedule straight away rather than waiting for the
                        // app to go to the background: permission was just
                        // granted and the next due date is already known.
                        await ReminderScheduler.reschedule(for: viewModel.nextReview)
                    },
                    onSeeProgress: { viewModel.dismissSessionEnd() }
                )
            } else {
                SummaryScreen(
                    boxLabels: boxLabels,
                    progress: viewModel.progress,
                    retiredCount: viewModel.retiredCount,
                    dueCount: viewModel.dueCount,
                    nextReviewDate: viewModel.nextReviewDate,
                    buttonAction: { viewModel.fetchNextSet() },
                    onAbout: { sheet = .about },
                    onHowItWorks: { sheet = .howItWorks }
                )
            }
        }
        .onAppear {
            viewModel.onAppear()
            // `onAppear` fires again when a sheet is dismissed, so the flag goes
            // down before the sheet goes up.
            if !hasSeenHowItWorks {
                hasSeenHowItWorks = true
                sheet = .howItWorks
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Leaving the app is the one moment the pending reminder is sure to
            // be stale, and the only one where rescheduling costs the user
            // nothing. Cancel-and-replace, so there is never a second request.
            guard phase == .background else { return }
            let review = viewModel.nextReview
            Task { await ReminderScheduler.reschedule(for: review) }
        }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .about: AboutScreen()
            case .howItWorks:
                HowItWorksScreen(onOpenSettings: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                })
            }
        }
    }
}

#Preview {
    ContentView(viewModel: .forPreview())
}
