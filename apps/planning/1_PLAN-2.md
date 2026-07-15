#Andy
(
I plan to write a successful iOS/macos tangram game. Provide a detailed plan to achieve this goal and include content for the app. Answer like you care about my success and finish with: what else should I know?
)


# Tangram Game – Detailed Success Plan

## What Is the Product?

A polished iOS/macOS tangram puzzle game where players drag, rotate, and flip the 7 classic tans to fill outlined silhouette shapes. The goal is to ship something people **love**, not just something that works.

---

## 1. Define Your Target Audience & Positioning

**Primary audience:** Puzzle lovers aged 8–60, casual gamers, parents/kids playing together, mindfulness seekers.

**Positioning options — pick one:**

- 🧘 **Calm/mindful** — no timers, ambient sound, meditative aesthetic (think Monument Valley)
- 🏆 **Competitive** — leaderboards, timed challenges, daily puzzles
- 📚 **Educational** — geometry concepts for kids, school-friendly

Choosing early prevents scope creep and sharpens your marketing.

---

## 2. Core Game Mechanics

**The 7 Tans:** 2 large triangles, 1 medium triangle, 2 small triangles, 1 square, 1 parallelogram.

**Interactions (must feel *great*):**
- Drag to move pieces
- Tap to rotate (45° snapping with optional free rotate)
- Double-tap or swipe to flip the parallelogram
- Snap-to-grid with satisfying haptic feedback
- Magnetic snap when piece is near correct position

**Winning condition:** All 7 pieces placed inside the silhouette with no overlap.

---

## 3. Content Plan — Puzzle Library

Organize puzzles into themed packs. Here's a full content roadmap:

| Pack | Theme | # of Puzzles | Unlock Method |
|---|---|---|---|
| 🐾 Animals | Cat, dog, rabbit, swan, horse, bird, fish, fox | 20 | Free starter |
| 🏡 Shapes & Objects | House, boat, candle, chair, bridge, rocket | 20 | Complete Animals |
| 👤 People | Running man, dancer, person sitting, yoga poses | 15 | IAP or stars |
| 🏯 Landmarks | Pagoda, pyramid, Eiffel Tower silhouette | 15 | IAP |
| 🌿 Nature | Tree, mountain, leaf, cloud, butterfly | 15 | IAP |
| 🎃 Seasonal | Halloween, Christmas, Lunar New Year themes | 10/season | Limited time |
| ⭐ Daily Challenge | New puzzle every day | 365/year | Free |
| 👑 Classic Masters | Rare/complex traditional Chinese tangrams | 30 | Premium |

**Total launch target:** 75–100 puzzles. Never launch with fewer than 50.

---

## 4. Difficulty System

Each puzzle gets a difficulty rating shown *before* the player starts:

- 🟢 **Easy** — symmetrical, few rotations needed, obvious silhouette
- 🟡 **Medium** — some flipping needed, less obvious shape
- 🔴 **Hard** — abstract silhouette, tricky parallelogram placement
- ⚫ **Expert** — traditional Chinese masterpieces, ambiguous outlines

---

## 5. Progression & Retention Systems

These keep players coming back:

- **Star system:** Earn 1–3 stars per puzzle (completed / completed with no hints / completed under time)
- **Daily puzzle streak** — push notification, streak counter, special reward at 7/30/100 days
- **Puzzle packs** — completing a pack unlocks a bonus "Master" puzzle
- **Hint system** — show one piece's correct position (limited, earned or bought)
- **Gallery mode** — completed puzzles shown as framed art in a museum-style collection
- **Achievement badges** — "Night Owl" (play after midnight), "Speedster" (solve in under 60s), "Purist" (never used a hint)

---

## 6. Monetization Strategy

**Freemium model** (most sustainable for puzzle games):

- **Free:** Animals pack (20), daily puzzle, basic themes
- **One-time "Full Game" IAP** (~$3.99–$5.99): Unlocks all current + future packs — pitch this prominently
- **Individual pack IAPs** (~$0.99–$1.99 each): For players who want à la carte
- **No ads in the core experience** — ads kill puzzle game retention
- **Optional cosmetics** (piece skins, backgrounds, sound packs): $0.99 each

