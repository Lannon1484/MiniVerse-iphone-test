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

var current_tab := "home"
var shop_category := "themes"
var profile_section := "overview"
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
var achievement_claimed: Dictionary = {}
var total_games_played := 0
var total_wins := 0
var game_play_counts: Dictionary = {}
var game_win_counts: Dictionary = {}
var achievement_new: Array[String] = []
# Cosmetic purchases are local, permanent and do not change game difficulty.
var owned_themes: Dictionary = {"classic": true}
var equipped_theme := "classic"
var shop_message := ""
const SHOP_THEMES := [
    {"id":"classic", "name":"Classic Portal", "price":0, "color":"#a78bfa", "description":"The original MiniVerse purple."},
    {"id":"sunset", "name":"Sunset Glow", "price":150, "color":"#fb923c", "description":"Warm orange highlights."},
    {"id":"ocean", "name":"Ocean Breeze", "price":250, "color":"#22d3ee", "description":"Cool turquoise highlights."},
    {"id":"emerald", "name":"Emerald Magic", "price":350, "color":"#34d399", "description":"Fresh green highlights."},
    {"id":"rose", "name":"Rose Sparkle", "price":500, "color":"#fb7185", "description":"Bright pink highlights."}
]
var owned_avatars: Dictionary = {"star": true}
var equipped_avatar := "star"
const SHOP_AVATARS := [
    {"id":"star","name":"Star Sprite","price":0,"color":"#facc15"},
    {"id":"fox","name":"Forest Fox","price":180,"color":"#fb923c"},
    {"id":"cat","name":"Moon Cat","price":260,"color":"#a78bfa"},
    {"id":"slime","name":"Happy Slime","price":320,"color":"#34d399"},
    {"id":"robot","name":"Pocket Robot","price":450,"color":"#67e8f9"}
]
var owned_effects: Dictionary = {"classic": true}
var equipped_effect := "classic"
const SHOP_EFFECTS := [
    {"id":"classic","name":"Classic Confetti","price":0,"description":"The original rainbow celebration.","color":"#a78bfa"},
    {"id":"starlight","name":"Starlight Shower","price":220,"description":"Glowing golden stars after a victory.","color":"#facc15"},
    {"id":"ocean","name":"Ocean Bubbles","price":320,"description":"Floating aqua circles after a victory.","color":"#22d3ee"},
    {"id":"hearts","name":"Heart Burst","price":420,"description":"Pink heart-shaped victory particles.","color":"#fb7185"}
]
# Daily missions are generated from the device's local calendar date.
# Only rounds finished today count toward today's missions.
var mission_day := ""
var mission_progress: Dictionary = {}
var mission_claimed: Dictionary = {}
var mission_notice := ""
# Weekly objectives reset every Monday (device local time). Their progress is
# stored independently of the daily missions and existing player statistics.
var weekly_key := ""
var weekly_progress: Dictionary = {}
var weekly_claimed: Dictionary = {}
var weekly_games: Dictionary = {}
var weekly_notice := ""
# A daily challenge streak advances only when all three daily missions
# have been claimed. Rewards are granted once per completed day.
var challenge_streak := 0
var challenge_streak_last_day := ""
var challenge_streak_notice := ""

const MISSION_GAMES := ["fast", "merge", "stack", "memory", "whack", "sort", "snake", "dots", "hopper", "rhythm"]

# Login rewards are claimable once per local calendar day. A missed day
# resets the consecutive streak; claiming again on the same day does not.
var login_last_claim := ""
var login_streak := 0
var login_notice := ""
var login_total_claims := 0

# Titles are earned through existing stats, never purchased.
var equipped_title := "explorer"
var title_notice := ""
const PROFILE_TITLES := [
    {"id":"explorer", "name":"MiniVerse Explorer", "requirement":"Available from the beginning."},
    {"id":"regular", "name":"Arcade Regular", "requirement":"Play 10 rounds."},
    {"id":"champion", "name":"Victory Champion", "requirement":"Win 25 rounds."},
    {"id":"collector", "name":"Star Collector", "requirement":"Earn 20 best-rating stars."},
    {"id":"hunter", "name":"Achievement Hunter", "requirement":"Unlock 10 achievements."},
    {"id":"veteran", "name":"Arcade Veteran", "requirement":"Play 100 rounds."},
    {"id":"master", "name":"Master of MiniVerse", "requirement":"Master all ten games."}
]

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

func _daily_rewards_ready() -> int:
    _mission_reset_if_needed()
    var ready: int = 0
    for mission in _mission_definitions():
        var key: String = str(mission["id"])
        if not mission_claimed.has(key) and int(mission_progress.get(key, 0)) >= int(mission["target"]):
            ready += 1
    if _login_can_claim():
        ready += 1
    return ready


func _weekly_rewards_ready() -> int:
    _weekly_reset_if_needed()
    var ready: int = 0
    for challenge in _weekly_definitions():
        var key: String = str(challenge["id"])
        if not weekly_claimed.has(key) and int(weekly_progress.get(key, 0)) >= int(challenge["target"]):
            ready += 1
    return ready


func _rewards_ready_count() -> int:
    return _daily_rewards_ready() + _weekly_rewards_ready()


func _rewards_hub() -> void:
    current_tab = "rewards"
    _shell()
    _heading("Rewards & Challenges", "Your daily rewards, achievements and events.")
    var daily_ready: int = _daily_rewards_ready()
    var weekly_ready: int = _weekly_rewards_ready()
    var total_ready: int = daily_ready + weekly_ready
    if total_ready > 0:
        _card("REWARDS READY TO CLAIM", "%d reward%s waiting! Open Daily Missions or Weekly Challenges to collect them." % [total_ready, "" if total_ready == 1 else "s"])
    else:
        _card("ALL CAUGHT UP", "Keep playing to complete missions and unlock more rewards.")
    if challenge_streak_last_day != "":
        _card("CHALLENGE STREAK", "%d completed day(s). Claim all three daily missions to keep it going!" % challenge_streak)
    var weekly_label: String = "WEEKLY CHALLENGES"
    if weekly_ready > 0:
        weekly_label += "  (%d READY)" % weekly_ready
    var daily_label: String = "DAILY MISSIONS & LOGIN REWARDS"
    if daily_ready > 0:
        daily_label += "  (%d READY)" % daily_ready
    content.add_child(_menu_button(weekly_label, weekly_challenges, Color("#34d399"), "missions"))
    content.add_child(_menu_button(daily_label, daily_missions, Color("#fbbf24"), "missions"))
    content.add_child(_menu_button("ACHIEVEMENTS", achievements, Color("#344a9b"), "achievements"))
    content.add_child(_menu_button("CHALLENGES & EVENTS", events, Color("#344a9b"), "events"))


