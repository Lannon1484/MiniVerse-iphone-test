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
    var progress := Label.new()
    progress.text = "LEVEL %d   •   BEST %s" % [Difficulty.level(str(g.id)), "★".repeat(int(best_stars.get(str(g.id), 0))) + "☆".repeat(3 - int(best_stars.get(str(g.id), 0)))]
    progress.add_theme_font_size_override("font_size", 11)
    progress.add_theme_color_override("font_color", Color("#ffe29e"))
    detail.add_child(progress)
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
    content.add_child(_button("RESET LOCAL PROGRESS", reset_progress, Color("#f9738f")))
    content.add_child(_button("← BACK TO HOME", home, PANEL2))

func _toggle_sound() -> void:
    sound_enabled = not sound_enabled
    _save()
    settings()

func reset_progress():
    coins = 0
    xp = 0
    level = 1
    best_scores = {}
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
    var base_goals := {"fast": 45, "merge": 24, "stack": 3, "whack": 65, "snake": 3, "hopper": 3, "rhythm": 25}
    var base: int = int(base_goals.get(id, 1))
    return maxi(1, int(round(float(base) * (1.0 + 0.12 * float(played_level - 1)))))

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

func _results(id: String, score: int, reward: int, record: bool, earned_xp: int, stars_earned: int, played_level: int, goal: int, passed: bool):
    _shell()
    _heading("Level Complete!" if passed else "Try Again!", "Level %d • %s" % [played_level, "Goal reached!" if passed else "You can retry this level."])
    var celebration := PanelContainer.new()
    celebration.add_theme_stylebox_override("panel", _style(Color("#25234e"), 22))
    content.add_child(celebration)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 9)
    celebration.add_child(column)
    var stars := Label.new()
    stars.text = "★ ".repeat(stars_earned) + "☆ ".repeat(3 - stars_earned)
    stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stars.add_theme_font_size_override("font_size", 39)
    stars.add_theme_color_override("font_color", Color("#ffdb78"))
    column.add_child(stars)
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
    celebration.modulate.a = 0.0
    celebration.scale = Vector2(0.94, 0.94)
    var reveal := create_tween()
    reveal.set_parallel(true)
    reveal.tween_property(celebration, "modulate:a", 1.0, 0.42)
    reveal.tween_property(celebration, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    # Confetti is drawn above the results without blocking buttons or scrolling.
    var confetti := RewardConfetti.new()
    confetti.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    confetti.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(confetti)
    if passed:
        content.add_child(_button("NEXT LEVEL  →", func(): launch(id), ACCENT))
    content.add_child(_button("↻  RETRY LEVEL %d" % played_level, func(): _retry_level(id, played_level), PANEL2))

    content.add_child(_button("⌂  BACK TO MINIVERSE", home, PANEL2))

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
        f.store_string(JSON.stringify({"coins":coins,"xp":xp,"level":level,"best_scores":best_scores,"best_stars":best_stars,"recent_games":recent_games,"sound_enabled":sound_enabled}))
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
        recent_games.clear()
        for saved_id in data.get("recent_games", []):
            if _game_data(str(saved_id)).size() > 0 and recent_games.size() < 3:
                recent_games.append(str(saved_id))