---

## 7. UI/UX Design Principles

- **Silhouette display:** Clean white/cream background, solid dark silhouette, colored pieces
- **Piece tray** at the bottom, pieces slide up into the play area
- **Undo button** — always present, no penalty
- **Color themes:** Unlock new piece color sets (classic wood, pastel, neon, night mode)
- **macOS:** Support trackpad gestures, keyboard shortcuts (R to rotate, F to flip)
- **Accessibility:** Colorblind mode, large piece handles, VoiceOver labels

---

## 8. Technical Stack (Swift/SwiftUI)

```
Platform:     iOS 16+ / macOS 13+ (use SwiftUI + Swift Playgrounds or Xcode)
Game Engine:  SpriteKit (ideal for 2D drag/rotate/physics feel)
              OR pure SwiftUI with gesture recognizers (simpler, less flexible)
Persistence:  SwiftData or CoreData for progress, CloudKit for iCloud sync
IAP:          StoreKit 2 (modern, async/await API)
Haptics:      CoreHaptics for satisfying piece-snap feedback
Analytics:    TelemetryDeck (privacy-first, App Store safe)
```

**Key technical challenge:** Collision detection and overlap checking for irregular polygon shapes. Use `SKPhysicsBody(polygonFrom: path)` in SpriteKit or implement your own CGPath intersection logic.

---

## 9. Sound & Music Design

Sound design is massively underrated in puzzle games:

- **Piece pickup:** soft "lift" sound
- **Piece snap:** satisfying wooden *click* or stone *thud*
- **Puzzle complete:** gentle chime + haptic pulse
- **Background music:** Lo-fi ambient, optional, volume slider always accessible
- **Flip/rotate:** subtle whoosh

Look at: **Zapsplat, Freesound.org, or hire a freelancer on SoundBetter** for custom audio.

---

## 10. Launch Strategy

**Phase 1 – Pre-launch (8–12 weeks before)**
- Build a landing page with email capture
- Post weekly dev logs on Reddit (r/indiegaming, r/swift), Twitter/X, TikTok
- Submit to TestFlight beta — target 200+ testers

**Phase 2 – Launch**
- Submit to App Store with full App Preview video (this is *critical*)
- Target "New Games We Love" — email Apple directly via developer relations
- Launch on a **Tuesday or Wednesday** (App Store editorial refresh days)
- Price competitively — consider free for launch week

**Phase 3 – Post-launch**
- Respond to every App Store review for the first month
- Ship a content update within 4 weeks (new puzzle pack)
- Pitch to puzzle/iOS game blogs: TouchArcade, AppAdvice, 148Apps

---

## 11. ASO (App Store Optimization)

- **Title:** include "Tangram" + a differentiator (e.g., *Tangram Zen – Puzzle Game*)
- **Keywords:** tangram, jigsaw, shape puzzle, brain teaser, geometry game, Chinese puzzle
- **Screenshots:** Show a satisfying mid-solve and a completed puzzle — show the *feeling*, not the UI
- **App Preview video:** 15–30 seconds showing a full solve with sound

---

## 12. Timeline (Solo Developer, Realistic)

| Milestone | Target |
|---|---|
| Prototype (core mechanic working) | Week 4 |
| 50 puzzles + 3 packs content complete | Week 10 |
| Full UI, IAP, progression systems | Week 16 |
| TestFlight beta | Week 18 |
| App Store submission | Week 20 |
| v1.1 with daily challenge + new pack | Week 26 |

---

## What Else Should You Know?

**The mechanic is solved — the *feel* is your moat.** Dozens of tangram apps exist. The ones that succeed do so because rotating and snapping a piece feels *satisfying* in a way that's hard to describe but instantly felt. Invest disproportionate time here — get the haptics, the snap animation, and the solve celebration right before you build anything else.

**Validate before you build everything.** Ship a TestFlight build with 10 puzzles as fast as possible and put it in front of real strangers. You'll learn more in one week than 3 months of solo development.

