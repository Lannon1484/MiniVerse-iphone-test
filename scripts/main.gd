extends Control

const BG := Color("#0e1024")
const PANEL := Color("#191d3b")
const PANEL2 := Color("#252b4c")
const TEXT := Color("#f5f7ff")
const MUTED := Color("#a9b1d0")
const ACCENT := Color("#a78bfa")
const CYAN := Color("#67e8f9")
const SAVE_PATH := "user://miniverse_save.json"
const GamePreview = preload("res://scripts/game_preview.gd")
const TouchFeedback = preload("res://scripts/touch_feedback.gd")
const GAMES := [
    {"id":"fast","title":"Fast Fingers","genre":"REFLEX ARCADE","desc":"Tap targets before time runs out.","color":Color("#f9738f")},
    {"id":"merge","title":"Number Merge","genre":"PUZZLE","desc":"Merge matching tiles to reach bigger numbers.","color":Color("#60a5fa")},
    {"id":"stack","title":"Perfect Stack","genre":"TIMING","desc":"Drop moving blocks and build a tower.","color":Color("#fbbf24")}
]

var content: VBoxContainer
var coins := 0
var xp := 0
var level := 1
var best_scores: Dictionary = {}
var game_id := ""
var game_root: Control
var rng := RandomNumberGenerator.new()

func _ready():
    rng.randomize()
    _load_save()
    _shell()
    home()

func _shell():
    for c in get_children():
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
    logo.add_theme_font_size_override("font_size", 28)
    logo.add_theme_color_override("font_color", TEXT)
    brand.add_child(logo)
    var subtitle := Label.new()
    subtitle.text = "A UNIVERSE OF QUICK FUN"
    subtitle.add_theme_font_size_override("font_size", 10)
    subtitle.add_theme_color_override("font_color", MUTED)
    brand.add_child(subtitle)
    var wallet := Label.new()
    wallet.text = "🪙 %d" % coins
    wallet.add_theme_font_size_override("font_size", 18)
    wallet.add_theme_color_override("font_color", Color("#fcd34d"))
    header.add_child(wallet)
    var line := ColorRect.new()
    line.color = Color("#2a2f52")
    line.custom_minimum_size.y = 2
    root.add_child(line)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
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

func _button(text: String, cb: Callable, color := ACCENT, height := 56) -> Button:
    var b := Button.new()
    b.text = text
    # Keep every interactive button comfortably tappable on phones.
    b.custom_minimum_size.y = maxi(height, 52)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 17)
    b.add_theme_color_override("font_color", Color("#17172b") if color == ACCENT or color == Color("#fbbf24") else TEXT)
    b.add_theme_stylebox_override("normal", _style(color))
    b.add_theme_stylebox_override("hover", _style(color.lightened(0.12)))
    b.add_theme_stylebox_override("pressed", _style(color.darkened(0.12)))
    b.add_theme_stylebox_override("focus", _style(color.lightened(0.18)))
    b.add_theme_constant_override("outline_size", 0)
    b.pressed.connect(cb)
    TouchFeedback.attach(b)
    return b

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

func _card(title: String, body: String):
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

func home():
    _shell()
    _heading("WELCOME BACK, PLAYER", "YOUR NEXT HIGH SCORE IS ONE ROUND AWAY.")
    _card("✦  YOUR ARCADE ADVENTURE", "PLAY QUICK. LEVEL UP. CHASE THE PERFECT RUN.\nEarn coins, build XP, and beat your personal bests.")
    content.add_child(_button("▶  PLAY A RANDOM GAME", _random_game, Color("#fbbf24"), 62))
    _heading("Featured games", "Choose your next challenge")
    for g in GAMES:
        content.add_child(_game_card(g))
    content.add_child(_button("🎮  GAME LIBRARY", library, PANEL2))
    content.add_child(_button("🏆  CHALLENGES & EVENTS", events, PANEL2))
    content.add_child(_button("⚙  SETTINGS", settings, PANEL2))
    _card("PLAYER PROGRESS", "Level %d  ·  %d XP  ·  %d coins  ·  %d personal records" % [level, xp, coins, best_scores.size()])

