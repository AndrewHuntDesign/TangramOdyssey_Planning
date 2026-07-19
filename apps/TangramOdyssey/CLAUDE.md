# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The **Xcode app target** for *Tangram Odyssey*. It was scaffolded from the default Xcode
SwiftUI template and currently contains only placeholder UI (`ContentView.swift` shows
"Hello, world!") — none of the game logic, puzzle rendering, or data loading described in the
spec exists yet. Treat this as a greenfield build-out, not an extension of working code.

The product spec, domain model, and puzzle dataset live **one directory up** in `apps/`:

- `../PLAN.md` — product/design spec (game concept, rules, platforms, intended data model).
- `../TangramData.json` — the real dataset: 2,097 puzzles, ~2.9 MB. Not yet bundled as an app
  resource. See `../CLAUDE.md` for the domain model (7 tans, area 16, reflection mechanic) and
  the important **spec-vs-data discrepancies** — read that before writing any code that consumes
  the JSON.

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
