//
//  PuzzleView.swift
//  TangramOdyssey
//
//  Renders a puzzle's assembled solution (or silhouette) into a Canvas, scaled to fit.
//

import SwiftUI

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
        Canvas { context, size in
            let polygons = puzzle.piecePolygons()
            let box = puzzle.boundingBox
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
                for (piece, vertices) in polygons {
                    let shape = path(for: vertices)
                    context.fill(shape, with: .color(piece.kind?.color ?? .gray))
                    context.stroke(shape, with: .color(.black.opacity(0.4)), lineWidth: 1)
                }
            case .silhouette(let color):
                for (_, vertices) in polygons {
                    context.fill(path(for: vertices), with: .color(color))
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
