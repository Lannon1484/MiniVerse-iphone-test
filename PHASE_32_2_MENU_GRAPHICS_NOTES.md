# Phase 32.2 - Menu Graphics Consistency

Audited the Games, Earn, Shop, and Profile header images and the three Home navigation shortcuts. The Games header had a different aspect ratio (1000x490) from the others (~1475x248). All four headers now share a 1475x248 canvas and matching gold-and-violet frame. The Games portal/logo is preserved uncropped in a centered panel, with a soft-focus extension to fill the wide banner; the other headers preserve their original imagery. Home shortcuts remain uniform at 360x300. No menu navigation, game logic, saved data, or rewards were changed.

ZIP integrity checked; visual presentation in Godot and iPhone Safari not tested.
