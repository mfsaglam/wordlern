//
//  Haptics.swift
//  thousand
//
//  Created by Fatih Sağlam on 30.09.2026.
//

import UIKit

/// The answer gesture's taps. Deliberately few: one per thing the user did, at
/// the moment they did it. The generators are kept alive and primed so the
/// first tap of a drag is not late; they are only ever touched from the main
/// thread, inside a gesture or a button action.
enum Haptics {
    private static let selection = UISelectionFeedbackGenerator()
    private static let crisp = UIImpactFeedbackGenerator(style: .rigid)
    private static let cushioned = UIImpactFeedbackGenerator(style: .soft)
    private static let light = UIImpactFeedbackGenerator(style: .light)

    /// Called as a drag starts. Warming the hardware up here is what keeps the
    /// commit tap in step with the finger.
    static func prepareForDrag() {
        selection.prepare()
        crisp.prepare()
        cushioned.prepare()
    }

    /// The drag crossed the point where letting go would answer — or came back
    /// under it. Feeling this lets the user commit or back out without looking.
    static func swipeArmingChanged() {
        selection.selectionChanged()
    }

    /// Correct snaps, incorrect is cushioned. The two are told apart by texture
    /// rather than by strength, so neither reads as a reward or a reprimand.
    static func answer(correct: Bool) {
        (correct ? crisp : cushioned).impactOccurred()
    }

    /// Lighter than an answer: taking one back is the smaller event.
    static func undo() {
        light.impactOccurred()
    }
}
