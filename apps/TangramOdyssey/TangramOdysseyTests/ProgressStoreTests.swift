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
    //
    // These exercise the cloud path through real ProgressStore instances sharing one
    // in-memory cloud fake, so nothing here depends on the store's private key or blob format.

    @Test func seedsFromCloudAtLaunch() {
        let cloud = InMemoryKeyValueStore()
        let deviceA = ProgressStore(defaults: makeDefaults(), cloud: cloud)
        deviceA.markSolved(5)

        // A second device launching against the same cloud sees the solve.
        let deviceB = ProgressStore(defaults: makeDefaults(), cloud: cloud)
        #expect(deviceB.isSolved(5))
    }

    @Test func mergesExternalCloudChanges() {
        let cloud = InMemoryKeyValueStore()
        let deviceA = ProgressStore(defaults: makeDefaults(), cloud: cloud)
        deviceA.markSolved(1)

        // Device B (sharing the cloud) solves more, then A reconciles.
        let deviceB = ProgressStore(defaults: makeDefaults(), cloud: cloud)
        deviceB.markSolved(2)
        deviceB.markSolved(3)
        deviceA.mergeExternalChanges()

        #expect(deviceA.isSolved(1))
        #expect(deviceA.isSolved(2))
        #expect(deviceA.isSolved(3))
        #expect(deviceA.solvedCount == 3)
    }

    @Test func observesExternalChangeNotification() async {
        let cloud = InMemoryKeyValueStore()
        let deviceA = ProgressStore(defaults: makeDefaults(), cloud: cloud)
        deviceA.markSolved(1)

        // Device B solves 2 into the shared cloud, then iCloud pushes the change to A.
        let deviceB = ProgressStore(defaults: makeDefaults(), cloud: cloud)
        deviceB.markSolved(2)
        cloud.postExternalChange()

        await waitUntil { deviceA.isSolved(2) }
        #expect(deviceA.isSolved(1))
        #expect(deviceA.isSolved(2))
    }

    // MARK: - Clear tombstone

    /// A reset must survive a stale/in-flight cloud push carrying pre-clear solves — the
    /// regression the union-only merge had.
    @Test func clearIsNotRepopulatedByStaleCloudPush() {
        let cloud = InMemoryKeyValueStore()
        let store = ProgressStore(defaults: makeDefaults(), cloud: cloud, now: { 200 })
        store.markSolved(1)
        store.markSolved(2)

        let stalePush = cloud.snapshot()   // {1,2} in the pre-clear epoch (clearedAt 0)
        store.clear()                       // resets and bumps the tombstone to 200
        cloud.restore(stalePush)            // an in-flight push overwrites the cloud again
        store.mergeExternalChanges()

        #expect(store.solvedCount == 0)     // reset wins; solves do not come back
    }

    /// A newer clear from another device wins on merge (adopts the empty, post-clear set).
    @Test func newerRemoteClearWins() {
        let cloud = InMemoryKeyValueStore()
        let deviceA = ProgressStore(defaults: makeDefaults(), cloud: cloud, now: { 100 })
        deviceA.markSolved(1)
        deviceA.markSolved(2)

        // Device B, sharing the cloud, resets more recently.
        let deviceB = ProgressStore(defaults: makeDefaults(), cloud: cloud, now: { 300 })
        deviceB.clear()

        deviceA.mergeExternalChanges()
        #expect(deviceA.solvedCount == 0)
    }

    /// Await `condition` becoming true, polling briefly so async observer delivery can land.
    private func waitUntil(timeoutMillis: Int = 1000,
                           _ condition: () -> Bool) async {
        var waited = 0
        while !condition() && waited < timeoutMillis {
            try? await Task.sleep(for: .milliseconds(10))
            waited += 10
        }
    }
}

/// A UserDefaults-free stand-in for the cloud slot: holds data in memory. Unlike the real
/// store it won't emit change notifications on its own, so tests trigger one explicitly with
/// `postExternalChange()`; the per-instance notification name keeps parallel tests isolated.
@MainActor
final class InMemoryKeyValueStore: KeyValueStore {
    private var storage: [String: Data] = [:]
    private let notificationName = Notification.Name("InMemoryKVS.\(UUID().uuidString)")

    func dataValue(forKey key: String) -> Data? { storage[key] }
    func setDataValue(_ data: Data?, forKey key: String) { storage[key] = data }
    @discardableResult func synchronizeStore() -> Bool { true }
    var externalChangeNotification: Notification.Name? { notificationName }

    /// Snapshot / restore the raw contents without knowing the store's keys — used to
    /// simulate a stale cloud value being pushed back after a local change.
    func snapshot() -> [String: Data] { storage }
    func restore(_ contents: [String: Data]) { storage = contents }

    /// Simulate iCloud notifying observers that another device changed the store.
    func postExternalChange() {
        NotificationCenter.default.post(name: notificationName, object: self)
    }
}
