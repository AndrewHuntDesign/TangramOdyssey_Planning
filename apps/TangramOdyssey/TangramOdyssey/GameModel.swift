//
//  GameModel.swift
//  TangramOdyssey
//
//  Interactive gameplay: the player drags, rotates, and flips the seven tans from a tray onto a
//  puzzle's target silhouette. State and all geometry/matching logic live here; rendering is in
//  GameBoardView.swift.
//
//  Coordinate space: everything is in the dataset's board space (y-up). `boardRect` frames both
//  the centered silhouette (top) and the tray of loose pieces (bottom). The view maps board →
//  screen (flipping y) uniformly.
//

import SwiftUI
import Observation

/// A target pose the player is trying to fill (one per solution piece).
struct Slot: Identifiable {
    let id: Int          // solution piece id (1...7), unique within a puzzle
    let kind: PieceKind
    let centroid: CGPoint
    let angleDegrees: Double
    let reflected: Bool
}

/// A player-controlled tan.
struct PlayPiece: Identifiable {
    let id: Int
    let kind: PieceKind
    var centroid: CGPoint
    var angleDegrees: Double
    var reflected: Bool
    var locked: Bool = false
    var home: CGPoint    // resting spot in the tray (recomputed when the view size changes)
    var homeAngleDegrees: Double
    var homeReflected: Bool
}

@MainActor
@Observable
final class TangramGame {
    private struct TrayHome {
        let centroid: CGPoint
        let angleDegrees: Double
        let reflected: Bool
    }

    private struct TrayLayout {
        let homes: [Int: TrayHome]
        let bounds: CGRect
    }

    let puzzle: Puzzle
    private(set) var slots: [Slot]
    var pieces: [PlayPiece]
    var selectedID: Int?
    private(set) var isSolved = false

    /// Board coordinate space (dataset y-up) framing the silhouette and tray. Recomputed from the
    /// view size (see `relayout(for:)`) so the silhouette centers vertically above the pinned tray.
    private(set) var boardRect: CGRect
    /// Pieces dropped below this board-space y snap back to the tray.
    private(set) var trayTopY: CGFloat
    /// Top of the tray pieces' resting strip (board space) — used to frame the tray background so
    /// it hugs the pieces rather than the whole gap below the silhouette.
    private(set) var trayRegionTopY: CGFloat

    // Inputs retained so the vertical layout can be recomputed for the actual view size.
    private let figureBox: CGRect          // silhouette bounding box (board space)
    private let figureCenterX: CGFloat
    private let metric: CGFloat            // max(figure width, height) — the layout's base unit
    private let trayHomeOffsets: [Int: TrayHome]  // per-piece offsets relative to the tray center
    private let trayBounds: CGRect         // assembled tray strip bounds (for width/height)

    private let unit: CGFloat
    private var occupied: Set<Int> = []          // indices into `slots` already filled
    private var dragStart: [Int: CGPoint] = [:]  // piece id -> centroid at drag start

    /// How forgiving snapping is, in board units (points at scale 1).
    private let positionTolerance: CGFloat = 30
    private let vertexTolerance: CGFloat = 32

    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        self.unit = TangramGeometry.pointsPerUnit * CGFloat(puzzle.scale)

        let box = puzzle.boundingBox
        let m = max(box.width, box.height)
        let cx = box.midX

        // Slots come straight from the solution.
        let builtSlots: [Slot] = puzzle.pieces.compactMap { piece in
            guard let kind = piece.kind else { return nil }
            return Slot(id: piece.id,
                        kind: kind,
                        centroid: piece.center,
                        angleDegrees: piece.rotationDegrees + Self.baselineOffset(pieceID: piece.id),
                        reflected: piece.isReflected)
        }
        self.slots = builtSlots

        // Tray home poses use the flat, horizontal composition from "Symmetric 079",
        // scaled as one assembled strip so the pieces sit edge-to-edge like the reference tray.
        let trayRenderScale = Self.trayPieceRenderScale
        let trayLayout = Self.symmetricTrayLayout(scale: trayRenderScale * CGFloat(puzzle.scale))

        self.figureBox = box
        self.figureCenterX = cx
        self.metric = m
        self.trayHomeOffsets = trayLayout.homes
        self.trayBounds = trayLayout.bounds

        // Placeholders; the real layout is set by applyLayout below and again by relayout(for:)
        // once the view's size is known.
        self.boardRect = .zero
        self.trayTopY = 0
        self.trayRegionTopY = 0
        self.pieces = builtSlots.enumerated().map { index, slot in
            PlayPiece(id: index, kind: slot.kind, centroid: .zero, angleDegrees: 0, reflected: false,
                      home: .zero, homeAngleDegrees: 0, homeReflected: false)
        }

