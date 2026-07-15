# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tangram Odyssey is a tangram puzzle game. The current implementation is a single-file web app (`tangram-game/tangram-game.html`). The README.txt outlines architecture for a planned native iOS/macOS SpriteKit/SwiftUI port.

## Running the Game

No build step required. Open `tangram-game/tangram-game.html` directly in any modern browser.

## Web Implementation Architecture

The entire game lives in `tangram-game/tangram-game.html` (~660 lines), organized into clearly commented sections:

- **Geometry** — Piece vertex definitions using a unit grid (`U = canvas size / 8`). The 7 tans: 2 large triangles, 1 medium triangle, 2 small triangles, 1 square, 1 parallelogram.
- **State** — Global piece objects (`pieces[]`), drag state, hint mode. Each piece: `{id, name, color, verts[], canFlip, x, y, angle, flipped, solved, solution, z, glowAlpha}`
- **Solution data** — Hard-coded "cat" silhouette path and per-piece snap targets
- **Render loop** — Canvas 2D: draws grid → silhouette → pieces (z-sorted) → hint overlays → glow effects
- **Input** — Unified pointer events (mouse + touch): drag moves, single tap rotates 45°, double-tap flips parallelogram
- **Snap logic** — Position tolerance `U * 0.55`, angle tolerance `0.45 rad`; on snap: glow animation, piece locked, z-order sent to back
- **Win detection** — All 7 pieces snapped triggers overlay

## Planned iOS/macOS Port (README.txt)

Key architecture notes from README.txt for the native port:

- **Files:** `GameScene.swift`, `TangramPiece.swift`, `PuzzleBoard.swift`, `PieceGeometry.swift`, `CollisionDetector.swift`, `HapticEngine.swift`, `PuzzleData.swift`
- **Collision:** SAT algorithm — quick bounds check first, then project verts onto edge-normal axes with 1pt tolerance
- **SpriteKit Y-axis is flipped vs UIKit** (Y increases upward) — affects all coordinate math
- **Parallelogram flip** must rebuild physicsBody every time; normalize verts to clockwise
- **Snap:** Use `shortestUnitArc: true` to avoid wrong rotation direction
- **Puzzle data format:** `PuzzleDefinition { id, name, difficulty, silhouettePath:[CGPoint], solutions:[PieceSolution] }`
- **Haptics:** Snap (intensity 1.0), lift (0.4), rotate (0.3), flip (double pulse), win (5-pulse ascending)
- Use `SKAction.sequence` for snap→flash→z-reset, not `DispatchQueue`
