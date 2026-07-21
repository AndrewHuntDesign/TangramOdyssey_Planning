//
//  PuzzleView.swift
//  TangramOdyssey
//
//  Renders a puzzle's assembled solution (or silhouette) into a Canvas, scaled to fit.
//

import SwiftUI

private struct PuzzlePieceGeometry {
    let piece: TanPiece
    let vertices: [CGPoint]
}

private struct PuzzleRenderGeometry {
    let polygons: [PuzzlePieceGeometry]
    let boundingBox: CGRect

    init(puzzle: Puzzle) {
        polygons = puzzle.pieces.map {
            PuzzlePieceGeometry(piece: $0, vertices: $0.vertices(scale: puzzle.scale))
        }

        let points = polygons.flatMap(\.vertices)
        guard let first = points.first else {
            boundingBox = .zero
            return
        }

        var minX = first.x
        var minY = first.y
        var maxX = first.x
        var maxY = first.y
        for point in points {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }
        boundingBox = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

@MainActor
private enum PuzzleGeometryCache {
    private static var geometries: [Int: PuzzleRenderGeometry] = [:]

    static func geometry(for puzzle: Puzzle) -> PuzzleRenderGeometry {
        if let geometry = geometries[puzzle.id] {
            return geometry
        }

        let geometry = PuzzleRenderGeometry(puzzle: puzzle)
        geometries[puzzle.id] = geometry
        return geometry
    }
}

/// How a puzzle is drawn.
enum PuzzleRenderStyle {
    /// Each tan filled with its kind's color and outlined — the solved puzzle.
    case solution
    /// A single filled shape in one color — the target silhouette to solve.
    case silhouette(Color)
}

/// Draws a `Puzzle`, fitting its bounding box into the available space.
///
/// The dataset's coordinate space is y-up (from its Mathematica origin); SwiftUI is y-down, so
/// the fit flips vertically to render puzzles upright.
struct PuzzleView: View {
    let puzzle: Puzzle
    var style: PuzzleRenderStyle = .solution
    var padding: CGFloat = 16

    var body: some View {
        let geometry = PuzzleGeometryCache.geometry(for: puzzle)

        Canvas { context, size in
            let polygons = geometry.polygons
            let box = geometry.boundingBox
            guard box.width > 0, box.height > 0 else { return }

            let scale = min((size.width - 2 * padding) / box.width,
                            (size.height - 2 * padding) / box.height)
            let drawnWidth = box.width * scale
            let drawnHeight = box.height * scale
            let offsetX = (size.width - drawnWidth) / 2
            let offsetY = (size.height - drawnHeight) / 2

            // Map a puzzle-space point into the fitted canvas rect. The dataset's y axis already
            // matches screen orientation (y-down), so no vertical flip is applied.
            func map(_ point: CGPoint) -> CGPoint {
                CGPoint(x: offsetX + (point.x - box.minX) * scale,
                        y: offsetY + (point.y - box.minY) * scale)
            }

            func path(for vertices: [CGPoint]) -> Path {
                var path = Path()
                let mapped = vertices.map(map)
                if let start = mapped.first {
                    path.move(to: start)
                    for point in mapped.dropFirst() { path.addLine(to: point) }
                    path.closeSubpath()
                }
                return path
            }

            switch style {
            case .solution:
                for polygon in polygons {
                    let shape = path(for: polygon.vertices)
                    context.fill(shape, with: .color(polygon.piece.kind?.color ?? .gray))
                    context.stroke(shape, with: .color(.black.opacity(0.4)), lineWidth: 1)
                }
            case .silhouette(let color):
                for polygon in polygons {
                    context.fill(path(for: polygon.vertices), with: .color(color))
                }
            }
        }
    }
}

#Preview("Square 001 – solution") {
    if let puzzle = try? PuzzleLoader.loadAll().first(where: { $0.id == 1785 }) {
        PuzzleView(puzzle: puzzle)
            .frame(width: 300, height: 300)
            .padding()
    } else {
        Text("Failed to load puzzle data")
    }
}

#Preview("Letter – orientation") {
    if let puzzle = try? PuzzleLoader.loadAll().first(where: { $0.id == 1300 }) {
        PuzzleView(puzzle: puzzle, style: .silhouette(.black))
            .frame(width: 300, height: 300)
            .padding()
    } else {
        Text("Failed to load puzzle data")
    }
}
