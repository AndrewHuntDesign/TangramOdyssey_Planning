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
    let home: CGPoint    // resting spot in the tray
}

@MainActor
@Observable
final class TangramGame {
    let puzzle: Puzzle
    private(set) var slots: [Slot]
    var pieces: [PlayPiece]
    var selectedID: Int?
    private(set) var isSolved = false

    /// Board coordinate space (dataset y-up) framing the silhouette and tray.
    let boardRect: CGRect
    /// Pieces dropped below this board-space y snap back to the tray.
    let trayTopY: CGFloat

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

        // Tray home positions use the flat, horizontal composition from "Symmetric 079",
        // scaled into a compact bottom tray while leaving enough inset for reduced-size pieces.
        let trayGap = m * 0.17
        let trayWidth = m * 1.02
        let trayHeight = m * 0.18
        let pieceHalf = m * 0.18
        let horizontalMargin = m * 0.22
        let verticalMargin = m * 0.05
        let trayTopInset = m * 0.08
        let trayBottomPadding = m * 0.02
        let trayCenterY = box.maxY + trayGap + trayHeight / 2
        let homes = Self.symmetricTrayHomes(centerX: cx, centerY: trayCenterY, width: trayWidth, height: trayHeight)

        self.trayTopY = box.maxY + trayTopInset
        self.boardRect = CGRect(x: box.minX - horizontalMargin,
                                y: box.minY - verticalMargin,
                                width: box.width + 2 * horizontalMargin,
                                height: (trayCenterY + pieceHalf + trayBottomPadding) - (box.minY - verticalMargin))

        self.pieces = builtSlots.enumerated().map { index, slot in
            let home = homes[index]
            return PlayPiece(id: index, kind: slot.kind, centroid: home,
                             angleDegrees: 0, reflected: false, home: home)
        }
    }

    private static func symmetricTrayHomes(centerX: CGFloat, centerY: CGFloat, width: CGFloat, height: CGFloat) -> [CGPoint] {
        let template: [CGPoint] = [
            CGPoint(x: 98.8, y: 288.81),
            CGPoint(x: 499.49, y: 288.81),
            CGPoint(x: 428.78, y: 288.81),
            CGPoint(x: 263.79, y: 288.81),
            CGPoint(x: 310.93, y: 312.38),
            CGPoint(x: 369.85, y: 300.59),
            CGPoint(x: 193.08, y: 300.59)
        ]

        let minX = template.map(\.x).min() ?? 0
        let maxX = template.map(\.x).max() ?? 1
        let minY = template.map(\.y).min() ?? 0
        let maxY = template.map(\.y).max() ?? 1
        let midX = (minX + maxX) / 2
        let midY = (minY + maxY) / 2
        let sourceWidth = max(maxX - minX, 1)
        let sourceHeight = max(maxY - minY, 1)

        return template.map { point in
            CGPoint(x: centerX + ((point.x - midX) / sourceWidth) * width,
                    y: centerY + ((point.y - midY) / sourceHeight) * height)
        }
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
            pieces[index].angleDegrees = 0
            pieces[index].reflected = false
            pieces[index].locked = false
        }
    }

    private func sendHome(_ index: Int) {
        pieces[index].centroid = pieces[index].home
        pieces[index].angleDegrees = 0
        pieces[index].reflected = false
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
