//
//  PuzzleDataTests.swift
//  TangramOdysseyTests
//
//  Validates that the bundled TangramData.json decodes into the model and satisfies
//  the tangram domain invariants (7 pieces, areas summing to 16, stable id→kind mapping).
//

import Testing
import Foundation
@testable import TangramOdyssey

struct PuzzleDataTests {

    /// The whole dataset decodes and contains the expected number of puzzles.
    @Test func decodesEveryPuzzle() throws {
        let puzzles = try PuzzleLoader.loadAll()
        #expect(puzzles.count == 2097)
    }

    /// Every puzzle has exactly seven tans whose areas sum to 16.
    @Test func everyPuzzleHasSevenPiecesSummingToSixteen() throws {
        for puzzle in try PuzzleLoader.loadAll() {
            #expect(puzzle.pieces.count == 7)
            #expect(puzzle.totalArea == 16)
        }
    }

    /// Piece ids are always 1...7 and each maps to a known kind whose area matches the data.
    @Test func pieceIdsMapToConsistentKinds() throws {
        for puzzle in try PuzzleLoader.loadAll() {
            #expect(Set(puzzle.pieces.map(\.id)) == Set(1...7))
            for piece in puzzle.pieces {
                let kind = try #require(piece.kind)
                #expect(kind.area == piece.area)
            }
        }
    }

    /// `categories` is populated for every puzzle (the dataset is fully categorized).
    @Test func everyPuzzleIsCategorized() throws {
        for puzzle in try PuzzleLoader.loadAll() {
            #expect(!puzzle.categories.isEmpty)
        }
    }

    /// Only the square and parallelogram ever carry a reflection flag.
    @Test func onlySquareAndParallelogramReflect() throws {
        for puzzle in try PuzzleLoader.loadAll() {
            for piece in puzzle.pieces where piece.isReflected {
                #expect(piece.kind == .square || piece.kind == .parallelogram)
            }
        }
    }

    /// The polymorphic `angles` field decodes in both its array and string forms.
    @Test func anglesDecodeInBothForms() throws {
        let puzzle = try #require(try PuzzleLoader.loadAll().first)
        let piece5 = try #require(puzzle.pieces.first { $0.id == 5 })
        #expect(piece5.angles == .named("TriangleSmall2"))

        let piece1 = try #require(puzzle.pieces.first { $0.id == 1 })
        if case .degrees(let angles) = piece1.angles {
            #expect(!angles.isEmpty)
        } else {
            Issue.record("Expected piece 1 angles to decode as a degree array")
        }
    }
}