**The parallelogram will break your heart.** It's the only non-symmetric piece and requires flipping — players consistently get stuck on it. Consider a subtle visual cue (a small flip arrow) that appears after 30 seconds of inactivity.

**iCloud sync is a must, not a nice-to-have.** Players *will* be on both iPhone and iPad. Losing progress is a 1-star review. Build it early.

**Daily puzzles are your retention engine.** If you do nothing else on this list, do a daily puzzle with a streak counter. It's the single highest-ROI feature for long-term DAU.

**Mind the parallelogram winding order in SpriteKit** — CGPath polygon detection can give you ghost collisions if vertices aren't declared consistently clockwise or counterclockwise.

Would you like me to go deeper on any section — the SpriteKit implementation, the puzzle content design, monetization, or the App Store submission process?


#Andy
(
Please go deeper into the Sprite kit implementation
)


Let me read the frontend design skill first to ensure the best output for any visual components.Here's a deep dive into the SpriteKit implementation, including a fully working interactive prototype so you can feel the core mechanic right now.

---

# SpriteKit Tangram — Deep Implementation Guide

## Architecture Overview

```
TangramGame/
├── GameScene.swift          # Main SpriteKit scene, input handling
├── TangramPiece.swift       # SKShapeNode subclass for each tan
├── PuzzleBoard.swift        # Silhouette rendering + placement validation
├── PieceGeometry.swift      # All polygon math, rotation, flip logic
├── CollisionDetector.swift  # Overlap detection between pieces
├── HapticEngine.swift       # CoreHaptics wrapper
├── PuzzleData.swift         # Puzzle definitions (points, solutions)
└── GameViewController.swift # UIViewController bridge
```

---

## 1. Defining the 7 Tans as Polygons

Every piece is defined by its **vertices in local space** (relative to its own center). The unit size is a grid where 1 unit = your base tile size (e.g., 60pt).

```swift
// PieceGeometry.swift
import SpriteKit

enum TanType: CaseIterable {
    case largeTri1, largeTri2
    case mediumTri
    case smallTri1, smallTri2
    case square
    case parallelogram
}

struct TanGeometry {
    // All coordinates relative to piece centroid
    // Unit size = 1.0, scale at runtime
    static func vertices(for type: TanType) -> [CGPoint] {
        switch type {
        case .largeTri1, .largeTri2:
            // Right triangle, legs = 2 units
            return [CGPoint(x: -1, y: -1),
                    CGPoint(x:  1, y: -1),
                    CGPoint(x: -1, y:  1)]

        case .mediumTri:
            // Right triangle, legs = √2 units
            return [CGPoint(x: -0.707, y: -0.707),
                    CGPoint(x:  0.707, y: -0.707),
                    CGPoint(x: -0.707, y:  0.707)]

        case .smallTri1, .smallTri2:
            // Right triangle, legs = 1 unit
            return [CGPoint(x: -0.5, y: -0.5),
                    CGPoint(x:  0.5, y: -0.5),
                    CGPoint(x: -0.5, y:  0.5)]

        case .square:
            // 1×1 square
            return [CGPoint(x: -0.5, y: -0.5),
                    CGPoint(x:  0.5, y: -0.5),
                    CGPoint(x:  0.5, y:  0.5),
                    CGPoint(x: -0.5, y:  0.5)]

        case .parallelogram:
            // The tricky one — offset parallelogram
            return [CGPoint(x: -1.0, y: -0.5),
                    CGPoint(x:  0.0, y: -0.5),
                    CGPoint(x:  1.0, y:  0.5),
                    CGPoint(x:  0.0, y:  0.5)]
        }
    }
}
```

---

## 2. TangramPiece — The SKShapeNode Subclass

