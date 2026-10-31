extends Control

const BG := Color("#080d27")
const PANEL := Color("#191d3b")
const PANEL2 := Color("#252b4c")
const TEXT := Color("#f5f7ff")
const MUTED := Color("#a9b1d0")
const ACCENT := Color("#a78bfa")
const CYAN := Color("#67e8f9")
const SAVE_PATH := "user://miniverse_save.json"
const GamePreview = preload("res://scripts/game_preview.gd")
const TouchFeedback = preload("res://scripts/touch_feedback.gd")
const HomeHero = preload("res://scripts/home_hero.gd")
const MemoryMatch = preload("res://scripts/memory_match.gd")
const WhackAMole = preload("res://scripts/whack_a_mole.gd")
const ColorSort = preload("res://scripts/color_sort.gd")
const NeonSnake = preload("res://scripts/neon_snake.gd")
const ConnectDots = preload("res://scripts/connect_dots.gd")
const Difficulty = preload("res://scripts/difficulty.gd")
const SkyHopper = preload("res://scripts/sky_hopper.gd")
const RhythmRush = preload("res://scripts/rhythm_rush.gd")
const RewardConfetti = preload("res://scripts/reward_confetti.gd")
const GameplaySparkles = preload("res://scripts/gameplay_sparkles.gd")
const SFX_TAP = preload("res://assets/sfx/tap.wav")
const SFX_START = preload("res://assets/sfx/start.wav")
const SFX_WIN = preload("res://assets/sfx/win.wav")
const SFX_COLLECT = preload("res://assets/sfx/collect.wav")
const SFX_POUR = preload("res://assets/sfx/pour.wav")
const SFX_CONNECT = preload("res://assets/sfx/connect.wav")
const SFX_OOPS = preload("res://assets/sfx/oops.wav")
const GAMES := [
    {"id":"fast","title":"Fast Fingers","genre":"REFLEX ARCADE","desc":"Tap targets before time runs out.","color":Color("#f9738f")},
    {"id":"merge","title":"Number Merge","genre":"PUZZLE","desc":"Merge matching tiles to reach bigger numbers.","color":Color("#60a5fa")},
    {"id":"stack","title":"Perfect Stack","genre":"TIMING","desc":"Drop moving blocks and build a tower.","color":Color("#fbbf24")},
    {"id":"memory","title":"Memory Match","genre":"BRAIN TRAINER","desc":"Flip cards and find all matching pairs.","color":Color("#34d399")},
    {"id":"whack","title":"Whack-a-Mole","genre":"REFLEX ARCADE","desc":"Whack moles, avoid snakes!","color":Color("#38d9b4")},
    {"id":"sort","title":"Color Sort","genre":"RELAXING PUZZLE","desc":"Pour colorful liquids into matching tubes.","color":Color("#c084fc")},
    {"id":"snake","title":"Neon Snake","genre":"ARCADE","desc":"Collect glowing stars and grow your snake.","color":Color("#58edc4")},
    {"id":"dots","title":"Connect the Dots","genre":"PUZZLE","desc":"Draw glowing paths between matching colors.","color":Color("#ff79b2")},
    {"id":"hopper","title":"Sky Hopper","genre":"ARCADE PLATFORMER","desc":"Hop between floating islands and collect stars.","color":Color("#9bd8ff")},
    {"id":"rhythm","title":"Rhythm Rush","genre":"TIMING ARCADE","desc":"Tap glowing notes on the beat line.","color":Color("#fb86d5")}
]

var content: VBoxContainer
var lobby_scroll: ScrollContainer
var lobby_touch_scrolling := true
var coins := 0
var xp := 0
var level := 1
var best_scores: Dictionary = {}
var best_stars: Dictionary = {}
var recent_games: Array[String] = []
var game_id := ""
var game_root: Control
var rng := RandomNumberGenerator.new()
var sound_enabled := true
var sound_player: AudioStreamPlayer
var library_filter := "ALL"
var seen_tutorials: Dictionary = {}
var tutorial_overlay: Control

const TUTORIALS := {
    "fast": ["Tap the glowing targets as quickly as you can.", "Build your score before the timer runs out. Smaller targets appear later."],
    "merge": ["Swipe to slide tiles across the board.", "Matching numbers combine. Make bigger merges to reach the level goal."],
    "stack": ["Tap to drop each moving block onto the tower.", "Line up the edges carefully. Perfect drops help you build higher."],
    "memory": ["Tap two cards to reveal their pictures.", "Remember where each picture is and find every matching pair."],
    "whack": ["Tap the moles when they pop out of their holes.", "Avoid the snakes! Earn enough points before the 20-second round ends."],
    "sort": ["Tap a tube, then another tube, to pour its top color.", "Group matching colors together until each tube contains only one color."],
    "snake": ["Swipe to steer your glowing snake around the grid.", "Collect stars to grow and score. Avoid walls and your own tail."],
    "dots": ["Drag a path between two dots of the same color.", "Connect every pair without crossing another path."],
    "hopper": ["Steer your character onto the floating platforms.", "Keep climbing and collecting stars. Watch where the next platform appears."],
    "rhythm": ["Tap the lane when a note enters the glowing catch zone.", "Each successful hit plays part of the melody. Keep the rhythm to finish the song!"]
}

func _ready():
    rng.randomize()
    _load_save()
    sound_player = AudioStreamPlayer.new()
    sound_player.volume_db = -11.0
    add_child(sound_player)
    _shell()
    home()

func _input(event: InputEvent) -> void:
    # Handle finger swipes globally while browsing the lobby/library, even when
    # a child button, artwork or card captures the touch event.
    if not lobby_touch_scrolling or not is_instance_valid(lobby_scroll):
        return
    if event is InputEventScreenDrag:
        lobby_scroll.scroll_vertical -= int(event.relative.y)
        get_viewport().set_input_as_handled()