func _bottom_navigation(root: VBoxContainer) -> void:
    var separator := ColorRect.new()
    separator.color = _theme_color().darkened(0.3)
    separator.custom_minimum_size.y = 2
    root.add_child(separator)
    var bar := HBoxContainer.new()
    bar.custom_minimum_size.y = 100
    bar.add_theme_constant_override("separation", 3)
    root.add_child(bar)
    for item in [
        {"id":"home", "label":"Home", "icon":"home"},
        {"id":"games", "label":"Games", "icon":"library"},
        {"id":"rewards", "label":"Earn", "icon":"achievements"},
        {"id":"shop", "label":"Shop", "icon":"shop"},
        {"id":"profile", "label":"Profile", "icon":"profile"}
    ]:
        var tab_id: String = str(item["id"])
        var selected: bool = current_tab == tab_id
        var button := Button.new()
        button.text = str(item["label"])
        if tab_id == "rewards":
            var ready_count: int = _rewards_ready_count()
            if ready_count > 0:
                button.text = "Earn %d" % mini(ready_count, 9)
        button.icon = load("res://assets/ui/menu_%s.png" % str(item["icon"]))
        button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
        button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
        button.expand_icon = true
        button.add_theme_constant_override("icon_max_width", 30)
        button.add_theme_font_size_override("font_size", 20)
        var nav_bg: Color = _theme_color().darkened(0.32) if selected else PANEL2
        button.add_theme_color_override("font_color", _button_text_color(nav_bg))
        button.add_theme_color_override("font_hover_color", _button_text_color(_theme_color().darkened(0.18)))
        button.add_theme_color_override("font_pressed_color", _button_text_color(_theme_color().darkened(0.42)))
        button.add_theme_stylebox_override("normal", _style(_theme_color().darkened(0.32) if selected else PANEL2, 10))
        button.add_theme_stylebox_override("hover", _style(_theme_color().darkened(0.18), 10))
        button.add_theme_stylebox_override("pressed", _style(_theme_color().darkened(0.42), 10))
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.custom_minimum_size.y = 94
        button.pressed.connect(func():
            _play_sound(SFX_TAP)
            match tab_id:
                "home": home()
                "games": library()
                "rewards": _rewards_hub()
                "shop": shop()
                "profile": player_profile()
        )
        bar.add_child(button)


func _section_chips(options: Array[String], selected: String, callback: Callable) -> void:
    var chips := HFlowContainer.new()
    chips.add_theme_constant_override("h_separation", 6)
    chips.add_theme_constant_override("v_separation", 6)
    content.add_child(chips)
    for option in options:
        var chip := _button(option, func(): callback.call(option), _theme_color() if option == selected else PANEL2, 58)
        chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        chip.add_theme_font_size_override("font_size", 21)
        chips.add_child(chip)


func _shell():
    tutorial_overlay = null
    lobby_touch_scrolling = true
    for c in get_children():
        if c != sound_player:
            c.queue_free()
    var bg := ColorRect.new()
    bg.color = BG.lerp(_theme_color(), 0.10)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    # Subtle arcade-style corner lights behind the interface.
    for deco in [{"pos": Vector2(-90, 150), "size": Vector2(250, 250), "color": Color(_theme_color(), 0.12)}, {"pos": Vector2(500, 540), "size": Vector2(280, 280), "color": Color("#22d3ee", 0.05)}]:
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
    logo.add_theme_color_override("font_shadow_color", _theme_color().darkened(0.38))
    logo.add_theme_constant_override("shadow_offset_x", 2)
    logo.add_theme_constant_override("shadow_offset_y", 3)
    logo.add_theme_color_override("font_color", Color("#ffda78").lerp(_theme_color().lightened(0.45), 0.45))
    brand.add_child(logo)
    var subtitle := Label.new()
    subtitle.text = "A UNIVERSE OF QUICK FUN"
    subtitle.add_theme_font_size_override("font_size", 15)
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
    line.color = _theme_color().darkened(0.38)
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
    _bottom_navigation(root)

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
    var style := _style(Color("#172858").lerp(_theme_color(), 0.19), 18)
    style.content_margin_left = 16
    style.content_margin_right = 16
    style.content_margin_top = 15
    style.content_margin_bottom = 15
    style.border_width_left = 3
    style.border_width_right = 1
    style.border_width_top = 1
    style.border_width_bottom = 2
    style.border_color = accent.darkened(0.22)
    style.shadow_color = Color("#030a26", 0.38)
    style.shadow_size = 3
    style.shadow_offset = Vector2(0, 3)
    return style


func _menu_accent_text(accent: Color) -> Color:
    # On dark panels, lift darker theme colors so headings stay readable.
    var contrast: float = 0.2126 * accent.r + 0.7152 * accent.g + 0.0722 * accent.b
    return accent.lightened(0.45) if contrast < 0.55 else accent


func _button_text_color(background: Color) -> Color:
    # Choose text based on the *rendered* button background, including
    # purchased themes. Light buttons get dark text, dark buttons get white.
    var luminance: float = 0.2126 * background.r + 0.7152 * background.g + 0.0722 * background.b
    return Color("#101827") if luminance > 0.49 else Color("#ffffff")


func _button(text: String, cb: Callable, color := ACCENT, height := 56) -> Button:
    var b := Button.new()
    b.text = text
    # Let touch drags on a button reach the surrounding ScrollContainer.
    # Taps still activate the button normally.
    b.mouse_filter = Control.MOUSE_FILTER_PASS
    # Keep every interactive button comfortably tappable on phones.
    b.custom_minimum_size.y = maxi(height, 62)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 21)
    var button_color: Color = _theme_button_color(color)
    var normal_text := _button_text_color(button_color)
    b.add_theme_color_override("font_color", normal_text)
    b.add_theme_color_override("font_hover_color", _button_text_color(button_color.lightened(0.12)))
    b.add_theme_color_override("font_pressed_color", _button_text_color(button_color.darkened(0.12)))
    b.add_theme_color_override("font_focus_color", normal_text)
    b.add_theme_color_override("font_disabled_color", normal_text.darkened(0.25) if normal_text.r > 0.5 else normal_text.lightened(0.25))
    b.add_theme_stylebox_override("normal", _lobby_button_style(button_color))
    b.add_theme_stylebox_override("hover", _lobby_button_style(button_color.lightened(0.12)))
    b.add_theme_stylebox_override("pressed", _lobby_button_style(button_color.darkened(0.12)))
    b.add_theme_stylebox_override("focus", _style(button_color.lightened(0.18)))
    b.add_theme_constant_override("outline_size", 0)
    b.pressed.connect(func():
        _play_sound(SFX_TAP)
        cb.call()
    )
    TouchFeedback.attach(b)
    return b

func _menu_button(label: String, cb: Callable, color: Color, icon_name: String, height: int = 56) -> Button:
    var button := _button(label, cb, color, height)
    button.icon = load("res://assets/ui/menu_%s.png" % icon_name)
    button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.expand_icon = true
    button.add_theme_constant_override("icon_max_width", 34)
    return button

func _play_sound(stream: AudioStream) -> void:
    if sound_enabled and is_instance_valid(sound_player):
        sound_player.stream = stream
        sound_player.play()

func _theme_color() -> Color:
    for item in SHOP_THEMES:
        if str(item["id"]) == equipped_theme:
            return Color(str(item["color"]))
    return ACCENT

func _theme_button_color(base: Color) -> Color:
    # Recolor standard navigation and secondary buttons while keeping
    # gameplay-specific bright colors (green play, gold daily, etc.) intact.
    if base == Color("#344a9b") or base == PANEL2 or base == Color("#344a76"):
        return base.lerp(_theme_color(), 0.55)
    if base == ACCENT:
        return _theme_color()
    return base


func _shop_purchase(theme_id: String) -> void:
    for item in SHOP_THEMES:
        if str(item["id"]) != theme_id:
            continue
        var cost: int = int(item["price"])
        if owned_themes.has(theme_id):
            equipped_theme = theme_id
            shop_message = "Equipped %s!" % str(item["name"])
        elif coins >= cost:
            coins -= cost
            owned_themes[theme_id] = true
            equipped_theme = theme_id
            shop_message = "Unlocked and equipped %s!" % str(item["name"])
            _play_sound(SFX_COLLECT)
        else:
            shop_message = "You need %d more coins to unlock %s." % [cost - coins, str(item["name"])]
        _save()
        shop()
        return