        // Seed with a reasonable gap; relayout(for:) recomputes it for the actual view size.
        applyLayout(trayGap: m * 0.5)
    }

    // MARK: Layout

    /// Recomputes the vertical layout for a given view size so the silhouette is centered in the
    /// space above a tray pinned to the bottom. Keeps a single uniform board→screen transform
    /// (the view bottom-anchors the board), so drag and snapping are unaffected.
    func relayout(for size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let horizontalMargin = Self.horizontalMargin(metric: metric, trayWidth: trayBounds.width, boxWidth: figureBox.width)
        let boardWidth = figureBox.width + 2 * horizontalMargin
        let scale = size.width / boardWidth
        guard scale > 0 else { return }
        // Gap that makes the space above the figure equal the gap between the figure and the tray
        // (derivation: size.height/scale = 2·gap + figureHeight + trayHeight).
        let idealGap = (size.height / scale - figureBox.height - trayBounds.height) / 2
        applyLayout(trayGap: max(metric * 0.1, idealGap))
    }

    private static func horizontalMargin(metric m: CGFloat, trayWidth: CGFloat, boxWidth: CGFloat) -> CGFloat {
        // Full-scale tray drives board width; keep only a thin margin so the silhouette fills
        // as much of the remaining width as possible.
        max(m * 0.04, (trayWidth - boxWidth) / 2 + m * 0.02)
    }

    private func applyLayout(trayGap: CGFloat) {
        let m = metric
        let box = figureBox
        let cx = figureCenterX
        let trayHeight = trayBounds.height
        let pieceHalf = trayHeight / 2
        let horizontalMargin = Self.horizontalMargin(metric: m, trayWidth: trayBounds.width, boxWidth: box.width)
        let verticalMargin = m * 0.03
        let trayTopInset = m * 0.04
        let trayBottomPadding = m * 0.02
        let trayCenterY = box.maxY + trayGap + trayHeight / 2

        trayTopY = box.maxY + trayTopInset
        trayRegionTopY = trayCenterY - pieceHalf - trayBottomPadding
        boardRect = CGRect(x: box.minX - horizontalMargin,
                           y: box.minY - verticalMargin,
                           width: box.width + 2 * horizontalMargin,
                           height: (trayCenterY + pieceHalf + trayBottomPadding) - (box.minY - verticalMargin))

        for index in pieces.indices {
            let slotID = slots[index].id
            let offset = trayHomeOffsets[slotID]
            let home = CGPoint(x: cx + (offset?.centroid.x ?? 0), y: trayCenterY + (offset?.centroid.y ?? 0))
            pieces[index].home = home
            pieces[index].homeAngleDegrees = offset?.angleDegrees ?? 0
            pieces[index].homeReflected = offset?.reflected ?? false
            // Keep unplaced pieces resting at their (possibly moved) home; leave locked pieces put.
            if !pieces[index].locked {
                pieces[index].centroid = home
                pieces[index].angleDegrees = pieces[index].homeAngleDegrees
                pieces[index].reflected = pieces[index].homeReflected
            }
        }
    }

    static let trayPieceRenderScale: CGFloat = 1.0

    private static func symmetricTrayLayout(scale: CGFloat) -> TrayLayout {
        let template: [(id: Int, centroid: CGPoint, rotation: Int, reflected: Bool)] = [
            (1, CGPoint(x: 98.8, y: 288.81), 9, false),
            (2, CGPoint(x: 499.49, y: 288.81), 9, false),
            (3, CGPoint(x: 428.78, y: 288.81), 9, false),
            (4, CGPoint(x: 263.79, y: 288.81), 9, false),
            (5, CGPoint(x: 310.93, y: 312.38), 15, false),
            (6, CGPoint(x: 369.85, y: 300.59), 21, false),
            (7, CGPoint(x: 193.08, y: 300.59), 3, true)
        ]

        let unit = TangramGeometry.pointsPerUnit
        let polygons = template.compactMap { piece -> [CGPoint]? in
            guard let kind = PieceKind(pieceID: piece.id) else { return nil }
            return placedPolygon(base: baseUnitPolygon(kind),
                                 centroid: piece.centroid,
                                 angleDegrees: Double(piece.rotation) * 15 + baselineOffset(pieceID: piece.id),
                                 reflected: piece.reflected,
                                 unit: unit)
        }
        let sourceBounds = boundingBox(for: polygons.flatMap { $0 })
        let sourceCenter = CGPoint(x: sourceBounds.midX, y: sourceBounds.midY)

        var homes: [Int: TrayHome] = [:]
        for piece in template {
            let angle = Double(piece.rotation) * 15 + baselineOffset(pieceID: piece.id)
            homes[piece.id] = TrayHome(centroid: CGPoint(x: (piece.centroid.x - sourceCenter.x) * scale,
                                                         y: (piece.centroid.y - sourceCenter.y) * scale),
                                       angleDegrees: angle,
                                       reflected: piece.reflected)
        }

        return TrayLayout(homes: homes,
                          bounds: CGRect(x: -sourceBounds.width * scale / 2,
                                         y: -sourceBounds.height * scale / 2,
                                         width: sourceBounds.width * scale,
                                         height: sourceBounds.height * scale))
    }

    private static func placedPolygon(base: [CGPoint],
                                      centroid: CGPoint,
                                      angleDegrees: Double,
                                      reflected: Bool,
                                      unit: CGFloat) -> [CGPoint] {
        let theta = angleDegrees * .pi / 180
        let cosT = CoreGraphics.cos(theta), sinT = CoreGraphics.sin(theta)
        return base.map { v in
            let x = reflected ? -v.x : v.x
            let y = v.y
            let rx = x * cosT - y * sinT
            let ry = x * sinT + y * cosT
            return CGPoint(x: centroid.x + rx * unit, y: centroid.y + ry * unit)
        }
    }

    private static func boundingBox(for points: [CGPoint]) -> CGRect {
        guard let first = points.first else { return .zero }
        var minX = first.x, minY = first.y, maxX = first.x, maxY = first.y
        for point in points {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // MARK: Geometry

    /// The kind's canonical unit polygon, centered on its centroid. Same-kind pieces share one
    /// base so they are interchangeable; per-id baseline differences are folded into slot angles.
    static func baseUnitPolygon(_ kind: PieceKind) -> [CGPoint] {
        let representativeID: Int
        switch kind {
        case .largeTriangle:  representativeID = 1
        case .mediumTriangle: representativeID = 4
        case .smallTriangle:  representativeID = 3
        case .square:         representativeID = 6
        case .parallelogram:  representativeID = 7
        }
        return TangramGeometry.unitPolygon(pieceID: representativeID)
    }

    /// Extra rotation (degrees) mapping the kind's base orientation to a given piece id's
    /// baseline. Only the non-representative same-kind ids differ (derived from id 1785).
    static func baselineOffset(pieceID: Int) -> Double {
        switch pieceID {
        case 2: return -90  // second large triangle
        case 5: return 90   // second small triangle
        default: return 0
        }
    }

    var pointsPerBoardUnit: CGFloat { unit }

    private func placedPolygon(base: [CGPoint], centroid: CGPoint, angleDegrees: Double, reflected: Bool) -> [CGPoint] {
        let theta = angleDegrees * .pi / 180
        let cosT = CoreGraphics.cos(theta), sinT = CoreGraphics.sin(theta)
        return base.map { v in
            let x = reflected ? -v.x : v.x
            let y = v.y
            let rx = x * cosT - y * sinT
            let ry = x * sinT + y * cosT
            return CGPoint(x: centroid.x + rx * unit, y: centroid.y + ry * unit)
        }
    }

    func slotPolygon(_ slot: Slot) -> [CGPoint] {
        placedPolygon(base: Self.baseUnitPolygon(slot.kind), centroid: slot.centroid,
                      angleDegrees: slot.angleDegrees, reflected: slot.reflected)
    }

    func piecePolygon(_ piece: PlayPiece) -> [CGPoint] {
        placedPolygon(base: Self.baseUnitPolygon(piece.kind), centroid: piece.centroid,
                      angleDegrees: piece.angleDegrees, reflected: piece.reflected)
    }

    // MARK: Interaction

    func drag(_ id: Int, screenTranslation: CGSize, scale: CGFloat) {
        guard let index = pieces.firstIndex(where: { $0.id == id }), !pieces[index].locked else { return }
        if dragStart[id] == nil {
            dragStart[id] = pieces[index].centroid
            selectedID = id
        }
        let start = dragStart[id]!
        pieces[index].centroid = CGPoint(x: start.x + screenTranslation.width / scale,
                                         y: start.y + screenTranslation.height / scale) // board y is screen-down
    }

    /// Returns `true` if the piece snapped into a slot (so the view can play a lock effect).
    @discardableResult
    func endDrag(_ id: Int) -> Bool {
        dragStart[id] = nil
        if trySnap(id) { return true }
        // Dropped over the tray region (below the silhouette, i.e. larger y) → send it home.
        if let index = pieces.firstIndex(where: { $0.id == id }), pieces[index].centroid.y > trayTopY {
            sendHome(index)
        }
        return false
    }

    @discardableResult
    func rotateSelected(byDegrees delta: Double) -> Bool {
        guard let id = selectedID, let index = pieces.firstIndex(where: { $0.id == id }), !pieces[index].locked else { return false }
        pieces[index].angleDegrees += delta
        return trySnap(id)
    }

    /// Sets a piece's absolute angle; wheel drags defer snapping until the gesture ends.
    @discardableResult
    func rotatePiece(_ id: Int, toDegrees angle: Double, shouldSnap: Bool = true) -> Bool {
        guard let index = pieces.firstIndex(where: { $0.id == id }), !pieces[index].locked else { return false }
        selectedID = id
        pieces[index].angleDegrees = angle
        return shouldSnap ? trySnap(id) : false
    }

    @discardableResult
    func flipSelected() -> Bool {
        guard let id = selectedID, let index = pieces.firstIndex(where: { $0.id == id }), !pieces[index].locked else { return false }
        pieces[index].reflected.toggle()
        return trySnap(id)
    }

    var selectedPiece: PlayPiece? { selectedID.flatMap { id in pieces.first { $0.id == id } } }

    func reset() {
        occupied.removeAll()
        isSolved = false
        selectedID = nil
        for index in pieces.indices {
            pieces[index].centroid = pieces[index].home
            pieces[index].angleDegrees = pieces[index].homeAngleDegrees
            pieces[index].reflected = pieces[index].homeReflected
            pieces[index].locked = false
        }
    }

    private func sendHome(_ index: Int) {
        pieces[index].centroid = pieces[index].home
        pieces[index].angleDegrees = pieces[index].homeAngleDegrees
        pieces[index].reflected = pieces[index].homeReflected
        if selectedID == pieces[index].id { selectedID = nil }
    }

    // MARK: Snapping

    @discardableResult
    private func trySnap(_ id: Int) -> Bool {
        guard let index = pieces.firstIndex(where: { $0.id == id }), !pieces[index].locked else { return false }
        let poly = piecePolygon(pieces[index])
        for (slotIndex, slot) in slots.enumerated() where !occupied.contains(slotIndex) {
            if polygonsMatch(poly, slotPolygon(slot)) {
                pieces[index].centroid = slot.centroid
                pieces[index].angleDegrees = slot.angleDegrees
                pieces[index].reflected = slot.reflected
                pieces[index].locked = true
                occupied.insert(slotIndex)
                if selectedID == id { selectedID = nil }
                isSolved = pieces.allSatisfy(\.locked)
                return true
            }
        }
        return false
    }

    /// Two congruent convex polygons match if their centroids and vertex sets nearly coincide.
    /// This handles piece symmetry (a square looks the same every 90°) and lets same-kind pieces
    /// fill any same-kind slot, without tracking orientation explicitly.
    private func polygonsMatch(_ a: [CGPoint], _ b: [CGPoint]) -> Bool {
        guard a.count == b.count else { return false }
        let ca = centroid(a), cb = centroid(b)
        if hypot(ca.x - cb.x, ca.y - cb.y) > positionTolerance { return false }
        for vb in b {
            if !a.contains(where: { hypot($0.x - vb.x, $0.y - vb.y) <= vertexTolerance }) { return false }
        }
        return true
    }

    private func centroid(_ polygon: [CGPoint]) -> CGPoint {
        guard !polygon.isEmpty else { return .zero }
        let sum = polygon.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(polygon.count), y: sum.y / CGFloat(polygon.count))
    }

    /// Slot ids that no piece occupies yet — candidates for a hint.
    var unfilledSlotIDs: [Int] {
        slots.enumerated().filter { !occupied.contains($0.offset) }.map { $0.element.id }
    }

    /// Hint: place one unplaced piece at a matching unfilled slot and lock it.
    /// Returns the placed piece's id (for a lock effect), or `nil` if the puzzle is complete.
    @discardableResult
    func placeHint() -> Int? {
        for (slotIndex, slot) in slots.enumerated() where !occupied.contains(slotIndex) {
            guard let index = pieces.firstIndex(where: { !$0.locked && $0.kind == slot.kind }) else { continue }
            pieces[index].centroid = slot.centroid
            pieces[index].angleDegrees = slot.angleDegrees
            pieces[index].reflected = slot.reflected
            pieces[index].locked = true
            occupied.insert(slotIndex)
            if selectedID == pieces[index].id { selectedID = nil }
            isSolved = pieces.allSatisfy(\.locked)
            return pieces[index].id
        }
        return nil
    }

    /// Places every piece at a matching slot pose and locks it.
    func placeAllAtSolution(markSolved: Bool = true) {
        occupied.removeAll()
        selectedID = nil
        for index in pieces.indices { pieces[index].locked = false }
        for (slotIndex, slot) in slots.enumerated() {
            if let index = pieces.firstIndex(where: { !$0.locked && $0.kind == slot.kind }) {
                pieces[index].centroid = slot.centroid
                pieces[index].angleDegrees = slot.angleDegrees
                pieces[index].reflected = slot.reflected
                pieces[index].locked = true
                occupied.insert(slotIndex)
            }
        }
        isSolved = markSolved && pieces.allSatisfy(\.locked)
    }
}