func _shell():
    tutorial_overlay = null
    lobby_touch_scrolling = true
    for c in get_children():
        if c != sound_player:
            c.queue_free()
    var bg := ColorRect.new()
    bg.color = BG
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    # Subtle arcade-style corner lights behind the interface.
    for deco in [{"pos": Vector2(-90, 150), "size": Vector2(250, 250), "color": Color("#8b5cf6", 0.08)}, {"pos": Vector2(500, 540), "size": Vector2(280, 280), "color": Color("#22d3ee", 0.05)}]:
        var glow := ColorRect.new()
        glow.position = deco.pos
        glow.size = deco.size
        glow.color = deco.color
        glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(glow)
    # Keep the interface comfortably inset from the screen edges on phones.
    # This is a visual safety margin; browser safe-area behavior is also tested
    # separately on the actual iPhone.
    var outer := MarginContainer.new()
    outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outer.add_theme_constant_override("margin_left", 16)
    outer.add_theme_constant_override("margin_right", 16)
    outer.add_theme_constant_override("margin_top", 12)
    outer.add_theme_constant_override("margin_bottom", 16)
    add_child(outer)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 0)
    outer.add_child(root)
    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 82
    root.add_child(header)
    var brand := VBoxContainer.new()
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(brand)
    var logo := Label.new()
    logo.text = "MINIVERSE"
    logo.add_theme_font_size_override("font_size", 30)
    logo.add_theme_color_override("font_shadow_color", Color("#7c3aed"))
    logo.add_theme_constant_override("shadow_offset_x", 2)
    logo.add_theme_constant_override("shadow_offset_y", 3)
    logo.add_theme_color_override("font_color", Color("#ffda78"))
    brand.add_child(logo)
    var subtitle := Label.new()
    subtitle.text = "A UNIVERSE OF QUICK FUN"
    subtitle.add_theme_font_size_override("font_size", 10)
    subtitle.add_theme_color_override("font_color", MUTED)
    brand.add_child(subtitle)
    var wallet_group := HBoxContainer.new()
    wallet_group.alignment = BoxContainer.ALIGNMENT_END
    wallet_group.add_theme_constant_override("separation", 5)
    header.add_child(wallet_group)
    var coin_icon := TextureRect.new()
    coin_icon.texture = preload("res://assets/ui/coin.png")
    coin_icon.custom_minimum_size = Vector2(27, 27)
    coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    wallet_group.add_child(coin_icon)
    var wallet := Label.new()
    wallet.text = "%d" % coins
    wallet.add_theme_font_size_override("font_size", 18)
    wallet.add_theme_color_override("font_color", Color("#fcd34d"))
    wallet_group.add_child(wallet)
    var line := ColorRect.new()
    line.color = Color("#2a2f52")
    line.custom_minimum_size.y = 2
    root.add_child(line)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    # Hide the skinny scrollbar; the entire content area is swipeable.
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
    # Global finger-drag handling prevents buttons and cards blocking swipes.
    scroll.scroll_deadzone = 0
    lobby_scroll = scroll
    root.add_child(scroll)
    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 16)
    content.add_theme_constant_override("margin_left", 20)
    content.add_theme_constant_override("margin_right", 20)
    content.add_theme_constant_override("margin_top", 20)
    content.add_theme_constant_override("margin_bottom", 28)
    scroll.add_child(content)

func _style(color: Color, radius := 14) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.corner_radius_top_left = radius
    s.corner_radius_top_right = radius
    s.corner_radius_bottom_left = radius
    s.corner_radius_bottom_right = radius
    s.content_margin_left = 12
    s.content_margin_right = 12
    s.content_margin_top = 10
    s.content_margin_bottom = 10
    return s

func _lobby_button_style(color: Color) -> StyleBoxFlat:
    var style := _style(color, 20)
    style.border_width_left = 2
    style.border_width_right = 2
    style.border_width_top = 2
    style.border_width_bottom = 3
    style.border_color = color.lightened(0.35)
    style.shadow_color = Color("#050922", 0.6)
    style.shadow_size = 5
    style.shadow_offset = Vector2(0, 4)
    return style

func _lobby_card_style(accent: Color) -> StyleBoxFlat:
    var style := _style(Color("#172858"), 20)
    style.border_width_left = 2
    style.border_width_right = 2
    style.border_width_top = 2
    style.border_width_bottom = 2
    style.border_color = accent.darkened(0.12)
    style.shadow_color = Color("#030a26", 0.6)
    style.shadow_size = 5
    style.shadow_offset = Vector2(0, 4)
    return style

func _button(text: String, cb: Callable, color := ACCENT, height := 56) -> Button:
    var b := Button.new()
    b.text = text
    # Let touch drags on a button reach the surrounding ScrollContainer.
    # Taps still activate the button normally.
    b.mouse_filter = Control.MOUSE_FILTER_PASS
    # Keep every interactive button comfortably tappable on phones.
    b.custom_minimum_size.y = maxi(height, 52)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 17)
    b.add_theme_color_override("font_color", Color("#17172b") if color == ACCENT or color == Color("#fbbf24") else TEXT)
    b.add_theme_stylebox_override("normal", _lobby_button_style(color))
    b.add_theme_stylebox_override("hover", _lobby_button_style(color.lightened(0.12)))
    b.add_theme_stylebox_override("pressed", _lobby_button_style(color.darkened(0.12)))
    b.add_theme_stylebox_override("focus", _style(color.lightened(0.18)))
    b.add_theme_constant_override("outline_size", 0)
    b.pressed.connect(func():
        _play_sound(SFX_TAP)
        cb.call()
    )
    TouchFeedback.attach(b)
    return b

func _play_sound(stream: AudioStream) -> void:
    if sound_enabled and is_instance_valid(sound_player):
        sound_player.stream = stream
        sound_player.play()

func _heading(title: String, subtitle := ""):
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 4)
    content.add_child(box)
    var t := Label.new()
    t.text = title
    t.add_theme_font_size_override("font_size", 27)
    t.add_theme_color_override("font_color", TEXT)
    box.add_child(t)
    if subtitle != "":
        var s := Label.new()
        s.text = subtitle
        s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        s.add_theme_color_override("font_color", MUTED)
        box.add_child(s)