```swift
// TangramPiece.swift
import SpriteKit

class TangramPiece: SKShapeNode {

    let tanType: TanType
    let unitSize: CGFloat = 60.0   // Points per unit
    var isFlipped: Bool = false
    var snapRotation: CGFloat = 0  // Snapped angle in radians
    var isSolved: Bool = false

    // The piece's solution transform (set by PuzzleData)
    var solutionPosition: CGPoint = .zero
    var solutionRotation: CGFloat = 0
    var solutionFlipped: Bool = false

    init(type: TanType, color: UIColor) {
        self.tanType = type
        super.init()
        buildShape()
        self.fillColor = color
        self.strokeColor = color.darker(by: 0.2)
        self.lineWidth = 1.5
        self.isUserInteractionEnabled = false // GameScene handles touches
    }

    private func buildShape() {
        let rawVerts = TanGeometry.vertices(for: tanType)
        let scaled = rawVerts.map {
            CGPoint(x: $0.x * unitSize, y: $0.y * unitSize)
        }
        let path = CGMutablePath()
        path.addLines(between: scaled)
        path.closeSubpath()
        self.path = path

        // Physics body for overlap detection
        self.physicsBody = SKPhysicsBody(polygonFrom: path)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.categoryBitMask = 0x1
        self.physicsBody?.contactTestBitMask = 0x1
        self.physicsBody?.collisionBitMask = 0  // No physics collision — we handle it
    }

    // Flip the parallelogram by mirroring X vertices
    func flip() {
        guard tanType == .parallelogram else { return }
        isFlipped.toggle()
        let rawVerts = TanGeometry.vertices(for: tanType)
        let flippedVerts = rawVerts.map {
            CGPoint(x: isFlipped ? -$0.x * unitSize : $0.x * unitSize,
                    y: $0.y * unitSize)
        }
        let path = CGMutablePath()
        path.addLines(between: flippedVerts)
        path.closeSubpath()
        self.path = path
        self.physicsBody = SKPhysicsBody(polygonFrom: path)
        self.physicsBody?.isDynamic = false
    }

    // Snap rotation to nearest 45°
    func snapToNearest45() {
        let degrees = zRotation * 180 / .pi
        let snapped = (degrees / 45).rounded() * 45
        snapRotation = snapped * .pi / 180
        let rotate = SKAction.rotate(toAngle: snapRotation, duration: 0.15, shortestUnitArc: true)
        run(rotate)
    }

    required init?(coder: NSCoder) { fatalError() }
}
```

---

## 3. GameScene — Touch Handling & Drag/Rotate

This is the heart of the interaction. **Get this feeling perfect before anything else.**