func _avatar_purchase(avatar_id: String) -> void:
    for item in SHOP_AVATARS:
        if str(item["id"]) != avatar_id:
            continue
        var cost: int = int(item["price"])
        if owned_avatars.has(avatar_id):
            equipped_avatar = avatar_id
            shop_message = "Equipped %s!" % str(item["name"])
        elif coins >= cost:
            coins -= cost
            owned_avatars[avatar_id] = true
            equipped_avatar = avatar_id
            shop_message = "Unlocked and equipped %s!" % str(item["name"])
            _play_sound(SFX_COLLECT)
        else:
            shop_message = "You need %d more coins for %s." % [cost - coins, str(item["name"])]
        _save()
        shop()
        return


func _avatar_image(avatar_id: String, dimension: int = 64) -> TextureRect:
    var picture := TextureRect.new()
    picture.texture = load("res://assets/ui/avatar_%s.png" % avatar_id)
    picture.custom_minimum_size = Vector2(dimension, dimension)
    picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return picture


func _effect_purchase(effect_id: String) -> void:
    for item in SHOP_EFFECTS:
        if str(item["id"]) != effect_id:
            continue
        var cost: int = int(item["price"])
        if owned_effects.has(effect_id):
            equipped_effect = effect_id
            shop_message = "Equipped %s!" % str(item["name"])
        elif coins >= cost:
            coins -= cost
            owned_effects[effect_id] = true
            equipped_effect = effect_id
            shop_message = "Unlocked and equipped %s!" % str(item["name"])
            _play_sound(SFX_COLLECT)
        else:
            shop_message = "You need %d more coins for %s." % [cost - coins, str(item["name"])]
        _save()
        shop()
        return


func shop() -> void:
    current_tab = "shop"
    _shell()
    _heading("Cosmetic Shop", "Customize themes, avatars and victory effects. No gameplay advantages.")
    _card("YOUR WALLET", "%d coins available  •  Purchases save automatically." % coins)
    if shop_message != "":
        _card("SHOP UPDATE", shop_message)
    _section_chips(["Themes", "Avatars", "Effects"], shop_category.capitalize(), func(value: String):
        shop_category = value.to_lower()
        shop()
    )
    if shop_category == "themes":
        for item in SHOP_THEMES:
            var id: String = str(item["id"])
            var price: int = int(item["price"])
            var owned: bool = owned_themes.has(id)
            var equipped: bool = equipped_theme == id
            var theme_color := Color(str(item["color"]))
            var card := PanelContainer.new()
            card.add_theme_stylebox_override("panel", _lobby_card_style(theme_color))
            content.add_child(card)
            var column := VBoxContainer.new()
            column.add_theme_constant_override("separation", 7)
            card.add_child(column)
            var preview := ColorRect.new()
            preview.color = theme_color
            preview.custom_minimum_size.y = 14
            preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
            column.add_child(preview)
            var title := Label.new()
            title.text = str(item["name"]) + ("  -  EQUIPPED" if equipped else "")
            title.add_theme_color_override("font_color", TEXT)
            title.add_theme_font_size_override("font_size", 21)
            column.add_child(title)
            var description := Label.new()
            description.text = str(item["description"]) + ("  •  Owned" if owned else "  •  %d coins" % price)
            description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            description.add_theme_font_size_override("font_size", 19)
            description.add_theme_color_override("font_color", Color("#e4eaff"))
            column.add_child(description)
            var button_label := "EQUIPPED" if equipped else ("EQUIP" if owned else "BUY FOR %d COINS" % price)
            var purchase := _button(button_label, func(): _shop_purchase(id), theme_color)
            purchase.disabled = equipped
            column.add_child(purchase)
    if shop_category == "avatars":
        _heading("Collectible Avatars", "Unlock a character to display beside your lobby progress.")
        for item in SHOP_AVATARS:
            var avatar_id: String = str(item["id"])
            var avatar_price: int = int(item["price"])
            var avatar_owned: bool = owned_avatars.has(avatar_id)
            var avatar_equipped: bool = equipped_avatar == avatar_id
            var avatar_card := PanelContainer.new()
            avatar_card.add_theme_stylebox_override("panel", _lobby_card_style(Color(str(item["color"]))))
            content.add_child(avatar_card)
            var avatar_row := HBoxContainer.new()
            avatar_row.add_theme_constant_override("separation", 12)
            avatar_card.add_child(avatar_row)
            avatar_row.add_child(_avatar_image(avatar_id, 72))
            var avatar_column := VBoxContainer.new()
            avatar_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            avatar_row.add_child(avatar_column)
            var avatar_title := Label.new()
            avatar_title.text = str(item["name"]) + ("  -  EQUIPPED" if avatar_equipped else "")
            avatar_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            avatar_title.add_theme_font_size_override("font_size", 21)
            avatar_title.add_theme_color_override("font_color", TEXT)
            avatar_column.add_child(avatar_title)
            var avatar_button := _button("EQUIPPED" if avatar_equipped else ("EQUIP" if avatar_owned else "BUY FOR %d COINS" % avatar_price), func(): _avatar_purchase(avatar_id), Color(str(item["color"])), 52)
            avatar_button.disabled = avatar_equipped
            avatar_column.add_child(avatar_button)
    if shop_category == "effects":
        _heading("Victory Effects", "Choose the celebration shown after winning a level.")
        for item in SHOP_EFFECTS:
            var effect_id: String = str(item["id"])
            var effect_price: int = int(item["price"])
            var effect_owned: bool = owned_effects.has(effect_id)
            var effect_equipped: bool = equipped_effect == effect_id
            var effect_card := PanelContainer.new()
            effect_card.add_theme_stylebox_override("panel", _lobby_card_style(Color(str(item["color"]))))
            content.add_child(effect_card)
            var effect_column := VBoxContainer.new()
            effect_column.add_theme_constant_override("separation", 6)
            effect_card.add_child(effect_column)
            var effect_title := Label.new()
            effect_title.text = str(item["name"]) + ("  -  EQUIPPED" if effect_equipped else "")
            effect_title.add_theme_color_override("font_color", _menu_accent_text(Color(str(item["color"]))))
            effect_title.add_theme_font_size_override("font_size", 22)
            effect_column.add_child(effect_title)
            var effect_description := Label.new()
            effect_description.text = str(item["description"])
            effect_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            effect_description.add_theme_font_size_override("font_size", 19)
            effect_description.add_theme_color_override("font_color", Color("#e4eaff"))
            effect_column.add_child(effect_description)
            var effect_button := _button("EQUIPPED" if effect_equipped else ("EQUIP" if effect_owned else "BUY FOR %d COINS" % effect_price), func(): _effect_purchase(effect_id), Color(str(item["color"])), 52)
            effect_button.disabled = effect_equipped
            effect_column.add_child(effect_button)


func _heading(title: String, subtitle := ""):
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 4)
    content.add_child(box)
    var t := Label.new()
    t.text = title
    t.add_theme_font_size_override("font_size", 30)
    t.add_theme_color_override("font_color", _menu_accent_text(_theme_color()))
    box.add_child(t)
    if subtitle != "":
        var s := Label.new()
        s.text = subtitle
        s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        s.add_theme_font_size_override("font_size", 19)
        s.add_theme_color_override("font_color", MUTED)
        box.add_child(s)

func _card(title: String, body: String) -> PanelContainer:
    var p := PanelContainer.new()
    p.add_theme_stylebox_override("panel", _lobby_card_style(_theme_color()))
    content.add_child(p)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 9)
    p.add_child(v)
    var t := Label.new()
    t.text = title
    t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    t.add_theme_font_size_override("font_size", 22)
    t.add_theme_color_override("font_color", _menu_accent_text(_theme_color()))
    v.add_child(t)
    var d := Label.new()
    d.text = body
    d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    d.add_theme_font_size_override("font_size", 19)
    d.add_theme_color_override("font_color", Color("#e4eaff"))
    v.add_child(d)
    return p