func _card(title: String, body: String) -> PanelContainer:
    var p := PanelContainer.new()
    p.add_theme_stylebox_override("panel", _style(PANEL, 18))
    content.add_child(p)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 6)
    p.add_child(v)
    var t := Label.new()
    t.text = title
    t.add_theme_font_size_override("font_size", 18)
    t.add_theme_color_override("font_color", TEXT)
    v.add_child(t)
    var d := Label.new()
    d.text = body
    d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    d.add_theme_color_override("font_color", MUTED)
    v.add_child(d)
    return p

func home():
    Difficulty.clear_retry_level(game_id)
    _shell()
    # Mobile-first welcome panel with custom procedural fantasy artwork.
    var hero := PanelContainer.new()
    var hero_style := StyleBoxFlat.new()
    hero_style.bg_color = Color("#243a82")
    hero.add_theme_stylebox_override("panel", hero_style)
    content.add_child(hero)
    var hero_box := VBoxContainer.new()
    hero_box.add_theme_constant_override("separation", 0)
    hero.add_child(hero_box)
    var art := HomeHero.new()
    art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero_box.add_child(art)
    var welcome := VBoxContainer.new()
    welcome.add_theme_constant_override("separation", 5)
    welcome.add_theme_constant_override("margin_left", 12)
    welcome.add_theme_constant_override("margin_right", 12)
    welcome.add_theme_constant_override("margin_top", 12)
    welcome.add_theme_constant_override("margin_bottom", 14)
    hero_box.add_child(welcome)
    var title := Label.new()
    title.text = "SMALL GAMES. BIG FUN."
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color("#fff2a8"))
    welcome.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "Pick a game, beat your best, earn rewards!"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.add_theme_color_override("font_color", Color("#e1e7ff"))
    welcome.add_child(subtitle)
    content.add_child(_button("▶  PLAY A RANDOM GAME", _random_game, Color("#36e58a"), 60))
    content.add_child(_button("☀  PLAY TODAY'S CHALLENGE", _daily_challenge, Color("#fbbf24"), 54))
    _heading("Recently Played", "Your last three games, ready to jump back into.")
    var shown := 0
    for recent_id in recent_games:
        var recent_game := _game_data(recent_id)
        if not recent_game.is_empty() and shown < 3:
            content.add_child(_game_card(recent_game))
            shown += 1
    if shown == 0:
        _card("YOUR ADVENTURE STARTS HERE", "Play a game from the library and your three most recently played games will appear here.")
    content.add_child(_button("▦  OPEN GAME LIBRARY", library, Color("#344a9b")))
    content.add_child(_button("🏆  CHALLENGES & EVENTS", events, Color("#344a9b")))
    content.add_child(_button("⚙  SETTINGS", settings, Color("#344a9b")))
    _card("YOUR PROGRESS", "Level %d  ·  %d XP  ·  %d coins  ·  %d personal records" % [level, xp, coins, best_scores.size()])

func _game_card(g: Dictionary) -> PanelContainer:
    var card := PanelContainer.new()
    card.custom_minimum_size.y = 126
    card.add_theme_stylebox_override("panel", _lobby_card_style(g.color))
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    card.add_child(row)

    var preview := GamePreview.new()
    preview.game_id = g.id
    preview.accent = g.color
    preview.custom_minimum_size = Vector2(94, 98)
    preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(preview)

    var detail := VBoxContainer.new()
    detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    detail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    detail.add_theme_constant_override("separation", 3)
    row.add_child(detail)
    var name := Label.new()
    name.text = g.title
    name.add_theme_font_size_override("font_size", 17)
    name.add_theme_color_override("font_color", TEXT)
    detail.add_child(name)
    var genre := Label.new()
    genre.text = g.genre
    genre.add_theme_font_size_override("font_size", 10)
    genre.add_theme_color_override("font_color", g.color)
    detail.add_child(genre)
    var progress_row := HBoxContainer.new()
    progress_row.add_theme_constant_override("separation", 3)
    detail.add_child(progress_row)
    var progress := Label.new()
    progress.text = "LEVEL %d   BEST" % Difficulty.level(str(g.id))
    progress.add_theme_font_size_override("font_size", 11)
    progress.add_theme_color_override("font_color", Color("#ffe29e"))
    progress_row.add_child(progress)
    for star_index in range(3):
        var star_icon := TextureRect.new()
        star_icon.texture = preload("res://assets/ui/star_filled.png") if star_index < int(best_stars.get(str(g.id), 0)) else preload("res://assets/ui/star_empty.png")
        star_icon.custom_minimum_size = Vector2(13, 13)
        star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        progress_row.add_child(star_icon)
    var desc := Label.new()
    desc.text = g.desc
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.add_theme_font_size_override("font_size", 11)
    desc.add_theme_color_override("font_color", MUTED)
    detail.add_child(desc)
    var best := Label.new()
    best.text = "BEST  %d" % int(best_scores.get(g.id, 0))
    best.add_theme_font_size_override("font_size", 10)
    best.add_theme_color_override("font_color", Color("#fcd34d"))
    detail.add_child(best)

    var play := _button("PLAY", func(): launch(g.id), g.color, 44)
    play.custom_minimum_size.x = 74
    play.size_flags_horizontal = Control.SIZE_SHRINK_END
    play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(play)
    return card

func library():
    _shell()
    _heading("Game Library", "10 games · Find your next favorite.")
    var filters := HFlowContainer.new()
    filters.add_theme_constant_override("h_separation", 6)
    filters.add_theme_constant_override("v_separation", 8)
    content.add_child(filters)
    for category in ["ALL", "ARCADE", "PUZZLE", "TIMING", "RELAXING"]:
        var chip := _button(category, func():
            library_filter = category
            library()
        , Color("#a78bfa") if library_filter == category else Color("#344a76"), 44)
        chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        chip.add_theme_font_size_override("font_size", 13)
        filters.add_child(chip)
    var count := 0
    for g in GAMES:
        if _matches_filter(g, library_filter):
            content.add_child(_game_card(g))
            count += 1
    _card("%d GAMES" % count, "Choose any game to play instantly.")
    content.add_child(_button("BACK TO HOME", home, PANEL2))

