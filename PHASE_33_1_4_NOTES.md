# Phase 33.1.4 - Bubble Burst aligned controls

Grid, next bubble preview and seven lane buttons now share a centered, fixed-width VBoxContainer. Grid width uses a 46%-viewport-height budget (capped at 410px) and a screen-width cap. Buttons expand only within that same grid width and align by column; no full-screen button stretching. Vertical gaps and control heights are compact to keep buttons visible. Bubble art, matching logic, scoring and progression are unchanged.

Test on iPhone Safari and in Godot 4.7.2; ZIP integrity is not a runtime test.