func _stat_rate(wins: int, played: int) -> String:
    if played <= 0:
        return "0%"
    return "%d%%" % int(round(100.0 * float(wins) / float(played)))


func _profile_favorite() -> String:
    var favorite_id := ""
    var favorite_plays := 0
    for g in GAMES:
        var id: String = str(g["id"])
        var played: int = int(game_play_counts.get(id, 0))
        if played > favorite_plays:
            favorite_plays = played
            favorite_id = id
    return _game_name(favorite_id) if favorite_id != "" else "Not yet discovered"


# Mastery is calculated from existing wins, so old saves retain their progress.
const MASTERY_TARGETS := [0, 3, 10, 25, 50]
const MASTERY_NAMES := ["Newcomer", "Apprentice", "Specialist", "Expert", "Master"]

func _mastery_tier(wins: int) -> int:
    var tier := 0
    for i in range(MASTERY_TARGETS.size()):
        if wins >= MASTERY_TARGETS[i]:
            tier = i
    return tier


func _profile_progress(label_text: String, current: int, target: int, accent: Color) -> void:
    var wrapper := VBoxContainer.new()
    wrapper.add_theme_constant_override("separation", 4)
    content.add_child(wrapper)
    var caption := Label.new()
    caption.text = "%s  (%d / %d)" % [label_text, mini(current, target), target]
    caption.add_theme_color_override("font_color", TEXT)
    caption.add_theme_font_size_override("font_size", 18)
    wrapper.add_child(caption)
    var bar := ProgressBar.new()
    bar.min_value = 0.0
    bar.max_value = float(maxi(target, 1))
    bar.value = float(mini(current, target))
    bar.show_percentage = false
    bar.custom_minimum_size = Vector2(0, 14)
    var track := StyleBoxFlat.new()
    track.bg_color = Color("#17213b")
    track.set_corner_radius_all(7)
    bar.add_theme_stylebox_override("background", track)
    var fill := StyleBoxFlat.new()
    fill.bg_color = accent
    fill.set_corner_radius_all(7)
    bar.add_theme_stylebox_override("fill", fill)
    wrapper.add_child(bar)


func _profile_milestone(title_text: String, description: String, achieved: bool) -> void:
    var status := "COMPLETED" if achieved else "IN PROGRESS"
    _card(("[DONE] " if achieved else "[   ] ") + title_text, description + "\n" + status)


func _profile_total_stars() -> int:
    var stars := 0
    for game in GAMES:
        stars += int(best_stars.get(str(game["id"]), 0))
    return stars


func _profile_achievement_count() -> int:
    var count := 0
    for achievement_id in achievement_claimed.keys():
        if bool(achievement_claimed[achievement_id]):
            count += 1
    return count


func _profile_master_count() -> int:
    var count := 0
    for game in GAMES:
        if int(game_win_counts.get(str(game["id"]), 0)) >= 50:
            count += 1
    return count


func _title_unlocked(title_id: String) -> bool:
    match title_id:
        "explorer":
            return true
        "regular":
            return total_games_played >= 10
        "champion":
            return total_wins >= 25
        "collector":
            return _profile_total_stars() >= 20
        "hunter":
            return _profile_achievement_count() >= 10
        "veteran":
            return total_games_played >= 100
        "master":
            return _profile_master_count() >= GAMES.size()
    return false


func _title_display_name(title_id: String) -> String:
    for item in PROFILE_TITLES:
        if str(item["id"]) == title_id:
            return str(item["name"])
    return "MiniVerse Explorer"


func _equip_profile_title(title_id: String) -> void:
    if not _title_unlocked(title_id):
        return
    equipped_title = title_id
    title_notice = "Now displaying: %s" % _title_display_name(title_id)
    _save()
    player_profile()


func player_profile() -> void:
    current_tab = "profile"
    _shell()
    _heading("Player Profile", "Your MiniVerse journey, all in one place.")
    var avatar_panel := PanelContainer.new()
    avatar_panel.add_theme_stylebox_override("panel", _style(PANEL.lerp(_theme_color(), 0.20), 18))
    content.add_child(avatar_panel)
    var avatar_row := HBoxContainer.new()
    avatar_row.add_theme_constant_override("separation", 14)
    avatar_panel.add_child(avatar_row)
    avatar_row.add_child(_avatar_image(equipped_avatar, 84))
    var profile_details := VBoxContainer.new()
    profile_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    avatar_row.add_child(profile_details)
    var profile_title := Label.new()
    if not _title_unlocked(equipped_title):
        equipped_title = "explorer"
    profile_title.text = _title_display_name(equipped_title).to_upper()
    profile_title.add_theme_color_override("font_color", _menu_accent_text(_theme_color()))
    profile_title.add_theme_font_size_override("font_size", 19)
    profile_details.add_child(profile_title)
    var profile_level := Label.new()
    profile_level.text = "Level %d  |  %d total XP" % [level, xp]
    profile_level.add_theme_color_override("font_color", TEXT)
    profile_details.add_child(profile_level)
    var profile_wallet := Label.new()
    profile_wallet.text = "%d coins available" % coins
    profile_wallet.add_theme_color_override("font_color", MUTED)
    profile_details.add_child(profile_wallet)
    var total_stars: int = _profile_total_stars()
    var unlocked_achievements: int = _profile_achievement_count()
    if profile_section == "overview":
        _card("OVERALL PERFORMANCE", "Rounds played: %d\nLevels cleared: %d\nWin rate: %s\nFavorite game: %s" % [total_games_played, total_wins, _stat_rate(total_wins, total_games_played), _profile_favorite()])
        _card("COLLECTION & REWARDS", "Achievements: %d / %d\nBest stars earned: %d / 30\nThemes owned: %d / %d\nAvatars owned: %d / %d\nVictory effects owned: %d / %d\nDaily login claims: %d" % [unlocked_achievements, ACHIEVEMENT_INFO.size(), total_stars, owned_themes.size(), SHOP_THEMES.size(), owned_avatars.size(), SHOP_AVATARS.size(), owned_effects.size(), SHOP_EFFECTS.size(), login_total_claims])
    _section_chips(["Overview", "Titles", "Milestones", "Games"], profile_section.capitalize(), func(value: String):
        profile_section = value.to_lower()
        player_profile()
    )
    if profile_section == "titles":
        _heading("Player Titles", "Earn titles through gameplay, then choose one to display on your profile.")
        if title_notice != "":
            _card("TITLE EQUIPPED", title_notice)
        for title_item in PROFILE_TITLES:
            var title_id: String = str(title_item["id"])
            var title_name: String = str(title_item["name"])
            var title_available: bool = _title_unlocked(title_id)
            var title_equipped: bool = equipped_title == title_id
            _card(title_name + ("  -  EQUIPPED" if title_equipped else ""), str(title_item["requirement"]) + ("  •  Unlocked" if title_available else "  •  Locked"))
            if title_available and not title_equipped:
                content.add_child(_button("EQUIP " + title_name.to_upper(), func(): _equip_profile_title(title_id), Color("#344a9b"), 48))
    if profile_section == "milestones":
        _heading("Personal Milestones", "Track the goals you've reached across MiniVerse.")
        _profile_milestone("First Steps", "Finish 10 mini-game rounds.", total_games_played >= 10)
        _profile_milestone("Winning Habit", "Clear 25 levels across all games.", total_wins >= 25)
        _profile_milestone("Star Collector", "Collect 20 best-rating stars across the ten games.", total_stars >= 20)
        _profile_milestone("Achievement Hunter", "Unlock 10 achievements.", unlocked_achievements >= 10)
        var mastered_games := 0
        for mastered_game in GAMES:
            if int(game_win_counts.get(str(mastered_game["id"]), 0)) >= 50:
                mastered_games += 1
        _profile_milestone("Master of MiniVerse", "Reach Master rank in all ten mini-games.", mastered_games >= GAMES.size())
    if profile_section == "games":
        _heading("Game Mastery", "Win rounds to climb five mastery ranks in each game.")
        _heading("Game Statistics", "Records and progress for each of your ten games.")
        for game in GAMES:
            var id: String = str(game["id"])
            var played: int = int(game_play_counts.get(id, 0))
            var wins: int = int(game_win_counts.get(id, 0))
            var record: int = int(best_scores.get(id, 0))
            var stars: int = int(best_stars.get(id, 0))
            var cleared: int = maxi(Difficulty.level(id) - 1, 0)
            _card(str(game["title"]), "Rounds: %d  |  Wins: %d  |  Win rate: %s\nBest score: %d  |  Best stars: %d / 3\nLevels cleared: %d" % [played, wins, _stat_rate(wins, played), record, stars, cleared])
            var tier: int = _mastery_tier(wins)
            var mastery_title := "%s  -  %s" % [str(game["title"]), MASTERY_NAMES[tier]]
            if tier >= MASTERY_TARGETS.size() - 1:
                _profile_progress(mastery_title + " (MAX RANK)", wins, 50, _theme_color())
            else:
                var next_target: int = MASTERY_TARGETS[tier + 1]
                _profile_progress(mastery_title + " - Next: " + MASTERY_NAMES[tier + 1], wins, next_target, _theme_color())
            content.add_child(_button("PLAY %s" % str(game["title"]).to_upper(), func(): launch(id), Color("#344a9b"), 44))