func _matches_filter(g: Dictionary, category: String) -> bool:
    if category == "ALL":
        return true
    var id: String = str(g.id)
    match category:
        "ARCADE": return id in ["fast", "whack", "snake", "hopper"]
        "PUZZLE": return id in ["merge", "memory", "sort", "dots"]
        "TIMING": return id in ["stack", "rhythm", "fast"]
        "RELAXING": return id in ["memory", "sort", "dots", "merge"]
    return true

func events():
    _shell()
    _heading("Challenges & Events", "Event previews for the growing MiniVerse.")
    var day_key := int(Time.get_unix_time_from_system() / 86400.0)
    var challenge_ids := ["fast", "merge", "stack", "memory", "whack", "sort", "snake", "dots", "hopper", "rhythm"]
    var challenge_id: String = challenge_ids[day_key % challenge_ids.size()]
    _card("☀ DAILY DASH", "Today's featured game: %s. Finish a round to earn coins and XP." % _game_name(challenge_id))
    content.add_child(_button("▶  PLAY DAILY CHALLENGE", _daily_challenge, Color("#fbbf24")))
    _card("🏆 MINIVERSE CUP", "Weekly score competitions will rotate between mini-games after an online backend is added.")
    _card("✦ MINIVERSE FESTIVAL", "Seasonal themes, cosmetic rewards, and special games are planned for future versions.")
    content.add_child(_button("← BACK TO HOME", home, PANEL2))

func settings():
    _shell()
    _heading("Settings", "Local starter build settings.")
    _card("SAVE DATA", "Progress is stored on this device in Godot's user data folder.")
    content.add_child(_button("SOUND EFFECTS: ON" if sound_enabled else "SOUND EFFECTS: OFF", _toggle_sound, Color("#344a9b")))
    _card("TUTORIALS", "Each game's instructions appear the first time you play. You can review them any time.")
    content.add_child(_button("REPLAY GAME TUTORIALS", _tutorial_menu, Color("#344a9b")))
    _card("LEVEL TESTING", "Reset a single game's level to 1 without losing coins, XP, or progress in other games.")
    content.add_child(_button("RESET MEMORY MATCH LEVEL", func(): _reset_game_level("memory"), Color("#344a9b")))
    content.add_child(_button("CHOOSE ANOTHER GAME TO RESET", _reset_level_menu, Color("#344a9b")))
    content.add_child(_button("RESET ALL GAME LEVELS", _confirm_reset_levels, Color("#f9738f")))
    content.add_child(_button("RESET LOCAL PROGRESS", _confirm_reset_progress, Color("#f9738f")))
    content.add_child(_button("← BACK TO HOME", home, PANEL2))

func _tutorial_menu() -> void:
    _shell()
    _heading("Game Tutorials", "Choose a game to review its instructions before playing.")
    for g in GAMES:
        var id: String = str(g.id)
        content.add_child(_button("HOW TO PLAY: %s" % str(g.title), func(): _replay_tutorial(id), Color("#344a9b")))
    content.add_child(_button("BACK TO SETTINGS", settings, PANEL2))

func _replay_tutorial(id: String) -> void:
    seen_tutorials.erase(id)
    _save()
    launch(id)

func _toggle_sound() -> void:
    sound_enabled = not sound_enabled
    _save()
    settings()

func _reset_game_level(id: String) -> void:
    Difficulty.reset_game(id)
    best_stars.erase(id)
    _save()
    settings()

func _reset_level_menu() -> void:
    _shell()
    _heading("Reset a Game Level", "Only the selected game's level and stars will reset.")
    for g in GAMES:
        var id: String = str(g.id)
        content.add_child(_button("%s  •  Level %d" % [str(g.title), Difficulty.level(id)], func(): _reset_game_level(id), Color("#344a9b")))
    content.add_child(_button("← BACK TO SETTINGS", settings, PANEL2))

func _confirm_reset_levels() -> void:
    _shell()
    _heading("Reset All Levels?", "All ten games return to Level 1. Coins, XP and high scores stay.")
    content.add_child(_button("YES, RESET ALL LEVELS", _reset_all_levels, Color("#f9738f")))
    content.add_child(_button("CANCEL", settings, PANEL2))

func _reset_all_levels() -> void:
    Difficulty.reset_all()
    best_stars.clear()
    _save()
    settings()

func _confirm_reset_progress() -> void:
    _shell()
    _heading("Erase Local Progress?", "This will clear coins, XP, scores, stars and all game levels.")
    content.add_child(_button("YES, ERASE EVERYTHING", reset_progress, Color("#f9738f")))
    content.add_child(_button("CANCEL", settings, PANEL2))

func reset_progress():
    coins = 0
    xp = 0
    level = 1
    best_scores = {}
    best_stars = {}
    recent_games.clear()
    seen_tutorials.clear()
    Difficulty.reset_all()
    _save()
    settings()

func _random_game():
    launch(GAMES[rng.randi_range(0, GAMES.size()-1)].id)

func launch(id: String):
    if game_id != id:
        Difficulty.clear_retry_level(game_id)
    _play_sound(SFX_START)
    game_id = id
    recent_games.erase(id)
    recent_games.push_front(id)
    while recent_games.size() > 3:
        recent_games.pop_back()
    _save()
    match id:
        "fast": _play_fast()
        "merge": _play_merge()
        "stack": _play_stack()
        "memory": _play_memory()
        "whack": _play_whack()
        "sort": _play_sort()
        "snake": _play_snake()
        "dots": _play_dots()
        "hopper": _play_hopper()
        "rhythm": _play_rhythm()
    if not bool(seen_tutorials.get(id, false)):
        _show_tutorial(id)

