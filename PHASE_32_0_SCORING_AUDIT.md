# Phase 32.0 — Scoring and Progression Audit

## Confirmed issues corrected
- **Number Merge:** Level 6+ goal previously used a base of 24, while level 5 was 96. Now level 6 starts at 106 and grows gradually.
- **Fruit Catch:** Level 6+ previously fell back to a default base of 1, after level 5 required 170. Now level 6 starts at 187 and grows gradually.
- **Puzzle result flags:** The shared completion handler now respects an explicit `completed` or `won` flag from puzzle games. If neither is present, the existing puzzle-completion behavior is preserved.

## Preserved behavior
- Number Merge earns three stars on reaching its target (since play ends at the target).
- The other games retain their existing star thresholds.
- No save format, achievements, rewards, or gameplay scripts were changed.

## Additional observations for next pass
- Best-star ratings are currently tracked **per game**, not per individual level.
- Puzzle games that end only upon successful completion earn three stars by design; their score remains useful for records and rewards.
- Star requirements should be reviewed game-by-game with actual gameplay tests before making broader changes.

## Test cases
- Number Merge levels 5 -> 6: target must increase rather than reset.
- Fruit Catch levels 5 -> 6: target must increase rather than reset.
- Clear a puzzle game and verify three stars.
- Replay an earlier level and ensure existing progression is retained.

ZIP integrity verified. Godot parser, gameplay, and iPhone Safari not run.