func home():
    Difficulty.clear_retry_level(game_id)
    current_tab = "home"
    _shell()
    # Mobile-first welcome panel with custom procedural fantasy artwork.
    var hero := PanelContainer.new()
    var hero_style := StyleBoxFlat.new()
    hero_style.bg_color = _theme_color().darkened(0.32)
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
    title.add_theme_color_override("font_color", _theme_color().lightened(0.50))
    welcome.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "Pick a game, beat your best, earn rewards!"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.add_theme_color_override("font_color", Color("#e1e7ff"))
    welcome.add_child(subtitle)
    var profile := HBoxContainer.new()
    profile.alignment = BoxContainer.ALIGNMENT_CENTER
    profile.add_theme_constant_override("separation", 10)
    content.add_child(profile)
    profile.add_child(_avatar_image(equipped_avatar, 62))
    var profile_label := Label.new()
    profile_label.text = "YOUR AVATAR  •  Level %d" % level
    profile_label.add_theme_color_override("font_color", _menu_accent_text(_theme_color()))
    profile.add_child(profile_label)
    content.add_child(_menu_button("PLAY A RANDOM GAME", _random_game, Color("#36e58a"), "play", 60))
    var quick_actions := HBoxContainer.new()
    quick_actions.add_theme_constant_override("separation", 8)
    content.add_child(quick_actions)
    quick_actions.add_child(_menu_button("DAILY", _daily_challenge, Color("#fbbf24"), "daily", 54))
    quick_actions.add_child(_menu_button("MISSIONS", daily_missions, Color("#344a9b"), "missions", 54))
    _heading("Recently Played", "Your last three games, ready to jump back into.")
    var shown := 0
    for recent_id in recent_games:
        var recent_game := _game_data(recent_id)
        if not recent_game.is_empty() and shown < 3:
            content.add_child(_game_card(recent_game))
            shown += 1
    if shown == 0:
        _card("YOUR ADVENTURE STARTS HERE", "Play a game from the library and your three most recently played games will appear here.")
    content.add_child(_menu_button("BROWSE ALL GAMES", library, Color("#344a9b"), "library", 54))
    content.add_child(_menu_button("SETTINGS", settings, PANEL2, "settings", 48))

func _game_card(g: Dictionary) -> PanelContainer:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", _lobby_card_style(g.color))
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    card.add_child(column)

    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation", 14)
    column.add_child(top)
    var preview := GamePreview.new()
    preview.game_id = g.id
    preview.accent = g.color
    preview.custom_minimum_size = Vector2(90, 100)
    preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    top.add_child(preview)

    var details := VBoxContainer.new()
    details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    details.add_theme_constant_override("separation", 5)
    top.add_child(details)
    var name := Label.new()
    name.text = str(g.title)
    name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    name.add_theme_font_size_override("font_size", 23)
    name.add_theme_color_override("font_color", TEXT)
    details.add_child(name)
    var genre := Label.new()
    genre.text = str(g.genre)
    genre.add_theme_font_size_override("font_size", 17)
    genre.add_theme_color_override("font_color", _menu_accent_text(g.color))
    details.add_child(genre)
    var level_info := Label.new()
    level_info.text = "LEVEL %d  |  BEST %d" % [Difficulty.level(str(g.id)), int(best_scores.get(g.id, 0))]
    level_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    level_info.add_theme_font_size_override("font_size", 17)
    level_info.add_theme_color_override("font_color", Color("#ffe29e"))
    details.add_child(level_info)
    var stars := HBoxContainer.new()
    stars.add_theme_constant_override("separation", 5)
    details.add_child(stars)
    for star_index in range(3):
        var star_icon := TextureRect.new()
        star_icon.texture = preload("res://assets/ui/star_filled.png") if star_index < int(best_stars.get(str(g.id), 0)) else preload("res://assets/ui/star_empty.png")
        star_icon.custom_minimum_size = Vector2(22, 22)
        star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        stars.add_child(star_icon)

    var description := Label.new()
    description.text = str(g.desc)
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.add_theme_font_size_override("font_size", 18)
    description.add_theme_color_override("font_color", Color("#e4eaff"))
    column.add_child(description)
    var play := _button("PLAY " + str(g.title).to_upper(), func(): launch(str(g.id)), g.color, 60)
    column.add_child(play)
    return card


func library():
    current_tab = "games"
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
        chip.add_theme_font_size_override("font_size", 19)
        filters.add_child(chip)
    var count := 0
    for g in GAMES:
        if _matches_filter(g, library_filter):
            content.add_child(_game_card(g))
            count += 1
    _card("%d GAMES" % count, "Choose any game to play instantly.")


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
    content.add_child(_menu_button("BACK TO HOME", home, PANEL2, "back"))