func _show_tutorial(id: String) -> void:
    if is_instance_valid(tutorial_overlay):
        tutorial_overlay.queue_free()
    # Freeze gameplay until the player dismisses the tutorial.
    if is_instance_valid(game_root):
        game_root.process_mode = Node.PROCESS_MODE_DISABLED
    var layer := Control.new()
    tutorial_overlay = layer
    layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.mouse_filter = Control.MOUSE_FILTER_STOP
    layer.z_index = 100
    add_child(layer)
    var shade := ColorRect.new()
    shade.color = Color(0.02, 0.04, 0.13, 0.88)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    layer.add_child(shade)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_STOP
    layer.add_child(center)
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(280, 0)
    panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    panel.add_theme_stylebox_override("panel", _style(PANEL, 20))
    center.add_child(panel)
    var margins := MarginContainer.new()
    for side in ["left", "right", "top", "bottom"]:
        margins.add_theme_constant_override("margin_" + side, 20)
    panel.add_child(margins)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 16)
    margins.add_child(body)
    var heading := Label.new()
    heading.text = "HOW TO PLAY"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 18)
    heading.add_theme_color_override("font_color", CYAN)
    body.add_child(heading)
    var name_label := Label.new()
    name_label.text = _game_name(id)
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 25)
    name_label.add_theme_color_override("font_color", TEXT)
    body.add_child(name_label)
    # Reuse the same illustrated artwork as the game cards so each tutorial
    # visually demonstrates which game the player is about to learn.
    var preview_frame := PanelContainer.new()
    preview_frame.custom_minimum_size = Vector2(240, 136)
    preview_frame.add_theme_stylebox_override("panel", _style(PANEL2, 16))
    body.add_child(preview_frame)
    var preview_holder := CenterContainer.new()
    preview_frame.add_child(preview_holder)
    var preview := GamePreview.new()
    preview.game_id = id
    preview.custom_minimum_size = Vector2(212, 116)
    preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    preview_holder.add_child(preview)
    # A gentle motion draws attention to the illustration without obscuring
    # instructions or requiring touch interactions.
    var motion := create_tween().set_loops()
    motion.tween_property(preview, "modulate:a", 0.72, 0.85)
    motion.tween_property(preview, "modulate:a", 1.0, 0.85)
    for instruction in TUTORIALS.get(id, []):
        var label := Label.new()
        label.text = str(instruction)
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.custom_minimum_size.x = 240
        label.add_theme_font_size_override("font_size", 17)
        label.add_theme_color_override("font_color", TEXT)
        body.add_child(label)
    # First interactive lessons: players practice the core action before
    # starting Fast Fingers and Memory Match. Other games retain their
    # illustrated instructions while their practice interactions are built.
    if id == "fast":
        _tutorial_fast_practice(body, id)
    elif id == "memory":
        _tutorial_memory_practice(body, id)
    elif id == "merge" or id == "snake":
        _tutorial_swipe_practice(body, id)
    elif id == "stack" or id == "rhythm":
        _tutorial_timing_practice(body, id)
    elif id == "whack":
        _tutorial_whack_practice(body, id)
    elif id == "sort":
        _tutorial_sort_practice(body, id)
    elif id == "dots":
        _tutorial_dots_practice(body, id)
    elif id == "hopper":
        _tutorial_hopper_practice(body, id)
    else:
        body.add_child(_button("LET'S PLAY!", func(): _dismiss_tutorial(id), ACCENT, 60))

func _tutorial_fast_practice(body: VBoxContainer, id: String) -> void:
    var prompt := Label.new()
    prompt.text = "PRACTICE: Tap the target three times!"
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    prompt.add_theme_color_override("font_color", CYAN)
    body.add_child(prompt)
    var target := _button("TAP TARGET  (0/3)", func(): pass, Color("#f9738f"), 64)
    body.add_child(target)
    var start := _button("LET'S PLAY!", func(): _dismiss_tutorial(id), ACCENT, 60)
    start.disabled = true
    body.add_child(start)
    var taps := [0]
    target.pressed.connect(func():
        taps[0] += 1
        target.text = "TAP TARGET  (%d/3)" % mini(taps[0], 3)
        if taps[0] >= 3:
            target.disabled = true
            prompt.text = "Great tapping! You're ready to play."
            start.disabled = false
    )

func _tutorial_memory_practice(body: VBoxContainer, id: String) -> void:
    var prompt := Label.new()
    prompt.text = "PRACTICE: Flip both matching cards!"
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    prompt.add_theme_color_override("font_color", CYAN)
    body.add_child(prompt)
    var cards := HBoxContainer.new()
    cards.alignment = BoxContainer.ALIGNMENT_CENTER
    body.add_child(cards)
    var start := _button("LET'S PLAY!", func(): _dismiss_tutorial(id), ACCENT, 60)
    start.disabled = true
    var flipped := [false, false]
    for i in range(2):
        var index: int = i
        var card := _button("?", func(): pass, Color("#34d399"), 68)
        card.custom_minimum_size.x = 92
        cards.add_child(card)
        card.pressed.connect(func():
            if flipped[index]:
                return
            flipped[index] = true
            card.text = ""
            card.icon = preload("res://assets/memory_symbols/sun.png")
            card.expand_icon = true
            card.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
            card.disabled = true
            if flipped[0] and flipped[1]:
                prompt.text = "Matching pair found! You're ready."
                start.disabled = false
        )
    body.add_child(start)

func _tutorial_swipe_practice(body: VBoxContainer, id: String) -> void:
    var prompt := Label.new()
    prompt.text = "PRACTICE: Swipe LEFT, then RIGHT in the box!"
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    prompt.add_theme_color_override("font_color", CYAN)
    body.add_child(prompt)

    var practice := PanelContainer.new()
    practice.custom_minimum_size = Vector2(240, 118)
    practice.add_theme_stylebox_override("panel", _style(PANEL2, 16))
    practice.mouse_filter = Control.MOUSE_FILTER_STOP
    body.add_child(practice)
    var hint := Label.new()
    hint.text = "DRAG  <    >"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hint.add_theme_font_size_override("font_size", 23)
    hint.add_theme_color_override("font_color", Color("#67e8f9"))
    practice.add_child(hint)

    var start := _button("LET'S PLAY!", func(): _dismiss_tutorial(id), ACCENT, 60)
    start.disabled = true
    body.add_child(start)

    var stage := [0]
    var start_position := [Vector2.ZERO]
    var dragging := [false]
    practice.gui_input.connect(func(event: InputEvent):
        var released := false
        var position := Vector2.ZERO
        if event is InputEventScreenTouch:
            position = event.position
            if event.pressed:
                dragging[0] = true
                start_position[0] = position
            else:
                released = true
        elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
            position = event.position
            if event.pressed:
                dragging[0] = true
                start_position[0] = position
            else:
                released = true
        if released and dragging[0]:
            dragging[0] = false
            var delta: Vector2 = position - start_position[0]
            if absf(delta.x) < 45.0 or absf(delta.x) < absf(delta.y):
                return
            if stage[0] == 0 and delta.x < 0.0:
                stage[0] = 1
                hint.text = "LEFT DONE!  Now swipe RIGHT"
                prompt.text = "Great! Now swipe to the right."
            elif stage[0] == 1 and delta.x > 0.0:
                stage[0] = 2
                hint.text = "BOTH SWIPES COMPLETE!"
                prompt.text = "Well done! You're ready to play."
                start.disabled = false
    )

