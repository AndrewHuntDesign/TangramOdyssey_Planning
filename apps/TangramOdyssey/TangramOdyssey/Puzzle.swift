//
//  Puzzle.swift
//  TangramOdyssey
//
//  Codable model for the puzzle dataset in TangramData.json.
//

import Foundation

// The model types are pure value data that must decode off the main actor and pass
// freely between actors, so they opt out of the project's default `MainActor` isolation.

/// One of the seven tans that make up every tangram puzzle.
///
/// The dataset identifies pieces only by numeric `id` (1...7); the kind is derived from
/// that id via a mapping that is stable across all 2,097 puzzles.
nonisolated enum PieceKind: String, Codable, Sendable, CaseIterable {
    case largeTriangle
    case mediumTriangle
    case smallTriangle
    case square
    case parallelogram

    /// Maps a piece `id` (1...7) to its tan kind. Returns `nil` for out-of-range ids.
    init?(pieceID: Int) {
        switch pieceID {
        case 1, 2: self = .largeTriangle
        case 3, 5: self = .smallTriangle
        case 4:    self = .mediumTriangle
        case 6:    self = .square
        case 7:    self = .parallelogram
        default:   return nil
        }
    }

    /// The piece's area in the puzzle's unit system. The seven areas always sum to 16.
    var area: Int {
        switch self {
        case .largeTriangle:  4
        case .mediumTriangle: 2
        case .square:         2
        case .parallelogram:  2
        case .smallTriangle:  1
        }
    }
}

/// The `angles` field is polymorphic in the data: normally an array of interior angles in
/// degrees, but piece id 5 always serializes as the string `"TriangleSmall2"` (a leaked
/// piece-type name). This preserves whichever form appears.
nonisolated enum PieceAngles: Codable, Hashable, Sendable {
    case degrees([Double])
    case named(String)

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let list = try? container.decode([Double].self) {
            self = .degrees(list)
        } else {
            self = .named(try container.decode(String.self))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .degrees(let list): try container.encode(list)
        case .named(let name):   try container.encode(name)
        }
    }
}

/// A single placed tan within a puzzle's solution silhouette.
nonisolated struct TanPiece: Codable, Hashable, Sendable, Identifiable {
    /// 1...7, unique within a puzzle. Determines the piece `kind`.
    let id: Int
    /// Center point as `[x, y]`. Values may be int or float in the source JSON.
    let position: [Double]
    /// Rotation as a raw step in 0...23. See `rotationDegrees`.
    let rotation: Int
    /// `0` or `1` in the data (not a JSON boolean).
    let reflected: Int
    /// Interior angles, or a leaked piece-name string for id 5. See `PieceAngles`.
    let angles: PieceAngles
    /// Piece area (1, 2, or 4); mirrors `kind.area`.
    let area: Int

    /// Whether this piece is mirrored. Only the square (id 6) and parallelogram (id 7)
    /// ever carry a non-zero value in the data; the parallelogram's reflection is the
    /// meaningful game mechanic.
    var isReflected: Bool { reflected != 0 }

    /// Rotation in degrees. `rotation` is stored as one of 24 steps (0...23), which maps
    /// to 15° increments (24 × 15° = 360°).
    var rotationDegrees: Double { Double(rotation) * 15 }

    /// The tan kind derived from `id`, or `nil` if the id is out of range.
    var kind: PieceKind? { PieceKind(pieceID: id) }

    /// The center point as a `CGPoint`.
    var center: CGPoint {
        CGPoint(x: position.first ?? 0, y: position.count > 1 ? position[1] : 0)
    }
}

/// A tangram puzzle: a named silhouette solved by placing all seven tans.
nonisolated struct Puzzle: Codable, Hashable, Sendable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let hint: String
    /// Category tags (e.g. `["Fishes", "Animals"]`). Populated for every puzzle.
    let categories: [String]
    let scale: Double
    /// Always exactly seven pieces.
    let pieces: [TanPiece]

    /// Sum of the piece areas; 16 for all valid puzzles.
    var totalArea: Int { pieces.reduce(0) { $0 + $1.area } }
}
