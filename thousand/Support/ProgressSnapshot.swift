//
//  ProgressSnapshot.swift
//  thousand
//
//  Created by Fatih Sağlam on 30.09.2026.
//

import Foundation

/// The six numbers a widget extension needs, written to the App Group
/// container. Nothing else about the app's progress is shared — the
/// SwiftData store stays private to this target; see step 24 of
/// `docs/PLAN.md`.
struct ProgressSnapshot: Codable {
    static let appGroupIdentifier = "group.com.mfsaglam.thousand"
    static let fileName = "progress-snapshot.json"

    let boxCounts: [Int]
    let mastered: Int
    let total: Int
    let dueCount: Int
    let nextDue: Date?
    let updated: Date

    /// Writes the snapshot to the App Group container. Does nothing if the
    /// container is unavailable — a widget that stays stale is not worth
    /// crashing the app over.
    func write() {
        guard let url = Self.containerURL else { return }
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Error writing progress snapshot: \(error)")
        }
    }

    private static var containerURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent(fileName)
    }
}