func _tutorial_timing_practice(body: VBoxContainer, id: String) -> void:
    var prompt := Label.new()
    prompt.text = "PRACTICE: Tap when the moving marker is in the middle!"
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    prompt.add_theme_color_override("font_color", CYAN)
    body.add_child(prompt)

    var caption := Label.new()
    caption.text = "        |      HIT ZONE      |"
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    caption.add_theme_color_override("font_color", Color("#facc15"))
    body.add_child(caption)

    var meter := ProgressBar.new()
    meter.custom_minimum_size = Vector2(240, 32)
    meter.min_value = 0.0
    meter.max_value = 100.0
    meter.value = 0.0
    meter.show_percentage = false
    body.add_child(meter)
    var travel := create_tween().set_loops()
    travel.tween_property(meter, "value", 100.0, 1.4)
    travel.tween_property(meter, "value", 0.0, 1.4)

    var attempts := [0]
    var hits := [0]
    var tap := _button("TAP TO TIME YOUR HIT", func(): pass, Color("#f9738f"), 60)
    body.add_child(tap)
    var start := _button("LET'S PLAY!", func(): _dismiss_tutorial(id), ACCENT, 60)
    start.disabled = true
    body.add_child(start)
    tap.pressed.connect(func():
        attempts[0] += 1
        if meter.value >= 38.0 and meter.value <= 62.0:
            hits[0] += 1
            prompt.text = "PERFECT TIMING! You are ready to play."
            tap.disabled = true
            start.disabled = false
            travel.kill()
        else:
            prompt.text = "Not quite! Watch the marker and try again."
    )

func _tutorial_whack_practice(body: VBoxContainer, id: String) -> void:
    var prompt := _practice_prompt(body, "PRACTICE: Tap the mole when it appears!")
    var mole := _button("MOLE!", func(): pass, Color("#f59e0b"), 66)
    body.add_child(mole)
    var start := _practice_start(body, id)
    mole.pressed.connect(func():
        mole.text = "GREAT HIT!"
        mole.disabled = true
        prompt.text = "Nice! Tap the moles quickly in the real game."
        start.disabled = false
    )


func _tutorial_sort_practice(body: VBoxContainer, id: String) -> void:
    var prompt := _practice_prompt(body, "PRACTICE: Move the red ball into its matching tube.")
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    body.add_child(row)
    var source := _button("RED BALL", func(): pass, Color("#ef4444"), 68)
    var target := _button("RED TUBE", func(): pass, Color("#be123c"), 68)
    row.add_child(source)
    row.add_child(target)
    target.disabled = true
    var start := _practice_start(body, id)
    source.pressed.connect(func():
        source.text = "EMPTY"
        source.disabled = true
        target.disabled = false
        prompt.text = "Now tap the red tube to place the ball!"
    )
    target.pressed.connect(func():
        target.text = "MATCH!"
        target.disabled = true
        prompt.text = "Perfect! Group matching colors together."
        start.disabled = false
    )


func _tutorial_dots_practice(body: VBoxContainer, id: String) -> void:
    var prompt := _practice_prompt(body, "PRACTICE: Drag from the left blue dot to the right blue dot. Keep your finger down!")
    var board := preload("res://scripts/tutorial_dots_drag.gd").new()
    board.custom_minimum_size = Vector2(240, 112)
    board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_child(board)
    var start := _practice_start(body, id)
    board.completed.connect(func():
        prompt.text = "Great connection! In the game, drag between matching colors without crossing paths."
        start.disabled = false
    )


func _tutorial_hopper_practice(body: VBoxContainer, id: String) -> void:
    var prompt := _practice_prompt(body, "PRACTICE: Tap to jump over three obstacles!")
    var jump := _button("TAP TO JUMP  (0/3)", func(): pass, Color("#a78bfa"), 66)
    body.add_child(jump)
    var start := _practice_start(body, id)
    var jumps := [0]
    jump.pressed.connect(func():
        jumps[0] += 1
        jump.text = "TAP TO JUMP  (%d/3)" % mini(jumps[0], 3)
        if jumps[0] >= 3:
            jump.disabled = true
            prompt.text = "Three jumps! You're ready to hop."
            start.disabled = false
    )


func _practice_prompt(body: VBoxContainer, message: String) -> Label:
    var prompt := Label.new()
    prompt.text = message
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    prompt.add_theme_color_override("font_color", CYAN)
    body.add_child(prompt)
    return prompt


func _practice_start(body: VBoxContainer, id: String) -> Button:
    var start := _button("LET'S PLAY!", func(): _dismiss_tutorial(id), ACCENT, 60)
    start.disabled = true
    body.add_child(start)
    return start


func _dismiss_tutorial(id: String) -> void:
    seen_tutorials[id] = true
    _save()
    if is_instance_valid(game_root):
        game_root.process_mode = Node.PROCESS_MODE_INHERIT
    if is_instance_valid(tutorial_overlay):
        tutorial_overlay.queue_free()
    tutorial_overlay = null

func _gameplay_sound(kind: String) -> void:
    match kind:
        "collect": _play_sound(SFX_COLLECT)
        "pour": _play_sound(SFX_POUR)
        "connect": _play_sound(SFX_CONNECT)
        "oops": _play_sound(SFX_OOPS)

