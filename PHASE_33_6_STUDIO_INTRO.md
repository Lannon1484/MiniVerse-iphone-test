# MiniVerse Phase 33.6: NLandragon Studios intro

Uses the exact user-supplied Dragon_Emblem.png and adapts the supplied NLandragonIntro.gd to the project.

On application launch: NLandragonIntro.tscn -> timed fade and scale animation -> scenes/main.tscn (lobby).
SKIP button plus keyboard/touch/mouse skip are supported.
The studio name and subtitle appear as NLANDRAGON / S T U D I O S.
The logo is stored in assets/branding/Dragon_Emblem.png.
The original game main scene and all 16 games are unchanged; the app main_scene setting is the only project setting changed.

The intro displays on application startup, not on every return to the lobby.
The ZIP integrity has been tested; Godot parsing and iPhone Safari behavior have not been runtime tested.
