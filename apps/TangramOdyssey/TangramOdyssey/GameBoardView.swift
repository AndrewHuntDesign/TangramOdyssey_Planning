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
    private var originY: CGFloat { size.height - board.height * scale }

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
    @State private var showsPieceLines = false // Starts with a clean silhouette; menu can reveal guides.
    @State private var restoredSolvedProgress = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ProgressStore.self) private var progress
    private var debugSolved = false
    private var onDone: (() -> Void)?

    init(puzzle: Puzzle, onDone: (() -> Void)? = nil) {
        _model = State(initialValue: TangramGame(puzzle: puzzle))
        self.onDone = onDone
    }

    init(puzzle: Puzzle, debugSolved: Bool) {
        _model = State(initialValue: TangramGame(puzzle: puzzle))
        self.debugSolved = debugSolved
    }

    var body: some View {
        board
        .navigationTitle(model.puzzle.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button("Show a spot", systemImage: "eye") { showSpot() }
                    Button("Place a piece", systemImage: "wand.and.stars") { placeHint() }
                    Divider()
                    Toggle("Piece lines", systemImage: "square.grid.3x3", isOn: $showsPieceLines)
                } label: {
                    Image(systemName: "lightbulb")
                }
                .accessibilityLabel("Hint")
                .accessibilityIdentifier("hintMenu")
                .disabled(model.isSolved || restoredSolvedProgress)

                Button("Reset", systemImage: "arrow.counterclockwise") {
                    resetPuzzle()
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
                silhouette(map: map, showsPieceLines: showsPieceLines)
                hintHighlight(map: map)
                ForEach(model.pieces) { piece in
                    pieceView(piece, map: map, pointScale: pointScale)
                }
                rotationWheel(map: map, pointScale: pointScale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .onTapGesture { model.selectedID = nil }
            .onChange(of: geo.size, initial: true) { _, size in
                model.relayout(for: size)
            }
        }
        .background(.background)
        .onAppear { restoreSolvedProgressIfNeeded() }
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
        let topLeft = map.toScreen(CGPoint(x: board.minX, y: model.trayRegionTopY))
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

    private func silhouette(map: BoardMap, showsPieceLines: Bool) -> some View {
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
                if showsPieceLines {
                    context.stroke(path, with: .color(.secondary.opacity(0.4)),
                                   style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func pieceView(_ piece: PlayPiece, map: BoardMap, pointScale: CGFloat) -> some View {
        let selected = model.selectedID == piece.id
        let base = TangramGame.baseUnitPolygon(piece.kind)
        let renderScale = pieceRenderScale(piece)
        let radius = (base.map { hypot($0.x, $0.y) }.max() ?? 2) * pointScale * renderScale
        let side = radius * 2 + 8
        let shape = PieceShape(base: base, pointScale: pointScale * renderScale)

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
                        let snapped = withOptionalAnimation(.bouncy) { model.endDrag(piece.id) }
                        if snapped { pop(piece.id) }
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        // Double-tap flips only the active piece; first tap still selects/moves.
                        guard model.selectedID == piece.id else { return }
                        flipSelectedPiece(piece.id)
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

    @ViewBuilder
    private func rotationWheel(map: BoardMap, pointScale: CGFloat) -> some View {
        if let piece = model.selectedPiece, !piece.locked, !model.isSolved {
            let radius = pieceRadius(piece, pointScale: pointScale, renderScale: pieceRenderScale(piece))
            let wheelRadius = max(radius + 22, 42)
            let handleSize: CGFloat = 26
            let diameter = (wheelRadius + handleSize) * 2

            RotationWheelView(angleDegrees: piece.angleDegrees,
                              wheelRadius: wheelRadius,
                              handleSize: handleSize) { angle, isFinished in
                let snapped = model.rotatePiece(piece.id, toDegrees: angle, shouldSnap: isFinished)
                if snapped { pop(piece.id) }
            }
            .frame(width: diameter, height: diameter)
            .position(map.toScreen(piece.centroid))
            .zIndex(3)
            .transition(.opacity)
        }
    }

    private func pieceRenderScale(_ piece: PlayPiece) -> CGFloat {
        // Tray pieces render smaller so the enlarged silhouette remains the visual focus.
        piece.locked || piece.centroid.y <= model.trayTopY ? 1 : TangramGame.trayPieceRenderScale
    }

    private func pieceRadius(_ piece: PlayPiece, pointScale: CGFloat, renderScale: CGFloat) -> CGFloat {
        let baseRadius = TangramGame.baseUnitPolygon(piece.kind)
            .map { hypot($0.x, $0.y) }
            .max() ?? 2
        return baseRadius * pointScale * renderScale
    }

    // MARK: Effects

    private func placeHint() {
        let id = withOptionalAnimation(.bouncy) { model.placeHint() }
        if let id { pop(id) }
    }

    private func showSpot() {
        guard let id = model.unfilledSlotIDs.first else { return }
        withOptionalAnimation(.easeInOut) { hintedSlotID = id }
    }

    private func flipSelectedPiece(_ id: Int) {
        let snapped = withOptionalAnimation(.bouncy) { model.flipSelected() }
        if snapped { pop(id) }
    }

    private func resetPuzzle() {
        restoredSolvedProgress = false
        withOptionalAnimation(.snappy) { model.reset() }
    }

    private func restoreSolvedProgressIfNeeded() {
        if debugSolved {
            model.placeAllAtSolution()
        } else if progress.isSolved(model.puzzle.id), !restoredSolvedProgress, !model.isSolved {
            model.placeAllAtSolution(markSolved: false)
            restoredSolvedProgress = true
        }
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
                Button("Done") { finishPuzzle() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .background(.regularMaterial, in: .rect(cornerRadius: 24))
        .transition(.scale.combined(with: .opacity))
    }

    private func finishPuzzle() {
        if let onDone {
            onDone()
        } else {
            dismiss()
        }
    }
}

private struct RotationWheelView: View {
    let angleDegrees: Double
    let wheelRadius: CGFloat
    let handleSize: CGFloat
    let onRotate: (Double, Bool) -> Void

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let handleCenter = handleCenter(center: center)

            ZStack {
                Circle()
                    .stroke(.primary.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [7, 6]))
                    .frame(width: wheelRadius * 2, height: wheelRadius * 2)
                    .position(center)

                Circle()
                    .fill(.background)
                    .frame(width: handleSize, height: handleSize)
                    .overlay {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .overlay(Circle().stroke(.primary.opacity(0.5), lineWidth: 1))
                    .shadow(radius: 2)
                    .position(handleCenter)
            }
            .contentShape(RotationWheelHitShape(innerRadius: wheelRadius - handleSize,
                                                outerRadius: wheelRadius + handleSize),
                          eoFill: true)
            .highPriorityGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        // A click on the wheel ring should rotate immediately without a drag.
                        onRotate(angle(from: value.location, center: center), true)
                    }
            )
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        onRotate(angle(from: value.location, center: center), false)
                    }
                    .onEnded { value in
                        onRotate(angle(from: value.location, center: center), true)
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rotation wheel")
            .accessibilityValue("\(Int(angleDegrees.rounded())) degrees")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    onRotate(angleDegrees + 5, true)
                case .decrement:
                    onRotate(angleDegrees - 5, true)
                @unknown default:
                    break
                }
            }
        }
    }

    private func handleCenter(center: CGPoint) -> CGPoint {
        let radians = angleDegrees * .pi / 180
        return CGPoint(x: center.x + cos(radians) * wheelRadius,
                       y: center.y + sin(radians) * wheelRadius)
    }

    private func angle(from location: CGPoint, center: CGPoint) -> Double {
        atan2(location.y - center.y, location.x - center.x) * 180 / .pi
    }
}

private struct RotationWheelHitShape: Shape {
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        // The even-odd ring leaves the piece center open so center drags keep moving the tan.
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addEllipse(in: CGRect(x: center.x - outerRadius,
                                   y: center.y - outerRadius,
                                   width: outerRadius * 2,
                                   height: outerRadius * 2))
        path.addEllipse(in: CGRect(x: center.x - innerRadius,
                                   y: center.y - innerRadius,
                                   width: innerRadius * 2,
                                   height: innerRadius * 2))
        return path
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