func _game_card(g: Dictionary) -> PanelContainer:
    var card := PanelContainer.new()
    card.custom_minimum_size.y = 112
    card.add_theme_stylebox_override("panel", _style(PANEL, 18))
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    card.add_child(row)

    var preview := GamePreview.new()
    preview.game_id = g.id
    preview.accent = g.color
    preview.custom_minimum_size = Vector2(88, 88)
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
    play.custom_minimum_size.x = 78
    play.size_flags_horizontal = Control.SIZE_SHRINK_END
    play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(play)
    return card

func library():
    _shell()
    _heading("Game Library", "Choose a game and start playing.")
    for g in GAMES:
        content.add_child(_game_card(g))
    content.add_child(_button("← BACK TO HOME", home, PANEL2))

func events():
    _shell()
    _heading("Challenges & Events", "Event previews for the growing MiniVerse.")
    _card("☀ DAILY DASH", "A featured challenge that refreshes daily. Live server-scheduled events are not connected in this starter.")
    _card("🏆 MINIVERSE CUP", "Weekly score competitions will rotate between mini-games after an online backend is added.")
    _card("✦ MINIVERSE FESTIVAL", "Seasonal themes, cosmetic rewards, and special games are planned for future versions.")
    content.add_child(_button("← BACK TO HOME", home, PANEL2))

func settings():
    _shell()
    _heading("Settings", "Local starter build settings.")
    _card("SAVE DATA", "Progress is stored on this device in Godot's user data folder.")
    content.add_child(_button("RESET LOCAL PROGRESS", reset_progress, Color("#f9738f")))
    content.add_child(_button("← BACK TO HOME", home, PANEL2))

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
    game_id = id
    match id:
        "fast": _play_fast()
        "merge": _play_merge()
        "stack": _play_stack()

func _mount_game(g: Control):
    _shell()
    game_root = g
    # Keep a visible way back to the lobby while playing any mini-game.
    content.add_child(_button("←  RETURN TO LOBBY", home, PANEL2, 46))
    # ScrollContainer content must have a real minimum height; otherwise nested
    # game controls can collapse to almost zero height on mobile-sized viewports.
    g.custom_minimum_size = Vector2(0, 820)
    content.add_child(g)
    g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    g.size_flags_vertical = Control.SIZE_EXPAND_FILL

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

func _finished(id: String, score: int, extra: Dictionary = {}):
    var record := score > int(best_scores.get(id, 0))
    if record:
        best_scores[id] = score
    var reward := maxi(5, int(score / 5.0) + 5)
    coins += reward
    xp += maxi(5, int(score / 2.0) + 5)
    level = int(xp / 100) + 1
    _save()
    _results(id, score, reward, record)

func _results(id: String, score: int, reward: int, record: bool):
    _shell()
    _heading("Round Complete", "Every attempt makes you better.")
    _card(_game_name(id), "FINAL SCORE\n\n%d\n\n%s\n\n+%d coins  ·  +%d XP" % [score, "✦ NEW PERSONAL BEST!" if record else "Personal best: %d" % int(best_scores.get(id,0)), reward, maxi(5, int(score/2.0)+5)])
    content.add_child(_button("↻  PLAY AGAIN", func(): launch(id), ACCENT))
    content.add_child(_button("⌂  BACK TO MINIVERSE", home, PANEL2))

func _game_name(id: String) -> String:
    for g in GAMES:
        if g.id == id: return g.title
    return "Mini-game"

func _save():
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify({"coins":coins,"xp":xp,"level":level,"best_scores":best_scores}))
        f.close()

func _load_save():
    if not FileAccess.file_exists(SAVE_PATH): return
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not f: return
    var data = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(data) == TYPE_DICTIONARY:
        coins = int(data.get("coins",0))
        xp = int(data.get("xp",0))
        level = int(data.get("level",1))
        best_scores = data.get("best_scores",{})
