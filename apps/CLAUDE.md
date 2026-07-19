# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is the **planning, design, and (now) implementation repository** for *Tangram Odyssey*, a proposed iOS/macOS/tvOS tangram puzzle game. It began as design-only; an Xcode app target now exists at [TangramOdyssey/](TangramOdyssey/) — see [TangramOdyssey/CLAUDE.md](TangramOdyssey/CLAUDE.md) for build/run/test commands and app-specific conventions. That target is still a scaffolded template with no game code yet, so this directory remains the source of truth for design and data.

Two files make up the design/data side of the repo:

- [PLAN.md](PLAN.md) — the product/design spec: game concept, rules, target platforms, feature list, and the intended data model. This is the source of truth for *intent*.
- [TangramData.json](TangramData.json) — the actual puzzle dataset (~2,900 KB, 2,097 puzzles). This is the source of truth for *data that exists*.

## Domain model

A tangram puzzle is a silhouette to be filled by arranging all **7 pieces** (tans) without overlap. Every puzzle has total area **16**, made of pieces with areas summing to 16:

- 2 large right-isosceles triangles (area 4 each)
- 1 medium right-isosceles triangle (area 2)
- 2 small right-isosceles triangles (area 1 each)
- 1 square (area 2)
- 1 parallelogram (area 2)

The parallelogram is the only piece that must be **reflected** (flipped) to reach its mirror image — reflection handling is a core mechanic, not an edge case.

### Puzzle JSON shape (as it exists in TangramData.json)

`TangramData.json` is a **flat top-level array** of puzzle objects (not the `{"packs": [...]}` wrapper sketched in PLAN.md — that is aspirational). Each puzzle:

```
id, name, description, hint, categories (array), scale, pieces (array of 7)
```

Each piece:

```
id (1-7), position ([x,y] center), rotation (degrees), reflected (0/1), angles (interior angles), area
```

Note: numeric values use scientific notation (e.g. `2.3333e2`); parse as floats. `reflected` is `0`/`1`, not a boolean.

## Known spec-vs-data discrepancies

When touching data or writing code that consumes it, be aware the spec (PLAN.md) and the shipped data (TangramData.json) do **not** yet agree. Verify against the JSON, and flag mismatches rather than silently assuming the spec:

- **`categories` is populated for all 2,097 puzzles** (e.g. `["Fishes", "Animals"]`) — the taxonomy from PLAN.md is present in the data. (An earlier revision of this doc claimed it was empty; that is no longer true — verified against the JSON.)
- **`area` is absent** at the puzzle level in the data, though PLAN.md lists it as a puzzle property (it is always 16, and piece `area` values are present).
- The **puzzle-pack structure** and **difficulty ranges** in PLAN.md do not exist in the data — there is no pack grouping yet.
- **`angles` is polymorphic**: usually an array of interior-angle degrees, but piece id 5 always serializes as the string `"TriangleSmall2"` (a leaked piece-type name). Decode it as either form.
- **`rotation` is an integer step 0–23, not degrees** — it maps to 15° increments (24 × 15° = 360°). Multiply by 15 for degrees.
- Piece `id`→kind is stable across all puzzles: 1,2 = large triangle (area 4); 3,5 = small triangle (area 1); 4 = medium triangle (area 2); 6 = square (area 2); 7 = parallelogram (area 2). Only 6 and 7 ever carry `reflected = 1`.

## Working in this repo

- Treat PLAN.md changes as product/design decisions; treat TangramData.json changes as data edits that must keep all 7 pieces per puzzle and areas summing to 16.
- TangramData.json is large — use `python3 -c` (or `jq`) to inspect/filter rather than reading it whole.
- If asked to "build the game," the first step is scaffolding an app target (per PLAN.md, iOS is primary, with SwiftUI implied by the platform choices) — there is no existing project to extend.
