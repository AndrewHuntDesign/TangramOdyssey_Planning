# Tangram Odyssey — Project Definition

## Vision

Well-designed and balanced puzzle game which constantly cycles players through:
Confusion → Experimentation → Insight → Satisfaction → Progression,
so that the experience feels addictive in a positive way. The user should not feel frustrated or bored.

## Target Audience

All ages and interests. From casual puzzle players to educators / teachers and fans of classic tangrams

## Platforms

| Platform | Status |
|----------|--------|
| iOS 26 (iPhone + iPad) | Primary |
| macOS | Planned |
| tvOS | Planned |

## Game Overview

Players are presented with a silhouette outline and must arrange the 7 classic tangram pieces to fill it exactly. All 7 pieces must be used; pieces may be dragged, rotated, and flipped.

### The 7 Pieces

| Piece | Quantity | Area (units) |
|-------|----------|--------------|
| Large right isosceles triangle | 2 | 4 |
| Medium right isosceles triangle | 1 | 2 |
| Small right isosceles triangle | 2 | 1 |
| Square | 1 | 2 |
| Parallelogram | 1 | 2 |

Total area of a completed puzzle: **16 units**

### Piece Relationships

- 1 medium triangle = 2 small triangles
- 1 square = 2 small triangles
- 1 parallelogram = 2 small triangles
- 1 large triangle = 4 small triangles

## Puzzle Content

Total of 12 puzzles to start, divided into 3 groups "Dogs", "Cats", and "Birds" of 4 puzzles each.
More puzzles will be available through in-app purchases.
Puzzle names:
- Dogs: "Dog 1", "Dog 2", "Dog 3" 
- Cats: "Cat 1", "Cat 2", "Cat 3"
- Birds: "Bird 1", "Bird 1", "Bird 1"

## Tangarm pieces format: JSON + Codable structs 

### Puzzle scheme 

```
/Puzzles/
  packs.json
  pack_animals.json
  pack_people.json
  pack_objects.json
```
## packs.json (index + progression)

```json
{
  "packs": [
    {
      "id": "animals",
      "name": "Animals",
      "difficultyRange": [1, 3],
      "puzzleCount": 120,
      "file": "pack_animals.json"
    },
    {
      "id": "people",
      "name": "People",
      "difficultyRange": [2, 5],
      "puzzleCount": 150,
      "file": "pack_people.json"
    }
  ]
}
```
## Pack File (e.g. pack_animals.json)

```json
{
  "packId": "animals",
  "puzzles": [
    {
      "id": "animals_001",
      "name": "Sitting Cat",
      "difficulty": 2,
      "bounds": { "width": 1.0, "height": 1.0 },
      "pieces": [
        {
          "id": "LT1",
          "type": "largeTriangle",
          "transform": {
            "position": { "x": 0.62, "y": 0.71 },
            "rotation": 45,
            "scale": 1.0,
            "flipped": false
          }
        }
      ],
      "silhouette": {
        "type": "vector",
        "points": [
          { "x": 0.1, "y": 0.2 },
          { "x": 0.8, "y": 0.2 },
          { "x": 0.7, "y": 0.9 }
        ]
      },
      "metadata": {
        "estimatedTime": 90,
        "tags": ["cat", "animal"],
        "author": "system"
      }
    }
  ]
}
```

## Transform-Based Pieces

* Store **base geometry once in code**
* Apply transform per puzzle



## Swift Data Models

```swift
import Foundation

struct PuzzlePackIndex: Codable {
    let packs: [PuzzlePackInfo]
}

struct PuzzlePackInfo: Codable {
    let id: String
    let name: String
    let difficultyRange: [Int]
    let puzzleCount: Int
    let file: String
}

// MARK: - Puzzle

struct TangramPuzzle: Codable, Identifiable {
    let id: String
    let name: String
    let difficulty: Int
    let bounds: SizeData
    let pieces: [TangramPiece]
    let silhouette: Silhouette?
    let metadata: PuzzleMetadata?
}

struct TangramPiece: Codable {
    let id: String
    let type: PieceType
    let transform: Transform
}

struct Transform: Codable {
    let position: CGPointData
    let rotation: Double   // degrees
    let scale: Double
    let flipped: Bool
}

struct CGPointData: Codable {
    let x: Double
    let y: Double
}

struct SizeData: Codable {
    let width: Double
    let height: Double
}

struct Silhouette: Codable {
    let type: String
    let points: [CGPointData]
}

struct PuzzleMetadata: Codable {
    let estimatedTime: Int?
    let tags: [String]?
    let author: String?
}

enum PieceType: String, Codable {
    case largeTriangle
    case mediumTriangle
    case smallTriangle
    case square
    case parallelogram
}
```




## SpriteKit Rendering System

### Base Geometry (defined once)

```swift
import SpriteKit

class TangramFactory {

    static func basePath(for type: PieceType) -> CGPath {
        let path = CGMutablePath()

        switch type {

        case .largeTriangle:
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: 1, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 1))
            path.closeSubpath()

        case .mediumTriangle:
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: 0.5, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 0.5))
            path.closeSubpath()

        case .smallTriangle:
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: 0.5, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 0.5))
            path.closeSubpath()

        case .square:
            path.addRect(CGRect(x: 0, y: 0, width: 0.5, height: 0.5))

        case .parallelogram:
            path.move(to: CGPoint(x: 0.2, y: 0))
            path.addLine(to: CGPoint(x: 0.7, y: 0))
            path.addLine(to: CGPoint(x: 0.5, y: 0.5))
            path.addLine(to: CGPoint(x: 0.0, y: 0.5))
            path.closeSubpath()
        }

        return path
    }
}
```