func _mount_game(g: Control):
    if g.has_signal("gameplay_sound"):
        g.connect("gameplay_sound", _gameplay_sound)
    _shell()
    lobby_touch_scrolling = false
    game_root = g
    # Shared progress header across all ten games.
    var progress_header := Label.new()
    progress_header.text = "%s  •  LEVEL %d" % [_game_name(game_id).to_upper(), Difficulty.level(game_id)]
    progress_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress_header.add_theme_font_size_override("font_size", 17)
    progress_header.add_theme_color_override("font_color", Color("#ffe29e"))
    content.add_child(progress_header)
    # Keep a visible way back to the lobby while playing any mini-game.
    content.add_child(_button("←  RETURN TO LOBBY", home, PANEL2, 46))
    # ScrollContainer content must have a real minimum height; otherwise nested
    # game controls can collapse to almost zero height on mobile-sized viewports.
    g.custom_minimum_size = Vector2(0, 820)
    content.add_child(g)
    g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    g.size_flags_vertical = Control.SIZE_EXPAND_FILL
    call_deferred("_attach_gameplay_sparkles", g)

func _attach_gameplay_sparkles(g: Control) -> void:
    if not is_instance_valid(g) or not g.is_inside_tree():
        return
    var effect: Control = GameplaySparkles.new()
    effect.set("tracked_game", g)
    effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    g.add_child(effect)
    effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _play_fast():
    var g := FastFingers.new()
    g.finished.connect(_finished)
    _mount_game(g)
    g.start_game()

func _play_merge():
    var g := NumberMerge.new()
    g.finished.connect(_finished)
    _mount_game(g)
    g.start_game()

func _play_stack():
    var g := PerfectStack.new()
    g.finished.connect(_finished)
    _mount_game(g)
    g.start_game()

func _play_memory():
    var g := MemoryMatch.new()
    g.finished.connect(_finished)
    _mount_game(g)
    g.start_game()

func _play_whack():
    var g := WhackAMole.new()
    g.finished.connect(_finished)
    _mount_game(g)
    g.start_game()

func _play_sort():
    var g := ColorSort.new()
    g.finished.connect(_finished)
    _mount_game(g)
    g.start_game()

func _play_snake():
    var g := NeonSnake.new()
    g.finished.connect(_finished)
    _mount_game(g)
    # Snake needs a wider touch arena than the standard game cards.
    content.add_theme_constant_override("margin_left", 2)
    content.add_theme_constant_override("margin_right", 2)
    g.start_game()

func _play_dots():
    var g := ConnectDots.new()
    g.finished.connect(_finished)
    _mount_game(g)
    g.start_game()

func _play_hopper():
    var g := SkyHopper.new()
    g.finished.connect(_finished)
    _mount_game(g)
    g.start_game()

func _play_rhythm():
    var g := RhythmRush.new()
    g.sound_enabled = sound_enabled
    g.finished.connect(_finished)
    _mount_game(g)
    g.start_game()

func _daily_challenge():
    # Local daily rotation; does not require an online backend.
    var day_key := int(Time.get_unix_time_from_system() / 86400.0)
    var challenge_ids := ["fast", "merge", "stack", "memory", "whack", "sort", "snake", "dots", "hopper", "rhythm"]
    launch(challenge_ids[day_key % challenge_ids.size()])

# The first five levels use explicit achievable score goals. Later goals
# increase gradually. Puzzle completion is its own success condition.
func _level_goal(id: String, played_level: int) -> int:
    # Hand-balanced introductory goals for the three reflex/timing games.
    var first_five := {
        "fast": [30, 50, 75, 105, 135],
        "stack": [2, 3, 4, 5, 6],
        "whack": [35, 50, 65, 85, 105],
        "merge": [16, 32, 48, 72, 96],
        "rhythm": [350, 650, 950, 1300, 1650]
    }
    if first_five.has(id) and played_level <= 5:
        return int(first_five[id][played_level - 1])
    var base_goals := {"fast": 135, "merge": 24, "stack": 6, "whack": 105, "snake": 3, "hopper": 3, "rhythm": 1650}
    var base: int = int(base_goals.get(id, 1))
    var step: int = maxi(0, played_level - (5 if first_five.has(id) else 1))
    return maxi(1, int(round(float(base) * (1.0 + 0.10 * float(step)))))

func _finished(id: String, score: int, extra: Dictionary = {}):
    var previous_best: int = int(best_scores.get(id, 0))
    var played_level: int = Difficulty.level(id)
    var goal: int = _level_goal(id, played_level)
    var puzzle_completion: bool = id in ["memory", "sort", "dots"]
    var passed: bool = puzzle_completion or score >= goal
    var stars_earned: int = 1
    if passed:
        stars_earned = 3 if puzzle_completion or score >= int(ceil(float(goal) * 1.6)) else 2
        Difficulty.complete(id)
    var record: bool = score > previous_best
    best_stars[id] = maxi(int(best_stars.get(id, 0)), stars_earned)
    if record:
        best_scores[id] = score
    var reward: int = clampi(5 + int(sqrt(float(maxi(score, 0))) * 1.8), 5, 75)
    var earned_xp: int = clampi(10 + int(sqrt(float(maxi(score, 0))) * 2.5), 10, 110)
    coins += reward
    xp += earned_xp
    level = int(xp / 100) + 1
    _save()
    _play_sound(SFX_WIN if passed else SFX_OOPS)
    _results(id, score, reward, record, earned_xp, stars_earned, played_level, goal, passed)

# Full recordings of the original level melodies. Only play after a successful clear.
const RHYTHM_COMPLETION_SONGS := [
    preload("res://assets/sfx/rhythm_song_1.wav"),
    preload("res://assets/sfx/rhythm_song_2.wav"),
    preload("res://assets/sfx/rhythm_song_3.wav"),
    preload("res://assets/sfx/rhythm_song_4.wav"),
    preload("res://assets/sfx/rhythm_song_5.wav")
]

func _play_completed_rhythm_song(played_level: int) -> void:
    if not sound_enabled:
        return
    var melody_player := AudioStreamPlayer.new()
    melody_player.stream = RHYTHM_COMPLETION_SONGS[clampi(played_level - 1, 0, RHYTHM_COMPLETION_SONGS.size() - 1)]
    melody_player.volume_db = -7.0
    content.add_child(melody_player)
    melody_player.play()