```swift
// GameScene.swift
import SpriteKit
import CoreHaptics

class GameScene: SKScene {

    var pieces: [TangramPiece] = []
    var board: PuzzleBoard!
    var haptics: HapticEngine!

    // Touch tracking
    private var activePiece: TangramPiece?
    private var touchOffset: CGPoint = .zero
    private var lastTouchTime: TimeInterval = 0
    private var touchStartPos: CGPoint = .zero

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(hex: "#F5F0E8")  // Warm parchment
        haptics = HapticEngine()
        setupBoard()
        setupPieces()
    }

    // MARK: - Touch Began

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        touchStartPos = loc
        lastTouchTime = touch.timestamp

        // Find topmost piece at touch point
        if let piece = topPiece(at: loc), !piece.isSolved {
            activePiece = piece
            touchOffset = CGPoint(x: piece.position.x - loc.x,
                                  y: piece.position.y - loc.y)
            liftPiece(piece)
        }
    }

    // MARK: - Touch Moved (drag)

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let piece = activePiece else { return }
        let loc = touch.location(in: self)
        piece.position = CGPoint(x: loc.x + touchOffset.x,
                                 y: loc.y + touchOffset.y)
    }

    // MARK: - Touch Ended

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let piece = activePiece else { return }
        let loc = touch.location(in: self)
        let dist = hypot(loc.x - touchStartPos.x, loc.y - touchStartPos.y)
        let duration = touch.timestamp - lastTouchTime

        if dist < 10 && duration < 0.3 {
            // TAP — rotate 45°
            rotatePiece(piece)
        } else if dist < 10 && duration >= 0.3 {
            // LONG PRESS — flip (parallelogram only)
            piece.flip()
            haptics.playFlip()
        } else {
            // DRAG ended — try to snap
            piece.snapToNearest45()
            trySnapToSolution(piece)
        }

        dropPiece(piece)
        activePiece = nil
    }

    // MARK: - Piece Lifecycle

    private func liftPiece(_ piece: TangramPiece) {
        piece.zPosition = 100
        let scale = SKAction.scale(to: 1.08, duration: 0.1)
        let shadow = SKAction.run { piece.shadowStrength = 0.4 }
        piece.run(SKAction.group([scale, shadow]))
        haptics.playLift()
    }

    private func dropPiece(_ piece: TangramPiece) {
        piece.zPosition = piece.isSolved ? 1 : 10
        let scale = SKAction.scale(to: 1.0, duration: 0.1)
        piece.run(scale)
    }

    private func rotatePiece(_ piece: TangramPiece) {
        let newAngle = piece.zRotation + (.pi / 4)  // +45°
        let rotate = SKAction.rotate(toAngle: newAngle, duration: 0.18,
                                     shortestUnitArc: true)
        rotate.timingMode = .easeOut
        piece.run(rotate) {
            piece.snapToNearest45()
        }
        haptics.playRotate()
    }

    // MARK: - Snap to Solution

    private func trySnapToSolution(_ piece: TangramPiece) {
        let snapDistance: CGFloat = 30.0
        let snapAngle: CGFloat = .pi / 8   // 22.5° tolerance

        let dPos = hypot(piece.position.x - piece.solutionPosition.x,
                         piece.position.y - piece.solutionPosition.y)

        var dAngle = abs(piece.zRotation - piece.solutionRotation)
        dAngle = min(dAngle, .pi * 2 - dAngle)  // Wrap around

        let flipMatch = piece.isFlipped == piece.solutionFlipped

        if dPos < snapDistance && dAngle < snapAngle && flipMatch {
            snapPieceToSolution(piece)
        }
    }

    private func snapPieceToSolution(_ piece: TangramPiece) {
        piece.isSolved = true
        let move = SKAction.move(to: piece.solutionPosition, duration: 0.2)
        let rotate = SKAction.rotate(toAngle: piece.solutionRotation,
                                     duration: 0.2, shortestUnitArc: true)
        move.timingMode = .easeOut
        rotate.timingMode = .easeOut

        piece.run(SKAction.group([move, rotate])) { [weak self] in
            piece.zPosition = 1
            self?.haptics.playSnap()
            self?.checkPuzzleComplete()
        }

        // Flash the piece green briefly
        let flash = SKAction.sequence([
            SKAction.colorize(with: .systemGreen, colorBlendFactor: 0.5, duration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.3)
        ])
        piece.run(flash)
    }

    // MARK: - Win Condition

    private func checkPuzzleComplete() {
        if pieces.allSatisfy({ $0.isSolved }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.playWinCelebration()
            }
        }
    }

    private func playWinCelebration() {
        haptics.playWin()
        // Emit particle burst from board center
        if let emitter = SKEmitterNode(fileNamed: "Confetti.sks") {
            emitter.position = board.position
            emitter.zPosition = 200
            addChild(emitter)
            emitter.run(SKAction.sequence([
                SKAction.wait(forDuration: 2.0),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Helpers

    private func topPiece(at point: CGPoint) -> TangramPiece? {
        return nodes(at: point)
            .compactMap { $0 as? TangramPiece }
            .sorted { $0.zPosition > $1.zPosition }
            .first
    }
}
```

---

## 4. Overlap Detection — The Hard Part

SpriteKit's physics won't stop pieces overlapping (you disabled collisions intentionally). You need **CGPath intersection** to detect illegal overlaps:

