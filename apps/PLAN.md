# Tangram Odyssey

## Project Overview

Develop a well-designed and balanced iOS Tangram[^tangram] puzzle game focusing on smooth animations, game state management, and user interaction.

[^tangram]: A tangram is an ancient Chinese dissection puzzle consisting of a large square divided into 7 specific geometric pieces called "tans."

## Game Overview

Players are presented with a silhouette outline of a shape. 
Players must arrange all 7 tangram pieces to fill the outline exactly. 
All 7 pieces must be used.
Pieces may be dragged, rotated, and reflected (flipped).

## Game Pieces

The 7 pieces include:

* 2 large right isosceles triangles
* 1 medium right isosceles triangle
* 2 small right isosceles triangles
* 1 small square
* 1 parallelogram

Total area of each puzzle is 16. 

The two large triangles and two small triangles are congruent pairs, meaning they are identical in size and shape.
All five triangles are similar, sharing the same 45-45-90 angle measurements, but their sizes differ.

Solving tangram puzzles requires an understanding of rigid motion transformations, including:

* Rotation: Turning a piece.
* Translation: Sliding a piece.
* Reflection (flipping): The parallelogram is a key piece for understanding reflection, as it must be reflected (flipped) to create its mirror image.

The objective is to arrange all seven pieces—without overlapping—to form various silhouettes, such as animals, humans, letters, or geometric shapes.

## Target Audience

All ages and interests. From casual puzzle players to educators / teachers and fans of classic tangrams

## Target Platforms

| Platform | Status |
| -------- | ------ |
| iOS (iPhone + iPad) | Primary |
| macOS | Planned |
| tvOS | Planned |

## Features of the iOS game

* Intuitive Touch Mechanics: drag-and-drop, swiping, and gestures (e.g., pinching to zoom or rotating) making gameplay feel natural and immediate.
* Minimalist & Aesthetic Design: focus on clean, intuitive interface that doesn’t overwhelm the user, emphasizing calming colors
* Progressive Difficulty & Hints: gentle learning curve, starting easy and increasing in complexity, often with three-tier hint systems to aid users
* iCloud and Social Sync: Support iCloud saves to seamlessly move between iPhone and iPad, plus leaderboard integration via Game Center.
* Accessibility Features: Support for iOS staples like Dark Mode, larger text, and VoiceOver.
* Offline Capability: internet connection should not be required, allowing user to play anywhere.
* Monetization & Replayability: Often free-to-play with in-app purchases for hints, ad removal, or extra "level packs"

### Optional features

* Short Session Friendliness: Designed for quick, 5-10 minute bursts, ideal for commuting or waiting in line

## Puzzle Data structure

### Each Puzzle Structure

| Property| | Value |
| --------- | ----- |
| Id | internal identification number |
| Name |  English title of puzzle |
| Description |  English text description of puzzle |
| Hint |  English text of puzzle hint |
| Categories |  the different categories the puzzle is a member of |
| Scale |  scale the puzzle needs to be rendered |
| Pieces |  list of 7 pieces |
| Area |  total area of puzzle |

### Structure of each of the 7 Pieces

| Property| | Value |
| --------- | ----- |
| Id |  identification number of the piece (1-7) |
| Position |  (x,y) position of the center of the piece |
| Rotation |  degree the piece is rotated |
| Reflected |  True/False whether the piece is reflected (flipped ) |
| Angles |  Interior angles of piece |
| Area |  area of piece |

### Example puzzle entry

```json
{
    "id":1785, 
    "name":"Square 001", 
    "description":"Standard Square",
    "hint":"The fox’s tail and ears offer helpful starting clues. Ensure no pieces overlap.",
    "categories":{ 
        "Shapes" 
    },
    "area":16,
    "scale":1.0, 
    "pieces":[ {
        "id":1,
        "position":[2.3333e2,2.9933e2],
        "rotation":0,
        "reflected":0,
        "angles":{45, 45, 90},
        "area":4
    }, {
        "id":2,
        "position":[300,366],
        "rotation":0,
        "reflected":0,
        "angles":{45, 45, 90},
        "area":4
    }, {
        "id":3,
        "position":[300,266],
        "rotation":0,
        "reflected":0,
        "angles":{45, 45, 90},
        "area":1
    }, {
        "id":4,
        "position":[3.6667e2,2.3267e2],
        "rotation":0,
        "reflected":0,
        "angles":{45, 45, 90},
        "area":2
    }, {
        "id":5,
        "position":[3.8333e2,3.4933e2],
        "rotation":0,
        "reflected":0,
        "angles":{45, 45, 90},
        "area":1
    }, {
        "id":6,
        "position":[350,2.9933e2],
        "rotation":0,
        "reflected":0,
        "angles":{90, 90, 90, 90},
        "area":2
    }, {
        "id":7,
        "position":[275,2.2433e2],
        "rotation":0,
        "reflected":0,
        "angles":{45, 135, 45, 135},
        "area":2
    } ]
}
```

## Packs of puzzles

## Categories

```json
categories = { 
    "Alphabet", "Numbers", "Animals", "Birds", "Boats", "Buildings", "Faces", "Fishes", "Human", "Nature", "Objects", "Shapes", "Sports", "Technical", "Toys", "Cats", "Dogs"
}

