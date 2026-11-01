# Phase 31.9 — Puzzle Fairness & Balancing

This update makes small, targeted adjustments following a code review.

## Changes
- **Number Merge:** Starting guaranteed pair appears in a random row/column rather than always top-left. After a new tile spawns, the game checks for an available adjacent merge and, when an empty space exists, can adjust one empty tile to avoid a no-moves softlock. A full board with no matches still ends normally.
- **Memory Match:** First three levels show their preview cards for 5.0, 4.0, and 2.75 seconds (previously 4.5, 3.5, and 2.0), giving phone players a little more time to memorize.
- **Tile Slide:** Scramble length grows with the saved difficulty level (20 to 44 legal moves). Scrambling from the solved board guarantees solvability. An accidental solved starting position is corrected.
- **Color Sort:** Existing curated introductory layouts, undo, and two spare tubes are preserved.
- **Connect the Dots:** Existing seeded, nonoverlapping path generation is preserved; no arbitrary changes to puzzle generation.

## Validation limits
The ZIP integrity check confirms the archive can be read. Godot parser and gameplay execution have not been run. Please test Number Merge for legal moves, Memory Match preview timing, and Tile Slide at low and high levels on iPhone Safari.
