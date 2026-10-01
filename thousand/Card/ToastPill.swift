//
//  ToastPill.swift
//  thousand
//
//  Created by Fatih Sağlam on 01.10.2026.
//

import SwiftUI

/// The card screen's one transient confirmation: a dark pill that says what
/// just happened and leaves. Used for tap-to-copy and for shake-to-undo, which
/// both act without changing anything the user can point at.
struct ToastPill: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.primary.opacity(0.85)))
            .foregroundStyle(Color(uiColor: .systemBackground))
            .allowsHitTesting(false)
    }
}

/// Drives a `ToastPill`'s brief appearance. Token-based rather than a
/// cancellable timer: a second flash while the first pill is still fading just
/// bumps the token, so the stale dismissal no-ops instead of cutting the new
/// pill short. Only ever touched from the main thread, inside a gesture, a
/// button action or its own `DispatchQueue.main` follow-up.
final class ToastFlash: ObservableObject {
    @Published private(set) var isVisible = false
    private var token = 0

    func flash() {
        token += 1
        let current = token
        withAnimation(.easeOut(duration: 0.15)) {
            isVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            guard let self, current == token else { return }
            withAnimation(.easeIn(duration: 0.2)) { [weak self] in
                self?.isVisible = false
            }
        }
    }
}

#Preview {
    ToastPill(text: "undone")
        .padding()
}