const ACHIEVEMENT_INFO := [
    {"id":"first_play", "title":"First Steps", "desc":"Play your first mini-game.", "coins":25, "xp":30},
    {"id":"first_win", "title":"First Victory", "desc":"Complete your first level successfully.", "coins":40, "xp":50},
    {"id":"five_plays", "title":"Getting Started", "desc":"Play five rounds across MiniVerse.", "coins":50, "xp":60},
    {"id":"twenty_plays", "title":"Arcade Regular", "desc":"Play twenty rounds.", "coins":120, "xp":150},
    {"id":"five_wins", "title":"Rising Star", "desc":"Win five rounds.", "coins":80, "xp":100},
    {"id":"twenty_wins", "title":"Champion", "desc":"Win twenty rounds.", "coins":200, "xp":250},
    {"id":"explorer", "title":"World Explorer", "desc":"Try all ten mini-games.", "coins":150, "xp":180},
    {"id":"score_500", "title":"High Scorer", "desc":"Score 500 or more in a single round.", "coins":100, "xp":125},
    {"id":"game_fast", "title":"Quick Reflexes", "desc":"Win 3 Fast Fingers rounds.", "coins":75, "xp":90},
    {"id":"game_merge", "title":"Merge Master", "desc":"Win 3 Number Merge rounds.", "coins":75, "xp":90},
    {"id":"game_stack", "title":"Tower Builder", "desc":"Win 3 Perfect Stack rounds.", "coins":75, "xp":90},
    {"id":"game_memory", "title":"Memory Keeper", "desc":"Complete 3 Memory Match boards.", "coins":75, "xp":90},
    {"id":"game_whack", "title":"Mole Hunter", "desc":"Win 3 Whack-a-Mole rounds.", "coins":75, "xp":90},
    {"id":"game_sort", "title":"Color Expert", "desc":"Complete 3 Color Sort puzzles.", "coins":75, "xp":90},
    {"id":"game_snake", "title":"Snake Charmer", "desc":"Win 3 Neon Snake rounds.", "coins":75, "xp":90},
    {"id":"game_dots", "title":"Pathfinder", "desc":"Complete 3 Connect the Dots puzzles.", "coins":75, "xp":90},
    {"id":"game_hopper", "title":"Sky Explorer", "desc":"Win 3 Sky Hopper rounds.", "coins":75, "xp":90},
    {"id":"game_rhythm", "title":"Rhythm Star", "desc":"Win 3 Rhythm Rush songs.", "coins":75, "xp":90}
]

func _achievement_unlocked(id: String) -> bool:
    match id:
        "first_play": return total_games_played >= 1
        "first_win": return total_wins >= 1
        "five_plays": return total_games_played >= 5
        "twenty_plays": return total_games_played >= 20
        "five_wins": return total_wins >= 5
        "twenty_wins": return total_wins >= 20
        "explorer": return game_play_counts.size() >= 10
        "score_500":
            for value in best_scores.values():
                if int(value) >= 500:
                    return true
    if id.begins_with("game_"):
        var game_key: String = id.trim_prefix("game_")
        return int(game_win_counts.get(game_key, 0)) >= 3
    return false

func _award_achievements() -> void:
    achievement_new.clear()
    for item in ACHIEVEMENT_INFO:
        var id: String = str(item["id"])
        if not achievement_claimed.has(id) and _achievement_unlocked(id):
            achievement_claimed[id] = true
            coins += int(item["coins"])
            xp += int(item["xp"])
            achievement_new.append(str(item["title"]))
    level = int(xp / 100) + 1

func achievements() -> void:
    _shell()
    _heading("Achievements", "Earn badges, coins and XP by playing.")
    var earned := 0
    for item in ACHIEVEMENT_INFO:
        if achievement_claimed.has(str(item["id"])):
            earned += 1
    _card("YOUR BADGES", "%d / %d unlocked  •  %d rounds played  •  %d victories" % [earned, ACHIEVEMENT_INFO.size(), total_games_played, total_wins])
    for item in ACHIEVEMENT_INFO:
        var unlocked: bool = achievement_claimed.has(str(item["id"]))
        var heading: String = ("UNLOCKED  •  " if unlocked else "LOCKED  •  ") + str(item["title"])
        var details: String = str(item["desc"]) + "\\nReward: %d coins + %d XP" % [int(item["coins"]), int(item["xp"])]
        var badge_card := _card(heading, details)
        var badge_icon := TextureRect.new()
        badge_icon.texture = preload("res://assets/ui/achievement_badge.png")
        badge_icon.custom_minimum_size = Vector2(48, 48)
        badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        badge_icon.modulate = Color.WHITE if unlocked else Color(0.4, 0.46, 0.6, 0.55)
        var badge_body := badge_card.get_child(0)
        var badge_header := HBoxContainer.new()
        badge_header.add_theme_constant_override("separation", 10)
        badge_body.add_child(badge_header)
        badge_body.move_child(badge_header, 0)
        var badge_title := badge_body.get_child(1)
        badge_body.remove_child(badge_title)
        badge_header.add_child(badge_icon)
        badge_header.add_child(badge_title)
        badge_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_child(_menu_button("BACK TO HOME", home, PANEL2, "home"))

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
    content.add_child(_menu_button("BACK TO HOME", home, PANEL2, "back"))

func _tutorial_menu() -> void:
    _shell()
    _heading("Game Tutorials", "Choose a game to review its instructions before playing.")
    for g in GAMES:
        var id: String = str(g.id)
        content.add_child(_button("HOW TO PLAY: %s" % str(g.title), func(): _replay_tutorial(id), Color("#344a9b")))
    content.add_child(_menu_button("SETTINGS", settings, PANEL2, "settings"))

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
    content.add_child(_menu_button("SETTINGS", settings, PANEL2, "settings"))

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
    achievement_claimed.clear()
    game_play_counts.clear()
    game_win_counts.clear()
    total_games_played = 0
    total_wins = 0
    achievement_new.clear()
    owned_themes = {"classic": true}
    equipped_theme = "classic"
    owned_avatars = {"star": true}
    equipped_avatar = "star"
    owned_effects = {"classic": true}
    equipped_effect = "classic"
    login_last_claim = ""
    login_streak = 0
    login_total_claims = 0
    login_notice = ""
    equipped_title = "explorer"
    title_notice = ""
    mission_day = ""
    mission_progress = {}
    mission_claimed = {}
    mission_notice = ""
    shop_message = ""
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
    heading.add_theme_font_size_override("font_size", 23)
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
    content.add_child(_menu_button("RETURN TO LOBBY", home, PANEL2, "back", 46))
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

func _login_can_claim() -> bool:
    return login_last_claim != Time.get_date_string_from_system()


func _login_claim() -> void:
    if not _login_can_claim():
        return
    var today: String = Time.get_date_string_from_system()
    var yesterday: String = Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string(today + "T12:00:00") - 86400.0)
    if login_last_claim == yesterday:
        login_streak += 1
    else:
        login_streak = 1
    login_streak = mini(login_streak, 7)
    var day_index: int = login_streak - 1
    var coin_rewards := [20, 30, 40, 50, 65, 80, 150]
    var xp_rewards := [20, 25, 35, 45, 55, 70, 125]
    var coins_earned: int = coin_rewards[day_index]
    var xp_earned: int = xp_rewards[day_index]
    coins += coins_earned
    xp += xp_earned
    level = int(xp / 100) + 1
    login_last_claim = today
    login_total_claims += 1
    login_notice = "Day %d reward claimed: +%d coins and +%d XP!" % [login_streak, coins_earned, xp_earned]
    _play_sound(SFX_COLLECT)
    _save()
    daily_missions()


func _login_calendar() -> void:
    _heading("Daily Login Rewards", "Claim once a day. Come back tomorrow to keep your streak!")
    var day_rewards := [20, 30, 40, 50, 65, 80, 150]
    var xp_rewards := [20, 25, 35, 45, 55, 70, 125]
    var current_day: int = mini(login_streak + (1 if _login_can_claim() and login_streak > 0 else 0), 7)
    if login_streak == 0:
        current_day = 1
    var yesterday: String = Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string(Time.get_date_string_from_system() + "T12:00:00") - 86400.0)
    if _login_can_claim() and login_last_claim != yesterday:
        current_day = 1
    _card("LOGIN STREAK", "%d consecutive days claimed  •  %d total claims" % [login_streak, login_total_claims])
    for i in range(7):
        var marker: String = "NEXT" if i + 1 == current_day and _login_can_claim() else ("CLAIMED" if i + 1 <= login_streak and not _login_can_claim() else "UPCOMING")
        _card("DAY %d  •  %s" % [i + 1, marker], "%d coins + %d XP" % [day_rewards[i], xp_rewards[i]])
    if login_notice != "":
        _card("LATEST LOGIN REWARD", login_notice)
    if _login_can_claim():
        content.add_child(_button("CLAIM TODAY'S LOGIN REWARD", _login_claim, Color("#36e58a"), 56))
    else:
        _card("COME BACK TOMORROW", "Today's login reward has already been claimed.")


