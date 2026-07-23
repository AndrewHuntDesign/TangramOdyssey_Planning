# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The **Xcode app target** for *Tangram Odyssey*. It was scaffolded from the default Xcode
SwiftUI template. The **data, rendering, and interactive gameplay layers are built**. Browse by
**category** (a "packs" list → a thumbnail grid), tap a puzzle to **Play**, then drag / rotate /
flip the tans from a **tray** to fill the silhouette; correct placements snap+lock (with a
glide/rotate animation, a lock "pop", and haptics), pieces dropped back over the tray re-home, and
filling all seven triggers a win. Solved puzzles are **remembered across launches** and surfaced
throughout the browser (grid thumbnails flip from silhouette to colored solution + checkmark). A
**hint** menu offers "Show a spot" (highlights where an unplaced piece goes) and "Place a piece".
Remaining work is polish (difficulty grouping, sound). Note: the dataset's `hint` string is the
generic "Ensure no pieces overlap." for **all** puzzles, so hints are gameplay assists, not text.

- `Puzzle.swift` — the Codable model (`Puzzle`, `TanPiece`, `PieceKind`, and the polymorphic
  `PieceAngles`). Model types are declared `nonisolated` to opt out of the project's default
  `MainActor` isolation so they can decode off the main actor.
- `PuzzleLibrary.swift` — `PuzzleLoader.loadAll()` decodes the bundled dataset.
- `TangramGeometry.swift` — turns pieces into drawable polygons (see **Geometry** below).
- `PuzzleView.swift` — a `Canvas` renderer (`.solution` colored pieces / `.silhouette` fill),
  used for grid thumbnails and previews.
- `PuzzleCatalog.swift` — groups puzzles by category (puzzles can be in several; categories are
  overlapping, e.g. Fishes ⊂ Animals). `ContentView` → `CategoryListView` (packs, with per-pack
  solved/total) → `CategoryPuzzlesView` (thumbnail grid) → `GameBoardView`. Navigation uses
  typed values (`CategoryRef`, `Puzzle`) via `navigationDestination`.
- `GameModel.swift` — `@Observable @MainActor TangramGame`: slots (targets), player pieces,
  drag/rotate/flip, and snapping. Snapping matches a piece's polygon against unfilled slots by
  **congruent-polygon comparison** (centroid + vertex sets), which makes same-kind pieces
  interchangeable and handles piece symmetry without tracking orientation. Same-kind pieces share
  one base polygon; per-id baseline differences (ids 2 and 5) fold into slot angles.
- `ProgressStore.swift` — `@Observable @MainActor` store of solved puzzle ids, persisted to
  `UserDefaults` and mirrored to iCloud so progress follows the player across iPhone / iPad /
  tvOS. Both stores sit behind a small `KeyValueStore` protocol (conformed by `UserDefaults`,
  `NSUbiquitousKeyValueStore`, and an in-memory test fake); the local `defaults` and the optional
  `cloud` slot are both injectable. Launch seeds from local then reconciles with the cloud; every
  solve write-throughs to both; external cloud changes are observed (`NSUbiquitousKeyValueStore`'s
  `didChangeExternallyNotification`, ignoring quota-violation reasons) and folded in via
  `mergeExternalChanges()`. Reconciliation **unions within a clear-epoch** (solving is monotonic —
  never un-solve) but tracks a `clearedAt` tombstone: `clear()` bumps it, and the **more recent
  clear wins a merge outright**, so a reset isn't silently repopulated by a stale/in-flight cloud
  push. The persisted blob is a `StoredProgress {solved, clearedAt}`; a legacy bare-`Set<Int>`
  blob still decodes (clearedAt 0) so existing players keep progress. `now:` is injectable for
  deterministic tests. Created in `TangramOdysseyApp` (`cloud: NSUbiquitousKeyValueStore.default`) and passed via
  `.environment`; the game calls `markSolved(puzzle.id)` on win and the browser reads it.
  **iCloud sync requires the iCloud → Key-value storage capability** on each target's
  entitlements (a manual Signing & Capabilities step; not yet enabled) — the code compiles and
  runs local-only without it. tvOS is not configured yet; when added, use the same KVS identifier
  so the container is shared.
- `GameBoardView.swift` — the interactive board. Pieces are **per-piece positioned views**
  (`PieceShape` in a centered frame + `.position`/`.rotationEffect(-angle)`/`.scaleEffect`) so
  SwiftUI animates glide, rotation, flip, and lock-pop; the silhouette is a `Canvas` layer; hit
  testing uses each piece's `contentShape`. `debugSolved:`/`placeAllAtSolution()` place every
  piece at its solution pose — handy for regression-checking the geometry against the silhouette.
- `TangramData.json` — the dataset is **bundled here as an app resource** (copied from
  `../TangramData.json`; the parent copy remains the source of truth, so keep them in sync).
- `TangramOdysseyTests/` — Swift Testing coverage: `PuzzleDataTests` (decode + invariants),
  `TangramGeometryTests` (piece areas, area-preservation, the reference square), and
  `ProgressStoreTests` (solved tracking + persistence, using an isolated `UserDefaults` suite,
  plus iCloud seed/merge, the change-notification observer, and the clear tombstone via an
  in-memory `KeyValueStore` fake that shares state across `ProgressStore` instances).
- `TangramOdysseyUITests/GameplayUITests.swift` — XCUITest flow: browse category → open puzzle →
  solve by tapping "Place a piece" ×7 → assert the win overlay. Relies on the accessibility
  identifiers `category-<name>`, `puzzle-<id>`, and `hintMenu`. (Dragging tans by coordinate is
  brittle, so the win path is driven through the hint menu instead.)

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

### Command-line fallback (when the MCP test runner can't boot a simulator)

In some headless environments the MCP `RunAllTests`/`RunSomeTests` calls return "Test execution
was cancelled". A `Makefile` wraps the working `xcodebuild` invocations (run from this directory):

- `make test` — all unit + UI tests on an `iPhone 17, OS=latest` simulator. Result bundle at
  `/tmp/TangramTests.xcresult`.
- `make build` — simulator build.
- `make build-device` — compiles for real device hardware (`generic/platform=iOS`, Release,
  `CODE_SIGNING_ALLOWED=NO`). A signed install additionally needs a connected device and a
  provisioning profile (a `DEVELOPMENT_TEAM` is already set; signing is Automatic).
- `make ci` — runs `Scripts/ci.sh` (dependency-free full test run, `CODE_SIGNING_ALLOWED=NO`).
  This is what CI uses: `.github/workflows/ci.yml` (repo root) runs it on push/PR — the runner
  image must provide **Xcode 26 + an iOS 26 simulator**.

The suite is 15 tests (13 unit across `PuzzleDataTests`/`TangramGeometryTests`/`ProgressStoreTests`
+ 2 in `GameplayUITests`); no template stubs remain. The simulator destination pins `OS=latest`
so it satisfies the iOS 26.5 deployment target.

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
