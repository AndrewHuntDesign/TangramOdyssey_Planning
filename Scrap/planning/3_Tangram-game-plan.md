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