func _weekly_period_key() -> String:
    # ISO-style Monday week boundary using the local device calendar.
    var today: Dictionary = Time.get_date_dict_from_system()
    var weekday: int = int(today.get("weekday", 1))
    # Godot: Sunday=0, Monday=1, ..., Saturday=6.
    var days_since_monday: int = (weekday + 6) % 7
    var now: float = Time.get_unix_time_from_system()
    var date_text: String = Time.get_date_string_from_unix_time(now - float(days_since_monday) * 86400.0)
    return date_text


func _weekly_reset_if_needed() -> void:
    var period: String = _weekly_period_key()
    if weekly_key != period:
        weekly_key = period
        weekly_progress = {}
        weekly_claimed = {}
        weekly_games = {}
        weekly_notice = ""


func _weekly_definitions() -> Array[Dictionary]:
    return [
        {"id":"rounds", "title":"Arcade Explorer", "detail":"Finish 15 mini-game rounds this week.", "target":15, "coins":180, "xp":200},
        {"id":"wins", "title":"Victory Marathon", "detail":"Successfully clear 8 levels this week.", "target":8, "coins":240, "xp":250},
        {"id":"variety", "title":"World Tour", "detail":"Finish a round in 5 different mini-games.", "target":5, "coins":300, "xp":300}
    ]


func _weekly_record(id: String, passed: bool) -> void:
    _weekly_reset_if_needed()
    if not weekly_claimed.has("rounds"):
        weekly_progress["rounds"] = mini(int(weekly_progress.get("rounds", 0)) + 1, 15)
    if passed and not weekly_claimed.has("wins"):
        weekly_progress["wins"] = mini(int(weekly_progress.get("wins", 0)) + 1, 8)
    if not weekly_claimed.has("variety"):
        weekly_games[id] = true
        weekly_progress["variety"] = mini(weekly_games.size(), 5)


func _weekly_claim(key: String) -> void:
    _weekly_reset_if_needed()
    for challenge in _weekly_definitions():
        if str(challenge["id"]) != key or weekly_claimed.has(key):
            continue
        if int(weekly_progress.get(key, 0)) < int(challenge["target"]):
            return
        weekly_claimed[key] = true
        coins += int(challenge["coins"])
        xp += int(challenge["xp"])
        level = int(xp / 100) + 1
        weekly_notice = "Claimed %s: +%d coins and +%d XP!" % [str(challenge["title"]), int(challenge["coins"]), int(challenge["xp"])]
        _play_sound(SFX_COLLECT)
        _save()
        weekly_challenges()
        return


func weekly_challenges() -> void:
    _weekly_reset_if_needed()
    current_tab = "rewards"
    _shell()
    _heading("Weekly Challenges", "Three bigger goals to complete before the next Monday.")
    var weekly_ready: int = _weekly_rewards_ready()
    if weekly_ready > 0:
        _card("READY TO CLAIM", "%d weekly reward%s available below." % [weekly_ready, "" if weekly_ready == 1 else "s"])
    _card("THIS WEEK", "Started Monday %s. Progress resets next Monday (device local time)." % weekly_key)
    if weekly_notice != "":
        _card("REWARD CLAIMED", weekly_notice)
    for challenge in _weekly_definitions():
        var key: String = str(challenge["id"])
        var target: int = int(challenge["target"])
        var progress: int = mini(int(weekly_progress.get(key, 0)), target)
        var claimed: bool = weekly_claimed.has(key)
        var status: String = "CLAIMED" if claimed else ("READY TO CLAIM" if progress >= target else "%d / %d" % [progress, target])
        _card(str(challenge["title"]), "%s\nProgress: %s\nReward: %d coins + %d XP" % [str(challenge["detail"]), status, int(challenge["coins"]), int(challenge["xp"])])
        var bar := ProgressBar.new()
        bar.custom_minimum_size.y = 16
        bar.max_value = target
        bar.value = progress
        bar.show_percentage = false
        content.add_child(bar)
        if not claimed and progress >= target:
            var claim_key: String = key
            content.add_child(_button("CLAIM WEEKLY REWARD", func(): _weekly_claim(claim_key), Color("#34d399"), 60))
    content.add_child(_menu_button("BACK TO REWARDS", _rewards_hub, PANEL2, "back"))


func _mission_today() -> String:
    return Time.get_date_string_from_system()


func _mission_reset_if_needed() -> void:
    var today := _mission_today()
    if mission_day != today:
        mission_day = today
        mission_progress = {}
        mission_claimed = {}
        mission_notice = ""


func _mission_definitions() -> Array[Dictionary]:
    # Three deterministic missions per calendar day; no internet required.
    var day_info: Dictionary = Time.get_datetime_dict_from_datetime_string(mission_day, false)
    var day_number: int = int(day_info.get("year", 2026)) * 372 + int(day_info.get("month", 1)) * 31 + int(day_info.get("day", 1))
    var focus_game: String = MISSION_GAMES[day_number % MISSION_GAMES.size()]
    var other_game: String = MISSION_GAMES[(day_number + 4) % MISSION_GAMES.size()]
    return [
        {"id":"play_three", "title":"Daily Warm-Up", "detail":"Finish any 3 mini-game rounds.", "target":3, "coins":40, "xp":45},
        {"id":"focus", "title":"Spotlight: %s" % _game_name(focus_game), "detail":"Finish 2 rounds of %s." % _game_name(focus_game), "target":2, "coins":65, "xp":70, "game":focus_game},
        {"id":"win", "title":"Victory Quest: %s" % _game_name(other_game), "detail":"Successfully clear 1 level of %s." % _game_name(other_game), "target":1, "coins":85, "xp":90, "game":other_game}
    ]


func _mission_record(id: String, passed: bool) -> void:
    _mission_reset_if_needed()
    for mission in _mission_definitions():
        var key: String = str(mission["id"])
        if mission_claimed.has(key):
            continue
        if key == "focus" and id != str(mission["game"]):
            continue
        if key == "win" and (not passed or id != str(mission["game"])):
            continue
        mission_progress[key] = mini(int(mission_progress.get(key, 0)) + 1, int(mission["target"]))


func _challenge_streak_reward() -> void:
    if challenge_streak_last_day == mission_day:
        return
    for mission in _mission_definitions():
        if not mission_claimed.has(str(mission["id"])):
            return
    var today: String = mission_day
    var yesterday: String = Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string(today + "T12:00:00") - 86400.0)
    challenge_streak = challenge_streak + 1 if challenge_streak_last_day == yesterday else 1
    challenge_streak_last_day = today
    var coins_earned: int = mini(25 * challenge_streak, 175)
    var xp_earned: int = mini(30 * challenge_streak, 210)
    coins += coins_earned
    xp += xp_earned
    level = int(xp / 100) + 1
    challenge_streak_notice = "Day %d streak complete! +%d coins and +%d XP." % [challenge_streak, coins_earned, xp_earned]
    _play_sound(SFX_COLLECT)


