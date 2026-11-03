# Phase 33.8.1 - Memory Match Preview Fix

The board preview previously ran only at levels 1-3. It now appears at **every** level, including level 5 and beyond. Preview length decreases gradually from 5 seconds at level 1 to a minimum of 2.5 seconds at higher levels. The board stays locked while memorizing, and restart invalidates stale preview timers via round_serial. All 16 games, studio intro, and save/progression systems are retained. ZIP integrity tested; Godot/iPhone runtime not tested.
