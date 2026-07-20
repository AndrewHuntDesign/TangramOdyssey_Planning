//
//  PuzzleCatalog.swift
//  TangramOdyssey
//
//  Groups the puzzle dataset by category for browsing. Puzzles can belong to several categories
//  (e.g. "Fishes" and "Animals"), so a puzzle appears in each of its categories.
//

import Foundation

/// A navigable reference to a category (a typed wrapper so navigation destinations are unambiguous).
struct CategoryRef: Hashable {
    let name: String
}

struct PuzzleCatalog {
    let all: [Puzzle]
    /// Category names, ordered by puzzle count (descending), then alphabetically.
    let categories: [String]
    private let byCategory: [String: [Puzzle]]

    init(_ puzzles: [Puzzle]) {
        self.all = puzzles
        var map: [String: [Puzzle]] = [:]
        for puzzle in puzzles {
            for category in puzzle.categories {
                map[category, default: []].append(puzzle)
            }
        }
        self.byCategory = map
        self.categories = map.keys.sorted { a, b in
            let ca = map[a]!.count, cb = map[b]!.count
            return ca != cb ? ca > cb : a < b
        }
    }

    func puzzles(in category: String) -> [Puzzle] { byCategory[category] ?? [] }
    func count(in category: String) -> Int { byCategory[category]?.count ?? 0 }
}