func _results(id: String, score: int, reward: int, record: bool, earned_xp: int, stars_earned: int, played_level: int, goal: int, passed: bool):
    _shell()
    _heading("Level Complete!" if passed else "Try Again!", "Level %d • %s" % [played_level, "Goal reached!" if passed else "You can retry this level."])
    var celebration := PanelContainer.new()
    celebration.add_theme_stylebox_override("panel", _style(Color("#25234e"), 22))
    content.add_child(celebration)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 9)
    celebration.add_child(column)
    var stars_row := HBoxContainer.new()
    stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
    stars_row.add_theme_constant_override("separation", 10)
    column.add_child(stars_row)
    for star_index in range(3):
        var star_icon := TextureRect.new()
        star_icon.texture = preload("res://assets/ui/star_filled.png") if star_index < stars_earned else preload("res://assets/ui/star_empty.png")
        star_icon.custom_minimum_size = Vector2(52, 52)
        star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        stars_row.add_child(star_icon)
    var title := Label.new()
    title.text = "NEW PERSONAL BEST!" if record else ("LEVEL CLEARED!" if passed else "KEEP PRACTICING!")
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 23)
    title.add_theme_color_override("font_color", Color("#8eeaff") if record else TEXT)
    column.add_child(title)
    var result := Label.new()
    result.text = "%s  •  LEVEL %d\n\nSCORE  %d  /  GOAL %d\n\n+%d COINS     +%d XP" % [_game_name(id), played_level, score, goal, reward, earned_xp]
    result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result.add_theme_font_size_override("font_size", 21)
    result.add_theme_color_override("font_color", TEXT)
    column.add_child(result)
    # A visual goal meter helps players understand how close they were.
    if id not in ["memory", "sort", "dots"]:
        var goal_meter := ProgressBar.new()
        goal_meter.custom_minimum_size = Vector2(0, 24)
        goal_meter.min_value = 0.0
        goal_meter.max_value = 100.0
        goal_meter.value = clampf(float(score) / float(maxi(goal, 1)) * 100.0, 0.0, 100.0)
        goal_meter.show_percentage = false
        column.add_child(goal_meter)
        var goal_caption := Label.new()
        goal_caption.text = "%d%% of level goal" % int(round(float(score) / float(maxi(goal, 1)) * 100.0))
        goal_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        goal_caption.add_theme_font_size_override("font_size", 14)
        goal_caption.add_theme_color_override("font_color", Color("#b9c7ec"))
        column.add_child(goal_caption)
    var tip := Label.new()
    tip.text = _result_tip(id, passed, stars_earned)
    tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tip.add_theme_font_size_override("font_size", 16)
    tip.add_theme_color_override("font_color", Color("#b9c7ec"))
    column.add_child(tip)
    celebration.modulate.a = 0.0
    celebration.scale = Vector2(0.94, 0.94)
    var reveal := create_tween()
    reveal.set_parallel(true)
    reveal.tween_property(celebration, "modulate:a", 1.0, 0.42)
    reveal.tween_property(celebration, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    # Confetti is drawn above the results without blocking buttons or scrolling.
    if passed:
        var confetti := RewardConfetti.new()
        confetti.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        confetti.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(confetti)
    if id == "rhythm" and passed:
        var song_label := Label.new()
        song_label.text = "Your completed song is playing!"
        song_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        content.add_child(song_label)
        content.add_child(_button("PLAY SONG AGAIN", func(): _play_completed_rhythm_song(played_level), PANEL2))
        _play_completed_rhythm_song(played_level)
    if passed:
        var next_button := _button("NEXT LEVEL", func(): launch(id), ACCENT)
        next_button.icon = preload("res://assets/ui/next_level.png")
        next_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        next_button.expand_icon = true
        content.add_child(next_button)
    content.add_child(_button("RETRY LEVEL %d" % played_level, func(): _retry_level(id, played_level), PANEL2))

    content.add_child(_button("BACK TO MINIVERSE", home, PANEL2))

func _result_tip(id: String, passed: bool, stars_earned: int) -> String:
    if passed:
        return "Outstanding! Three stars earned." if stars_earned == 3 else "Level cleared! Replay to aim for three stars."
    var hints := {
        "fast": "Tip: Keep your combo going by tapping targets quickly.",
        "stack": "Tip: Watch the edges and time each drop carefully.",
        "whack": "Tip: Avoid the snakes and focus on safe moles.",
        "merge": "Tip: Build bigger merges to reach the score target.",
        "snake": "Tip: Plan your turns before you reach the wall.",
        "hopper": "Tip: Aim for the center of each platform.",
        "rhythm": "Tip: Tap when notes enter the glowing catch zone."
    }
    return str(hints.get(id, "Try again — every attempt helps you improve."))

func _retry_level(id: String, played_level: int) -> void:
    Difficulty.set_retry_level(id, played_level)
    launch(id)

func _game_data(id: String) -> Dictionary:
    for g in GAMES:
        if g.id == id:
            return g
    return {}

func _game_name(id: String) -> String:
    var data := _game_data(id)
    if not data.is_empty():
        return str(data.title)
    return "Mini-game"

func _save():
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify({"coins":coins,"xp":xp,"level":level,"best_scores":best_scores,"best_stars":best_stars,"recent_games":recent_games,"seen_tutorials":seen_tutorials,"sound_enabled":sound_enabled}))
        f.close()

func _load_save():
    if not FileAccess.file_exists(SAVE_PATH): return
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not f: return
    var data = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(data) == TYPE_DICTIONARY:
        sound_enabled = bool(data.get("sound_enabled", true))
        coins = int(data.get("coins",0))
        xp = int(data.get("xp",0))
        level = int(data.get("level",1))
        best_scores = data.get("best_scores",{})
        best_stars = data.get("best_stars",{})
        seen_tutorials = data.get("seen_tutorials",{})
        recent_games.clear()
        for saved_id in data.get("recent_games", []):
            if _game_data(str(saved_id)).size() > 0 and recent_games.size() < 3:
                recent_games.append(str(saved_id))
