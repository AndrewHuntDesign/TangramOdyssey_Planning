//
//  TangramGeometry.swift
//  TangramOdyssey
//
//  Turns the decoded puzzle data into drawable polygons.
//
//  The geometry was reverse-engineered from the dataset's only all-rotation-zero puzzle
//  ("Square 001", id 1785), whose seven pieces sit at their baseline orientation and tile a
//  perfect square. The resulting constants tile all 2,097 puzzles with negligible overlap.
//
//  Conventions:
//  - One tangram "unit" is `pointsPerUnit` points; a puzzle's overall size also multiplies by
//    its `scale` field. The assembled silhouette is a 4×4-unit square (area 16).
//  - `position` is the piece centroid. `rotation` is a step count: degrees = rotation × 15,
//    applied counter-clockwise. `reflected` mirrors the piece across its vertical axis (x → −x)
//    before rotation.
//  - Each piece `id` (1...7) has its own baseline orientation, so canonical polygons are keyed
//    by id, not by `PieceKind`.
//

import SwiftUI

nonisolated enum TangramGeometry {
    /// Points per tangram unit. The seven tans are rigid and identical across every puzzle,
    /// so this is constant; a puzzle's `scale` field multiplies it.
    static let pointsPerUnit: CGFloat = 50

    /// Canonical vertices for a piece `id` (1...7), in units, centered on the piece centroid,
    /// at rotation 0 and not reflected. Returns an empty array for unknown ids.
    static func unitPolygon(pieceID: Int) -> [CGPoint] {
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
        let t = 1.0 / 3.0
        switch pieceID {
        case 1: return [p(-2*t, -2), p(-2*t, 2), p(4*t, 0)]          // large triangle
        case 2: return [p(-2, 2*t), p(2, 2*t), p(0, -4*t)]          // large triangle
        case 3: return [p(-1, -t), p(1, -t), p(0, 2*t)]            // small triangle
        case 4: return [p(2*t, -2*t), p(2*t, 4*t), p(-4*t, -2*t)]  // medium triangle
        case 5: return [p(t, -1), p(-2*t, 0), p(t, 1)]            // small triangle
        case 6: return [p(-1, 0), p(0, -1), p(1, 0), p(0, 1)]      // square (diamond)
        case 7: return [p(-1.5, -0.5), p(0.5, -0.5), p(1.5, 0.5), p(-0.5, 0.5)] // parallelogram
        default: return []
        }
    }
}

extension TanPiece {
    /// The piece's polygon in the puzzle's coordinate space (points), ready to draw.
    ///
    /// - Parameter scale: the owning puzzle's `scale` field.
    func vertices(scale: Double) -> [CGPoint] {
        let unit = TangramGeometry.pointsPerUnit * CGFloat(scale)
        let theta = rotationDegrees * .pi / 180
        let cosT = cos(theta), sinT = sin(theta)
        let cx = center.x, cy = center.y
        return TangramGeometry.unitPolygon(pieceID: id).map { v in
            let x = isReflected ? -v.x : v.x          // mirror before rotating
            let y = v.y
            let rx = x * cosT - y * sinT
            let ry = x * sinT + y * cosT
            return CGPoint(x: cx + rx * unit, y: cy + ry * unit)
        }
    }
}

extension Puzzle {
    /// Each piece paired with its drawable polygon, in puzzle coordinate space.
    func piecePolygons() -> [(piece: TanPiece, vertices: [CGPoint])] {
        pieces.map { ($0, $0.vertices(scale: scale)) }
    }

    /// Axis-aligned bounding box enclosing every piece, in puzzle coordinate space.
    var boundingBox: CGRect {
        let points = pieces.flatMap { $0.vertices(scale: scale) }
        guard let first = points.first else { return .zero }
        var minX = first.x, minY = first.y, maxX = first.x, maxY = first.y
        for pt in points {
            minX = min(minX, pt.x); minY = min(minY, pt.y)
            maxX = max(maxX, pt.x); maxY = max(maxY, pt.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

extension PieceKind {
    /// A distinct fill color per tan kind, for the assembled/solution view.
    var color: Color {
        switch self {
        case .largeTriangle:  Color(red: 0.20, green: 0.55, blue: 0.85)
        case .mediumTriangle: Color(red: 0.95, green: 0.70, blue: 0.20)
        case .smallTriangle:  Color(red: 0.85, green: 0.35, blue: 0.35)
        case .square:         Color(red: 0.35, green: 0.75, blue: 0.45)
        case .parallelogram:  Color(red: 0.60, green: 0.45, blue: 0.80)
        }
    }
}