```swift
// CollisionDetector.swift
import SpriteKit

struct CollisionDetector {

    /// Returns true if two pieces overlap in world space
    static func overlaps(_ a: TangramPiece, _ b: TangramPiece,
                         in scene: SKScene) -> Bool {
        guard a !== b else { return false }

        // Convert each piece's path to scene coordinates
        let pathA = worldPath(for: a, in: scene)
        let pathB = worldPath(for: b, in: scene)

        // Use CGPath intersection via UIBezierPath
        let bezA = UIBezierPath(cgPath: pathA)
        let bezB = UIBezierPath(cgPath: pathB)

        // Quick bounding box check first (cheap)
        guard bezA.bounds.intersects(bezB.bounds) else { return false }

        // Detailed polygon intersection (more expensive)
        return polygonsIntersect(pathA, pathB)
    }

    static func worldPath(for piece: TangramPiece,
                          in scene: SKScene) -> CGPath {
        // Build transform: translate + rotate + flip
        var transform = CGAffineTransform.identity
            .translatedBy(x: piece.position.x, y: piece.position.y)
            .rotated(by: piece.zRotation)
        if piece.isFlipped {
            transform = transform.scaledBy(x: -1, y: 1)
        }
        return piece.path!.copy(using: &transform)!
    }

    /// SAT (Separating Axis Theorem) — accurate polygon intersection
    static func polygonsIntersect(_ pathA: CGPath,
                                  _ pathB: CGPath) -> Bool {
        let vertsA = extractVertices(from: pathA)
        let vertsB = extractVertices(from: pathB)

        // Test all axes from both polygons
        for polygon in [vertsA, vertsB] {
            for i in 0..<polygon.count {
                let edge = CGPoint(
                    x: polygon[(i+1) % polygon.count].x - polygon[i].x,
                    y: polygon[(i+1) % polygon.count].y - polygon[i].y
                )
                // Perpendicular axis
                let axis = CGPoint(x: -edge.y, y: edge.x)

                let projA = project(vertsA, onto: axis)
                let projB = project(vertsB, onto: axis)

                // Gap found — no intersection
                if projA.max < projB.min || projB.max < projA.min {
                    return false
                }
            }
        }
        return true  // No separating axis found — they overlap
    }

    private static func project(_ verts: [CGPoint],
                                 onto axis: CGPoint) -> (min: CGFloat, max: CGFloat) {
        let dots = verts.map { $0.x * axis.x + $0.y * axis.y }
        return (dots.min()!, dots.max()!)
    }

    private static func extractVertices(from path: CGPath) -> [CGPoint] {
        var points: [CGPoint] = []
        path.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint, .addLineToPoint:
                points.append(element.pointee.points[0])
            default: break
            }
        }
        return points
    }
}
```

---

## 5. Haptic Feedback — CoreHaptics

```swift
// HapticEngine.swift
import CoreHaptics

class HapticEngine {
    private var engine: CHHapticEngine?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
    }

    func playSnap() {
        play(intensity: 1.0, sharpness: 0.8, duration: 0.05)
    }

    func playLift() {
        play(intensity: 0.4, sharpness: 0.3, duration: 0.08)
    }

    func playRotate() {
        play(intensity: 0.3, sharpness: 0.6, duration: 0.04)
    }

    func playFlip() {
        // Double pulse for flip
        play(intensity: 0.5, sharpness: 0.5, duration: 0.04)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.play(intensity: 0.5, sharpness: 0.5, duration: 0.04)
        }
    }

    func playWin() {
        // Ascending rumble
        var events: [CHHapticEvent] = []
        for i in 0..<5 {
            let t = Double(i) * 0.08
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity,
                                                   value: Float(0.3 + Double(i) * 0.14))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness,
                                                   value: 0.5)
            events.append(CHHapticEvent(eventType: .hapticTransient,
                                        parameters: [intensity, sharpness],
                                        relativeTime: t))
        }
        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine?.makePlayer(with: pattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    private func play(intensity: Float, sharpness: Float, duration: TimeInterval) {
        let i = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let s = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [i, s],
                                  relativeTime: 0, duration: duration)
        guard let pattern = try? CHHapticPattern(events: [event], parameters: []),
              let player = try? engine?.makePlayer(with: pattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
    }
}
```

---

## 6. Puzzle Data Format

Define puzzles as data, not code. This makes adding 100 puzzles trivial:

