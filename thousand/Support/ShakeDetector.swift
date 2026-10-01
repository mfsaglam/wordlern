//
//  ShakeDetector.swift
//  thousand
//
//  Created by Fatih Sağlam on 01.10.2026.
//

import SwiftUI
import UIKit

/// Bridges the one UIKit event SwiftUI has no equivalent for:
/// `UIEventSubtypeMotionShake`. It is delivered as `motionEnded(_:with:)` down
/// the responder chain, so an invisible view claims the first-responder spot
/// and forwards it.
///
/// Attach it as a zero-size background, not as a layer over content — it must
/// never take a touch away from the card.
struct ShakeDetector: UIViewRepresentable {
    let onShake: () -> Void

    func makeUIView(context: Context) -> ShakeReceivingView {
        let view = ShakeReceivingView()
        view.onShake = onShake
        return view
    }

    func updateUIView(_ view: ShakeReceivingView, context: Context) {
        view.onShake = onShake
    }
}

final class ShakeReceivingView: UIView {
    var onShake: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Not in `init`: a view with no window cannot become first responder,
        // and the attempt fails silently rather than throwing.
        guard window != nil else { return }
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else {
            super.motionEnded(motion, with: event)
            return
        }
        onShake?()
    }
}
