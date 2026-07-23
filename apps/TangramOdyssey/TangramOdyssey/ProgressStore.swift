//
//  ProgressStore.swift
//  TangramOdyssey
//
//  Tracks which puzzles the player has solved. Persisted locally via UserDefaults and,
//  when available, mirrored to iCloud's key-value store so progress follows the player
//  across iPhone / iPad / tvOS. Solving is monotonic, so cross-device merges just union.
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
    /// stores that never sync (local `UserDefaults`, test fakes).
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

    private let defaults: UserDefaults
    private let cloud: KeyValueStore?   // nil for local-only / tests
    private let storageKey = "solvedPuzzleIDs"
    @ObservationIgnored private var observationTask: Task<Void, Never>?

    /// - Parameters:
    ///   - defaults: device-local store (injectable for tests).
    ///   - cloud: cross-device store. Pass `NSUbiquitousKeyValueStore.default` in the app;
    ///     leave `nil` for local-only behavior or inject a fake in tests.
    init(defaults: UserDefaults = .standard, cloud: KeyValueStore? = nil) {
        self.defaults = defaults
        self.cloud = cloud

        // Seed from local, then fold in whatever the cloud already knows about.
        var ids = Self.decode(defaults.data(forKey: storageKey))
        if let cloud {
            ids.formUnion(Self.decode(cloud.dataValue(forKey: storageKey)))
        }
        self.solvedIDs = ids

        // Put both stores in agreement on the merged view.
        if cloud != nil { persist() }

        observeCloudChanges()
        cloud?.synchronizeStore()
    }

    deinit { observationTask?.cancel() }

    var solvedCount: Int { solvedIDs.count }

    func isSolved(_ puzzleID: Int) -> Bool { solvedIDs.contains(puzzleID) }

    func markSolved(_ puzzleID: Int) {
        guard solvedIDs.insert(puzzleID).inserted else { return }
        persist()
    }

    /// Clears all recorded progress. Note: with union-merge, another signed-in device can
    /// re-propagate its solved set — reset is effectively local unless you add a tombstone.
    func clear() {
        guard !solvedIDs.isEmpty else { return }
        solvedIDs.removeAll()
        persist()
    }

    // MARK: - Sync

    /// Fold externally-changed cloud state into the in-memory set (union — never un-solve).
    /// Factored out so tests can drive it without a live iCloud account.
    func mergeExternalChanges() {
        guard let cloud else { return }
        let merged = solvedIDs.union(Self.decode(cloud.dataValue(forKey: storageKey)))
        guard merged != solvedIDs else { return }
        solvedIDs = merged
        persist()   // write the widened set back so it propagates onward
    }

    private func observeCloudChanges() {
        guard let name = cloud?.externalChangeNotification else { return }
        observationTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: name) {
                self?.mergeExternalChanges()
            }
        }
    }

    private func persist() {
        let data = Self.encode(solvedIDs)
        defaults.set(data, forKey: storageKey)
        cloud?.setDataValue(data, forKey: storageKey)
        cloud?.synchronizeStore()
    }

    // MARK: - Coding (unchanged JSON shape: a Set<Int>)

    private static func decode(_ data: Data?) -> Set<Int> {
        guard let data,
              let ids = try? JSONDecoder().decode(Set<Int>.self, from: data) else { return [] }
        return ids
    }

    private static func encode(_ ids: Set<Int>) -> Data? {
        try? JSONEncoder().encode(ids)
    }
}