func _mission_claim(key: String) -> void:
    _mission_reset_if_needed()
    for mission in _mission_definitions():
        if str(mission["id"]) != key or mission_claimed.has(key):
            continue
        if int(mission_progress.get(key, 0)) < int(mission["target"]):
            return
        mission_claimed[key] = true
        coins += int(mission["coins"])
        xp += int(mission["xp"])
        level = int(xp / 100) + 1
        mission_notice = "Claimed %s: +%d coins and +%d XP!" % [str(mission["title"]), int(mission["coins"]), int(mission["xp"])]
        _challenge_streak_reward()
        _play_sound(SFX_COLLECT)
        _save()
        daily_missions()
        return


func daily_missions() -> void:
    _mission_reset_if_needed()
    _shell()
    _heading("Daily Missions", "Three fresh challenges each day. Complete them to claim extra rewards!")
    var daily_ready: int = _daily_rewards_ready()
    if daily_ready > 0:
        _card("REWARDS WAITING", "%d daily reward%s ready to claim, including today's login reward if available." % [daily_ready, "" if daily_ready == 1 else "s"])
    _login_calendar()
    _heading("Today's Missions", "Claim all three missions today to build your challenge streak.")
    var streak_display: int = challenge_streak
    var yesterday: String = Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string(mission_day + "T12:00:00") - 86400.0)
    if challenge_streak_last_day != mission_day and challenge_streak_last_day != yesterday:
        streak_display = 0
    var next_streak: int = streak_display + (0 if challenge_streak_last_day == mission_day else 1)
    var next_coins: int = mini(25 * next_streak, 175)
    var next_xp: int = mini(30 * next_streak, 210)
    _card("DAILY CHALLENGE STREAK", "%d consecutive completed days\\n%s" % [streak_display, "Today's streak bonus already claimed!" if challenge_streak_last_day == mission_day else "Complete and claim all 3 missions: +%d coins and +%d XP" % [next_coins, next_xp]])
    if challenge_streak_notice != "":
        _card("STREAK REWARD", challenge_streak_notice)
    _card("TODAY: %s" % mission_day, "Missions reset on your device's next local calendar day.")
    if mission_notice != "":
        _card("REWARD CLAIMED", mission_notice)
    for mission in _mission_definitions():
        var key: String = str(mission["id"])
        var progress: int = int(mission_progress.get(key, 0))
        var target: int = int(mission["target"])
        var claimed: bool = mission_claimed.has(key)
        var status: String = "CLAIMED" if claimed else ("READY TO CLAIM" if progress >= target else "%d / %d" % [progress, target])
        _card(str(mission["title"]), "%s\nProgress: %s\nReward: %d coins + %d XP" % [str(mission["detail"]), status, int(mission["coins"]), int(mission["xp"])])
        if not claimed and progress >= target:
            content.add_child(_button("CLAIM REWARD", func(): _mission_claim(key), Color("#36e58a"), 52))
        elif not claimed and mission.has("game"):
            var game_id_to_play: String = str(mission["game"])
            content.add_child(_button("PLAY %s" % _game_name(game_id_to_play), func(): launch(game_id_to_play), Color("#344a9b"), 48))
    content.add_child(_menu_button("BACK TO HOME", home, PANEL2, "back"))


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
    total_games_played += 1
    game_play_counts[id] = int(game_play_counts.get(id, 0)) + 1
    if passed:
        total_wins += 1
        game_win_counts[id] = int(game_win_counts.get(id, 0)) + 1
    _award_achievements()
    _mission_record(id, passed)
    _weekly_record(id, passed)
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
    if not achievement_new.is_empty():
        _card("NEW ACHIEVEMENT!", " • ".join(achievement_new) + "\\nBonus coins and XP added to your wallet.")
    for mission in _mission_definitions():
        var mission_id: String = str(mission["id"])
        if not mission_claimed.has(mission_id) and int(mission_progress.get(mission_id, 0)) >= int(mission["target"]):
            _card("DAILY MISSION COMPLETE!", "%s — claim your bonus in Daily Missions!" % str(mission["title"]))


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
        confetti.effect_style = equipped_effect
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

    content.add_child(_menu_button("BACK TO MINIVERSE", home, PANEL2, "home"))

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
        f.store_string(JSON.stringify({"coins":coins,"xp":xp,"level":level,"best_scores":best_scores,"best_stars":best_stars,"recent_games":recent_games,"seen_tutorials":seen_tutorials,"sound_enabled":sound_enabled,"achievement_claimed":achievement_claimed,"total_games_played":total_games_played,"total_wins":total_wins,"game_play_counts":game_play_counts,"game_win_counts":game_win_counts,"owned_themes":owned_themes,"equipped_theme":equipped_theme,"owned_avatars":owned_avatars,"equipped_avatar":equipped_avatar,"owned_effects":owned_effects,"equipped_effect":equipped_effect,"mission_day":mission_day,"mission_progress":mission_progress,"mission_claimed":mission_claimed,"login_last_claim":login_last_claim,"login_streak":login_streak,"login_total_claims":login_total_claims,"equipped_title":equipped_title,"weekly_key":weekly_key,"weekly_progress":weekly_progress,"weekly_claimed":weekly_claimed,"weekly_games":weekly_games,"challenge_streak":challenge_streak,"challenge_streak_last_day":challenge_streak_last_day}))
        f.close()

func _load_save():
    if not FileAccess.file_exists(SAVE_PATH): return
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not f: return
    var data = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(data) == TYPE_DICTIONARY:
        login_last_claim = str(data.get("login_last_claim", ""))
        login_streak = int(data.get("login_streak", 0))
        login_total_claims = int(data.get("login_total_claims", 0))
        equipped_title = str(data.get("equipped_title", "explorer"))
        weekly_key = str(data.get("weekly_key", ""))
        weekly_progress = data.get("weekly_progress", {})
        weekly_claimed = data.get("weekly_claimed", {})
        weekly_games = data.get("weekly_games", {})
        challenge_streak = int(data.get("challenge_streak", 0))
        challenge_streak_last_day = str(data.get("challenge_streak_last_day", ""))
        _weekly_reset_if_needed()
        mission_day = str(data.get("mission_day", ""))
        mission_progress = data.get("mission_progress", {})
        mission_claimed = data.get("mission_claimed", {})
        _mission_reset_if_needed()
        sound_enabled = bool(data.get("sound_enabled", true))
        coins = int(data.get("coins",0))
        xp = int(data.get("xp",0))
        level = int(data.get("level",1))
        best_scores = data.get("best_scores",{})
        best_stars = data.get("best_stars",{})
        seen_tutorials = data.get("seen_tutorials",{})
        achievement_claimed = data.get("achievement_claimed", {})
        total_games_played = int(data.get("total_games_played", 0))
        total_wins = int(data.get("total_wins", 0))
        game_play_counts = data.get("game_play_counts", {})
        game_win_counts = data.get("game_win_counts", {})
        owned_themes = data.get("owned_themes", {"classic": true})
        owned_themes["classic"] = true
        owned_avatars = data.get("owned_avatars", {"star": true})
        owned_avatars["star"] = true
        owned_effects = data.get("owned_effects", {"classic": true})
        owned_effects["classic"] = true
        equipped_effect = str(data.get("equipped_effect", "classic"))
        if not owned_effects.has(equipped_effect):
            equipped_effect = "classic"
        equipped_avatar = str(data.get("equipped_avatar", "star"))
        if not owned_avatars.has(equipped_avatar):
            equipped_avatar = "star"
        equipped_theme = str(data.get("equipped_theme", "classic"))
        if not owned_themes.has(equipped_theme):
            equipped_theme = "classic"
        recent_games.clear()
        for saved_id in data.get("recent_games", []):
            if _game_data(str(saved_id)).size() > 0 and recent_games.size() < 3:
                recent_games.append(str(saved_id))
