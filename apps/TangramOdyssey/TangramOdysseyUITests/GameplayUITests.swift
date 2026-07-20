//
//  GameplayUITests.swift
//  TangramOdysseyUITests
//
//  Drives the real UI: browse categories → open a puzzle → play. The solve test uses the
//  "Place a piece" hint seven times to reach a win deterministically (dragging tans by coordinate
//  is brittle in XCUITest; the hint path exercises the same placement + win logic).
//

import XCTest

final class GameplayUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    /// Navigates from the category list into a puzzle and confirms the board is interactive.
    @MainActor
    func testBrowseIntoPuzzleShowsBoard() {
        let app = XCUIApplication()
        app.launch()

        openFirstPuzzle(in: app, category: "Animals")

        XCTAssertTrue(app.buttons["Reset"].waitForExistence(timeout: 10),
                      "The game board should show a Reset control.")
        XCTAssertTrue(app.buttons["hintMenu"].exists,
                      "The game board should show the hint menu.")
    }

    /// Solves a puzzle by placing all seven pieces via the hint menu, then checks the win state.
    @MainActor
    func testSolvePuzzleWithHints() {
        let app = XCUIApplication()
        app.launch()

        openFirstPuzzle(in: app, category: "Animals")

        let hint = app.buttons["hintMenu"]
        XCTAssertTrue(hint.waitForExistence(timeout: 10))

        for piece in 1...7 {
            hint.tap()
            let place = app.buttons["Place a piece"]
            XCTAssertTrue(place.waitForExistence(timeout: 5), "Hint menu should offer 'Place a piece' (piece \(piece)).")
            place.tap()
        }

        XCTAssertTrue(app.staticTexts["Solved!"].waitForExistence(timeout: 10),
                      "Placing all seven pieces should complete the puzzle.")
    }

    // MARK: Helpers

    /// Taps into a category and opens its first puzzle thumbnail.
    @MainActor
    private func openFirstPuzzle(in app: XCUIApplication, category: String) {
        let categoryCell = app.staticTexts[category]
        XCTAssertTrue(categoryCell.waitForExistence(timeout: 15), "Category '\(category)' should appear once puzzles load.")
        categoryCell.tap()

        let firstPuzzle = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'puzzle-'")).firstMatch
        XCTAssertTrue(firstPuzzle.waitForExistence(timeout: 10), "A puzzle thumbnail should appear in the category grid.")
        firstPuzzle.tap()
    }
}
