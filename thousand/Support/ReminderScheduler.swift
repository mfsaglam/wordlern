//
//  ReminderScheduler.swift
//  thousand
//
//  Created by Fatih Sağlam on 30.09.2026.
//

import UserNotifications

/// The app's one local notification: fired at the moment the next card comes
/// due, saying how many words are waiting. No repeat, no server, no push
/// entitlement — and no in-app toggle, since iOS Settings is the off switch.
enum ReminderScheduler {
    /// A single identifier, so scheduling always replaces the pending request
    /// instead of stacking another one behind it.
    private static let requestIdentifier = "next-review"

    /// Asked for from the session end screen, never at launch — a prompt that
    /// arrives before the app has shown its worth gets denied, and a denial
    /// only comes back through Settings. iOS shows the prompt on the first call
    /// and answers every later one from the stored decision, so this is safe to
    /// call at the end of every session.
    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Replaces the pending reminder with one for `review`. A nil `review`
    /// clears it: either cards are due already — the user needs no reminder of
    /// something they can do now — or there is nothing left to review at all.
    static func reschedule(for review: WordViewModel.NextReview?) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])

        guard let review else { return }
        let wait = review.date.timeIntervalSinceNow
        guard wait > 0 else { return }

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "time to review")
        content.body = body(for: review.count)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: requestIdentifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: wait, repeats: false)
        )
        try? await center.add(request)
    }

    /// Says what is waiting rather than nagging. Split by count because the
    /// string catalog carries no plural rule for this one line.
    private static func body(for count: Int) -> String {
        count == 1
            ? String(localized: "1 word is ready to review")
            : String(localized: "\(count) words are ready to review")
    }
}
