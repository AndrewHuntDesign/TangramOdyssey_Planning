# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Project Context

## Overview

Tangram Odyssey is a multiplatform SpriteKit tangram puzzle game targeting iOS, macOS, and tvOS.

- iOS 26 SwiftUI app targeting iPhone and iPad
- Minimum deployment: iOS 26
- Swift 6 with strict concurrency
- Uses SwiftUI throughout - no UIKit unless absolutely necessary

### Tangram game pieces (7 piece set)

- Set is formed by cutting a square into 7 pieces: 2 large right isosceles triangles, 1 medium right isosceles triangle, 2 small right isosceles triangles, 1 square, 1 parallelogram
- medium triangle is formed by two small triangles
- square is formed by two small triangles
- parallelogram is formed by two small triangles
- large triangle is formed by four small triangles

#### Area of each piece
- small triangle: 1 unit
- medium triangle: 2 units
- square: 2 units
- parallelogram: 2 units
- large triangle: 4 units

## Architecture

- MVVM with @Observable ViewModels (NOT ObservableObjects)
- Views own their ViewModel as a @State property
- ViewModels handle all business logic - Views are declarative only
- Navigation uses NavigationStack with NavigationPath - never NavigationView
- Dependency injection through the SwiftUI Environment
- use AppStorage for simple user preferences
- use SwiftData for persistent models
- Keep core puzzle logic (matching, snapping) in pure Swift classes, independent of SwiftUI
- Use `.withAnimation(.spring())` for smooth piece movements
- Support drag gestures (`.gesture(DragGesture())`) for interaction
- Optimize SpriteKit nodes for rendering performance. Avoid unnecessary view redraws
- Implement a clear `GameState` enum (playing, paused, gameover, loading)

## Build System

- use BuildProject for completion (not shell commands or xcodebuild)
- Previews are available via RenderPreview
- SPM for package management - no CocoaPods
- Build target: "TangramOdyssey" iOS

## Testing

- Use Swift Testing framework -- NOT XCTest
- Test functions use @Test attribute, not func testXYZ()
- Use #expect() for assertions - not XCTAssertEqual
- Test target: TangramOdysseyTests
- Run with RunAllTests or RunSomeTests MCP tools

## Documentation & APIs

- Use DocumentationSearch for Apple API questions
- Do NOT hallucinate API names - Verify with the docs first
- prefer async/await - never completion handlers
- use structured concurrency (TaskGroup) over manual task management
- Error handling: use typed throws where supported

## Code Style

- All new views must include a #Preview block
- Use SF symbols for icons - reference by exact name
- Prefer Liquid Glass materials for iOS 26 UI
- File organization: one type per file
- Naming: PascalCase for types, camelCase for properties
- Group files by feature, not by type (e.g. Game/, Puzzles/, Settings/)
