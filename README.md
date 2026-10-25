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

## Mobile touch polish update
This update adds shared visual feedback when buttons are pressed, including the main hub, Fast Fingers targets, Number Merge tiles/actions, and Perfect Stack controls. The main interface also has consistent side/top/bottom margins to reduce edge-hugging controls on narrow phone screens. Existing game rules are unchanged.

The update is intended for testing in Godot 4.7.2 and Safari web exports, but it has not been run through the Godot editor or verified on a physical device in this packaging environment. After importing, run all three games before exporting a fresh web build.

## Next steps
1. Run and test on your Godot 4 version.
2. Polish mobile layouts, accessibility, and sound.
3. Formalize a reusable mini-game interface.
4. Configure Android export and test on device.
5. Use macOS/Xcode for iOS export and physical-device testing.
6. Add backend authentication, score validation, leaderboards, and server-scheduled events.
7. Add more games after the shared framework is stable.


## Touchscreen support

This build is configured for portrait mobile screens and touch-friendly controls. Buttons have larger minimum tap areas, Fast Fingers targets are larger, and Number Merge tiles are easier to tap. The project enables touch-to-mouse emulation as a fallback for input code that listens for mouse events. Godot UI buttons also respond directly to touch input. The interface uses an expanding canvas layout to better accommodate different phone aspect ratios.

Before publishing, test on a real iOS and Android device or their platform emulators; this starter project has not yet been packaged as a signed mobile app.
