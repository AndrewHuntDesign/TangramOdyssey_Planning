//
//  PuzzleLibrary.swift
//  TangramOdyssey
//
//  Loads and decodes the bundled TangramData.json puzzle dataset.
//

import Foundation

/// Errors thrown while locating or decoding the puzzle dataset.
nonisolated enum PuzzleLoaderError: Error, CustomStringConvertible {
    case resourceNotFound(name: String)
    case decodingFailed(any Error)

    var description: String {
        switch self {
        case .resourceNotFound(let name):
            "Could not find bundled resource \(name).json"
        case .decodingFailed(let error):
            "Failed to decode puzzle data: \(error)"
        }
    }
}

/// Loads the puzzle dataset from the app bundle.
nonisolated enum PuzzleLoader {
    /// Base name of the bundled JSON resource (`TangramData.json`).
    static let resourceName = "TangramData"

    /// Decodes every puzzle from the bundled dataset.
    ///
    /// - Parameter bundle: Bundle to search; defaults to `.main` (the host app bundle,
    ///   which is also correct for app-hosted test targets).
    /// - Returns: All puzzles in file order.
    static func loadAll(from bundle: Bundle = .main) throws -> [Puzzle] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw PuzzleLoaderError.resourceNotFound(name: resourceName)
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode([Puzzle].self, from: data)
        } catch {
            throw PuzzleLoaderError.decodingFailed(error)
        }
    }
}
