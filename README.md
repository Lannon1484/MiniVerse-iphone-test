# MiniVerse — Starter Project

A Godot 4 starter project for a mobile-first mini-game collection.

## Included
- Main hub and game library
- Fast Fingers: 20-second target tapping
- Number Merge: adjacent matching-tile puzzle
- Perfect Stack: timing-based tower game
- Shared results, coins, XP, levels, local personal-best saves
- Event and settings preview screens
- Modular structure for future games

## Run
1. Install Godot 4.x from https://godotengine.org/download/
2. Extract `MiniVerse.zip`.
3. In Godot Project Manager, choose Import.
4. Select `project.godot` inside the extracted MiniVerse folder.
5. Open the project and press F6 or F5 to run.

## Controls
- Fast Fingers: tap/click targets.
- Number Merge: tap a tile, then an adjacent tile with the same number.
- Perfect Stack: tap DROP BLOCK.

## Save data
Stored locally in Godot's `user://miniverse_save.json` location. Use Settings to reset progress.

## Important limitations
This is a playable starter build, not a production-ready commercial release. It does not yet include online accounts, cloud saves, server-validated leaderboards, live events, ads, in-app purchases, store-ready export configuration, or real-device QA. The Events screen is a preview only. Local scores are not secure competitive results.

## Next steps
1. Run and test on your Godot 4 version.
2. Polish mobile layouts, accessibility, and sound.
3. Formalize a reusable mini-game interface.
4. Configure Android export and test on device.
5. Use macOS/Xcode for iOS export and physical-device testing.
6. Add backend authentication, score validation, leaderboards, and server-scheduled events.
7. Add more games after the shared framework is stable.


## New in this update
- Added Memory Match, a touch-friendly 4×4 matching-pairs mini-game.
- Added a daily featured game that rotates locally by calendar day.
- Existing games and home-screen artwork are retained.


## Recent-games and icon update
- Home screen now shows only the three most recently launched games.
- Recent game history is saved locally and restored between sessions.
- Full game list remains available in Game Library.
- Memory Match now has its own card illustration, distinct from Perfect Stack.

## Memory Match phone readability update
- 125px high cards and large 54px characters in a 4x4 grid.
- High-contrast A-H pairs with unique bright card colors to avoid missing emoji font glyphs on mobile Web.
- Clear matched-card green state, larger scores, and larger restart button.


Visual update: illustrated Fast Fingers target and candy-sky field; glossy rounded Number Merge tiles; floating-island Perfect Stack scenery and toy-like block highlights. Gameplay logic preserved.


## Lobby artwork polish
- New illustrated fantasy portal and floating-islands hero.
- Gold title, colorful outlined game cards, glossy raised buttons.
- Existing games, Recently Played and progress preserved.


## Game #7 — Neon Snake
- Swipe controls on mobile, arrow keys/WASD on PC, plus on-screen direction buttons.
- Collect glowing stars, grow the snake, avoid walls and your own body.
- Difficulty rises gradually; scores feed existing coins/XP/personal bests.
