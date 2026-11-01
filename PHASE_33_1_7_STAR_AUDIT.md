# Phase 33.1.7 — Star Rewards Audit (14 Games)

## Actual shared star rules
- **1 star:** Round ends without meeting the win condition (current design; no zero-star tier).
- **2 stars:** Round is won but its game-specific 3-star condition is not met.
- **3 stars:** Round is won and its 3-star condition is met.
- **Best stars:** Saved per GAME, not per level. Highest previously earned rating is preserved.

## Individual game outcomes
| Game | Win condition | Three stars |
|---|---|---|
| Fast Fingers | Reach level score target by round end | At least 160% of goal |
| Number Merge | Reach internal board target (round ends automatically) | Every successful clear |
| Perfect Stack | Reach target tower height | Reach 160% of target, or full 30-block tower |
| Memory Match | Match all pairs | Every successful clear |
| Whack-a-Mole | Reach level score target | At least 160% of goal |
| Color Sort | Complete sorting puzzle | Every successful clear |
| Neon Snake | Reach level score target before collision | At least 160% of goal |
| Connect the Dots | Complete all paths | Every successful clear |
| Sky Hopper | Reach level score target before run ends | At least 160% of goal |
| Rhythm Rush | Reach level score target | At least 160% of goal |
| Neon Dodge | Survive at least the level target (maximum 30s target) | Survive full 35-second round |
| Tile Slide | Solve sliding puzzle | Every successful clear |
| Fruit Catch | Reach level score target | At least 160% of goal |
| Bubble Burst | Reach level score target (round ends automatically) | Every successful clear |

## Fixed issues
1. Number Merge's level 6+ shared goal now equals its own internal score target (`96 + 24*(level-5)`).
2. Neon Dodge level goals stop growing at 30 seconds, below its fixed 35-second run cap. Its three-star goal is now the achievable full 35-second survival.
3. Perfect Stack's later goals never exceed its hard 30-block maximum. A complete 30-block tower always awards three stars.
4. Existing Number Merge and Bubble Burst three-star-on-clear behavior remains intact.

## Limitations
This is a source-code audit, not automated gameplay testing. The 160%-score games can still vary in practical difficulty; tune with playtesting. Existing saved best-star records are not reduced or erased. The game-wide star total is the sum of best stars across games, not per-level stars.
