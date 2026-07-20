//
//  GameBoardView.swift
//  TangramOdyssey
//
//  Interactive board: a tray of loose tans below a target silhouette. Pieces are individually
//  positioned views so SwiftUI animates their glide, rotation, flip, and lock-pop directly.
//

import SwiftUI

/// Maps the game's board coordinate space (y-up) into a view's rect (y-down), uniformly.
private struct BoardMap {
    let board: CGRect
    let size: CGSize

    var scale: CGFloat { min(size.width / board.width, size.height / board.height) }
    private var originX: CGFloat { (size.width - board.width * scale) / 2 }
    private var originY: CGFloat { (size.height - board.height * scale) / 2 }

    func toScreen(_ p: CGPoint) -> CGPoint {
        // Board space is screen-oriented (y-down); no vertical flip.
        CGPoint(x: originX + (p.x - board.minX) * scale,
                y: originY + (p.y - board.minY) * scale)
    }
}

/// Draws a polygon from already-computed screen points.
private struct PolyShape: Shape {
    var points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if let first = points.first {
            path.move(to: first)
            for point in points.dropFirst() { path.addLine(to: point) }
            path.closeSubpath()
        }
        return path
    }
}

/// A single tan drawn in its own local, centered frame. Orientation, reflection, and position
/// are applied by view modifiers (so they animate); the path itself is the static base shape.
private struct PieceShape: Shape {
    /// Base unit polygon, centered on the centroid (board units, screen-oriented y-down).
    var base: [CGPoint]
    /// Points per board unit × render scale.
    var pointScale: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let points = base.map { v in
            CGPoint(x: center.x + v.x * pointScale,
                    y: center.y + v.y * pointScale)
        }
        if let first = points.first {
            path.move(to: first)
            for point in points.dropFirst() { path.addLine(to: point) }
            path.closeSubpath()
        }
        return path
    }
}