### Create Piece Node

```swift
func createPieceNode(piece: TangramPiece, sceneSize: CGSize) -> SKShapeNode {

    let basePath = TangramFactory.basePath(for: piece.type)
    let node = SKShapeNode(path: basePath)

    node.fillColor = .systemBlue
    node.strokeColor = .black
    node.lineWidth = 1.0

    // Scale to screen
    let scaleFactor = sceneSize.width * piece.transform.scale
    node.setScale(scaleFactor)

    // Position (normalized → screen)
    let x = sceneSize.width * piece.transform.position.x
    let y = sceneSize.height * piece.transform.position.y
    node.position = CGPoint(x: x, y: y)

    // Rotation (degrees → radians)
    node.zRotation = CGFloat(piece.transform.rotation * .pi / 180)

    // Flip
    if piece.transform.flipped {
        node.xScale *= -1
    }

    return node
}
```

### Load Puzzle into Scene

```swift
class GameScene: SKScene {

    var puzzle: TangramPuzzle!

    override func didMove(to view: SKView) {
        backgroundColor = .white
        renderPuzzle()
    }

    func renderPuzzle() {
        guard let puzzle = puzzle else { return }

        for piece in puzzle.pieces {
            let node = createPieceNode(piece: piece, sceneSize: size)
            addChild(node)
        }
    }
}
```


### Touch Handling (Drag System)

```swift
class GameScene: SKScene {

    private var selectedNode: PieceNode?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        let nodes = nodes(at: location)
        selectedNode = nodes.compactMap { $0 as? PieceNode }.first
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let node = selectedNode else { return }

        let location = touch.location(in: self)
        node.position = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = selectedNode else { return }

        trySnap(node)
        selectedNode = nil
    }
}
```


### Silhouette Rendering

```swift
func createSilhouette(points: [CGPointData], size: CGSize) -> SKShapeNode {
    let path = CGMutablePath()

    guard let first = points.first else { return SKShapeNode() }

    path.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))

    for p in points.dropFirst() {
        path.addLine(to: CGPoint(x: p.x * size.width, y: p.y * size.height))
    }

    path.closeSubpath()

    let node = SKShapeNode(path: path)
    node.strokeColor = .gray
    node.lineWidth = 2
    return node
}
```




### Snapping System

* Compare piece transform vs target transform
* Snap if within tolerance
* Core Idea

Each piece has:

* A **current transform** (player moves it)
* A **target transform** (solution from JSON)

We compare the two and **snap when within tolerance**.


#### Snap Logic (Core System)

```swift
func trySnap(_ node: PieceNode) {

    let target = node.targetTransform!

    let targetPosition = CGPoint(
        x: size.width * target.position.x,
        y: size.height * target.position.y
    )

    let targetRotation = CGFloat(target.rotation * .pi / 180)

    let positionDelta = hypot(node.position.x - targetPosition.x,
                              node.position.y - targetPosition.y)

    let rotationDelta = abs(node.zRotation - targetRotation)

    let positionTolerance: CGFloat = 30
    let rotationTolerance: CGFloat = 0.2

    if positionDelta < positionTolerance && rotationDelta < rotationTolerance {

        // Snap into place
        node.run(SKAction.group([
            SKAction.move(to: targetPosition, duration: 0.15),
            SKAction.rotate(toAngle: targetRotation, duration: 0.15)
        ]))

        node.fillColor = .systemGreen
        node.isUserInteractionEnabled = false
    }
}
```

#### Optional: Snap Feedback (Highly Recommended)

Add polish:

```swift
func snapFeedback(_ node: SKNode) {
    let scaleUp = SKAction.scale(by: 1.1, duration: 0.08)
    let scaleDown = SKAction.scale(by: 0.9, duration: 0.08)
    node.run(SKAction.sequence([scaleUp, scaleDown]))
}
```










## Progression & Difficulty

Puzzles will have categories of "Easy", "Medium", and "Hard" 
Unlockable puzzle packs available through in-app purchase

## Scoring & Goals

Successfully finished puzzles will be highlighted in the list of available puzzles

## Hints & Accessibility

A hint is available which showing the final position of all pieces

## Monetization

Unlockable puzzle packs available through in-app purchase
Links to website to buy books, pictures, and other mechandise

## Game States

| State | Description |
|-------|-------------|
| `loading` | Initial asset load / puzzle setup |
| `playing` | Active puzzle in progress |
| `paused` | Game paused, overlay shown |
| `gameover` | Puzzle solved (or abandoned) |

## Key Interactions

- **Drag** — move a piece across the board
- **Rotate** — rotate piece in 45° increments
- **Flip** — mirror the parallelogram (only asymmetric piece)
- **Snap** — piece snaps to valid grid position when close enough
- **Reset** — return all pieces to the tray

## Out of Scope (v1)

A choice of hints will be available 
- show the final position of all pieces
- only show location of one piece which has not been played

Users can have a 'favorite' list. Future feature is to share with other users

