//
//  ProgressStore.swift
//  TangramOdyssey
//
//  Tracks which puzzles the player has solved, persisted across launches via UserDefaults.
//  Injected through the SwiftUI environment. `UserDefaults` is injectable so tests can use an
//  isolated suite instead of the shared defaults.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProgressStore {
    private(set) var solvedIDs: Set<Int>

    private let defaults: UserDefaults
    private let storageKey = "solvedPuzzleIDs"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let ids = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            self.solvedIDs = ids
        } else {
            self.solvedIDs = []
        }
    }

    var solvedCount: Int { solvedIDs.count }

    func isSolved(_ puzzleID: Int) -> Bool { solvedIDs.contains(puzzleID) }

    func markSolved(_ puzzleID: Int) {
        guard solvedIDs.insert(puzzleID).inserted else { return }
        persist()
    }

    /// Clears all recorded progress.
    func clear() {
        guard !solvedIDs.isEmpty else { return }
        solvedIDs.removeAll()
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(solvedIDs) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
