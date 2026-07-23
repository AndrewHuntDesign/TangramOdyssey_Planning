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

    // MARK: - Cross-device sync

    /// The JSON key ProgressStore uses; mirrored here since it's private to the store.
    private let storageKey = "solvedPuzzleIDs"

    private func cloudBlob(_ ids: Set<Int>) -> Data {
        try! JSONEncoder().encode(ids)
    }

    @Test func seedsFromCloudAtLaunch() {
        let cloud = InMemoryKeyValueStore()
        cloud.setDataValue(cloudBlob([5]), forKey: storageKey)
        let store = ProgressStore(defaults: makeDefaults(), cloud: cloud)
        #expect(store.isSolved(5))
    }

    @Test func mirrorsSolvesToCloud() {
        let cloud = InMemoryKeyValueStore()
        let store = ProgressStore(defaults: makeDefaults(), cloud: cloud)
        store.markSolved(9)
        let mirrored = try! JSONDecoder().decode(Set<Int>.self, from: cloud.dataValue(forKey: storageKey)!)
        #expect(mirrored.contains(9))
    }

    @Test func mergesExternalCloudChanges() {
        let cloud = InMemoryKeyValueStore()
        let store = ProgressStore(defaults: makeDefaults(), cloud: cloud)
        store.markSolved(1)

        // Simulate another device having solved 2 and 3, then a change notification.
        cloud.setDataValue(cloudBlob([2, 3]), forKey: storageKey)
        store.mergeExternalChanges()

        #expect(store.isSolved(1))
        #expect(store.isSolved(2))
        #expect(store.isSolved(3))
        #expect(store.solvedCount == 3)
    }
}

/// A UserDefaults-free stand-in for the cloud slot: holds data in memory and never
/// posts external-change notifications (tests drive `mergeExternalChanges()` directly).
@MainActor
final class InMemoryKeyValueStore: KeyValueStore {
    private var storage: [String: Data] = [:]
    func dataValue(forKey key: String) -> Data? { storage[key] }
    func setDataValue(_ data: Data?, forKey key: String) { storage[key] = data }
    @discardableResult func synchronizeStore() -> Bool { true }
    var externalChangeNotification: Notification.Name? { nil }
}
