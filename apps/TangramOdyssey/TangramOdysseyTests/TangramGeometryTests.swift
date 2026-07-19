//
//  TangramGeometryTests.swift
//  TangramOdysseyTests
//
//  Guards the reverse-engineered geometry constants: canonical piece areas, area preservation
//  under rotation/reflection, and that the reference square (id 1785) spans exactly a 4×4-unit
//  square. Full tiling (zero overlap across all 2,097 puzzles) was verified out-of-band.
//

import Testing
import Foundation
import CoreGraphics
@testable import TangramOdyssey

struct TangramGeometryTests {

    /// Shoelace area of a simple polygon.
    private func area(_ polygon: [CGPoint]) -> Double {
        guard polygon.count >= 3 else { return 0 }
        var sum = 0.0
        for i in polygon.indices {
            let a = polygon[i], b = polygon[(i + 1) % polygon.count]
            sum += Double(a.x * b.y - b.x * a.y)
        }
        return abs(sum) / 2
    }

    /// Canonical unit polygons have the piece's expected area (× pointsPerUnit²).
    @Test func canonicalPolygonAreasMatchPieceAreas() {
        let unit = Double(TangramGeometry.pointsPerUnit)
        let expectedByID = [1: 4, 2: 4, 3: 1, 4: 2, 5: 1, 6: 2, 7: 2]
        for (id, expectedArea) in expectedByID {
            let scaled = TangramGeometry.unitPolygon(pieceID: id)
                .map { CGPoint(x: $0.x * unit, y: $0.y * unit) }
            #expect(abs(area(scaled) - Double(expectedArea) * unit * unit) < 0.01)
        }
    }

    /// Rotation and reflection are rigid motions, so every placed piece keeps its area.
    @Test func placedPiecesPreserveArea() throws {
        let unit = Double(TangramGeometry.pointsPerUnit)
        for puzzle in try PuzzleLoader.loadAll() {
            for piece in puzzle.pieces {
                let expected = Double(piece.area) * unit * unit * puzzle.scale * puzzle.scale
                #expect(abs(area(piece.vertices(scale: puzzle.scale)) - expected) < 0.5)
            }
        }
    }

    /// The reference puzzle "Square 001" (all pieces at baseline orientation) spans exactly a
    /// 4-unit square — the anchor that pins every other constant.
    @Test func referenceSquareSpansFourUnits() throws {
        let square = try #require(try PuzzleLoader.loadAll().first { $0.id == 1785 })
        let side = Double(TangramGeometry.pointsPerUnit) * 4
        let box = square.boundingBox
        #expect(abs(Double(box.width) - side) < 0.5)
        #expect(abs(Double(box.height) - side) < 0.5)
    }
}
