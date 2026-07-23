//
//  ProgressStore.swift
//  TangramOdyssey
//
//  Tracks which puzzles the player has solved. Persisted locally via UserDefaults and,
//  when available, mirrored to iCloud's key-value store so progress follows the player
//  across iPhone / iPad / tvOS.
//
//  Solving is monotonic, so same-epoch merges just union. A `clear()` bumps a `clearedAt`
//  tombstone; the more recent clear wins a merge outright, so a reset is not silently
//  repopulated by an in-flight/stale cloud push carrying pre-clear solves.
//

import Foundation
import Observation

/// Minimal abstraction over a key-value backing store, so the same ProgressStore logic
/// works against local `UserDefaults`, iCloud's `NSUbiquitousKeyValueStore`, or an
/// in-memory fake in tests. Distinct method names (vs. `data(forKey:)` / `set(_:forKey:)`)
/// keep witness matching unambiguous across those concrete types.
protocol KeyValueStore: AnyObject {
    func dataValue(forKey key: String) -> Data?
    func setDataValue(_ data: Data?, forKey key: String)
    @discardableResult func synchronizeStore() -> Bool
    /// The notification posted when another device changes the store, or `nil` for
    /// stores that never sync (local `UserDefaults`, test fakes without an observer).
    var externalChangeNotification: Notification.Name? { get }
}

extension UserDefaults: KeyValueStore {
    func dataValue(forKey key: String) -> Data? { data(forKey: key) }
    func setDataValue(_ data: Data?, forKey key: String) { set(data, forKey: key) }
    @discardableResult func synchronizeStore() -> Bool { synchronize() }
    var externalChangeNotification: Notification.Name? { nil }
}

extension NSUbiquitousKeyValueStore: KeyValueStore {
    func dataValue(forKey key: String) -> Data? { data(forKey: key) }
    func setDataValue(_ data: Data?, forKey key: String) { set(data, forKey: key) }
    @discardableResult func synchronizeStore() -> Bool { synchronize() }
    var externalChangeNotification: Notification.Name? { Self.didChangeExternallyNotification }
}

@MainActor
@Observable
final class ProgressStore {
    private(set) var solvedIDs: Set<Int>

    /// Timestamp of the last `clear()` on any device this state has merged with. Solves are
    /// only valid within the latest clear-epoch; a newer clear discards older solves on merge.
    @ObservationIgnored private var clearedAt: TimeInterval

    private let defaults: UserDefaults
    private let cloud: KeyValueStore?   // nil for local-only / tests
    private let storageKey = "solvedPuzzleIDs"
    @ObservationIgnored private let now: () -> TimeInterval
    @ObservationIgnored private var observerToken: (any NSObjectProtocol)?

    /// - Parameters:
    ///   - defaults: device-local store (injectable for tests).
    ///   - cloud: cross-device store. Pass `NSUbiquitousKeyValueStore.default` in the app;
    ///     leave `nil` for local-only behavior or inject a fake in tests.
    ///   - now: clock for the clear tombstone (injectable so tests can order clears/solves).
    init(defaults: UserDefaults = .standard,
         cloud: KeyValueStore? = nil,
         now: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }) {
        self.defaults = defaults
        self.cloud = cloud
        self.now = now

        // Seed from local, then reconcile with whatever the cloud already knows about.
        var state = Self.decode(defaults.data(forKey: storageKey))
        if let cloud {
            state = Self.merge(state, Self.decode(cloud.dataValue(forKey: storageKey)))
        }
        self.solvedIDs = state.solved
        self.clearedAt = state.clearedAt

        // Put both stores in agreement on the reconciled view.
        if cloud != nil { persist() }

        observeCloudChanges()
        cloud?.synchronizeStore()
    }

    deinit {
        if let observerToken {
            NotificationCenter.default.removeObserver(observerToken)
        }
    }

    var solvedCount: Int { solvedIDs.count }

    func isSolved(_ puzzleID: Int) -> Bool { solvedIDs.contains(puzzleID) }

    func markSolved(_ puzzleID: Int) {
        guard solvedIDs.insert(puzzleID).inserted else { return }
        persist()
    }

    /// Clears all recorded progress and bumps the clear tombstone so the reset wins over
    /// concurrent or in-flight solves from other devices (rather than being unioned away).
    func clear() {
        guard !solvedIDs.isEmpty else { return }
        solvedIDs.removeAll()
        clearedAt = now()
        persist()
    }

    // MARK: - Sync

    /// Reconcile the current in-memory state with the cloud's state and adopt the result.
    /// Factored out so tests can drive it without a live iCloud account.
    func mergeExternalChanges() {
        guard let cloud else { return }
        let local = StoredProgress(solved: solvedIDs, clearedAt: clearedAt)
        let merged = Self.merge(local, Self.decode(cloud.dataValue(forKey: storageKey)))
        guard merged.solved != solvedIDs || merged.clearedAt != clearedAt else { return }
        solvedIDs = merged.solved
        clearedAt = merged.clearedAt
        persist()   // write the reconciled state back so it propagates onward
    }

    private func observeCloudChanges() {
        guard let name = cloud?.externalChangeNotification else { return }
        observerToken = NotificationCenter.default.addObserver(
            forName: name, object: nil, queue: nil
        ) { [weak self] note in
            // A quota violation means our own last write was rejected — there's nothing new
            // from the server to merge, so don't bother reconciling.
            if let reason = note.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int,
               reason == NSUbiquitousKeyValueStoreQuotaViolationChange {
                return
            }
            // The notification can arrive on any thread; reconcile on the main actor.
            Task { @MainActor in self?.mergeExternalChanges() }
        }
    }

    private func persist() {
        let data = Self.encode(StoredProgress(solved: solvedIDs, clearedAt: clearedAt))
        defaults.set(data, forKey: storageKey)
        cloud?.setDataValue(data, forKey: storageKey)
        cloud?.synchronizeStore()
    }

    // MARK: - Reconciliation

    /// Union solves within the same clear-epoch; across epochs, the more recent clear wins
    /// outright (its set already reflects any solves made after that clear).
    private static func merge(_ a: StoredProgress, _ b: StoredProgress) -> StoredProgress {
        if a.clearedAt == b.clearedAt {
            return StoredProgress(solved: a.solved.union(b.solved), clearedAt: a.clearedAt)
        }
        return a.clearedAt > b.clearedAt ? a : b
    }

    // MARK: - Coding

    /// The persisted shape. Decodes legacy bare-`Set<Int>` blobs (clearedAt = 0) so existing
    /// players keep their progress across the format change.
    private struct StoredProgress: Codable {
        var solved: Set<Int>
        var clearedAt: TimeInterval
    }

    private static func decode(_ data: Data?) -> StoredProgress {
        guard let data else { return StoredProgress(solved: [], clearedAt: 0) }
        if let stored = try? JSONDecoder().decode(StoredProgress.self, from: data) {
            return stored
        }
        // Legacy format: a bare Set<Int> with no tombstone.
        if let ids = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            return StoredProgress(solved: ids, clearedAt: 0)
        }
        return StoredProgress(solved: [], clearedAt: 0)
    }

    private static func encode(_ stored: StoredProgress) -> Data? {
        try? JSONEncoder().encode(stored)
    }
}
