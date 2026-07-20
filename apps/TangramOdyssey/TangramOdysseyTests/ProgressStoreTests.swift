//
//  ProgressStoreTests.swift
//  TangramOdysseyTests
//
//  Verifies solved-puzzle tracking and that it persists across store instances (same defaults).
//

import Testing
import Foundation
@testable import TangramOdyssey

@MainActor
struct ProgressStoreTests {

    /// A fresh, isolated UserDefaults suite so tests never touch the shared defaults.
    private func makeDefaults() -> UserDefaults {
        let name = "ProgressStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func marksAndReportsSolved() {
        let store = ProgressStore(defaults: makeDefaults())
        #expect(!store.isSolved(42))
        store.markSolved(42)
        #expect(store.isSolved(42))
        #expect(store.solvedCount == 1)
    }

    @Test func markingIsIdempotent() {
        let store = ProgressStore(defaults: makeDefaults())
        store.markSolved(7)
        store.markSolved(7)
        #expect(store.solvedCount == 1)
    }

    @Test func persistsAcrossInstances() {
        let defaults = makeDefaults()
        let first = ProgressStore(defaults: defaults)
        first.markSolved(1)
        first.markSolved(2)

        let reloaded = ProgressStore(defaults: defaults)
        #expect(reloaded.isSolved(1))
        #expect(reloaded.isSolved(2))
        #expect(reloaded.solvedCount == 2)
    }

    @Test func clearResetsProgress() {
        let defaults = makeDefaults()
        let store = ProgressStore(defaults: defaults)
        store.markSolved(3)
        store.clear()
        #expect(store.solvedCount == 0)
        #expect(!ProgressStore(defaults: defaults).isSolved(3)) // cleared value also persisted
    }
}
