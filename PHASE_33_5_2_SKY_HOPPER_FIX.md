# Phase 33.5.2 - Sky Hopper Unexpected Exit Fix

Root cause: falling below the camera called `_game_over()`, which immediately emitted the shared `finished` signal. The main menu handler interpreted this as an ended game and switched to the results screen, making it look like a random lobby exit.

Changes:
- Falling stops the run **inside Sky Hopper** and displays retry / finish guidance; it no longer emits `finished` automatically.
- `NEW RUN` restarts without leaving the game.
- `FINISH RUN & CLAIM SCORE` explicitly submits the score and opens the standard results screen.
- First two generated islands remain centered; later islands use bounded relative horizontal drift, reducing unfair early misses.
- Physics returns immediately after a fall to avoid post-fall world updates.

Preserves all 16 games, art, menus, stars, and progression. ZIP integrity checked; Godot parsing and iPhone runtime testing not performed.