struct GameBoardView: View {
    @State private var model: TangramGame
    @State private var popID: Int?
    @State private var hintedSlotID: Int?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ProgressStore.self) private var progress
    private var debugSolved = false

    init(puzzle: Puzzle) {
        _model = State(initialValue: TangramGame(puzzle: puzzle))
    }

    init(puzzle: Puzzle, debugSolved: Bool) {
        _model = State(initialValue: TangramGame(puzzle: puzzle))
        self.debugSolved = debugSolved
    }

    var body: some View {
        VStack(spacing: 0) {
            board
            controls
        }
        .navigationTitle(model.puzzle.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button("Show a spot", systemImage: "eye") { showSpot() }
                    Button("Place a piece", systemImage: "wand.and.stars") { placeHint() }
                } label: {
                    Image(systemName: "lightbulb")
                }
                .accessibilityLabel("Hint")
                .accessibilityIdentifier("hintMenu")
                .disabled(model.isSolved)

                Button("Reset", systemImage: "arrow.counterclockwise") {
                    withOptionalAnimation(.snappy) { model.reset() }
                }
            }
        }
    }

    private var board: some View {
        GeometryReader { geo in
            let map = BoardMap(board: model.boardRect, size: geo.size)
            let pointScale = model.pointsPerBoardUnit * map.scale

            ZStack {
                trayBackground(map: map)
                silhouette(map: map)
                hintHighlight(map: map)
                ForEach(model.pieces) { piece in
                    pieceView(piece, map: map, pointScale: pointScale)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .onTapGesture { model.selectedID = nil }
        }
        .background(.background)
        .onAppear { if debugSolved { model.placeAllAtSolution() } }
        .onChange(of: model.isSolved) { _, solved in
            if solved { progress.markSolved(model.puzzle.id) }
        }
        .task(id: hintedSlotID) {
            guard hintedSlotID != nil else { return }
            try? await Task.sleep(for: .seconds(2.5))
            withOptionalAnimation(.easeInOut) { hintedSlotID = nil }
        }
        .overlay { if model.isSolved { winOverlay } }
    }

    // MARK: Layers

    private func trayBackground(map: BoardMap) -> some View {
        let board = model.boardRect
        let topLeft = map.toScreen(CGPoint(x: board.minX, y: model.trayTopY))
        let bottomRight = map.toScreen(CGPoint(x: board.maxX, y: board.maxY))
        let rect = CGRect(x: topLeft.x, y: topLeft.y,
                          width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y)
        return RoundedRectangle(cornerRadius: 16)
            .fill(.quaternary.opacity(0.6))
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }

    @ViewBuilder
    private func hintHighlight(map: BoardMap) -> some View {
        if let id = hintedSlotID, let slot = model.slots.first(where: { $0.id == id }) {
            let points = model.slotPolygon(slot).map(map.toScreen)
            let outline = PolyShape(points: points)
            outline
                .fill(Color.accentColor.opacity(0.3))
                .overlay(outline.stroke(Color.accentColor, lineWidth: 3))
                .allowsHitTesting(false)
                .transition(.opacity)
        }
    }

    private func silhouette(map: BoardMap) -> some View {
        Canvas { context, _ in
            for slot in model.slots {
                var path = Path()
                let points = model.slotPolygon(slot).map(map.toScreen)
                if let first = points.first {
                    path.move(to: first)
                    for point in points.dropFirst() { path.addLine(to: point) }
                    path.closeSubpath()
                }
                context.fill(path, with: .color(.secondary.opacity(0.15)))
                context.stroke(path, with: .color(.secondary.opacity(0.4)),
                               style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            }
        }
        .allowsHitTesting(false)
    }

    private func pieceView(_ piece: PlayPiece, map: BoardMap, pointScale: CGFloat) -> some View {
        let selected = model.selectedID == piece.id
        let base = TangramGame.baseUnitPolygon(piece.kind)
        let radius = (base.map { hypot($0.x, $0.y) }.max() ?? 2) * pointScale
        let side = radius * 2 + 8
        let shape = PieceShape(base: base, pointScale: pointScale)

        return shape
            .fill(piece.kind.color.opacity(piece.locked ? 1 : 0.9))
            .overlay(shape.stroke(selected ? Color.primary : Color.black.opacity(0.35),
                                  lineWidth: selected ? 3 : 1))
            .contentShape(shape)
            .frame(width: side, height: side)
            .scaleEffect(x: piece.reflected ? -1 : 1, y: 1)          // reflect (inside rotation)
            .rotationEffect(.degrees(piece.angleDegrees))            // y-down board: apply angle directly
            .scaleEffect(popID == piece.id ? 1.14 : 1)               // lock pop, around centroid
            .position(map.toScreen(piece.centroid))
            .zIndex(selected ? 2 : (piece.locked ? 0 : 1))
            .allowsHitTesting(!piece.locked && !model.isSolved)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        model.drag(piece.id, screenTranslation: value.translation, scale: map.scale)
                    }
                    .onEnded { _ in
                        let snapped = withAnimation(.bouncy) { model.endDrag(piece.id) }
                        if snapped { pop(piece.id) }
                    }
            )
            .accessibilityLabel("\(piece.kind.accessibilityName) piece")
            .accessibilityValue(piece.locked ? "Placed" : "Unplaced")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Select") {
                guard !piece.locked, !model.isSolved else { return }
                model.selectedID = piece.id
            }
    }

    private var controls: some View {
        HStack(spacing: 20) {
            Button("Rotate left", systemImage: "rotate.left") { rotate(-45) }
            Button("Rotate right", systemImage: "rotate.right") { rotate(45) }
            Button("Flip", systemImage: "trapezoid.and.line.vertical") { flip() }
        }
        .font(.title)
        .buttonStyle(.bordered)
        .disabled(model.selectedPiece == nil)
        .padding()
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    // MARK: Effects

    private func rotate(_ delta: Double) {
        let id = model.selectedID
        let snapped = withOptionalAnimation(.bouncy) { model.rotateSelected(byDegrees: delta) }
        if snapped, let id { pop(id) }
    }

    private func flip() {
        let id = model.selectedID
        let snapped = withOptionalAnimation(.bouncy) { model.flipSelected() }
        if snapped, let id { pop(id) }
    }

    private func placeHint() {
        let id = withOptionalAnimation(.bouncy) { model.placeHint() }
        if let id { pop(id) }
    }

    private func showSpot() {
        guard let id = model.unfilledSlotIDs.first else { return }
        withOptionalAnimation(.easeInOut) { hintedSlotID = id }
    }

    private func pop(_ id: Int) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        #endif
        withOptionalAnimation(.bouncy(duration: 0.25)) { popID = id }
        withOptionalAnimation(.easeOut(duration: 0.2).delay(0.22)) { popID = nil }
    }

    private func withOptionalAnimation<Result>(_ animation: Animation, _ body: () throws -> Result) rethrows -> Result {
        try withAnimation(reduceMotion ? nil : animation, body)
    }

    private var winOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64)).foregroundStyle(.green)
            Text("Solved!").font(.largeTitle.bold())
            HStack {
                Button("Play again") { withOptionalAnimation(.snappy) { model.reset() } }
                    .buttonStyle(.bordered)
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .background(.regularMaterial, in: .rect(cornerRadius: 24))
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview("Playable") {
    NavigationStack {
        if let puzzle = try? PuzzleLoader.loadAll().first(where: { $0.id == 25 }) {
            GameBoardView(puzzle: puzzle)
        } else {
            Text("Failed to load puzzle data")
        }
    }
    .environment(ProgressStore())
}

#Preview("Solved-placement check") {
    NavigationStack {
        if let puzzle = try? PuzzleLoader.loadAll().first(where: { $0.id == 25 }) {
            GameBoardView(puzzle: puzzle, debugSolved: true)
        } else {
            Text("Failed to load puzzle data")
        }
    }
    .environment(ProgressStore())
}