```swift
// PuzzleData.swift
struct PieceSolution {
    let type: TanType
    let position: CGPoint     // Relative to board center
    let rotation: CGFloat     // Radians
    let isFlipped: Bool
}

struct PuzzleDefinition {
    let id: String
    let name: String
    let difficulty: Difficulty
    let silhouettePath: [CGPoint]  // Outline of the shape
    let solutions: [PieceSolution]
}

// Example: Cat silhouette
let catPuzzle = PuzzleDefinition(
    id: "animals_cat_01",
    name: "Cat",
    difficulty: .easy,
    silhouettePath: [ /* CGPoints defining the cat outline */ ],
    solutions: [
        PieceSolution(type: .largeTri1,   position: CGPoint(x: -30, y: 20),
                      rotation: .pi/4,    isFlipped: false),
        PieceSolution(type: .largeTri2,   position: CGPoint(x:  30, y: 20),
                      rotation: -.pi/4,   isFlipped: false),
        PieceSolution(type: .mediumTri,   position: CGPoint(x:   0, y: 60),
                      rotation: 0,        isFlipped: false),
        // ... all 7 pieces
    ]
)
```

---

## 7. Piece Tray (Bottom UI)

```swift
// In GameScene.swift — setupPieces()
private func setupPieces() {
    let colors: [UIColor] = [.systemRed, .systemOrange, .systemYellow,
                              .systemGreen, .systemBlue, .systemPurple,
                              .systemPink]
    let trayY: CGFloat = 120
    let spacing: CGFloat = 75

    for (i, type) in TanType.allCases.enumerated() {
        let piece = TangramPiece(type: type, color: colors[i])
        let x = CGFloat(i - 3) * spacing + frame.midX
        piece.position = CGPoint(x: x, y: trayY)
        piece.zPosition = 10
        addChild(piece)
        pieces.append(piece)

        // Animate pieces sliding up on load
        piece.position.y = -100
        let delay = Double(i) * 0.06
        let move = SKAction.move(to: CGPoint(x: x, y: trayY), duration: 0.4)
        move.timingMode = .easeOut
        piece.run(SKAction.sequence([.wait(forDuration: delay), move]))
    }
}
```

---

## 8. Common Bugs & How to Fix Them

| Bug | Cause | Fix |
|---|---|---|
| Piece snaps to wrong rotation | `shortestUnitArc` not set | Always pass `shortestUnitArc: true` to `rotate(toAngle:)` |
| Parallelogram flips unexpectedly | Winding order inconsistency | Normalize all vertex arrays to clockwise order |
| SAT overlap false positives | Floating point rounding at edges | Add 1pt tolerance: `projA.max < projB.min - 1.0` |
| Piece "sticks" under another | zPosition not restored after drop | Always reset `zPosition` in `dropPiece()` |
| Touch lost mid-drag on fast move | `touchesMoved` skips frames | Use `coalescedTouches(for:)` for smoother tracking |
| Physics body out of sync after flip | Body not rebuilt after flip | Rebuild `physicsBody` in `flip()` every time |

---

## Interactive Prototype

Here's a working browser prototype so you can feel the core drag/rotate mechanic right now — before you write a line of Swift:Now let me build the interactive prototype:The prototype above lets you feel the core mechanic — drag pieces, click to rotate 45°, double-click the parallelogram to flip it, and hit **Hint** to see ghost outlines of where pieces belong.

---

## What Else Should You Know?

**The SAT collision algorithm is your most important investment.** Sloppy overlap detection (bounding boxes only) makes the game feel broken — players will place overlapping pieces and not understand why their solution looks right but won't win. Implement SAT early and test it with the parallelogram against every other piece — it's the hardest edge case.

**SpriteKit coordinate system is flipped vs UIKit.** Y increases *upward* in SpriteKit, downward in UIKit. This bites every iOS developer at least once, especially when converting touch locations. Always use `touch.location(in: self)` where `self` is the `SKScene`, not the view.

**`SKAction.sequence` is your animation best friend.** Chain snap → flash → z-reset in one sequence block rather than using `DispatchQueue.asyncAfter` — it's cleaner and cancellable.

**Profile early on a real device.** SpriteKit's `SKView.showsDrawCount` and `showsNodeCount` are invaluable. Target under 30 draw calls and under 50 nodes for smooth 60fps on older iPhones.

**Build a puzzle editor before you build 100 puzzles.** A simple macOS tool (even a SwiftUI form) where you drag pieces into position and hit "Export JSON" will save you dozens of hours — manually computing solution coordinates is painful and error-prone.

