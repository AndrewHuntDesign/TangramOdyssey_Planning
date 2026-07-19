# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The **Xcode app target** for *Tangram Odyssey*. It was scaffolded from the default Xcode
SwiftUI template. The **data and rendering layers are built**; interaction (dragging/rotating
tans, snap-to-place, win detection) does not exist yet. `ContentView.swift` is a simple
read-only puzzle browser (prev/next, solution ↔ silhouette toggle).

- `Puzzle.swift` — the Codable model (`Puzzle`, `TanPiece`, `PieceKind`, and the polymorphic
  `PieceAngles`). Model types are declared `nonisolated` to opt out of the project's default
  `MainActor` isolation so they can decode off the main actor.
- `PuzzleLibrary.swift` — `PuzzleLoader.loadAll()` decodes the bundled dataset.
- `TangramGeometry.swift` — turns pieces into drawable polygons (see **Geometry** below).
- `PuzzleView.swift` — a `Canvas` renderer (`.solution` colored pieces / `.silhouette` fill).
- `TangramData.json` — the dataset is **bundled here as an app resource** (copied from
  `../TangramData.json`; the parent copy remains the source of truth, so keep them in sync).
- `TangramOdysseyTests/` — Swift Testing coverage: `PuzzleDataTests` (decode + invariants),
  `TangramGeometryTests` (piece areas, area-preservation, the reference square).

### Geometry (reverse-engineered — do not re-derive)

The dataset ships no geometry description, so `TangramGeometry.swift`'s constants were
reverse-engineered from puzzle **id 1785 ("Square 001")** — the only all-rotation-0 puzzle,
whose pieces sit at baseline orientation and tile a perfect square. The conventions, verified
to tile all 2,097 puzzles with ~0 overlap:

- **1 unit = 50 points** (`pointsPerUnit`), times the puzzle's `scale`. The assembled figure is
  a 4×4-unit square (area 16).
- `position` is the piece **centroid**. `rotation` is a **step count**: degrees = `rotation × 15`,
  applied **counter-clockwise**. `reflected` mirrors **x → −x** before rotating.
- Canonical polygons are keyed by **piece `id` (1...7), not `PieceKind`** — each id has its own
  baseline orientation (e.g. the two large triangles, ids 1 and 2, differ by 90°).
- The dataset's coordinate space is **y-up** (Mathematica origin); `PuzzleView` flips y so
  figures render upright. Confirmed against the letter and arrow puzzles.

The product spec and canonical dataset live **one directory up** in `apps/`:

- `../PLAN.md` — product/design spec (game concept, rules, platforms, intended data model).
- `../CLAUDE.md` — the domain model (7 tans, area 16, reflection mechanic) and the important
  **spec-vs-data discrepancies** — read that before writing code that consumes the JSON.

## Build, run, test

Prefer the `xcode-tools` MCP tools over the command line (the user is driving from Xcode):

- **Build**: `BuildProject`. Scheme/target is `TangramOdyssey`.
- **Run a snippet / try an idea**: `RunCodeSnippet` (fast, throwaway).
- **Fast diagnostics for one file**: `XcodeRefreshCodeIssuesInFile` (seconds, catches type
  errors and hallucinated APIs without a full build).
- **Tests**: `RunAllTests`, or `RunSomeTests` / `GetTestList` for a single test.

Three targets exist: `TangramOdyssey` (app), `TangramOdysseyTests` (Swift Testing), and
`TangramOdysseyUITests` (XCUITest). Unit tests use the **Swift Testing** framework
(`import Testing`, `@Test`, `#expect`) — not XCTest. UI tests use XCTest/`XCUIApplication`.

## Project conventions specific to this setup

- **File-system-synchronized groups** (`PBXFileSystemSynchronizedRootGroup`, objectVersion 77):
  files added to the `TangramOdyssey/`, `TangramOdysseyTests/`, or `TangramOdysseyUITests/`
  folders are picked up automatically. **Do not hand-edit `project.pbxproj`** to register new
  source files — just create them in the right folder. Bundling a resource like `TangramData.json`
  is the exception and does need project/Xcode configuration.
- **Platform**: iOS only right now (`SDKROOT = iphoneos`, deployment target **26.5**, device
  family iPhone + iPad). PLAN.md's macOS/tvOS ambitions are not configured here — adding a
  platform is a deliberate project change, not an assumption.
- **Swift concurrency**: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and
  `SWIFT_APPROACHABLE_CONCURRENCY = YES` are set — new types are `@MainActor` by default. Match
  the repo's async/await-first style (avoid Combine, per the shared code-style guidance).
- Bundle id `com.andrewhuntdesign.TangramOdyssey`; language Swift 5.0; Xcode 26.6.

## Toolchain note

This targets Xcode 26 / iOS 26 APIs (Liquid Glass, FoundationModels, current SwiftUI). When an
API is unfamiliar or you can't find something, assume it's newer than training data and use the
`DocumentationSearch` MCP tool rather than guessing.
