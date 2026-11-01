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
const NeonDodge = preload("res://scripts/neon_dodge.gd")
const TileSlide = preload("res://scripts/tile_slide.gd")
const FruitCatch = preload("res://scripts/fruit_catch.gd")
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
    {"id":"rhythm","title":"Rhythm Rush","genre":"TIMING ARCADE","desc":"Tap glowing notes on the beat line.","color":Color("#fb86d5")},
    {"id":"dodge","title":"Neon Dodge","genre":"REFLEX SURVIVAL","desc":"Drag your glowing orb to dodge falling hazards.","color":Color("#55f0ed")},
    {"id":"slide","title":"Tile Slide","genre":"PUZZLE","desc":"Slide numbered tiles into order using the empty space.","color":Color("#a9b6ff")},
    {"id":"fruit","title":"Fruit Catch","genre":"ARCADE","desc":"Catch falling fruit and dodge dangerous bombs.","color":Color("#ffb55f")}
]

var current_tab := "home"
var rewards_snapshot_expanded := false

var shop_category := "home"
var profile_section := "overview"
var showcased_badge := "none"
var showcased_game := "none"
var showcase_notice := ""
var content: VBoxContainer
var lobby_scroll: ScrollContainer
var lobby_wallet_label: Label
var lobby_touch_scrolling := true
var coins := 0
var xp := 0
var level := 1
var last_rewarded_level := 1
var level_up_notice := ""
var best_scores: Dictionary = {}
var best_stars: Dictionary = {}
var recent_games: Array[String] = []
var game_id := ""
var game_root: Control
var rng := RandomNumberGenerator.new()
var sound_enabled := true
var show_background_glow := true
var compact_menus := false
var show_header_tagline := true
var settings_section := "home"
var equipped_background := "midnight"
var equipped_banner := "starlight"
var equipped_banner_decoration := "sparkles"
var custom_player_name := "Player"
var custom_player_motto := "Small games. Big fun."
var equipped_name_style := "classic"
var owned_name_styles: Dictionary = {}
var name_style_notice := ""
const NAME_STYLES = [
    {"id":"classic","name":"Classic","color":"#ffffff","symbol":"","description":"Simple white name"},
    {"id":"sky","name":"Sky Blue","color":"#8ad8ff","symbol":"✦","description":"Bright blue name with a star"},
    {"id":"rose","name":"Rose","color":"#ffb5d1","symbol":"♥","description":"Soft pink name with a heart"},
    {"id":"mint","name":"Mint","color":"#a3f7c5","symbol":"❖","description":"Fresh green name with a flourish","price":120},
    {"id":"gold","name":"Golden","color":"#ffe08a","symbol":"★","description":"Golden champion nameplate","price":200},
    {"id":"royal","name":"Royal","color":"#d5b5ff","symbol":"♛","description":"Regal violet nameplate","level_required":5},
    {"id":"legend","name":"Legend","color":"#ffca92","symbol":"◆","description":"Exclusive level-ten nameplate","level_required":10}
]

var identity_edit_notice := ""
var owned_banner_decorations: Dictionary = {}
var banner_decoration_notice := ""
const BANNER_DECORATIONS = [
    {"id":"none","name":"None","symbol":"","description":"A clean, minimal banner"},
    {"id":"sparkles","name":"Sparkles","symbol":"✦","description":"Classic shimmering stars"},
    {"id":"hearts","name":"Hearts","symbol":"♥","description":"A cheerful heart accent"},
    {"id":"crown","name":"Royal Crown","symbol":"♛","description":"A regal banner accent","price":180},
    {"id":"diamonds","name":"Diamonds","symbol":"◆","description":"Sharp crystal decorations","price":240},
    {"id":"stars","name":"Champion Stars","symbol":"★","description":"Earned at player level 5","level_required":5},
    {"id":"laurel","name":"Victory Laurel","symbol":"❖","description":"Earned at player level 10","level_required":10},
    {"id":"master_flame","name":"Master Flame","symbol":"✹","description":"Earn 40 total wins across MiniVerse","mastery_wins_required":40},
    {"id":"master_gem","name":"Master Gem","symbol":"✧","description":"Earn 150 total wins across MiniVerse","mastery_wins_required":150},
    {"id":"achievement_star","name":"Achievement Star","symbol":"✪","description":"Claim 20 game achievements","achievement_claims_required":20},
    {"id":"achievement_crown","name":"Achievement Crown","symbol":"♕","description":"Claim all 52 game achievements","achievement_claims_required":52}
]

var owned_backgrounds: Dictionary = {}
var owned_banners: Dictionary = {}
var cosmetic_unlock_message := ""
var banner_animation_enabled := true
const MENU_BACKGROUNDS = [
    {"id":"midnight","name":"Midnight","color":"#0b1026","description":"Classic deep-space navy"},
    {"id":"nebula","name":"Nebula","color":"#241239","description":"Violet cosmic haze"},
    {"id":"ocean","name":"Deep Ocean","color":"#082a36","description":"Calm underwater blue"},
    {"id":"forest","name":"Enchanted Forest","color":"#112b25","description":"Rich emerald shadows"},
    {"id":"sunset","name":"Sunset Arcade","color":"#38202e","description":"Warm pink twilight"},
    {"id":"galaxy","name":"Galaxy","color":"#27174b","description":"Unlock with 150 coins","price":150},
    {"id":"lava","name":"Lava","color":"#442019","description":"Unlock with 250 coins","price":250},
    {"id":"ice","name":"Frost","color":"#133c53","description":"Earn at player level 5","level_required":5},
    {"id":"gold","name":"Golden Hour","color":"#443719","description":"Earn at player level 10","level_required":10}
]
const PROFILE_BANNERS = [
    {"id":"starlight","name":"Starlight","color":"#3450a2","description":"A bright blue welcome"},
    {"id":"aurora","name":"Aurora","color":"#286f73","description":"Cool northern lights"},
    {"id":"royal","name":"Royal Purple","color":"#6d3e9b","description":"A bold purple banner"},
    {"id":"ember","name":"Ember","color":"#a14c42","description":"Warm sunset energy"},
    {"id":"prism","name":"Prism","color":"#5c448f","description":"Unlock with 120 coins","price":120},
    {"id":"champion","name":"Champion","color":"#8d6333","description":"Unlock with 220 coins","price":220},
    {"id":"explorer","name":"Explorer","color":"#29745c","description":"Earn at player level 5","level_required":5},
    {"id":"legend","name":"Legend","color":"#873d73","description":"Earn at player level 10","level_required":10},
    {"id":"bronze_master","name":"Bronze Master","color":"#77503d","description":"Earn 15 total wins across MiniVerse","mastery_wins_required":15},
    {"id":"diamond_master","name":"Diamond Master","color":"#236e91","description":"Earn 80 total wins across MiniVerse","mastery_wins_required":80},
    {"id":"achievement_hunter","name":"Achievement Hunter","color":"#5b3581","description":"Claim 10 game achievements","achievement_claims_required":10},
    {"id":"achievement_legend","name":"Achievement Legend","color":"#805329","description":"Claim 35 game achievements","achievement_claims_required":35}
]

var sound_player: AudioStreamPlayer
var library_filter := "ALL"
var favorite_games: Dictionary = {}
var discovery_rewards_claimed: Dictionary = {}
var discovery_notice := ""
const DISCOVERY_COIN_REWARD := 35
var collection_milestones_claimed: Dictionary = {}
var collection_reward_notice := ""
const COLLECTION_MILESTONES := [
    {"count": 3, "title": "Curious Explorer", "coins": 75},
    {"count": 5, "title": "Game Collector", "coins": 125},
    {"count": 8, "title": "Arcade Adventurer", "coins": 200},
    {"count": 10, "title": "MiniVerse Completionist", "coins": 350}
]
var seen_tutorials: Dictionary = {}
var achievement_claimed: Dictionary = {}
var total_games_played := 0
var total_wins := 0
var game_play_counts: Dictionary = {}
var game_win_counts: Dictionary = {}
var mastery_rewards_claimed: Dictionary = {}
var game_achievement_claimed: Dictionary = {}
var game_achievement_notice := ""
var achievement_selected_game := ""
var achievement_status_filter := "ALL"
const GAME_ACHIEVEMENT_TIERS = [
    {"id":"first_steps","name":"First Steps","type":"plays","target":1,"coins":20,"desc":"Play this game once"},
    {"id":"regular","name":"Regular","type":"plays","target":10,"coins":60,"desc":"Play this game 10 times"},
    {"id":"first_win","name":"First Victory","type":"wins","target":1,"coins":35,"desc":"Win a round in this game"},
    {"id":"dedicated","name":"Dedicated","type":"wins","target":15,"coins":110,"desc":"Win 15 rounds in this game"}
]

var mastery_selected_game := ""
var mastery_rank_filter := "ALL"
var mastery_notice := ""
const MASTERY_TIERS = [
    {"wins":3,"name":"Bronze","coins":40},
    {"wins":10,"name":"Silver","coins":90},
    {"wins":25,"name":"Gold","coins":175},
    {"wins":50,"name":"Diamond","coins":300}
]

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
    {"id":"rose", "name":"Rose Sparkle", "price":500, "color":"#fb7185", "description":"Bright pink highlights."},
    {"id":"challenger", "name":"Challenger Flame", "price":0, "level_required":10, "color":"#f97316", "description":"Exclusive level 10 reward. Fiery orange accents."},
    {"id":"champion", "name":"Champion Gold", "price":0, "level_required":20, "color":"#facc15", "description":"Exclusive level 20 reward. Golden highlights."},
    {"id":"master", "name":"Arcade Master Neon", "price":0, "level_required":35, "color":"#38bdf8", "description":"Exclusive level 35 reward. Brilliant neon blue."},
    {"id":"legend", "name":"Arcade Legend", "price":0, "level_required":50, "color":"#e879f9", "description":"Exclusive level 50 reward. Legendary violet glow."}
]
var owned_avatars: Dictionary = {"star": true}
var equipped_avatar := "star"
var owned_avatar_frames: Dictionary = {"classic": true}
var cosmetic_rewards_claimed: Dictionary = {}
var cosmetic_reward_notice := ""
const COSMETIC_REWARD_MILESTONES := [
    {"count": 4, "coins": 60},
    {"count": 8, "coins": 120},
    {"count": 12, "coins": 200},
    {"count": 16, "coins": 300}
]
var equipped_profile_badge := "rookie"
var badge_notice := ""
const PROFILE_BADGES := [
    {"id":"rookie","name":"First Steps","symbol":"★","color":"#a78bfa","requirement":"Available from the start"},
    {"id":"explorer","name":"Explorer","symbol":"✦","color":"#38bdf8","requirement":"Discover 3 games"},
    {"id":"collector","name":"Collector","symbol":"◆","color":"#facc15","requirement":"Discover 5 games"},
    {"id":"champion","name":"Champion","symbol":"✹","color":"#fb923c","requirement":"Win 25 rounds"},
    {"id":"veteran","name":"Veteran","symbol":"✿","color":"#34d399","requirement":"Play 100 rounds"},
    {"id":"legend","name":"Legend","symbol":"✧","color":"#fb7185","requirement":"Reach player level 50"}
]
var equipped_avatar_frame := "classic"
var frame_notice := ""
const AVATAR_FRAMES := [
    {"id":"classic", "name":"Classic", "price":0, "color":"#a78bfa", "description":"Your original purple outline."},
    {"id":"bronze", "name":"Bronze Explorer", "price":120, "color":"#d49a65", "description":"A warm bronze border."},
    {"id":"ocean", "name":"Ocean Glow", "price":220, "color":"#22d3ee", "description":"Bright aqua highlights."},
    {"id":"royal", "name":"Royal Gold", "price":350, "color":"#facc15", "description":"A golden collector frame."},
    {"id":"legend", "name":"Legendary Rose", "price":500, "color":"#fb7185", "description":"A bold rose-colored frame."}
]
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
var daily_feature_active := false
var daily_feature_game := ""
var daily_feature_day := ""
var daily_feature_notice := ""
# Daily featured-game bonus is awarded only once per local calendar date.
var daily_feature_reward_day := ""
# Up to 30 calendar days of featured-game participation, stored locally.
var daily_feature_history: Dictionary = {}
const DAILY_FEATURE_COINS := 60
const DAILY_FEATURE_XP := 15
var mission_day := ""
var mission_progress: Dictionary = {}
var mission_claimed: Dictionary = {}
var mission_notice := ""
var challenge_ready_notice: String = ""
var daily_bonus_progress := 0
var daily_bonus_claimed := false
var daily_bonus_notice := ""
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

const MISSION_GAMES := ["fast", "merge", "stack", "memory", "whack", "sort", "snake", "dots", "hopper", "rhythm", "dodge", "slide", "fruit"]

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
    "rhythm": ["Tap the lane when a note enters the glowing catch zone.", "Each successful hit plays part of the melody. Keep the rhythm to finish the song!"],
    "dodge": ["Drag your glowing orb left and right to avoid falling neon hazards.", "Survive for 35 seconds. Earn one point each second, and clear the level by reaching its goal."],
    "slide": ["Tap a numbered tile next to the empty space to slide it.", "Put all numbers in order, with the empty space at the end. Fewer moves earn a higher score."],
    "fruit": ["Drag your basket left and right to catch falling fruit.", "Avoid bombs! Collect fruit for points and survive the 40-second round."]
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
    var bonus: Dictionary = _daily_bonus_definition()
    if not daily_bonus_claimed and daily_bonus_progress >= int(bonus["target"]):
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


func _challenge_summary_line(title: String, progress: int, target: int, claimed: bool) -> String:
    var status: String = "CLAIMED" if claimed else ("READY" if progress >= target else "%d/%d" % [mini(progress, target), target])
    return "%s  •  %s" % [title, status]


func _challenge_highlights() -> void:
    # Read-only visual feedback: use the existing progress and claim state.
    var ready_names: Array[String] = []
    var completed_today: int = 0
    var completed_week: int = 0
    for mission in _mission_definitions():
        var key: String = str(mission["id"])
        if mission_claimed.has(key):
            completed_today += 1
        elif int(mission_progress.get(key, 0)) >= int(mission["target"]):
            ready_names.append(str(mission["title"]))
    var bonus: Dictionary = _daily_bonus_definition()
    if daily_bonus_claimed:
        completed_today += 1
    elif daily_bonus_progress >= int(bonus["target"]):
        ready_names.append(str(bonus["title"]))
    for challenge in _weekly_definitions():
        var key: String = str(challenge["id"])
        if weekly_claimed.has(key):
            completed_week += 1
        elif int(weekly_progress.get(key, 0)) >= int(challenge["target"]):
            ready_names.append(str(challenge["title"]))
    if ready_names.size() > 0:
        _card("★ CHALLENGES COMPLETE!", "%d reward%s ready to claim!\n%s" % [ready_names.size(), "" if ready_names.size() == 1 else "s", "  •  ".join(ready_names)])
    elif completed_today == 4 and completed_week == 4:
        _card("★ ALL CHALLENGES CLAIMED!", "You've collected every daily and weekly challenge reward. Great work!")
    elif completed_today > 0 or completed_week > 0:
        _card("★ CHALLENGE MOMENTUM", "Daily rewards claimed: %d / 4  •  Weekly rewards claimed: %d / 4" % [completed_today, completed_week])
    var daily_progress_label := Label.new()
    daily_progress_label.text = "Daily claimed: %d / 4" % completed_today
    daily_progress_label.add_theme_font_size_override("font_size", 17)
    content.add_child(daily_progress_label)
    var daily_bar := ProgressBar.new()
    daily_bar.custom_minimum_size.y = 14
    daily_bar.max_value = 4
    daily_bar.value = completed_today
    daily_bar.show_percentage = false
    content.add_child(daily_bar)
    var weekly_progress_label := Label.new()
    weekly_progress_label.text = "Weekly claimed: %d / 4" % completed_week
    weekly_progress_label.add_theme_font_size_override("font_size", 17)
    content.add_child(weekly_progress_label)
    var weekly_bar := ProgressBar.new()
    weekly_bar.custom_minimum_size.y = 14
    weekly_bar.max_value = 4
    weekly_bar.value = completed_week
    weekly_bar.show_percentage = false
    content.add_child(weekly_bar)


func _toggle_rewards_snapshot() -> void:
    rewards_snapshot_expanded = not rewards_snapshot_expanded
    _rewards_hub()


func _rewards_section_label(title_text: String, hint_text: String) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    content.add_child(row)
    var heading := Label.new()
    heading.text = title_text
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_theme_font_size_override("font_size", 21)
    heading.add_theme_color_override("font_color", _menu_accent_text(_theme_color()))
    row.add_child(heading)
    var hint := Label.new()
    hint.text = hint_text
    hint.add_theme_font_size_override("font_size", 15)
    hint.add_theme_color_override("font_color", MUTED)
    row.add_child(hint)


func _challenge_overview() -> void:
    # Keep the two destinations visible even when the full list is collapsed.
    var daily_ready: int = maxi(0, _daily_rewards_ready() - (1 if _login_can_claim() else 0))
    var weekly_ready: int = _weekly_rewards_ready()
    _rewards_section_label("Today", "%d ready" % daily_ready)
    if rewards_snapshot_expanded:
        var daily_lines: Array[String] = []
        for mission in _mission_definitions():
            var key: String = str(mission["id"])
            daily_lines.append(_challenge_summary_line(str(mission["title"]), int(mission_progress.get(key, 0)), int(mission["target"]), mission_claimed.has(key)))
        var daily_bonus: Dictionary = _daily_bonus_definition()
        daily_lines.append(_challenge_summary_line(str(daily_bonus["title"]), daily_bonus_progress, int(daily_bonus["target"]), daily_bonus_claimed))
        _card("TODAY'S OBJECTIVES", "\n".join(daily_lines))
    content.add_child(_menu_button("OPEN DAILY MISSIONS", daily_missions, Color("#fbbf24"), "missions", 50))
    _rewards_section_label("This Week", "%d ready" % weekly_ready)
    if rewards_snapshot_expanded:
        var weekly_lines: Array[String] = []
        for challenge in _weekly_definitions():
            var key: String = str(challenge["id"])
            weekly_lines.append(_challenge_summary_line(str(challenge["title"]), int(weekly_progress.get(key, 0)), int(challenge["target"]), weekly_claimed.has(key)))
        _card("THIS WEEK'S OBJECTIVES", "\n".join(weekly_lines))
    content.add_child(_menu_button("OPEN WEEKLY CHALLENGES", weekly_challenges, Color("#34d399"), "missions", 50))
    content.add_child(_button("HIDE OBJECTIVE DETAILS" if rewards_snapshot_expanded else "SHOW ALL 8 OBJECTIVES", _toggle_rewards_snapshot, PANEL2, 48))


func _claim_all_challenge_rewards() -> void:
    # The daily login reward is intentionally excluded: it uses a separate
    # calendar claim flow. The three core daily missions still trigger the
    # normal streak calculation exactly once after they are all claimed.
    _mission_reset_if_needed()
    _weekly_reset_if_needed()
    var daily_count: int = 0
    var weekly_count: int = 0
    var coins_earned: int = 0
    var xp_earned: int = 0
    for mission in _mission_definitions():
        var key: String = str(mission["id"])
        if not mission_claimed.has(key) and int(mission_progress.get(key, 0)) >= int(mission["target"]):
            mission_claimed[key] = true
            daily_count += 1
            coins_earned += int(mission["coins"])
            xp_earned += int(mission["xp"])
    var bonus: Dictionary = _daily_bonus_definition()
    if not daily_bonus_claimed and daily_bonus_progress >= int(bonus["target"]):
        daily_bonus_claimed = true
        daily_count += 1
        coins_earned += int(bonus["coins"])
        xp_earned += int(bonus["xp"])
    for challenge in _weekly_definitions():
        var key: String = str(challenge["id"])
        if not weekly_claimed.has(key) and int(weekly_progress.get(key, 0)) >= int(challenge["target"]):
            weekly_claimed[key] = true
            weekly_count += 1
            coins_earned += int(challenge["coins"])
            xp_earned += int(challenge["xp"])
    if daily_count + weekly_count == 0:
        _rewards_hub()
        return
    coins += coins_earned
    xp += xp_earned
    level = _level_from_xp(xp)
    # Preserve the established 3-mission streak rules and reward.
    _challenge_streak_reward()
    mission_notice = "Claimed %d daily and %d weekly rewards: +%d coins, +%d XP!" % [daily_count, weekly_count, coins_earned, xp_earned]
    weekly_notice = mission_notice
    daily_bonus_notice = mission_notice
    _play_sound(SFX_COLLECT)
    _save()
    _rewards_hub()


func _rewards_hub() -> void:
    current_tab = "rewards"
    _mission_reset_if_needed()
    _weekly_reset_if_needed()
    _shell()
    _heading("Rewards Hub", "Your challenges, rewards, and daily login in one place.")
    _fantasy_feature_art("fantasy_rewards_header", "MAGICAL REWARDS AWAIT")
    if level_up_notice != "":
        _card("LEVEL-UP REWARD!", level_up_notice)
        level_up_notice = ""
    var daily_ready: int = maxi(0, _daily_rewards_ready() - (1 if _login_can_claim() else 0))
    var weekly_ready: int = _weekly_rewards_ready()
    var challenge_ready: int = daily_ready + weekly_ready
    if challenge_ready > 0:
        _card("REWARDS READY", "%d completed challenge%s waiting to be claimed." % [challenge_ready, "" if challenge_ready == 1 else "s"])
        content.add_child(_button("CLAIM ALL CHALLENGE REWARDS (%d)" % challenge_ready, _claim_all_challenge_rewards, Color("#34d399"), 56))
    _rewards_section_label("Challenge Progress", "Daily + Weekly")
    _challenge_highlights()
    _challenge_overview()
    _rewards_section_label("Daily Login", "Once per day")
    var login_label: String = "CLAIM DAILY LOGIN" if _login_can_claim() else "VIEW DAILY LOGIN CALENDAR"
    content.add_child(_menu_button(login_label, _login_rewards_page, Color("#fbbf24"), "missions", 50))
    if challenge_streak > 0:
        var streak_label := Label.new()
        streak_label.text = "Mission streak: %d day%s" % [challenge_streak, "" if challenge_streak == 1 else "s"]
        streak_label.add_theme_font_size_override("font_size", 16)
        streak_label.add_theme_color_override("font_color", MUTED)
        content.add_child(streak_label)
    _rewards_section_label("More to Earn", "Explore")
    content.add_child(_menu_button("ACHIEVEMENTS", achievements, Color("#344a9b"), "achievements", 50))
    content.add_child(_menu_button("CHALLENGES & EVENTS", events, Color("#344a9b"), "events", 50))


func _login_rewards_page() -> void:
    current_tab = "rewards"
    _mission_reset_if_needed()
    _shell()
    _heading("Daily Login", "Visit every day to keep your login rewards coming.")
    _login_calendar()
    content.add_child(_menu_button("TODAY'S MISSIONS", daily_missions, Color("#fbbf24"), "missions"))
    content.add_child(_menu_button("BACK TO REWARDS", _rewards_hub, PANEL2, "back"))


func _fantasy_nav_style(selected: bool) -> StyleBoxFlat:
    var style := _style(Color("#5831a2") if selected else Color("#1d285d"), 14)
    style.border_width_left = 2
    style.border_width_right = 2
    style.border_width_top = 2
    style.border_width_bottom = 3
    style.border_color = Color("#ffd66e") if selected else Color("#677bc5")
    style.shadow_color = Color("#09072b", 0.60)
    style.shadow_size = 3
    return style


func _bottom_navigation(root: VBoxContainer) -> void:
    var separator := ColorRect.new()
    separator.color = Color("#ffd36e")
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
        button.add_theme_stylebox_override("normal", _fantasy_nav_style(selected))
        button.add_theme_stylebox_override("hover", _fantasy_nav_style(true))
        button.add_theme_stylebox_override("pressed", _fantasy_nav_style(true))
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


# Phase 30.1: user-supplied fantasy banner visual language.
const FANTASY_BRAND_BANNER = preload("res://assets/lobby/fantasy_brand_banner.png")
const FANTASY_MENU_BACKDROP = preload("res://assets/lobby/fantasy_menu_backdrop.png")

func _fantasy_section_art() -> void:
    var frame := PanelContainer.new()
    var frame_style := _style(Color("#141d4a"), 17)
    frame_style.border_width_left = 2
    frame_style.border_width_right = 2
    frame_style.border_width_top = 2
    frame_style.border_width_bottom = 3
    frame_style.border_color = Color("#f5c76a")
    frame.add_theme_stylebox_override("panel", frame_style)
    content.add_child(frame)
    var illustration := TextureRect.new()
    illustration.texture = FANTASY_BRAND_BANNER
    illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    illustration.custom_minimum_size.y = maxf(220.0, (get_viewport_rect().size.x - 42.0) * 368.0 / 491.0)
    illustration.clip_contents = true
    illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
    frame.add_child(illustration)


func _shell():
    tutorial_overlay = null
    lobby_touch_scrolling = true
    for c in get_children():
        if c != sound_player:
            c.queue_free()
    var bg := ColorRect.new()
    bg.color = _background_color().lerp(_theme_color(), 0.06)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    # Fantasy environment behind translucent, high-contrast menu panels.
    var fantasy_backdrop := TextureRect.new()
    fantasy_backdrop.texture = FANTASY_MENU_BACKDROP
    fantasy_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    fantasy_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    fantasy_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fantasy_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(fantasy_backdrop)
    var backdrop_tint := ColorRect.new()
    backdrop_tint.color = Color("#17103d", 0.25)
    backdrop_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(backdrop_tint)
    # Subtle arcade-style corner lights behind the interface.
    for deco in [{"pos": Vector2(-90, 150), "size": Vector2(250, 250), "color": Color(_theme_color(), 0.12)}, {"pos": Vector2(500, 540), "size": Vector2(280, 280), "color": Color("#22d3ee", 0.05)}]:
        var glow := ColorRect.new()
        glow.position = deco.pos
        glow.size = deco.size
        glow.color = deco.color
        glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
        if show_background_glow:
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
    if show_header_tagline:
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
    lobby_wallet_label = wallet
    # Keep Settings one tap away on Home without adding another dashboard card.
    if current_tab == "home":
        var settings_button := Button.new()
        settings_button.text = "⚙"
        settings_button.tooltip_text = "Settings"
        settings_button.custom_minimum_size = Vector2(48, 48)
        settings_button.focus_mode = Control.FOCUS_NONE
        settings_button.add_theme_font_size_override("font_size", 27)
        settings_button.add_theme_color_override("font_color", Color("#ffffff"))
        settings_button.add_theme_stylebox_override("normal", _lobby_button_style(Color("#344a76")))
        settings_button.add_theme_stylebox_override("hover", _lobby_button_style(Color("#49679b")))
        settings_button.add_theme_stylebox_override("pressed", _lobby_button_style(Color("#263b62")))
        settings_button.pressed.connect(func():
            _play_sound(SFX_TAP)
            settings()
        )
        wallet_group.add_child(settings_button)
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
    content.add_theme_constant_override("separation", 8 if compact_menus else 16)
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
    style.border_color = Color("#ffd36e").lerp(color.lightened(0.30), 0.22)
    style.shadow_color = Color("#0a0639", 0.72)
    style.shadow_size = 5
    style.shadow_offset = Vector2(0, 4)
    return style

func _lobby_card_style(accent: Color) -> StyleBoxFlat:
    var style := _style(Color("#171348").lerp(_theme_color(), 0.10), 18)
    style.content_margin_left = 16
    style.content_margin_right = 16
    style.content_margin_top = 15
    style.content_margin_bottom = 15
    style.border_width_left = 3
    style.border_width_right = 1
    style.border_width_top = 1
    style.border_width_bottom = 2
    style.border_color = Color("#ffd36e").lerp(accent, 0.24)
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

func _fantasy_shortcut(asset_name: String, cb: Callable) -> TextureButton:
    var button := TextureButton.new()
    button.texture_normal = load("res://assets/lobby/concept_shortcut_%s.png" % asset_name)
    button.texture_hover = button.texture_normal
    button.texture_pressed = button.texture_normal
    button.ignore_texture_size = true
    button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    button.custom_minimum_size = Vector2(0, 98)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.mouse_filter = Control.MOUSE_FILTER_PASS
    button.pressed.connect(func():
        _play_sound(SFX_TAP)
        cb.call()
    )
    return button


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

func _background_color() -> Color:
    for item in MENU_BACKGROUNDS:
        if str(item["id"]) == equipped_background:
            return Color(str(item["color"]))
    return BG


func _background_name() -> String:
    for item in MENU_BACKGROUNDS:
        if str(item["id"]) == equipped_background:
            return str(item["name"])
    return "Midnight"


func _profile_banner_preview(banner_id: String, large: bool = false) -> PanelContainer:
    var banner_item: Dictionary = PROFILE_BANNERS[0]
    for item in PROFILE_BANNERS:
        if str(item["id"]) == banner_id:
            banner_item = item
            break
    var color: Color = Color(str(banner_item["color"]))
    var panel := PanelContainer.new()
    var style := _style(color, 18)
    style.border_width_left = 3
    style.border_width_right = 3
    style.border_width_top = 3
    style.border_width_bottom = 3
    style.border_color = color.lightened(0.42)
    style.content_margin_top = 26 if large else 16
    style.content_margin_bottom = 26 if large else 16
    panel.add_theme_stylebox_override("panel", style)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 8)
    panel.add_child(stack)
    var symbol := Label.new()
    symbol.text = _banner_decoration_symbol() if banner_id == equipped_banner else "✦  ◆  ✦"
    symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    symbol.add_theme_font_size_override("font_size", 26 if large else 21)
    symbol.add_theme_color_override("font_color", Color.WHITE)
    stack.add_child(symbol)
    var name_label := Label.new()
    name_label.text = str(banner_item["name"]).to_upper()
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 26 if large else 20)
    name_label.add_theme_color_override("font_color", Color.WHITE)
    stack.add_child(name_label)
    if large:
        var subtitle := Label.new()
        subtitle.text = "MY MINIVERSE PROFILE"
        subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        subtitle.add_theme_font_size_override("font_size", 15)
        subtitle.add_theme_color_override("font_color", Color.WHITE)
        stack.add_child(subtitle)
    return panel


func _save_player_identity(new_name: String, new_motto: String) -> void:
    var clean_name: String = new_name.strip_edges().replace("\n", " ").replace("\r", " ")
    var clean_motto: String = new_motto.strip_edges().replace("\n", " ").replace("\r", " ")
    if clean_name.is_empty():
        identity_edit_notice = "Please enter a player name."
        _open_profile_section("identity")
        return
    custom_player_name = clean_name.substr(0, 18)
    custom_player_motto = clean_motto.substr(0, 48)
    identity_edit_notice = "Your identity has been saved!"
    _save()
    _open_profile_section("identity")


func _name_style_data() -> Dictionary:
    for item in NAME_STYLES:
        if str(item["id"]) == equipped_name_style:
            return item
    return NAME_STYLES[0]


func _styled_player_name() -> String:
    var symbol: String = str(_name_style_data().get("symbol", ""))
    return (symbol + "  " if symbol != "" else "") + custom_player_name


func _name_style_owned(item: Dictionary) -> bool:
    var item_id: String = str(item["id"])
    var required_level: int = int(item.get("level_required", 0))
    var price: int = int(item.get("price", 0))
    return (price == 0 and required_level == 0) or (required_level > 0 and level >= required_level) or owned_name_styles.has(item_id)


func _choose_name_style(item_id: String) -> void:
    for item in NAME_STYLES:
        if str(item["id"]) != item_id:
            continue
        var style_name: String = str(item["name"])
        var price: int = int(item.get("price", 0))
        var required_level: int = int(item.get("level_required", 0))
        if _name_style_owned(item):
            equipped_name_style = item_id
            name_style_notice = "Equipped " + style_name + "."
        elif required_level > level:
            name_style_notice = "Reach level %d to unlock %s." % [required_level, style_name]
        elif coins < price:
            name_style_notice = "You need %d more coins for %s." % [price - coins, style_name]
        else:
            coins -= price
            owned_name_styles[item_id] = true
            equipped_name_style = item_id
            name_style_notice = "Unlocked %s for %d coins!" % [style_name, price]
        _save()
        _open_profile_section("name_styles")
        return


func _banner_decoration_symbol() -> String:
    for item in BANNER_DECORATIONS:
        if str(item["id"]) == equipped_banner_decoration:
            var symbol: String = str(item["symbol"])
            return symbol + "   " + symbol if symbol != "" else ""
    return "✦   ✦"


func _decorated_banner_title() -> String:
    var symbol: String = _banner_decoration_symbol()
    return symbol + "  " + _banner_name().to_upper() + "  " + symbol if symbol != "" else _banner_name().to_upper()


func _total_mastery_wins() -> int:
    var total: int = 0
    for game in GAMES:
        total += int(game_win_counts.get(str(game["id"]), 0))
    return total


func _cosmetic_unlock_status(item: Dictionary) -> String:
    if int(item.get("achievement_claims_required", 0)) > 0:
        return _achievement_cosmetic_progress(item)
    if int(item.get("mastery_wins_required", 0)) > 0:
        return _mastery_cosmetic_progress(item)
    if int(item.get("level_required", 0)) > 0:
        return "LEVEL %d" % int(item["level_required"])
    return "%d COINS" % int(item.get("price", 0))


func _achievement_cosmetic_progress(item: Dictionary) -> String:
    var goal: int = int(item.get("achievement_claims_required", 0))
    if goal <= 0:
        return ""
    return "%d / %d ACHIEVEMENTS CLAIMED" % [min(game_achievement_claimed.size(), goal), goal]


func _mastery_cosmetic_progress(item: Dictionary) -> String:
    var goal: int = int(item.get("mastery_wins_required", 0))
    if goal <= 0:
        return ""
    return "%d / %d TOTAL WINS" % [min(_total_mastery_wins(), goal), goal]


func _banner_decoration_owned(item: Dictionary) -> bool:
    var decoration_id: String = str(item["id"])
    var required_level: int = int(item.get("level_required", 0))
    var price: int = int(item.get("price", 0))
    var mastery_goal: int = int(item.get("mastery_wins_required", 0))
    var achievement_goal: int = int(item.get("achievement_claims_required", 0))
    if achievement_goal > 0:
        return game_achievement_claimed.size() >= achievement_goal
    if mastery_goal > 0:
        return _total_mastery_wins() >= mastery_goal
    return (required_level == 0 and price == 0) or (required_level > 0 and level >= required_level) or owned_banner_decorations.has(decoration_id)


func _choose_banner_decoration(decoration_id: String) -> void:
    for item in BANNER_DECORATIONS:
        if str(item["id"]) != decoration_id:
            continue
        var name: String = str(item["name"])
        var price: int = int(item.get("price", 0))
        var required_level: int = int(item.get("level_required", 0))
        if int(item.get("achievement_claims_required", 0)) > 0 and not _banner_decoration_owned(item):
            banner_decoration_notice = "Claim more game achievements! " + _achievement_cosmetic_progress(item)
        elif int(item.get("mastery_wins_required", 0)) > 0 and not _banner_decoration_owned(item):
            banner_decoration_notice = "Keep winning games! " + _mastery_cosmetic_progress(item)
        elif _banner_decoration_owned(item):
            equipped_banner_decoration = decoration_id
            banner_decoration_notice = "Equipped " + name + "."
        elif required_level > level:
            banner_decoration_notice = "Reach level %d to unlock %s." % [required_level, name]
        elif price > coins:
            banner_decoration_notice = "You need %d more coins for %s." % [price - coins, name]
        else:
            coins -= price
            owned_banner_decorations[decoration_id] = true
            equipped_banner_decoration = decoration_id
            banner_decoration_notice = "Unlocked and equipped %s for %d coins!" % [name, price]
        _save()
        _open_profile_section("decorations")
        return


func _banner_color() -> Color:
    for item in PROFILE_BANNERS:
        if str(item["id"]) == equipped_banner:
            return Color(str(item["color"]))
    return Color("#3450a2")


func _banner_name() -> String:
    for item in PROFILE_BANNERS:
        if str(item["id"]) == equipped_banner:
            return str(item["name"])
    return "Starlight"


func _equip_background(id: String) -> void:
    _unlock_cosmetic_choice("background", id)


func _equip_banner(id: String) -> void:
    _unlock_cosmetic_choice("banner", id)


func _cosmetic_owned(kind: String, item: Dictionary) -> bool:
    var cosmetic_id: String = str(item["id"])
    var mastery_goal: int = int(item.get("mastery_wins_required", 0))
    var achievement_goal: int = int(item.get("achievement_claims_required", 0))
    if achievement_goal > 0:
        return game_achievement_claimed.size() >= achievement_goal
    if mastery_goal > 0:
        return _total_mastery_wins() >= mastery_goal
    if int(item.get("price", 0)) == 0 and int(item.get("level_required", 0)) == 0:
        return true
    if int(item.get("level_required", 0)) > 0 and level >= int(item["level_required"]):
        return true
    return owned_backgrounds.has(cosmetic_id) if kind == "background" else owned_banners.has(cosmetic_id)


func _unlock_cosmetic_choice(kind: String, cosmetic_id: String) -> void:
    var items: Array = MENU_BACKGROUNDS if kind == "background" else PROFILE_BANNERS
    for item in items:
        if str(item["id"]) != cosmetic_id:
            continue
        var item_name: String = str(item["name"])
        var required_level: int = int(item.get("level_required", 0))
        var price: int = int(item.get("price", 0))
        if int(item.get("achievement_claims_required", 0)) > 0 and not _cosmetic_owned(kind, item):
            cosmetic_unlock_message = "Claim more game achievements! " + _achievement_cosmetic_progress(item)
        elif int(item.get("mastery_wins_required", 0)) > 0 and not _cosmetic_owned(kind, item):
            cosmetic_unlock_message = "Keep winning games! " + _mastery_cosmetic_progress(item)
        elif _cosmetic_owned(kind, item):
            if kind == "background":
                equipped_background = cosmetic_id
            else:
                equipped_banner = cosmetic_id
            cosmetic_unlock_message = "Equipped %s!" % item_name
        elif required_level > level:
            cosmetic_unlock_message = "Reach player level %d to unlock %s." % [required_level, item_name]
        elif coins >= price and price > 0:
            coins -= price
            if kind == "background":
                owned_backgrounds[cosmetic_id] = true
                equipped_background = cosmetic_id
            else:
                owned_banners[cosmetic_id] = true
                equipped_banner = cosmetic_id
            cosmetic_unlock_message = "Unlocked and equipped %s for %d coins!" % [item_name, price]
            _play_sound(SFX_COLLECT)
        else:
            cosmetic_unlock_message = "You need %d more coins for %s." % [price - coins, item_name]
        _save()
        if kind == "background":
            _settings_page("backgrounds")
        else:
            _open_profile_section("banners")
        return


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
        elif int(item.get("level_required", 0)) > level:
            shop_message = "Reach player level %d to unlock %s." % [int(item["level_required"]), str(item["name"])]
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


func _framed_avatar(avatar_id: String, dimension: int = 64) -> PanelContainer:
    var frame_color := Color("#a78bfa")
    for frame in AVATAR_FRAMES:
        if str(frame["id"]) == equipped_avatar_frame:
            frame_color = Color(str(frame["color"]))
            break
    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#181a34")
    style.border_color = frame_color
    style.set_border_width_all(5)
    style.set_corner_radius_all(18)
    style.set_content_margin_all(5)
    panel.add_theme_stylebox_override("panel", style)
    # HBoxContainer otherwise stretches the frame to match taller name/rank text.
    # Keep the avatar square and center it vertically beside player details.
    panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    var square_size: float = float(dimension + 20)
    panel.custom_minimum_size = Vector2(square_size, square_size)
    var avatar_picture := _avatar_image(avatar_id, dimension)
    avatar_picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    avatar_picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    panel.add_child(avatar_picture)
    return panel


func _frame_select(frame_id: String) -> void:
    for frame in AVATAR_FRAMES:
        if str(frame["id"]) != frame_id:
            continue
        var cost: int = int(frame["price"])
        if owned_avatar_frames.has(frame_id):
            equipped_avatar_frame = frame_id
            frame_notice = "Equipped %s frame!" % str(frame["name"])
        elif coins >= cost:
            coins -= cost
            owned_avatar_frames[frame_id] = true
            equipped_avatar_frame = frame_id
            frame_notice = "Unlocked and equipped %s frame!" % str(frame["name"])
            _play_sound(SFX_COLLECT)
        else:
            frame_notice = "You need %d more coins for this frame." % (cost - coins)
        _save()
        player_profile()
        return


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


func _open_shop_category(category: String) -> void:
    shop_category = category
    shop()


func _open_profile_section(section: String) -> void:
    profile_section = section
    player_profile()


func shop() -> void:
    current_tab = "shop"
    _shell()
    _heading("Cosmetic Shop", "Find a look you love. Cosmetics never affect gameplay.")
    _fantasy_feature_art("fantasy_shop_header", "TREASURES OF MINIVERSE")
    _card("YOUR WALLET", "%d coins  •  Purchases save automatically." % coins)
    if shop_message != "":
        _card("SHOP UPDATE", shop_message)
    if shop_category == "home":
        _heading("Shop Categories", "Choose what you'd like to browse.")
        _card("THEMES", "%d / %d owned  •  Change the colors of MiniVerse." % [owned_themes.size(), SHOP_THEMES.size()])
        content.add_child(_button("BROWSE THEMES", func(): _open_shop_category("themes"), _theme_color(), 56))
        _card("AVATARS", "%d / %d owned  •  Choose your player character." % [owned_avatars.size(), SHOP_AVATARS.size()])
        content.add_child(_button("BROWSE AVATARS", func(): _open_shop_category("avatars"), _theme_color(), 56))
        _card("VICTORY EFFECTS", "%d / %d owned  •  Customize your win celebrations." % [owned_effects.size(), SHOP_EFFECTS.size()])
        content.add_child(_button("BROWSE EFFECTS", func(): _open_shop_category("effects"), _theme_color(), 56))
        _card("AVATAR FRAMES & BADGES", "Find frames and earned badges in Profile → Customize.")
        content.add_child(_button("OPEN PROFILE CUSTOMIZATION", func(): _open_profile_section("customize"), PANEL2, 56))
        return
    content.add_child(_button("BACK TO SHOP CATEGORIES", func(): _open_shop_category("home"), PANEL2, 52))
    _heading(shop_category.capitalize(), "Browse, unlock, and equip.")
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
            var required_level: int = int(item.get("level_required", 0))
            description.text = str(item["description"]) + ("  •  Owned" if owned else ("  •  Unlocks at level %d" % required_level if required_level > 0 else "  •  %d coins" % price))
            description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            description.add_theme_font_size_override("font_size", 19)
            description.add_theme_color_override("font_color", Color("#e4eaff"))
            column.add_child(description)
            var button_label := "EQUIPPED" if equipped else ("EQUIP" if owned else ("UNLOCK AT LEVEL %d" % required_level if required_level > 0 else "BUY FOR %d COINS" % price))
            var purchase := _button(button_label, func(): _shop_purchase(id), theme_color)
            purchase.disabled = equipped or (required_level > level and not owned)
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


func _fantasy_feature_art(asset_name: String, _caption: String) -> void:
    # Full-width illustrated banners with their captions already in the artwork.
    # Keep aspect ratio and avoid STRETCH_KEEP_ASPECT_COVERED double cropping.
    var picture := TextureRect.new()
    picture.texture = load("res://assets/lobby/%s.png" % asset_name)
    picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    picture.custom_minimum_size.y = maxf(84.0, (get_viewport_rect().size.x - 40.0) * 0.169)
    picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    content.add_child(picture)


func _heading(title: String, subtitle := ""):
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 4)
    content.add_child(box)
    var t := Label.new()
    t.text = title
    t.add_theme_font_size_override("font_size", 30)
    t.add_theme_color_override("font_color", Color("#ffe39c"))
    t.add_theme_color_override("font_shadow_color", Color("#09062b"))
    t.add_theme_constant_override("shadow_offset_x", 1)
    t.add_theme_constant_override("shadow_offset_y", 2)
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


# Overall player ranks are derived from the existing level and XP.
# No migration or additional saved data is required.
const PLAYER_RANK_LEVELS := [1, 5, 10, 20, 35, 50]
const PLAYER_RANK_NAMES := ["Rookie", "Explorer", "Challenger", "Champion", "Arcade Master", "Arcade Legend"]

func _player_rank_index(player_level: int) -> int:
    var rank_index: int = 0
    for i in range(PLAYER_RANK_LEVELS.size()):
        if player_level >= int(PLAYER_RANK_LEVELS[i]):
            rank_index = i
    return rank_index


func _player_rank_name(player_level: int) -> String:
    return str(PLAYER_RANK_NAMES[_player_rank_index(player_level)])


func _player_rank_progress() -> String:
    var rank_index: int = _player_rank_index(level)
    if rank_index >= PLAYER_RANK_LEVELS.size() - 1:
        return "Highest rank achieved!"
    var next_level: int = int(PLAYER_RANK_LEVELS[rank_index + 1])
    return "Next: %s at level %d (%d levels away)" % [str(PLAYER_RANK_NAMES[rank_index + 1]), next_level, next_level - level]


func _profile_progress_panel() -> void:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _lobby_card_style(_theme_color()))
    content.add_child(panel)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 10)
    panel.add_child(stack)

    var title_label := Label.new()
    title_label.text = "LEVEL PROGRESSION"
    title_label.add_theme_font_size_override("font_size", 23)
    title_label.add_theme_color_override("font_color", _menu_accent_text(_theme_color()))
    stack.add_child(title_label)

    var current_xp: int = _level_xp_progress()
    var progress_label := Label.new()
    progress_label.text = "LEVEL %d  |  %d / %d XP to level %d" % [level, current_xp, _xp_to_next_level(level), level + 1]
    progress_label.add_theme_font_size_override("font_size", 19)
    progress_label.add_theme_color_override("font_color", Color("#e4eaff"))
    progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(progress_label)

    var xp_bar := ProgressBar.new()
    xp_bar.custom_minimum_size = Vector2(0, 24)
    xp_bar.min_value = 0
    xp_bar.max_value = _xp_to_next_level(level)
    xp_bar.value = current_xp
    xp_bar.show_percentage = false
    stack.add_child(xp_bar)

    var rank_index: int = _player_rank_index(level)
    var rank_label := Label.new()
    rank_label.text = "CURRENT RANK: " + _player_rank_name(level).to_upper()
    rank_label.add_theme_font_size_override("font_size", 20)
    rank_label.add_theme_color_override("font_color", Color("#ffe29e"))
    rank_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(rank_label)

    if rank_index < PLAYER_RANK_LEVELS.size() - 1:
        var next_rank_level: int = int(PLAYER_RANK_LEVELS[rank_index + 1])
        var rank_bar := ProgressBar.new()
        rank_bar.custom_minimum_size = Vector2(0, 20)
        rank_bar.min_value = int(PLAYER_RANK_LEVELS[rank_index])
        rank_bar.max_value = next_rank_level
        rank_bar.value = level
        rank_bar.show_percentage = false
        stack.add_child(rank_bar)
        var next_rank_label := Label.new()
        next_rank_label.text = "NEXT RANK: %s AT LEVEL %d" % [str(PLAYER_RANK_NAMES[rank_index + 1]).to_upper(), next_rank_level]
        next_rank_label.add_theme_font_size_override("font_size", 18)
        next_rank_label.add_theme_color_override("font_color", Color("#e4eaff"))
        next_rank_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        stack.add_child(next_rank_label)
    else:
        var top_label := Label.new()
        top_label.text = "You've reached the highest player rank!"
        top_label.add_theme_font_size_override("font_size", 18)
        stack.add_child(top_label)

    var upcoming_level: int = 0
    var upcoming_theme: String = ""
    for cosmetic in SHOP_THEMES:
        var required_level: int = int(cosmetic.get("level_required", 0))
        if required_level > level and (upcoming_level == 0 or required_level < upcoming_level):
            upcoming_level = required_level
            upcoming_theme = str(cosmetic["name"])
    var reward_label := Label.new()
    if upcoming_level > 0:
        reward_label.text = "NEXT EXCLUSIVE THEME: %s (LEVEL %d)" % [upcoming_theme.to_upper(), upcoming_level]
    else:
        reward_label.text = "ALL EXCLUSIVE LEVEL THEMES UNLOCKED!"
    reward_label.add_theme_font_size_override("font_size", 18)
    reward_label.add_theme_color_override("font_color", _menu_accent_text(_theme_color()))
    reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(reward_label)


func _badge_unlocked(badge_id: String) -> bool:
    match badge_id:
        "rookie": return true
        "explorer": return _discovered_game_count() >= 3
        "collector": return _discovered_game_count() >= 5
        "champion": return total_wins >= 25
        "veteran": return total_games_played >= 100
        "legend": return level >= 50
    return false


func _badge_data(badge_id: String) -> Dictionary:
    for badge in PROFILE_BADGES:
        if str(badge["id"]) == badge_id:
            return badge
    return PROFILE_BADGES[0]


func _showcase_game_label() -> Label:
    var display := Label.new()
    display.add_theme_font_size_override("font_size", 16)
    display.add_theme_color_override("font_color", Color("#e4eaff"))
    display.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    if showcased_game == "none":
        display.text = "FEATURED GAME  •  None selected"
    else:
        var title: String = showcased_game
        for g in GAMES:
            if str(g.id) == showcased_game:
                title = str(g.title)
                break
        display.text = "FAVORITE GAME  •  %s  |  BEST %d  |  %d ★" % [title, int(best_scores.get(showcased_game, 0)), int(best_stars.get(showcased_game, 0))]
    return display


func _choose_showcase_game(selected_id: String) -> void:
    if selected_id != "none":
        var found: bool = false
        for g in GAMES:
            if str(g.id) == selected_id:
                found = true
                break
        if not found:
            return
    showcased_game = selected_id
    showcase_notice = "Featured game updated!"
    _save()
    _open_profile_section("showcase")


func _showcase_label() -> Label:
    var display := Label.new()
    if showcased_badge == "none" or not _badge_unlocked(showcased_badge):
        display.text = "SHOWCASE  •  No featured badge"
        display.add_theme_color_override("font_color", Color("#d4ddf7"))
    else:
        var badge: Dictionary = _badge_data(showcased_badge)
        display.text = "SHOWCASE  •  %s  %s" % [str(badge["symbol"]), str(badge["name"])]
        display.add_theme_color_override("font_color", Color(str(badge["color"])))
    display.add_theme_font_size_override("font_size", 16)
    display.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return display


func _choose_showcase_badge(badge_id: String) -> void:
    if badge_id != "none" and not _badge_unlocked(badge_id):
        showcase_notice = "That badge is still locked."
    else:
        showcased_badge = badge_id
        showcase_notice = "Showcase updated!"
        _save()
    _open_profile_section("showcase")


func _badge_label() -> Label:
    var badge: Dictionary = _badge_data(equipped_profile_badge)
    var label_node := Label.new()
    label_node.text = "%s  %s" % [str(badge["symbol"]), str(badge["name"])]
    label_node.add_theme_font_size_override("font_size", 20)
    label_node.add_theme_color_override("font_color", Color(str(badge["color"])))
    label_node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return label_node


func _equip_profile_badge(badge_id: String) -> void:
    if not _badge_unlocked(badge_id):
        return
    equipped_profile_badge = badge_id
    badge_notice = "Now displaying: %s" % str(_badge_data(badge_id)["name"])
    _save()
    player_profile()


func _profile_badge_collection() -> void:
    _heading("Profile Badges", "Earn badges through gameplay and equip one to display.")
    if badge_notice != "":
        _card("BADGE EQUIPPED", badge_notice)
        badge_notice = ""
    for badge in PROFILE_BADGES:
        var badge_id: String = str(badge["id"])
        var unlocked: bool = _badge_unlocked(badge_id)
        var equipped: bool = equipped_profile_badge == badge_id
        var status: String = "EQUIPPED" if equipped else ("UNLOCKED" if unlocked else "LOCKED")
        _card("%s  %s — %s" % [str(badge["symbol"]), str(badge["name"]), status], str(badge["requirement"]))
        if unlocked and not equipped:
            var selected_id: String = badge_id
            content.add_child(_button("EQUIP " + str(badge["name"]).to_upper(), func(): _equip_profile_badge(selected_id), Color(str(badge["color"])), 56))


func _cosmetic_owned_count() -> int:
    var count: int = owned_themes.size() + owned_avatars.size() + owned_avatar_frames.size() + owned_effects.size()
    for badge in PROFILE_BADGES:
        if _badge_unlocked(str(badge["id"])):
            count += 1
    return count


func _claim_all_cosmetic_rewards(button: Button) -> void:
    var owned_count: int = _cosmetic_owned_count()
    var earned: int = 0
    var claimed_count: int = 0
    for milestone in COSMETIC_REWARD_MILESTONES:
        var threshold: int = int(milestone["count"])
        var milestone_key: String = str(threshold)
        if owned_count >= threshold and not bool(cosmetic_rewards_claimed.get(milestone_key, false)):
            cosmetic_rewards_claimed[milestone_key] = true
            earned += int(milestone["coins"])
            claimed_count += 1
    if claimed_count == 0:
        return
    coins += earned
    cosmetic_reward_notice = "Claimed %d collection rewards! +%d coins." % [claimed_count, earned]
    _save()
    # Keep the current scroll position: do not rebuild the Profile screen.
    button.text = "CLAIMED! +%d COINS" % earned
    button.release_focus()
    button.focus_mode = Control.FOCUS_NONE
    button.disabled = true


func _cosmetic_collection_section() -> void:
    var owned_badges: int = 0
    for badge in PROFILE_BADGES:
        if _badge_unlocked(str(badge["id"])):
            owned_badges += 1
    var categories: Array[Dictionary] = [
        {"name":"Themes", "owned":owned_themes.size(), "total":SHOP_THEMES.size(), "equipped":equipped_theme},
        {"name":"Avatars", "owned":owned_avatars.size(), "total":SHOP_AVATARS.size(), "equipped":equipped_avatar},
        {"name":"Avatar Frames", "owned":owned_avatar_frames.size(), "total":AVATAR_FRAMES.size(), "equipped":equipped_avatar_frame},
        {"name":"Profile Badges", "owned":owned_badges, "total":PROFILE_BADGES.size(), "equipped":equipped_profile_badge},
        {"name":"Victory Effects", "owned":owned_effects.size(), "total":SHOP_EFFECTS.size(), "equipped":equipped_effect}
    ]
    var total_owned: int = 0
    var total_available: int = 0
    for category in categories:
        total_owned += int(category["owned"])
        total_available += int(category["total"])
    _heading("Cosmetic Collection", "Your complete MiniVerse customization progress.")
    _card("COLLECTION OVERVIEW", "%d / %d cosmetics unlocked (%d%%)" % [total_owned, total_available, int(round(100.0 * float(total_owned) / float(maxi(total_available, 1))))])
    var overall_bar := ProgressBar.new()
    overall_bar.custom_minimum_size = Vector2(0, 24)
    overall_bar.min_value = 0
    overall_bar.max_value = maxi(total_available, 1)
    overall_bar.value = total_owned
    overall_bar.show_percentage = false
    content.add_child(overall_bar)
    for category in categories:
        var owned_count: int = int(category["owned"])
        var available_count: int = int(category["total"])
        _card(str(category["name"]).to_upper(), "%d / %d unlocked  •  Equipped: %s" % [owned_count, available_count, str(category["equipped"]).capitalize().replace("_", " ")])
        var progress := ProgressBar.new()
        progress.custom_minimum_size = Vector2(0, 18)
        progress.min_value = 0
        progress.max_value = maxi(available_count, 1)
        progress.value = owned_count
        progress.show_percentage = false
        content.add_child(progress)
    _heading("Collection Rewards", "Unlock cosmetics and claim your milestone coin bonuses.")
    var ready_rewards: int = 0
    var ready_coins: int = 0
    for milestone in COSMETIC_REWARD_MILESTONES:
        var threshold: int = int(milestone["count"])
        var reward: int = int(milestone["coins"])
        var claimed: bool = bool(cosmetic_rewards_claimed.get(str(threshold), false))
        var ready: bool = total_owned >= threshold
        var status: String = "CLAIMED" if claimed else ("READY" if ready else "LOCKED")
        _card("%d COSMETICS — %s" % [threshold, status], "%d / %d unlocked  •  %d coin reward" % [mini(total_owned, threshold), threshold, reward])
        if ready and not claimed:
            ready_rewards += 1
            ready_coins += reward
    if ready_rewards > 0:
        var claim_button: Button = _button("CLAIM ALL %d REWARDS (+%d COINS)" % [ready_rewards, ready_coins], func(): pass, _theme_color(), 58)
        claim_button.pressed.connect(func(): _claim_all_cosmetic_rewards(claim_button))
        content.add_child(claim_button)
    if cosmetic_reward_notice != "":
        _card("LATEST COLLECTION REWARD", cosmetic_reward_notice)
    _card("KEEP COLLECTING", "Visit Shop for themes, avatars, and victory effects. Open Profile to equip avatar frames and earn badges through gameplay.")


func _progression_milestone_highlights() -> void:
    var completed: Array[String] = []
    var upcoming: Array[Dictionary] = []
    var discovered: int = _discovered_game_count()
    for target in [3, 5, 8, 10, 13]:
        if discovered >= target:
            completed.append("Explorer: %d games discovered" % target)
        else:
            upcoming.append({"label":"Discover %d games" % target, "current":discovered, "target":target, "remaining":target - discovered, "group":"exploration"})
    var claimed: int = game_achievement_claimed.size()
    for target in [10, 20, 35, 52]:
        if claimed >= target:
            completed.append("Achievement collector: %d rewards claimed" % target)
        else:
            upcoming.append({"label":"Claim %d game achievements" % target, "current":claimed, "target":target, "remaining":target - claimed, "group":"achievements"})
    var total_wins: int = _total_mastery_wins()
    for target in [15, 40, 80, 150]:
        if total_wins >= target:
            completed.append("Mastery: %d combined wins" % target)
        else:
            upcoming.append({"label":"Earn %d total wins" % target, "current":total_wins, "target":target, "remaining":target - total_wins, "group":"mastery"})
    var diamond_games: int = 0
    for game in GAMES:
        var game_id: String = str(game["id"])
        var wins: int = int(game_win_counts.get(game_id, 0))
        if wins >= 50:
            diamond_games += 1
        else:
            var next_target: int = 3
            for tier in MASTERY_TIERS:
                if wins < int(tier["wins"]):
                    next_target = int(tier["wins"])
                    break
            upcoming.append({"label":"%s: %s mastery" % [str(game["title"]), _next_mastery_rank_label(wins)], "current":wins, "target":next_target, "remaining":next_target - wins, "group":"mastery"})
    if diamond_games > 0:
        completed.append("Diamond master in %d game(s)" % diamond_games)
    upcoming.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var a_ratio: float = float(a["remaining"]) / float(maxi(1, int(a["target"])))
        var b_ratio: float = float(b["remaining"]) / float(maxi(1, int(b["target"])))
        if is_equal_approx(a_ratio, b_ratio):
            return int(a["remaining"]) < int(b["remaining"])
        return a_ratio < b_ratio
    )
    _heading("MILESTONE HIGHLIGHTS", "Your latest accomplishments and closest goals.")
    if completed.is_empty():
        _card("COMPLETED MILESTONES", "Your first milestone is waiting. Keep playing!")
    else:
        var recent: Array[String] = []
        for i in range(maxi(0, completed.size() - 3), completed.size()):
            recent.append("✓ " + completed[i])
        _card("COMPLETED HIGHLIGHTS  •  %d TOTAL" % completed.size(), "\n".join(recent))
    if upcoming.is_empty():
        _card("UPCOMING MILESTONES", "All tracked milestones completed. Amazing work!")
    else:
        var shown: int = mini(3, upcoming.size())
        for i in range(shown):
            var goal: Dictionary = upcoming[i]
            _card(str(goal["label"]).to_upper(), "%d / %d  •  %d remaining" % [int(goal["current"]), int(goal["target"]), int(goal["remaining"])])
            _profile_progress("Milestone progress", int(goal["current"]), int(goal["target"]), Color("#66cfd5"))
    content.add_child(_button("VIEW GAME MASTERY", game_mastery_page, PANEL2, 48))
    content.add_child(_button("VIEW GAME ACHIEVEMENTS", game_achievements_page, PANEL2, 48))


func _next_mastery_rank_label(wins: int) -> String:
    for tier in MASTERY_TIERS:
        if wins < int(tier["wins"]):
            return str(tier["name"])
    return "Diamond"


func progression_overview() -> void:
    current_tab = "profile"
    _shell()
    _heading("Progression Overview", "Your MiniVerse journey at a glance.")
    _card("PLAYER LEVEL", "Level %d  •  %s  •  %d total XP" % [level, _player_rank_name(level), xp])
    _profile_progress("Next level", _level_xp_progress(), _xp_to_next_level(level), Color("#9a85ff"))
    var discovered: int = _discovered_game_count()
    var total_plays: int = 0
    for game in GAMES:
        total_plays += int(game_play_counts.get(str(game["id"]), 0))
    _card("GAME EXPLORATION", "%d / %d games discovered  •  %d rounds played" % [discovered, GAMES.size(), total_plays])
    _profile_progress("Games discovered", discovered, GAMES.size(), Color("#38c6df"))
    content.add_child(_button("VIEW GAME COLLECTION", game_collection_page, PANEL2, 50))
    var mastery_count: int = 0
    var diamond_count: int = 0
    for game in GAMES:
        var wins: int = int(game_win_counts.get(str(game["id"]), 0))
        if wins >= 3:
            mastery_count += 1
        if wins >= 50:
            diamond_count += 1
    _card("GAME MASTERY", "%d total wins  •  %d Bronze+ games  •  %d Diamond games  •  %d rewards ready" % [_total_mastery_wins(), mastery_count, diamond_count, _mastery_claimable_count()])
    _profile_progress("Games with Bronze mastery", mastery_count, GAMES.size(), Color("#d29a65"))
    _profile_progress("Games with Diamond mastery", diamond_count, GAMES.size(), Color("#5dcdec"))
    content.add_child(_button("VIEW GAME MASTERY", game_mastery_page, PANEL2, 50))
    var achieved: int = 0
    for game in GAMES:
        var game_id: String = str(game["id"])
        for achievement in GAME_ACHIEVEMENT_TIERS:
            if _game_achievement_progress(game_id, achievement) >= int(achievement["target"]):
                achieved += 1
    var achievement_total: int = GAMES.size() * GAME_ACHIEVEMENT_TIERS.size()
    _card("GAME ACHIEVEMENTS", "%d / %d completed  •  %d claimed  •  %d rewards ready" % [achieved, achievement_total, game_achievement_claimed.size(), _game_achievements_ready()])
    _profile_progress("Challenges completed", achieved, achievement_total, Color("#f0c36b"))
    _profile_progress("Rewards claimed", game_achievement_claimed.size(), achievement_total, Color("#7ce2aa"))
    content.add_child(_button("VIEW GAME ACHIEVEMENTS", game_achievements_page, PANEL2, 50))
    _progression_milestone_highlights()
    _card("PLAYER MILESTONES", "Track your player level, badges and other long-term goals.")
    content.add_child(_button("VIEW PLAYER MILESTONES", func(): _open_profile_section("milestones"), PANEL2, 50))
    content.add_child(_button("BACK TO PROFILE PROGRESS", func(): _open_profile_section("progress"), PANEL2, 52))


func player_profile() -> void:
    current_tab = "profile"
    _shell()
    _heading("Player Profile", "Your MiniVerse journey, all in one place.")
    _fantasy_feature_art("fantasy_profile_header", "YOUR ADVENTURE, YOUR LEGACY")
    # Large banner with a contrasting border and prominent title.
    content.add_child(_profile_banner_preview(equipped_banner, true))
    if showcased_badge != "none" and _badge_unlocked(showcased_badge):
        content.add_child(_showcase_label())
    if showcased_game != "none":
        content.add_child(_showcase_game_label())

    if level_up_notice != "":
        _card("LEVEL-UP REWARD!", level_up_notice)
        level_up_notice = ""
    var avatar_panel := PanelContainer.new()
    avatar_panel.add_theme_stylebox_override("panel", _style(PANEL.lerp(_theme_color(), 0.20), 18))
    content.add_child(avatar_panel)
    var avatar_row := HBoxContainer.new()
    avatar_row.add_theme_constant_override("separation", 14)
    avatar_panel.add_child(avatar_row)
    avatar_row.add_child(_framed_avatar(equipped_avatar, 84))
    var profile_details := VBoxContainer.new()
    profile_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    avatar_row.add_child(profile_details)
    var profile_title := Label.new()
    if not _title_unlocked(equipped_title):
        equipped_title = "explorer"
    profile_title.text = _title_display_name(equipped_title).to_upper()
    profile_title.add_theme_color_override("font_color", _menu_accent_text(_theme_color()))
    profile_title.add_theme_font_size_override("font_size", 19)
    var profile_name := Label.new()
    profile_name.text = _styled_player_name()
    profile_name.add_theme_font_size_override("font_size", 24)
    profile_name.add_theme_color_override("font_color", Color(str(_name_style_data()["color"])))
    profile_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    profile_details.add_child(profile_name)
    var profile_motto := Label.new()
    profile_motto.text = custom_player_motto
    profile_motto.add_theme_font_size_override("font_size", 16)
    profile_motto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    profile_motto.add_theme_color_override("font_color", Color("#e4eaff"))
    profile_details.add_child(profile_motto)
    profile_details.add_child(profile_title)
    profile_details.add_child(_badge_label())
    var profile_level := Label.new()
    profile_level.text = "Level %d  |  %d total XP" % [level, xp]
    profile_level.add_theme_color_override("font_color", TEXT)
    profile_details.add_child(profile_level)
    var rank_label := Label.new()
    rank_label.text = "RANK: " + _player_rank_name(level).to_upper()
    rank_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    rank_label.add_theme_font_size_override("font_size", 21)
    rank_label.add_theme_color_override("font_color", Color("#ffe29e"))
    profile_details.add_child(rank_label)
    var profile_wallet := Label.new()
    profile_wallet.text = "%d coins available" % coins
    profile_wallet.add_theme_color_override("font_color", MUTED)
    profile_details.add_child(profile_wallet)
    var total_stars: int = _profile_total_stars()
    var unlocked_achievements: int = _profile_achievement_count()
    _section_chips(["Overview", "Customize", "Progress", "Games"], profile_section.capitalize() if profile_section in ["overview", "customize", "progress", "games"] else "Customize" if profile_section in ["frames", "collection", "badges", "titles", "banners", "decorations", "identity", "name_styles"] else "Progress", func(value: String):
        _open_profile_section(value.to_lower())
    )
    if profile_section == "customize":
        _heading("My Customization", "Choose a category to manage your collection.")
        _card("FEATURED SHOWCASE", "Pick one earned badge to highlight on your Home avatar banner.")
        content.add_child(_button("EDIT MY SHOWCASE", func(): _open_profile_section("showcase"), _theme_color(), 54))
        _card("NAME STYLES", "Choose your name color and collectible nameplate symbol.")
        content.add_child(_button("CUSTOMIZE NAME STYLE", func(): _open_profile_section("name_styles"), _theme_color(), 54))
        _card("PLAYER NAME & MOTTO", "Choose the name and short message displayed beside your avatar on Home and Profile.")
        content.add_child(_button("EDIT MY IDENTITY", func(): _open_profile_section("identity"), _theme_color(), 54))
        _card("BANNER DECORATIONS", "Add stars, hearts, crowns, and other small accents to your Home avatar banner.")
        content.add_child(_button("CHANGE BANNER DECORATION", func(): _open_profile_section("decorations"), _theme_color(), 54))
        _card("PROFILE BANNERS", "Choose a colorful banner for the top of your profile.")
        content.add_child(_button("CHANGE PROFILE BANNER", func(): _open_profile_section("banners"), _theme_color(), 54))

        _card("AVATAR FRAMES", "%d / %d unlocked" % [owned_avatar_frames.size(), AVATAR_FRAMES.size()])
        content.add_child(_button("MANAGE FRAMES", func(): _open_profile_section("frames"), _theme_color(), 54))
        _card("PROFILE BADGES", "Earn and display badges through gameplay.")
        content.add_child(_button("VIEW BADGES", func(): _open_profile_section("badges"), _theme_color(), 54))
        _card("PLAYER TITLES", "Choose the title displayed on your profile.")
        content.add_child(_button("MANAGE TITLES", func(): _open_profile_section("titles"), _theme_color(), 54))
        _card("COSMETIC COLLECTION", "Track your cosmetics and claim collection rewards.")
        content.add_child(_button("VIEW COLLECTION & REWARDS", func(): _open_profile_section("collection"), _theme_color(), 54))
    if profile_section == "progress":
        _heading("Player Progress", "Your ranks, milestones, and game collection.")
        content.add_child(_button("PROGRESSION OVERVIEW", progression_overview, _theme_color(), 56))
        content.add_child(_button("VIEW PLAYER MILESTONES", func(): _open_profile_section("milestones"), _theme_color(), 56))
        content.add_child(_button("VIEW GAME COLLECTION", func(): game_collection_page(), PANEL2, 56))
    if profile_section in ["frames", "collection", "badges", "titles", "banners", "decorations", "identity", "name_styles"]:
        content.add_child(_button("BACK TO CUSTOMIZATION", func(): _open_profile_section("customize"), PANEL2, 52))
    if profile_section == "milestones":
        content.add_child(_button("BACK TO PLAYER PROGRESS", func(): _open_profile_section("progress"), PANEL2, 52))
    if profile_section == "overview":
            _profile_progress_panel()
            _card("OVERALL PERFORMANCE", "Rounds played: %d\nLevels cleared: %d\nWin rate: %s\nFavorite game: %s" % [total_games_played, total_wins, _stat_rate(total_wins, total_games_played), _profile_favorite()])
            _card("COLLECTION & REWARDS", "Achievements: %d / %d\nBest stars earned: %d / 30\nThemes owned: %d / %d\nAvatars owned: %d / %d\nVictory effects owned: %d / %d\nDaily login claims: %d" % [unlocked_achievements, ACHIEVEMENT_INFO.size(), total_stars, owned_themes.size(), SHOP_THEMES.size(), owned_avatars.size(), SHOP_AVATARS.size(), owned_effects.size(), SHOP_EFFECTS.size(), login_total_claims])
    if profile_section == "name_styles":
        _heading("Name Styles", "Change the color and symbol next to your player name on Home.")
        _card("CURRENT NAMEPLATE", _styled_player_name())
        if name_style_notice != "":
            _card("NAME STYLE UPDATE", name_style_notice)
        for style_item in NAME_STYLES:
            var style_id: String = str(style_item["id"])
            var style_name: String = str(style_item["name"])
            var style_owned: bool = _name_style_owned(style_item)
            var status: String = "EQUIPPED" if equipped_name_style == style_id else ("OWNED" if style_owned else ("LEVEL %d" % int(style_item["level_required"]) if int(style_item.get("level_required", 0)) > 0 else "%d COINS" % int(style_item.get("price", 0))))
            _card(str(style_item["symbol"]) + "  " + style_name.to_upper() + "  •  " + status, str(style_item["description"]))
            if equipped_name_style != style_id:
                content.add_child(_button(("EQUIP " if style_owned else "UNLOCK ") + style_name.to_upper(), func(): _choose_name_style(style_id), Color(str(style_item["color"])).darkened(0.3), 48))
        content.add_child(_button("VIEW ON HOME", home, PANEL2, 52))
    if profile_section == "identity":
        _heading("Player Identity", "Make your Home avatar card feel like yours.")
        _card("LIVE IDENTITY", custom_player_name + "\n" + custom_player_motto)
        if identity_edit_notice != "":
            _card("UPDATE", identity_edit_notice)
        var name_label := Label.new()
        name_label.text = "PLAYER NAME (MAX 18 CHARACTERS)"
        name_label.add_theme_font_size_override("font_size", 17)
        content.add_child(name_label)
        var name_input := LineEdit.new()
        name_input.text = custom_player_name
        name_input.max_length = 18
        name_input.custom_minimum_size.y = 52
        content.add_child(name_input)
        var motto_label := Label.new()
        motto_label.text = "PROFILE MOTTO (MAX 48 CHARACTERS)"
        motto_label.add_theme_font_size_override("font_size", 17)
        content.add_child(motto_label)
        var motto_input := LineEdit.new()
        motto_input.text = custom_player_motto
        motto_input.max_length = 48
        motto_input.custom_minimum_size.y = 52
        content.add_child(motto_input)
        content.add_child(_button("SAVE NAME & MOTTO", func(): _save_player_identity(name_input.text, motto_input.text), _theme_color(), 56))
        content.add_child(_button("VIEW ON HOME", home, PANEL2, 52))
    if profile_section == "decorations":
        _heading("Banner Decorations", "Choose an accent for your Home avatar banner.")
        _card("YOUR CURRENT LOOK", _decorated_banner_title())
        if banner_decoration_notice != "":
            _card("DECORATION UPDATE", banner_decoration_notice)
        for decoration in BANNER_DECORATIONS:
            var decoration_id: String = str(decoration["id"])
            var decoration_name: String = str(decoration["name"])
            var decoration_owned: bool = _banner_decoration_owned(decoration)
            var decoration_status: String = "EQUIPPED" if equipped_banner_decoration == decoration_id else ("OWNED" if decoration_owned else ("MASTERY LOCKED" if int(decoration.get("mastery_wins_required", 0)) > 0 else _cosmetic_unlock_status(decoration)))
            _card(str(decoration.get("symbol", "")) + "  " + decoration_name.to_upper() + "  •  " + decoration_status, str(decoration["description"]))
            if int(decoration.get("mastery_wins_required", 0)) > 0 and not decoration_owned:
                _card("MASTERY PROGRESS", _mastery_cosmetic_progress(decoration))
            elif equipped_banner_decoration != decoration_id:
                content.add_child(_button(("EQUIP " if decoration_owned else "UNLOCK ") + decoration_name.to_upper(), func(): _choose_banner_decoration(decoration_id), _theme_color(), 48))
        content.add_child(_button("VIEW ON HOME", home, PANEL2, 52))
    if profile_section == "showcase":
        _heading("Featured Showcase", "Feature an earned badge and one favorite game on your Home avatar banner.")
        _card("FEATURED MINI-GAME", "Your chosen game and personal best appear on Home and Profile.")
        content.add_child(_showcase_game_label())
        if showcased_game != "none":
            content.add_child(_button("CLEAR FEATURED GAME", func(): _choose_showcase_game("none"), PANEL2, 48))
        for g in GAMES:
            var featured_game_id: String = str(g.id)
            var game_selected: bool = showcased_game == featured_game_id
            var plays: int = int(game_play_counts.get(featured_game_id, 0))
            var score: int = int(best_scores.get(featured_game_id, 0))
            _card(str(g.title).to_upper() + ("  •  FEATURED" if game_selected else ""), "%s  •  %d plays  •  Best %d" % [str(g.genre), plays, score])
            if not game_selected:
                content.add_child(_button("FEATURE " + str(g.title).to_upper(), func(): _choose_showcase_game(featured_game_id), _theme_color(), 48))
        _heading("Featured Badge", "Show an earned badge alongside your featured game.")
        content.add_child(_showcase_label())
        if showcase_notice != "":
            _card("SHOWCASE UPDATE", showcase_notice)
        if showcased_badge != "none":
            content.add_child(_button("CLEAR SHOWCASE", func(): _choose_showcase_badge("none"), PANEL2, 48))
        for badge in PROFILE_BADGES:
            var badge_id: String = str(badge["id"])
            var unlocked: bool = _badge_unlocked(badge_id)
            var selected: bool = showcased_badge == badge_id
            var status: String = "FEATURED" if selected else ("EARNED" if unlocked else "LOCKED")
            _card("%s  %s  •  %s" % [str(badge["symbol"]), str(badge["name"]), status], str(badge["requirement"]))
            if unlocked and not selected:
                content.add_child(_button("FEATURE " + str(badge["name"]).to_upper(), func(): _choose_showcase_badge(badge_id), Color(str(badge["color"])), 48))
        content.add_child(_button("VIEW ON HOME", home, PANEL2, 52))
    if profile_section == "banners":
        _heading("Profile Banners", "Preview your banner here, then visit Profile Overview to see it full size.")
        if cosmetic_unlock_message != "":
            _card("CUSTOMIZATION", cosmetic_unlock_message)
        _card("CURRENTLY EQUIPPED", _banner_name())
        content.add_child(_profile_banner_preview(equipped_banner, false))
        content.add_child(_button("VIEW ON MY PROFILE", func(): _open_profile_section("overview"), PANEL2, 54))
        for banner in PROFILE_BANNERS:
            var banner_id: String = str(banner["id"])
            var banner_name: String = str(banner["name"])
            var owned: bool = _cosmetic_owned("banner", banner)
            var status: String = "EQUIPPED" if equipped_banner == banner_id else ("OWNED" if owned else ("MASTERY LOCKED" if int(banner.get("mastery_wins_required", 0)) > 0 else _cosmetic_unlock_status(banner)))
            _card(banner_name.to_upper() + "  •  " + status, str(banner["description"]))
            content.add_child(_profile_banner_preview(banner_id, false))
            if int(banner.get("mastery_wins_required", 0)) > 0 and not owned:
                _card("MASTERY PROGRESS", _mastery_cosmetic_progress(banner))
            elif equipped_banner != banner_id:
                content.add_child(_button(("EQUIP " if owned else "UNLOCK ") + banner_name.to_upper(), func(): _equip_banner(banner_id), Color(str(banner["color"])), 54))
    if profile_section == "frames":
        _heading("Avatar Frames", "Unlock decorative borders with coins. Frames are cosmetic only.")
        if frame_notice != "":
            _card("FRAME UPDATE", frame_notice)
            frame_notice = ""
        for frame in AVATAR_FRAMES:
            var frame_id: String = str(frame["id"])
            var owned: bool = owned_avatar_frames.has(frame_id)
            var equipped: bool = equipped_avatar_frame == frame_id
            var frame_color: Color = Color(str(frame["color"]))
            var frame_card := PanelContainer.new()
            frame_card.add_theme_stylebox_override("panel", _lobby_card_style(frame_color))
            content.add_child(frame_card)
            var frame_row := HBoxContainer.new()
            frame_row.add_theme_constant_override("separation", 12)
            frame_card.add_child(frame_row)
            var swatch := ColorRect.new()
            swatch.color = frame_color
            swatch.custom_minimum_size = Vector2(24, 64)
            swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
            frame_row.add_child(swatch)
            var frame_column := VBoxContainer.new()
            frame_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            frame_row.add_child(frame_column)
            var frame_label := Label.new()
            frame_label.text = str(frame["name"]) + ("  -  EQUIPPED" if equipped else "")
            frame_label.add_theme_font_size_override("font_size", 20)
            frame_label.add_theme_color_override("font_color", TEXT)
            frame_column.add_child(frame_label)
            var frame_description := Label.new()
            frame_description.text = str(frame["description"]) + ("  •  Owned" if owned else "  •  %d coins" % int(frame["price"]))
            frame_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            frame_description.add_theme_font_size_override("font_size", 18)
            frame_description.add_theme_color_override("font_color", Color("#e4eaff"))
            frame_column.add_child(frame_description)
            if not equipped:
                var chosen_frame: String = frame_id
                frame_column.add_child(_button("EQUIP" if owned else "UNLOCK  %d COINS" % int(frame["price"]), func(): _frame_select(chosen_frame), frame_color, 56))
    if profile_section == "badges":
        _profile_badge_collection()
    if profile_section == "collection":
        _cosmetic_collection_section()
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
        var collected_count: int = _discovered_game_count()
        var claimed_count: int = 0
        for collection_milestone in COLLECTION_MILESTONES:
            if bool(collection_milestones_claimed.get(str(collection_milestone["count"]), false)):
                claimed_count += 1
        _card("GAME COLLECTION", "%d / %d games discovered\\n%d / %d milestone rewards claimed\\nVisit Games to collect available milestone rewards." % [collected_count, GAMES.size(), claimed_count, COLLECTION_MILESTONES.size()])
        _heading("Player Ranks", "Rise through six ranks as your overall player level grows.")
        for rank_i in range(PLAYER_RANK_LEVELS.size()):
            var required_level: int = int(PLAYER_RANK_LEVELS[rank_i])
            var earned_rank: bool = level >= required_level
            var rank_status: String = "UNLOCKED" if earned_rank else "LOCKED"
            _card(str(PLAYER_RANK_NAMES[rank_i]).to_upper() + "  -  " + rank_status, "Reach player level %d." % required_level)
        _heading("EXCLUSIVE COSMETIC REWARDS", "Level up to unlock special themes for free.")
        for cosmetic in SHOP_THEMES:
            var unlock_level: int = int(cosmetic.get("level_required", 0))
            if unlock_level > 0:
                var is_unlocked: bool = owned_themes.has(str(cosmetic["id"]))
                _card(str(cosmetic["name"]).to_upper() + (" - UNLOCKED" if is_unlocked else " - LOCKED"), "Level %d milestone. %s" % [unlock_level, "Available in Shop > Themes." if is_unlocked else "Keep leveling to earn this theme."])
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



func _home_shortcut(label_text: String, action: Callable, accent: Color) -> Button:
    var button := _button(label_text, action, accent, 58)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", 19)
    return button


func _home_shortcut_row(left_label: String, left_action: Callable, right_label: String, right_action: Callable) -> void:
    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 9)
    content.add_child(actions)
    actions.add_child(_home_shortcut(left_label, left_action, Color("#344a9b")))
    actions.add_child(_home_shortcut(right_label, right_action, Color("#344a9b")))


func favorite_games_page() -> void:
    current_tab = "games"
    _shell()
    _heading("Favorite Games", "Your saved games in one place.")
    content.add_child(_button("BROWSE ALL GAMES", library, _theme_color(), 54))
    var count: int = 0
    for game in GAMES:
        if bool(favorite_games.get(str(game.id), false)):
            content.add_child(_game_card(game))
            count += 1
    if count == 0:
        _card("NO FAVORITES YET", "Open the Game Library and tap Add to Favorites on a game you love.")
    content.add_child(_button("BACK TO HOME", home, Color("#344a9b"), 54))


func home():
    Difficulty.clear_retry_level(game_id)
    current_tab = "home"
    _shell()
    # Phase 26: a short, actionable dashboard instead of a long stack of cards.
    var hero := PanelContainer.new()
    var hero_style := StyleBoxFlat.new()
    hero_style.bg_color = Color("#211653")
    hero_style.border_width_left = 3
    hero_style.border_width_right = 3
    hero_style.border_width_top = 3
    hero_style.border_width_bottom = 3
    hero_style.border_color = Color("#ffd36e")
    hero_style.corner_radius_top_left = 18
    hero_style.corner_radius_top_right = 18
    hero_style.corner_radius_bottom_left = 18
    hero_style.corner_radius_bottom_right = 18
    hero.add_theme_stylebox_override("panel", hero_style)
    content.add_child(hero)
    var hero_box := VBoxContainer.new()
    hero_box.add_theme_constant_override("separation", 4)
    hero.add_child(hero_box)
    var art := TextureRect.new()
    art.texture = FANTASY_BRAND_BANNER
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    art.custom_minimum_size.y = maxf(220.0, (get_viewport_rect().size.x - 42.0) * 368.0 / 491.0)
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hero_box.add_child(art)
    var tagline := Label.new()
    tagline.text = "SMALL GAMES. BIG FUN."
    tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tagline.add_theme_font_size_override("font_size", 20)
    tagline.add_theme_color_override("font_color", Color("#e4eaff"))
    hero_box.add_child(tagline)
    # Phase 30.3: large, illustrated navigation tiles from the concept art.
    var fantasy_actions := HBoxContainer.new()
    fantasy_actions.add_theme_constant_override("separation", 6)
    content.add_child(fantasy_actions)
    fantasy_actions.add_child(_fantasy_shortcut("games", library))
    fantasy_actions.add_child(_fantasy_shortcut("earn", _rewards_hub))
    fantasy_actions.add_child(_fantasy_shortcut("shop", shop))
    # The equipped profile banner is the background of the HOME avatar card.
    # This is the main visible banner, not a separate decoration on Profile.
    var identity := PanelContainer.new()
    var identity_style := _style(_banner_color(), 18)
    identity_style.border_width_left = 3
    identity_style.border_width_right = 3
    identity_style.border_width_top = 3
    identity_style.border_width_bottom = 3
    identity_style.border_color = _banner_color().lightened(0.48)
    identity_style.content_margin_left = 16
    identity_style.content_margin_right = 16
    identity_style.content_margin_top = 16
    identity_style.content_margin_bottom = 16
    identity.add_theme_stylebox_override("panel", identity_style)
    content.add_child(identity)
    if banner_animation_enabled:
        # Animate only the border color; no movement or flashing of the avatar.
        var banner_tween := create_tween().bind_node(identity)
        banner_tween.set_loops()
        banner_tween.set_trans(Tween.TRANS_SINE)
        banner_tween.tween_property(identity_style, "border_color", _banner_color().lightened(0.78), 2.2)
        banner_tween.tween_property(identity_style, "border_color", _banner_color().lightened(0.32), 2.2)
    var identity_stack := VBoxContainer.new()
    identity_stack.add_theme_constant_override("separation", 10)
    identity.add_child(identity_stack)
    var banner_heading := Label.new()
    banner_heading.text = _decorated_banner_title()
    banner_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner_heading.add_theme_font_size_override("font_size", 20)
    banner_heading.add_theme_color_override("font_color", Color.WHITE)
    identity_stack.add_child(banner_heading)
    # Compact showcase: badge and favorite game share one subtle row.
    # Full records remain available in Profile > Customize > Showcase.
    var showcase_parts: Array[String] = []
    if showcased_badge != "none" and _badge_unlocked(showcased_badge):
        var featured_badge: Dictionary = _badge_data(showcased_badge)
        showcase_parts.append(str(featured_badge["symbol"]) + " " + str(featured_badge["name"]))
    if showcased_game != "none":
        var featured_title: String = showcased_game
        for featured_game in GAMES:
            if str(featured_game.id) == showcased_game:
                featured_title = str(featured_game.title)
                break
        showcase_parts.append("★ " + featured_title + " · Best " + str(int(best_scores.get(showcased_game, 0))))
    if not showcase_parts.is_empty():
        var showcase_strip := PanelContainer.new()
        showcase_strip.add_theme_stylebox_override("panel", _style(_banner_color().darkened(0.20), 10))
        identity_stack.add_child(showcase_strip)
        var showcase_text := Label.new()
        showcase_text.text = "  •  ".join(showcase_parts)
        showcase_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        showcase_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        showcase_text.add_theme_font_size_override("font_size", 14)
        showcase_text.add_theme_color_override("font_color", Color("#f2f5ff"))
        showcase_strip.add_child(showcase_text)
    if banner_animation_enabled:
        var heading_tween := create_tween().bind_node(banner_heading)
        heading_tween.set_loops()
        heading_tween.set_trans(Tween.TRANS_SINE)
        heading_tween.tween_property(banner_heading, "modulate:a", 0.72, 2.2)
        heading_tween.tween_property(banner_heading, "modulate:a", 1.0, 2.2)
    var identity_row := HBoxContainer.new()
    identity_row.add_theme_constant_override("separation", 12)
    identity_stack.add_child(identity_row)
    identity_row.add_child(_framed_avatar(equipped_avatar, 62))
    var identity_text := VBoxContainer.new()
    identity_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    identity_row.add_child(identity_text)
    var identity_name := Label.new()
    identity_name.text = _styled_player_name()
    identity_name.add_theme_font_size_override("font_size", 21)
    identity_name.add_theme_color_override("font_color", Color(str(_name_style_data()["color"])))
    identity_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    identity_text.add_child(identity_name)
    var player_rank := Label.new()
    player_rank.text = "%s  •  LEVEL %d" % [_player_rank_name(level).to_upper(), level]
    player_rank.add_theme_font_size_override("font_size", 20)
    player_rank.add_theme_color_override("font_color", Color("#ffe29e"))
    identity_text.add_child(player_rank)
    var identity_motto := Label.new()
    identity_motto.text = custom_player_motto
    identity_motto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    identity_motto.add_theme_font_size_override("font_size", 15)
    identity_motto.add_theme_color_override("font_color", Color("#e4eaff"))
    identity_text.add_child(identity_motto)
    identity_text.add_child(_badge_label())
    var progress := ProgressBar.new()
    progress.min_value = 0
    progress.max_value = _xp_to_next_level(level)
    progress.value = _level_xp_progress()
    progress.custom_minimum_size.y = 14
    progress.show_percentage = false
    identity_text.add_child(progress)
    # Keep banner customization discoverable without competing with the avatar.
    var banner_actions := HBoxContainer.new()
    banner_actions.alignment = BoxContainer.ALIGNMENT_END
    banner_actions.add_theme_constant_override("separation", 6)
    identity_stack.add_child(banner_actions)
    var change_banner := _button("Edit banner", func(): _open_profile_section("banners"), _banner_color().darkened(0.25), 36)
    change_banner.size_flags_horizontal = Control.SIZE_SHRINK_END
    change_banner.custom_minimum_size = Vector2(112, 38)
    change_banner.add_theme_font_size_override("font_size", 14)
    banner_actions.add_child(change_banner)
    var decorate_banner := _button("Decor", func(): _open_profile_section("decorations"), _banner_color().darkened(0.28), 36)
    decorate_banner.size_flags_horizontal = Control.SIZE_SHRINK_END
    decorate_banner.custom_minimum_size = Vector2(74, 38)
    decorate_banner.add_theme_font_size_override("font_size", 14)
    banner_actions.add_child(decorate_banner)
    content.add_child(_menu_button("PLAY A RANDOM GAME", _random_game, Color("#36e58a"), "play", 60))
    _card("TODAY'S FEATURED GAME", _daily_feature_description())
    content.add_child(_menu_button("PLAY DAILY CHALLENGE", _daily_challenge, Color("#fbbf24"), "daily", 58))
    _heading("Quick Access", "Everything important, without the scrolling.")
    _home_shortcut_row("FAVORITES (%d)" % _favorite_game_count(), favorite_games_page, "ALL GAMES (%d)" % GAMES.size(), library)
    _home_shortcut_row("REWARDS", _rewards_hub, "MY PROFILE", player_profile)
    _heading("Recently Played", "Your last three games.")
    var shown: int = 0
    for recent_id in recent_games:
        var recent_game: Dictionary = _game_data(recent_id)
        if not recent_game.is_empty() and shown < 3:
            content.add_child(_game_card(recent_game))
            shown += 1
    if shown == 0:
        _card("READY TO PLAY?", "Choose a game from the library to begin. Your recent games will appear here.")
    # Detailed daily history, achievements, settings and cosmetic pages
    # remain available in their existing navigation destinations.

func _toggle_game_favorite(id: String) -> void:
    if bool(favorite_games.get(id, false)):
        favorite_games.erase(id)
    else:
        favorite_games[id] = true
    _save()
    if current_tab == "games":
        library()
    else:
        home()


func _favorite_game_count() -> int:
    var count: int = 0
    for game in GAMES:
        if bool(favorite_games.get(str(game.id), false)):
            count += 1
    return count


func _game_card(g: Dictionary) -> PanelContainer:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", _lobby_card_style(g.color))
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 7)
    card.add_child(column)

    # Full illustration in a wide, framed card image. The art is precomposed
    # into a panoramic canvas so COVERED never zooms into a tiny detail.
    var art := TextureRect.new()
    art.texture = load("res://assets/lobby/wide_card_%s.png" % str(g.id))
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    art.custom_minimum_size = Vector2(0, 105)
    art.size_flags_stretch_ratio = 1.0
    art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    art.clip_contents = true
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    column.add_child(art)

    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation", 14)
    column.add_child(top)
    var preview := GamePreview.new()
    preview.game_id = g.id
    preview.accent = g.color
    preview.custom_minimum_size = Vector2(72, 78)
    preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    top.add_child(preview)

    var details := VBoxContainer.new()
    details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    details.add_theme_constant_override("separation", 5)
    top.add_child(details)
    var name := Label.new()
    name.text = str(g.title)
    name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    name.add_theme_font_size_override("font_size", 21)
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
    var mastery_label := Label.new()
    mastery_label.text = "MASTERY: %s  •  %d WINS" % [_mastery_tier_name(str(g.id)).to_upper(), int(game_win_counts.get(str(g.id), 0))]
    mastery_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    mastery_label.add_theme_font_size_override("font_size", 15)
    mastery_label.add_theme_color_override("font_color", Color("#a8e6d0"))
    details.add_child(mastery_label)
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
    description.add_theme_font_size_override("font_size", 17)
    description.add_theme_color_override("font_color", Color("#e4eaff"))
    column.add_child(description)
    var favorite_id: String = str(g.id)
    var is_favorite: bool = bool(favorite_games.get(favorite_id, false))
    var favorite_label: String = "REMOVE FROM FAVORITES" if is_favorite else "ADD TO FAVORITES"
    var favorite_button := _button(favorite_label, func(): _toggle_game_favorite(favorite_id), Color("#344a76"), 52)
    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 7)
    column.add_child(actions)
    favorite_button.text = "♥ FAVORITE" if not is_favorite else "♥ UNFAVORITE"
    favorite_button.add_theme_font_size_override("font_size", 16)
    favorite_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    actions.add_child(favorite_button)
    var play := _button("▶ PLAY", func(): launch(str(g.id)), Color("#fa7098"), 60)
    play.add_theme_font_size_override("font_size", 19)
    play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    actions.add_child(play)
    return card


# A single primary category per game makes browsing predictable.
# Existing game genre labels remain unchanged.
const GAME_CATEGORIES := {
    "fast": "REFLEX",
    "merge": "PUZZLE",
    "stack": "REFLEX",
    "memory": "PUZZLE",
    "whack": "ARCADE",
    "sort": "STRATEGY",
    "snake": "ARCADE",
    "dots": "STRATEGY",
    "hopper": "ARCADE",
    "rhythm": "REFLEX",
    "dodge": "REFLEX",
    "slide": "PUZZLE",
    "fruit": "ARCADE"
}

const CATEGORY_DESCRIPTIONS := {
    "ALL": "Browse the complete MiniVerse collection.",
    "FAVORITES": "The games you've saved for quick access.",
    "ARCADE": "Action, movement, and classic arcade fun.",
    "PUZZLE": "Think, match, and solve at your own pace.",
    "REFLEX": "Test your timing and quick reactions.",
    "STRATEGY": "Plan your moves and solve each challenge."
}


func _category_game_count(category: String) -> int:
    var result: int = 0
    for game in GAMES:
        if _matches_filter(game, category):
            result += 1
    return result


func _matches_filter(g: Dictionary, category: String) -> bool:
    if category == "ALL":
        return true
    if category == "FAVORITES":
        return bool(favorite_games.get(str(g.id), false))
    return str(GAME_CATEGORIES.get(str(g.id), "")) == category


func _discovered_game_count() -> int:
    var count: int = 0
    for game in GAMES:
        if int(game_play_counts.get(str(game.id), 0)) > 0:
            count += 1
    return count


func _claim_all_collection_milestones() -> void:
    var discovered: int = _discovered_game_count()
    var total_coins: int = 0
    var claimed_count: int = 0
    for milestone in COLLECTION_MILESTONES:
        var required_count: int = int(milestone["count"])
        var milestone_key: String = str(required_count)
        if discovered >= required_count and not bool(collection_milestones_claimed.get(milestone_key, false)):
            collection_milestones_claimed[milestone_key] = true
            total_coins += int(milestone["coins"])
            claimed_count += 1
    if claimed_count == 0:
        return
    coins += total_coins
    collection_reward_notice = "%d collection milestone(s) claimed! +%d coins." % [claimed_count, total_coins]
    _save()
    # Refresh the collection page after a single Claim All action.
    game_collection_page()


func _collection_milestone_cards() -> void:
    var discovered: int = _discovered_game_count()
    _heading("Collection Milestones", "Discover new games to unlock one-time coin rewards.")
    if collection_reward_notice != "":
        _card("COLLECTION REWARDS CLAIMED!", collection_reward_notice)
        collection_reward_notice = ""
    var ready_count: int = 0
    var ready_coins: int = 0
    for milestone in COLLECTION_MILESTONES:
        var required_count: int = int(milestone["count"])
        var claimed: bool = bool(collection_milestones_claimed.get(str(required_count), false))
        var ready: bool = discovered >= required_count
        if ready and not claimed:
            ready_count += 1
            ready_coins += int(milestone["coins"])
        var state: String = "CLAIMED" if claimed else ("READY TO CLAIM" if ready else "IN PROGRESS")
        _card(str(milestone["title"]).to_upper() + "  -  " + state,
            "Discover %d / %d games. Reward: %d coins." % [mini(discovered, required_count), required_count, int(milestone["coins"])])
    if ready_count > 0:
        content.add_child(_button("CLAIM ALL %d REWARDS  (+%d COINS)" % [ready_count, ready_coins],
            _claim_all_collection_milestones, _theme_color(), 60))
    else:
        _card("COLLECTION REWARDS", "All available milestone rewards have been claimed. Discover more games to unlock the rest.")


func _mastery_tier_name(game_id: String) -> String:
    var wins: int = int(game_win_counts.get(game_id, 0))
    var tier_name: String = "Newcomer"
    for tier in MASTERY_TIERS:
        if wins >= int(tier["wins"]):
            tier_name = str(tier["name"])
    return tier_name


func _mastery_claimable_count() -> int:
    var count: int = 0
    for game in GAMES:
        var game_id: String = str(game["id"])
        var wins: int = int(game_win_counts.get(game_id, 0))
        for tier in MASTERY_TIERS:
            var key: String = game_id + ":" + str(tier["wins"])
            if wins >= int(tier["wins"]) and not bool(mastery_rewards_claimed.get(key, false)):
                count += 1
    return count


func _claim_all_mastery_rewards() -> void:
    var total: int = 0
    var count: int = 0
    for game in GAMES:
        var game_id: String = str(game["id"])
        var wins: int = int(game_win_counts.get(game_id, 0))
        for tier in MASTERY_TIERS:
            var key: String = game_id + ":" + str(tier["wins"])
            if wins >= int(tier["wins"]) and not bool(mastery_rewards_claimed.get(key, false)):
                mastery_rewards_claimed[key] = true
                total += int(tier["coins"])
                count += 1
    if count > 0:
        coins += total
        mastery_notice = "Claimed %d mastery rewards: +%d coins!" % [count, total]
    else:
        mastery_notice = "No new mastery rewards are ready yet."
    _save()
    game_mastery_page()


func _game_achievement_progress(game_id: String, achievement: Dictionary) -> int:
    if str(achievement["type"]) == "plays":
        return int(game_play_counts.get(game_id, 0))
    return int(game_win_counts.get(game_id, 0))


func _game_achievements_ready() -> int:
    var ready: int = 0
    for game in GAMES:
        var game_id: String = str(game["id"])
        for achievement in GAME_ACHIEVEMENT_TIERS:
            var claim_key: String = game_id + ":" + str(achievement["id"])
            if _game_achievement_progress(game_id, achievement) >= int(achievement["target"]) and not bool(game_achievement_claimed.get(claim_key, false)):
                ready += 1
    return ready


func _claim_all_game_achievements() -> void:
    var count: int = 0
    var earned: int = 0
    for game in GAMES:
        var game_id: String = str(game["id"])
        for achievement in GAME_ACHIEVEMENT_TIERS:
            var claim_key: String = game_id + ":" + str(achievement["id"])
            if _game_achievement_progress(game_id, achievement) >= int(achievement["target"]) and not bool(game_achievement_claimed.get(claim_key, false)):
                game_achievement_claimed[claim_key] = true
                count += 1
                earned += int(achievement["coins"])
    if count > 0:
        coins += earned
        game_achievement_notice = "Claimed %d achievements and earned %d coins!" % [count, earned]
        if game_achievement_claimed.size() in [10, 20, 35, 52]:
            game_achievement_notice += " A new showcase cosmetic is unlocked!"
    else:
        game_achievement_notice = "No unclaimed achievements yet."
    _save()
    game_achievements_page()


func _achievement_game_name(game_id: String) -> String:
    for game in GAMES:
        if str(game["id"]) == game_id:
            return str(game["title"])
    return "Game"


func _achievement_game_claimed(game_id: String) -> int:
    var count: int = 0
    for achievement in GAME_ACHIEVEMENT_TIERS:
        if bool(game_achievement_claimed.get(game_id + ":" + str(achievement["id"]), false)):
            count += 1
    return count


func _select_achievement_game(game_id: String) -> void:
    achievement_selected_game = game_id
    achievement_status_filter = "ALL"
    game_achievements_page()


func _set_achievement_status_filter(status: String) -> void:
    achievement_status_filter = status
    game_achievements_page()


func game_achievements_page() -> void:
    current_tab = "games"
    _shell()
    _heading("Game Achievements", "Choose a game to see its four challenges.")
    var ready: int = _game_achievements_ready()
    var total: int = GAMES.size() * GAME_ACHIEVEMENT_TIERS.size()
    _card("ACHIEVEMENT COLLECTION", "%d / %d claimed  •  %d ready to collect" % [game_achievement_claimed.size(), total, ready])
    if game_achievement_notice != "":
        _card("LATEST REWARD", game_achievement_notice)
    if ready > 0:
        content.add_child(_button("CLAIM ALL ACHIEVEMENT REWARDS (%d)" % ready, _claim_all_game_achievements, Color("#fbbf24"), 56))
    if achievement_selected_game == "":
        _heading("Choose a Mini-Game", "See progress without scrolling through all 52 achievements.")
        for game in GAMES:
            var game_id: String = str(game["id"])
            var claimed: int = _achievement_game_claimed(game_id)
            var game_ready: int = 0
            for achievement in GAME_ACHIEVEMENT_TIERS:
                var claim_key: String = game_id + ":" + str(achievement["id"])
                if _game_achievement_progress(game_id, achievement) >= int(achievement["target"]) and not bool(game_achievement_claimed.get(claim_key, false)):
                    game_ready += 1
            var suffix: String = "  •  %d READY" % game_ready if game_ready > 0 else ""
            content.add_child(_button("%s  •  %d/4%s" % [str(game["title"]), claimed, suffix], func(): _select_achievement_game(game_id), _theme_color() if game_ready > 0 else PANEL2, 50))
        _card("EXCLUSIVE COSMETICS", "Claim 10, 20, 35 and 52 game achievements to earn special banner cosmetics.")
        content.add_child(_button("VIEW ACHIEVEMENT BANNERS", func(): _open_profile_section("banners"), PANEL2, 48))
        content.add_child(_button("VIEW ACHIEVEMENT DECORATIONS", func(): _open_profile_section("decorations"), PANEL2, 48))
        content.add_child(_button("BACK TO GAME LIBRARY", library, PANEL2, 52))
        return

    content.add_child(_button("BACK TO ALL GAMES", func(): _select_achievement_game(""), PANEL2, 52))
    _heading(_achievement_game_name(achievement_selected_game), "%d of 4 achievements claimed" % _achievement_game_claimed(achievement_selected_game))
    var filters := HFlowContainer.new()
    filters.add_theme_constant_override("h_separation", 8)
    filters.add_theme_constant_override("v_separation", 8)
    content.add_child(filters)
    for status in ["ALL", "READY", "IN PROGRESS", "CLAIMED"]:
        var selected_status: String = status
        var chip := _button(status, func(): _set_achievement_status_filter(selected_status), _theme_color() if achievement_status_filter == status else PANEL2, 42)
        chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        chip.add_theme_font_size_override("font_size", 15)
        filters.add_child(chip)
    var shown: int = 0
    for achievement in GAME_ACHIEVEMENT_TIERS:
        var claim_key: String = achievement_selected_game + ":" + str(achievement["id"])
        var progress: int = _game_achievement_progress(achievement_selected_game, achievement)
        var target: int = int(achievement["target"])
        var claimed: bool = bool(game_achievement_claimed.get(claim_key, false))
        var unlocked: bool = progress >= target
        var status: String = "CLAIMED" if claimed else ("READY" if unlocked else "IN PROGRESS")
        if achievement_status_filter != "ALL" and achievement_status_filter != status:
            continue
        shown += 1
        _card(str(achievement["name"]).to_upper() + "  •  " + status, "%s  •  %d / %d  •  +%d coins" % [str(achievement["desc"]), mini(progress, target), target, int(achievement["coins"])])
    if shown == 0:
        _card("NOTHING HERE YET", "No achievements match this filter. Try All to see every challenge.")
    content.add_child(_button("BACK TO ALL GAMES", func(): _select_achievement_game(""), PANEL2, 52))


func _select_mastery_game(game_id: String) -> void:
    mastery_selected_game = game_id
    game_mastery_page()


func _set_mastery_rank_filter(rank: String) -> void:
    mastery_rank_filter = rank
    game_mastery_page()


func _mastery_game_ready(game_id: String) -> int:
    var ready: int = 0
    var wins: int = int(game_win_counts.get(game_id, 0))
    for tier in MASTERY_TIERS:
        var key: String = game_id + ":" + str(tier["wins"])
        if wins >= int(tier["wins"]) and not bool(mastery_rewards_claimed.get(key, false)):
            ready += 1
    return ready


func game_mastery_page() -> void:
    current_tab = "games"
    _shell()
    _heading("Game Mastery", "Choose a mini-game to explore its mastery ranks.")
    var ready: int = _mastery_claimable_count()
    _card("MASTERY OVERVIEW", "%d rewards ready  •  %d total wins across %d games" % [ready, _total_mastery_wins(), GAMES.size()])
    if mastery_notice != "":
        _card("MASTERY UPDATE", mastery_notice)
    if ready > 0:
        content.add_child(_button("CLAIM ALL MASTERY REWARDS (%d)" % ready, _claim_all_mastery_rewards, Color("#fbbf24"), 56))
    if mastery_selected_game == "":
        content.add_child(_button("GAME ACHIEVEMENTS (%d READY)" % _game_achievements_ready(), game_achievements_page, PANEL2, 48))
        _card("MASTERY COSMETICS", "%d total wins  •  Cosmetic milestones at 15, 40, 80 and 150 wins" % _total_mastery_wins())
        content.add_child(_button("VIEW MASTERY BANNERS", func(): _open_profile_section("banners"), PANEL2, 48))
        content.add_child(_button("VIEW MASTERY DECORATIONS", func(): _open_profile_section("decorations"), PANEL2, 48))
        _heading("Filter by Rank", "Find games at a particular mastery level.")
        var chips := HFlowContainer.new()
        chips.add_theme_constant_override("h_separation", 8)
        chips.add_theme_constant_override("v_separation", 8)
        content.add_child(chips)
        for rank in ["ALL", "NEWCOMER", "BRONZE", "SILVER", "GOLD", "DIAMOND"]:
            var selected_rank: String = rank
            var chip := _button(rank, func(): _set_mastery_rank_filter(selected_rank), _theme_color() if mastery_rank_filter == selected_rank else PANEL2, 44)
            chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
            chip.add_theme_font_size_override("font_size", 16)
            chips.add_child(chip)
        var shown: int = 0
        for game in GAMES:
            var game_id: String = str(game["id"])
            var rank_name: String = _mastery_tier_name(game_id)
            if mastery_rank_filter != "ALL" and rank_name.to_upper() != mastery_rank_filter:
                continue
            shown += 1
            var wins: int = int(game_win_counts.get(game_id, 0))
            var game_ready: int = _mastery_game_ready(game_id)
            var suffix: String = "  •  %d READY" % game_ready if game_ready > 0 else ""
            content.add_child(_button("%s  •  %s  •  %d WINS%s" % [str(game["title"]), rank_name, wins, suffix], func(): _select_mastery_game(game_id), _theme_color() if game_ready > 0 else PANEL2, 52))
        if shown == 0:
            _card("NO MATCHING GAMES", "Try another mastery rank filter.")
        content.add_child(_button("BACK TO GAME LIBRARY", library, PANEL2, 52))
        return

    var game_id: String = mastery_selected_game
    var game_data: Dictionary = _game_data(game_id)
    if game_data.is_empty():
        mastery_selected_game = ""
        game_mastery_page()
        return
    content.add_child(_button("BACK TO ALL GAMES", func(): _select_mastery_game(""), PANEL2, 52))
    var wins: int = int(game_win_counts.get(game_id, 0))
    _heading(str(game_data["title"]), "%d wins  •  Current rank: %s" % [wins, _mastery_tier_name(game_id)])
    for tier in MASTERY_TIERS:
        var goal: int = int(tier["wins"])
        var key: String = game_id + ":" + str(goal)
        var claimed: bool = bool(mastery_rewards_claimed.get(key, false))
        var reached: bool = wins >= goal
        var status: String = "CLAIMED" if claimed else ("READY TO CLAIM" if reached else "IN PROGRESS")
        _card(str(tier["name"]).to_upper() + "  •  " + status, "%d / %d wins  •  +%d coins" % [mini(wins, goal), goal, int(tier["coins"])])
    content.add_child(_button("BACK TO ALL GAMES", func(): _select_mastery_game(""), PANEL2, 52))


func game_collection_page() -> void:
    current_tab = "games"
    _shell()
    _heading("Game Collection", "Discovery progress and one-time milestone rewards.")
    var discovered: int = _discovered_game_count()
    _card("DISCOVERED  %d / %d" % [discovered, GAMES.size()], "Finish a round in each new game to earn %d bonus coins. Games you played before this feature count toward discovery." % DISCOVERY_COIN_REWARD)
    _collection_milestone_cards()
    content.add_child(_button("BACK TO GAME LIBRARY", library, _theme_color(), 56))


func library(restore_scroll: int = -1):
    current_tab = "games"
    _shell()
    _heading("Game Library", "%d mini-games. Choose a category and jump into a game." % GAMES.size())
    _fantasy_section_art()

    # Collection rewards now live on their own page, rather than pushing the
    # game cards far below the fold.
    var discovered: int = _discovered_game_count()
    content.add_child(_button("COLLECTION & REWARDS  (%d/%d DISCOVERED)" % [discovered, GAMES.size()], game_collection_page, _theme_color(), 58))
    content.add_child(_button("MY FAVORITE GAMES", favorite_games_page, Color("#344a76"), 52))
    content.add_child(_button("GAME MASTERY  (%d REWARDS READY)" % _mastery_claimable_count(), game_mastery_page, Color("#344a76"), 52))
    content.add_child(_button("GAME ACHIEVEMENTS  (%d READY)" % _game_achievements_ready(), game_achievements_page, Color("#344a76"), 52))

    var filters := HFlowContainer.new()
    filters.add_theme_constant_override("h_separation", 8)
    filters.add_theme_constant_override("v_separation", 9)
    content.add_child(filters)
    for category in ["ALL", "FAVORITES", "ARCADE", "PUZZLE", "REFLEX", "STRATEGY"]:
        var selected_category: String = category
        var amount: int = _category_game_count(selected_category)
        var chip_label: String = "%s (%d)" % [selected_category, amount]
        var chip := _button(chip_label, func():
            library_filter = selected_category
            library()
        , _theme_color() if library_filter == selected_category else Color("#344a76"), 48)
        chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        chip.add_theme_font_size_override("font_size", 18)
        filters.add_child(chip)

    var count: int = _category_game_count(library_filter)
    _heading("%s  (%d)" % [library_filter, count], str(CATEGORY_DESCRIPTIONS.get(library_filter, "Browse the collection.")))
    if count == 0:
        if library_filter == "FAVORITES":
            _card("NO FAVORITES YET", "Tap ADD TO FAVORITES on any game card to save it here.")
        else:
            _card("NO GAMES IN THIS CATEGORY", "Try another category to find a game.")
    else:
        for game in GAMES:
            if _matches_filter(game, library_filter):
                content.add_child(_game_card(game))

    if restore_scroll >= 0 and is_instance_valid(lobby_scroll):
        lobby_scroll.set_deferred("scroll_vertical", restore_scroll)

func events():
    _shell()
    _heading("Challenges & Events", "Event previews for the growing MiniVerse.")
    _card("DAILY DASH", _daily_feature_description())
    content.add_child(_button("PLAY TODAY'S FEATURED GAME", _daily_challenge, Color("#fbbf24")))
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
    level = _level_from_xp(xp)

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

func _settings_page(section: String) -> void:
    settings_section = section
    settings()


func _settings_toggle(option: String) -> void:
    match option:
        "banner_animation":
            banner_animation_enabled = not banner_animation_enabled
        "glow":
            show_background_glow = not show_background_glow
        "compact":
            compact_menus = not compact_menus
        "tagline":
            show_header_tagline = not show_header_tagline
    _save()
    settings()


func settings():
    _shell()
    _heading("Settings", "Personalize MiniVerse and manage your game.")
    if settings_section == "home":
        _card("APPEARANCE & LAYOUT", "Change the interface, visual effects, and your personal style.")
        content.add_child(_button("APPEARANCE SETTINGS", func(): _settings_page("appearance"), _theme_color()))
        _card("SOUND", "Adjust sound effects for your games and menus.")
        content.add_child(_button("SOUND SETTINGS", func(): _settings_page("audio"), Color("#344a9b")))
        _card("HELP & TUTORIALS", "Review the instructions for any mini-game.")
        content.add_child(_button("GAME TUTORIALS", func(): _settings_page("help"), Color("#344a9b")))
        _card("GAME DATA", "Reset individual levels or manage local saved progress.")
        content.add_child(_button("SAVE & RESET OPTIONS", func(): _settings_page("data"), Color("#344a9b")))
        content.add_child(_menu_button("BACK TO HOME", home, PANEL2, "back"))
        return

    content.add_child(_button("BACK TO SETTINGS", func(): _settings_page("home"), PANEL2, 52))
    if settings_section == "appearance":
        _heading("Appearance", "Choose how MiniVerse looks and feels.")
        _card("MENU BACKGROUND", "Currently: %s. Pick a color atmosphere for every menu." % _background_name())
        content.add_child(_button("CHOOSE MENU BACKGROUND", func(): _settings_page("backgrounds"), _theme_color()))

        _card("BACKGROUND GLOW", "Decorative corner lighting behind menus.")
        content.add_child(_button("BACKGROUND GLOW: ON" if show_background_glow else "BACKGROUND GLOW: OFF", func(): _settings_toggle("glow"), _theme_color()))
        _card("MENU SPACING", "Compact mode fits more items on screen with smaller gaps.")
        content.add_child(_button("COMPACT MENUS: ON" if compact_menus else "COMPACT MENUS: OFF", func(): _settings_toggle("compact"), _theme_color()))
        _card("ANIMATED AVATAR BANNER", "Subtle, gently pulsing highlights on your Home avatar banner. Disable for a still design.")
        content.add_child(_button("BANNER ANIMATION: ON" if banner_animation_enabled else "BANNER ANIMATION: OFF", func(): _settings_toggle("banner_animation"), _theme_color()))
        _card("HEADER TAGLINE", "Show or hide the MiniVerse slogan beneath the logo.")
        content.add_child(_button("HEADER TAGLINE: ON" if show_header_tagline else "HEADER TAGLINE: OFF", func(): _settings_toggle("tagline"), _theme_color()))
        _card("YOUR LOOK", "Themes, avatars and victory effects can be equipped in the Shop. Frames, titles and badges live in Profile.")
        content.add_child(_button("OPEN COSMETIC SHOP", func(): _open_shop_category("home"), Color("#344a9b")))
        content.add_child(_button("CUSTOMIZE PROFILE", func(): _open_profile_section("customize"), Color("#344a9b")))
    elif settings_section == "backgrounds":
        _heading("Menu Backgrounds", "Free choices plus rewards for coins and player levels.")
        if cosmetic_unlock_message != "":
            _card("CUSTOMIZATION", cosmetic_unlock_message)
        for background_item in MENU_BACKGROUNDS:
            var bg_id: String = str(background_item["id"])
            var bg_name: String = str(background_item["name"])
            var owned: bool = _cosmetic_owned("background", background_item)
            var status: String = "EQUIPPED" if equipped_background == bg_id else ("OWNED" if owned else ("LEVEL %d" % int(background_item["level_required"]) if int(background_item.get("level_required", 0)) > 0 else "%d COINS" % int(background_item.get("price", 0))))
            _card(bg_name.to_upper() + "  •  " + status, str(background_item["description"]))
            if equipped_background != bg_id:
                content.add_child(_button(("USE " if owned else "UNLOCK ") + bg_name.to_upper(), func(): _equip_background(bg_id), Color(str(background_item["color"])).lightened(0.24), 54))
        content.add_child(_button("BACK TO APPEARANCE", func(): _settings_page("appearance"), PANEL2, 52))
    elif settings_section == "audio":
        _heading("Audio", "Choose whether game and menu sounds play.")
        content.add_child(_button("SOUND EFFECTS: ON" if sound_enabled else "SOUND EFFECTS: OFF", _toggle_sound, _theme_color()))
    elif settings_section == "help":
        _heading("Help & Tutorials", "Review instructions whenever you want.")
        content.add_child(_button("REPLAY GAME TUTORIALS", _tutorial_menu, Color("#344a9b")))
    elif settings_section == "data":
        _heading("Saved Data", "Progress is stored locally on this device.")
        _card("RESET ONE GAME", "Start one game's levels again without losing coins or XP.")
        content.add_child(_button("CHOOSE GAME TO RESET", _reset_level_menu, Color("#344a9b")))
        _card("RESET ALL LEVELS", "Start game levels again. Other progress remains.")
        content.add_child(_button("RESET ALL GAME LEVELS", _confirm_reset_levels, Color("#f9738f")))
        _card("DANGER ZONE", "Erasing local progress cannot be undone.")
        content.add_child(_button("ERASE LOCAL PROGRESS", _confirm_reset_progress, Color("#f9738f")))



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
    _settings_page("audio")

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
    last_rewarded_level = 1
    level_up_notice = ""
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
        "dodge": _play_dodge()
        "slide": _play_slide()
        "fruit": _play_fruit()
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
    panel.add_theme_stylebox_override("panel", _lobby_card_style(Color("#ffcf67")))
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
    var preview := TextureRect.new()
    preview.texture = load("res://assets/lobby/wide_card_%s.png" % id)
    preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    preview.custom_minimum_size = Vector2(240, 116)
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
    # Shared fantasy gameplay identity for all 13 mini-games.
    # This sits above the gameplay control, so it cannot obscure touch targets.
    var adventure_panel := PanelContainer.new()
    var adventure_style := _lobby_card_style(Color("#ffdc7b"))
    adventure_style.content_margin_left = 6
    adventure_style.content_margin_right = 6
    adventure_style.content_margin_top = 6
    adventure_style.content_margin_bottom = 6
    adventure_panel.add_theme_stylebox_override("panel", adventure_style)
    content.add_child(adventure_panel)
    var adventure_stack := VBoxContainer.new()
    adventure_stack.add_theme_constant_override("separation", 5)
    adventure_panel.add_child(adventure_stack)
    var adventure_art := TextureRect.new()
    adventure_art.texture = load("res://assets/lobby/wide_card_%s.png" % game_id)
    adventure_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    adventure_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    adventure_art.custom_minimum_size.y = 72
    adventure_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    adventure_art.clip_contents = true
    adventure_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    adventure_stack.add_child(adventure_art)
    var progress_header := Label.new()
    progress_header.text = "✦  %s  •  LEVEL %d  ✦" % [_game_name(game_id).to_upper(), Difficulty.level(game_id)]
    progress_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    progress_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    progress_header.add_theme_font_size_override("font_size", 19)
    progress_header.add_theme_color_override("font_color", Color("#ffe39c"))
    progress_header.add_theme_color_override("font_shadow_color", Color("#09062b"))
    adventure_stack.add_child(progress_header)
    # Keep a visible way back to the lobby while playing any mini-game.
    content.add_child(_menu_button("RETURN TO LOBBY", home, PANEL2, "back", 46))
    # ScrollContainer content must have a real minimum height; otherwise nested
    # game controls can collapse to almost zero height on mobile-sized viewports.
    g.custom_minimum_size = Vector2(0, 820)
    content.add_child(g)
    # Each game inherits its own banner's colors and fantasy border.
    # This decorative layer is behind the gameplay UI and ignores touches.
    var game_backdrop := TextureRect.new()
    game_backdrop.texture = load("res://assets/lobby/gameplay_backdrop_%s.png" % game_id)
    game_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    game_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    game_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
    game_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_backdrop.show_behind_parent = true
    g.add_child(game_backdrop)
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

func _play_fruit():
    var g := FruitCatch.new()
    g.finished.connect(_finished)
    _mount_game(g)
    g.start_game()

func _play_slide():
    var g := TileSlide.new()
    g.finished.connect(_finished)
    _mount_game(g)
    g.start_game()

func _play_dodge():
    var g := NeonDodge.new()
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
    level = _level_from_xp(xp)
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


func _weekly_bonus_definition() -> Dictionary:
    # A predictable rotation tied to the Monday start date; no server needed.
    var monday_unix: float = Time.get_unix_time_from_datetime_string(weekly_key + "T12:00:00")
    var rotation: int = posmod(int(monday_unix / 86400.0 / 7.0), 3)
    if rotation == 0:
        return {"id":"bonus_rounds", "title":"Bonus: Round Runner", "detail":"Finish 10 additional rounds this week.", "target":10, "coins":125, "xp":140}
    if rotation == 1:
        return {"id":"bonus_wins", "title":"Bonus: Winning Spirit", "detail":"Win 5 rounds this week.", "target":5, "coins":150, "xp":160}
    return {"id":"bonus_variety", "title":"Bonus: Game Sampler", "detail":"Try 3 different mini-games this week.", "target":3, "coins":135, "xp":150}


func _weekly_definitions() -> Array[Dictionary]:
    var challenges: Array[Dictionary] = [
        {"id":"rounds", "title":"Arcade Explorer", "detail":"Finish 15 mini-game rounds this week.", "target":15, "coins":180, "xp":200},
        {"id":"wins", "title":"Victory Marathon", "detail":"Successfully clear 8 levels this week.", "target":8, "coins":240, "xp":250},
        {"id":"variety", "title":"World Tour", "detail":"Finish a round in 5 different mini-games.", "target":5, "coins":300, "xp":300}
    ]
    challenges.append(_weekly_bonus_definition())
    return challenges


func _weekly_record(id: String, passed: bool) -> void:
    _weekly_reset_if_needed()
    if not weekly_claimed.has("rounds"):
        weekly_progress["rounds"] = mini(int(weekly_progress.get("rounds", 0)) + 1, 15)
    if passed and not weekly_claimed.has("wins"):
        weekly_progress["wins"] = mini(int(weekly_progress.get("wins", 0)) + 1, 8)
    if not weekly_claimed.has("variety"):
        weekly_games[id] = true
        weekly_progress["variety"] = mini(weekly_games.size(), 5)
    var bonus: Dictionary = _weekly_bonus_definition()
    var bonus_id: String = str(bonus["id"])
    if not weekly_claimed.has(bonus_id):
        if bonus_id == "bonus_rounds" or (bonus_id == "bonus_wins" and passed):
            weekly_progress[bonus_id] = mini(int(weekly_progress.get(bonus_id, 0)) + 1, int(bonus["target"]))
        elif bonus_id == "bonus_variety":
            weekly_progress[bonus_id] = mini(weekly_games.size(), int(bonus["target"]))


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
        level = _level_from_xp(xp)
        weekly_notice = "Claimed %s: +%d coins and +%d XP!" % [str(challenge["title"]), int(challenge["coins"]), int(challenge["xp"])]
        _play_sound(SFX_COLLECT)
        _save()
        weekly_challenges()
        return


func weekly_challenges() -> void:
    _weekly_reset_if_needed()
    current_tab = "rewards"
    _shell()
    _heading("Weekly Challenges", "Three core goals plus one rotating bonus each week.")
    var weekly_ready: int = _weekly_rewards_ready()
    if weekly_ready > 0:
        _card("READY TO CLAIM", "%d weekly reward%s available below." % [weekly_ready, "" if weekly_ready == 1 else "s"])
    if weekly_ready > 0:
        content.add_child(_button("CLAIM ALL READY CHALLENGES (%d)" % (_daily_rewards_ready() + weekly_ready - (1 if _login_can_claim() else 0)), _claim_all_challenge_rewards, Color("#34d399"), 54))
    _card("THIS WEEK", "Started Monday %s. Progress resets next Monday (device local time)." % weekly_key)
    _card("ROTATING BONUS", "The fourth challenge changes every Monday. Finish it for extra coins and XP!")
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
        daily_bonus_progress = 0
        daily_bonus_claimed = false
        daily_bonus_notice = ""


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


func _daily_bonus_definition() -> Dictionary:
    var day_info: Dictionary = Time.get_datetime_dict_from_datetime_string(mission_day, false)
    var day_number: int = int(day_info.get("year", 2026)) * 372 + int(day_info.get("month", 1)) * 31 + int(day_info.get("day", 1))
    match day_number % 3:
        0:
            return {"title":"Bonus: Play More", "detail":"Finish 5 rounds in any mini-games.", "target":5, "type":"plays", "coins":70, "xp":65}
        1:
            return {"title":"Bonus: Winning Day", "detail":"Win 2 rounds in any mini-games.", "target":2, "type":"wins", "coins":85, "xp":80}
        _:
            return {"title":"Bonus: Game Explorer", "detail":"Finish 3 rounds in the featured bonus game.", "target":3, "type":"focus", "game":MISSION_GAMES[(day_number + 7) % MISSION_GAMES.size()], "coins":75, "xp":70}


func _daily_bonus_record(id: String, passed: bool) -> void:
    _mission_reset_if_needed()
    if daily_bonus_claimed:
        return
    var bonus: Dictionary = _daily_bonus_definition()
    var bonus_type: String = str(bonus["type"])
    if bonus_type == "wins" and not passed:
        return
    if bonus_type == "focus" and id != str(bonus["game"]):
        return
    daily_bonus_progress = mini(daily_bonus_progress + 1, int(bonus["target"]))


func _daily_bonus_claim() -> void:
    _mission_reset_if_needed()
    var bonus: Dictionary = _daily_bonus_definition()
    if daily_bonus_claimed or daily_bonus_progress < int(bonus["target"]):
        return
    daily_bonus_claimed = true
    coins += int(bonus["coins"])
    xp += int(bonus["xp"])
    level = _level_from_xp(xp)
    daily_bonus_notice = "Bonus claimed: +%d coins and +%d XP!" % [int(bonus["coins"]), int(bonus["xp"])]
    _play_sound(SFX_COLLECT)
    _save()
    daily_missions()


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
    level = _level_from_xp(xp)
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
        level = _level_from_xp(xp)
        mission_notice = "Claimed %s: +%d coins and +%d XP!" % [str(mission["title"]), int(mission["coins"]), int(mission["xp"])]
        _challenge_streak_reward()
        _play_sound(SFX_COLLECT)
        _save()
        daily_missions()
        return


func daily_missions() -> void:
    _mission_reset_if_needed()
    current_tab = "rewards"
    _shell()
    _heading("Daily Missions", "Three fresh challenges each day. Complete them to claim extra rewards!")
    var daily_ready: int = _daily_rewards_ready()
    if daily_ready > 0:
        _card("REWARDS WAITING", "%d daily reward%s ready to claim, including today's login reward if available." % [daily_ready, "" if daily_ready == 1 else "s"])
    var claimable_challenges: int = daily_ready + _weekly_rewards_ready() - (1 if _login_can_claim() else 0)
    if claimable_challenges > 0:
        content.add_child(_button("CLAIM ALL READY CHALLENGES (%d)" % claimable_challenges, _claim_all_challenge_rewards, Color("#34d399"), 54))
    content.add_child(_menu_button("VIEW DAILY LOGIN REWARDS", _login_rewards_page, Color("#fbbf24"), "missions"))
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
    _heading("Rotating Daily Bonus", "One extra objective each day. This does not affect your three-mission streak.")
    var bonus: Dictionary = _daily_bonus_definition()
    var bonus_target: int = int(bonus["target"])
    var bonus_status: String = "CLAIMED" if daily_bonus_claimed else ("READY TO CLAIM" if daily_bonus_progress >= bonus_target else "%d / %d" % [daily_bonus_progress, bonus_target])
    var bonus_detail: String = str(bonus["detail"])
    if str(bonus["type"]) == "focus":
        bonus_detail = "Finish 3 rounds of %s." % _game_name(str(bonus["game"]))
    _card(str(bonus["title"]), "%s\nProgress: %s\nReward: %d coins + %d XP" % [bonus_detail, bonus_status, int(bonus["coins"]), int(bonus["xp"])])
    if daily_bonus_notice != "":
        _card("BONUS REWARD", daily_bonus_notice)
    if not daily_bonus_claimed and daily_bonus_progress >= bonus_target:
        content.add_child(_button("CLAIM DAILY BONUS", _daily_bonus_claim, Color("#36e58a"), 52))
    elif not daily_bonus_claimed and str(bonus["type"]) == "focus":
        var bonus_game: String = str(bonus["game"])
        content.add_child(_button("PLAY BONUS GAME", func(): launch(bonus_game), Color("#344a9b"), 48))
    content.add_child(_menu_button("BACK TO HOME", home, PANEL2, "back"))


func _record_daily_feature_history(id: String, score: int, completed: bool, day: String) -> void:
    var entry: Dictionary = daily_feature_history.get(day, {})
    if entry.is_empty():
        entry = {"game": id, "attempts": 0, "best": 0, "completed": false}
    entry["attempts"] = int(entry.get("attempts", 0)) + 1
    entry["best"] = maxi(int(entry.get("best", 0)), score)
    entry["completed"] = bool(entry.get("completed", false)) or completed
    daily_feature_history[day] = entry
    var dates: Array = daily_feature_history.keys()
    dates.sort()
    while dates.size() > 30:
        daily_feature_history.erase(str(dates.pop_front()))


func daily_game_history() -> void:
    _shell()
    _heading("Daily Game History", "Your last 30 featured-game days, saved on this device.")
    var dates: Array = daily_feature_history.keys()
    dates.sort()
    dates.reverse()
    var completed_days: int = 0
    var total_attempts: int = 0
    for date in dates:
        var entry: Dictionary = daily_feature_history[date]
        total_attempts += int(entry.get("attempts", 0))
        if bool(entry.get("completed", false)):
            completed_days += 1
    _card("YOUR DAILY DASH RECORD", "Days participated: %d\\nChallenges completed: %d\\nTotal featured-game attempts: %d" % [dates.size(), completed_days, total_attempts])
    if dates.is_empty():
        _card("NO DAILY GAMES YET", "Play today's featured game from the lobby to start your history.")
    else:
        for date in dates:
            var entry: Dictionary = daily_feature_history[date]
            var status: String = "COMPLETED" if bool(entry.get("completed", false)) else "IN PROGRESS"
            _card(str(date) + "  -  " + status, "%s\\nAttempts: %d  |  Best score: %d" % [_game_name(str(entry.get("game", ""))), int(entry.get("attempts", 0)), int(entry.get("best", 0))])
    content.add_child(_button("BACK TO LOBBY", home, Color("#344a9b"), 54))


func _daily_feature() -> Dictionary:
    # Stable per local calendar day, including across restarts.
    # Rotates through every game before repeating the same game.
    var date_string: String = Time.get_date_string_from_system()
    var day_number: int = int(Time.get_unix_time_from_datetime_string(date_string + "T12:00:00") / 86400.0)
    var index: int = posmod(day_number, MISSION_GAMES.size())
    var featured_id: String = str(MISSION_GAMES[index])
    var mode: int = posmod(int(day_number / MISSION_GAMES.size()), 2)
    return {"date": date_string, "id": featured_id, "mode": mode}


func _daily_feature_description() -> String:
    var feature: Dictionary = _daily_feature()
    var condition: String = "Clear a level" if int(feature["mode"]) == 1 else "Finish one round"
    var claimed: bool = daily_feature_reward_day == str(feature["date"])
    var status: String = "BONUS CLAIMED TODAY" if claimed else "First completion: +%d coins and +%d XP" % [DAILY_FEATURE_COINS, DAILY_FEATURE_XP]
    return "%s\nToday's objective: %s.\n%s\nNew featured game tomorrow." % [_game_name(str(feature["id"])), condition, status]


func _daily_challenge():
    var feature: Dictionary = _daily_feature()
    daily_feature_active = true
    daily_feature_game = str(feature["id"])
    daily_feature_day = str(feature["date"])
    daily_feature_notice = ""
    launch(daily_feature_game)

# The first five levels use explicit achievable score goals. Later goals
# increase gradually. Puzzle completion is its own success condition.
func _level_goal(id: String, played_level: int) -> int:
    # Hand-balanced introductory goals for the three reflex/timing games.
    var first_five := {
        "fast": [30, 50, 75, 105, 135],
        "stack": [2, 3, 4, 5, 6],
        "whack": [35, 50, 65, 85, 105],
        "merge": [16, 32, 48, 72, 96],
        "rhythm": [350, 650, 950, 1300, 1650],
        "dodge": [12, 16, 20, 25, 30],
        "fruit": [50, 80, 110, 140, 170]
    }
    if first_five.has(id) and played_level <= 5:
        return int(first_five[id][played_level - 1])
    var base_goals := {"fast": 135, "merge": 24, "stack": 6, "whack": 105, "snake": 3, "hopper": 3, "rhythm": 1650, "dodge": 30}
    var base: int = int(base_goals.get(id, 1))
    var step: int = maxi(0, played_level - (5 if first_five.has(id) else 1))
    return maxi(1, int(round(float(base) * (1.0 + 0.10 * float(step)))))

func _finished(id: String, score: int, extra: Dictionary = {}):
    var previous_best: int = int(best_scores.get(id, 0))
    var played_level: int = Difficulty.level(id)
    var goal: int = _level_goal(id, played_level)
    var puzzle_completion: bool = id in ["memory", "sort", "dots", "slide"]
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
    discovery_notice = ""
    if not bool(discovery_rewards_claimed.get(id, false)):
        discovery_rewards_claimed[id] = true
        coins += DISCOVERY_COIN_REWARD
        discovery_notice = "NEW GAME DISCOVERED! +%d bonus coins for your first completed round of %s." % [DISCOVERY_COIN_REWARD, _game_name(id)]
    if passed:
        total_wins += 1
        game_win_counts[id] = int(game_win_counts.get(id, 0)) + 1
    _award_achievements()
    var ready_before: int = _daily_rewards_ready() + _weekly_rewards_ready() - (1 if _login_can_claim() else 0)
    _mission_record(id, passed)
    _daily_bonus_record(id, passed)
    _weekly_record(id, passed)
    var ready_after: int = _daily_rewards_ready() + _weekly_rewards_ready() - (1 if _login_can_claim() else 0)
    if ready_after > ready_before:
        var newly_ready: int = ready_after - ready_before
        challenge_ready_notice = "%d new challenge reward%s ready! Collect them in Earn." % [newly_ready, "" if newly_ready == 1 else "s"]
    else:
        challenge_ready_notice = ""
    if daily_feature_active:
        var feature: Dictionary = _daily_feature()
        if id == daily_feature_game and daily_feature_day == str(feature["date"]):
            var completed: bool = int(feature["mode"]) == 0 or passed
            _record_daily_feature_history(id, score, completed, daily_feature_day)
            if completed:
                if daily_feature_reward_day != str(feature["date"]):
                    daily_feature_reward_day = str(feature["date"])
                    coins += DAILY_FEATURE_COINS
                    xp += DAILY_FEATURE_XP
                    daily_feature_notice = "DAILY BONUS EARNED! +%d coins and +%d XP. Come back tomorrow for another bonus!" % [DAILY_FEATURE_COINS, DAILY_FEATURE_XP]
                else:
                    daily_feature_notice = "FEATURED OBJECTIVE COMPLETE! Today's bonus has already been collected."
            else:
                daily_feature_notice = "Today's featured objective: clear the level to complete it."
        daily_feature_active = false
        daily_feature_game = ""
        daily_feature_day = ""
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
    # Show the actual mini-game's fantasy art on its results screen.
    # Reuse the same image used in the library and gameplay header.
    var result_art_panel := PanelContainer.new()
    var result_art_style := _lobby_card_style(Color("#ffd66e") if passed else Color("#9da7ed"))
    result_art_style.content_margin_left = 5
    result_art_style.content_margin_right = 5
    result_art_style.content_margin_top = 5
    result_art_style.content_margin_bottom = 5
    result_art_panel.add_theme_stylebox_override("panel", result_art_style)
    content.add_child(result_art_panel)
    var result_art_stack := VBoxContainer.new()
    result_art_stack.add_theme_constant_override("separation", 5)
    result_art_panel.add_child(result_art_stack)
    var result_art := TextureRect.new()
    result_art.texture = load("res://assets/lobby/wide_card_%s.png" % id)
    result_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    result_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    result_art.custom_minimum_size.y = 96
    result_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    result_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    result_art_stack.add_child(result_art)
    var result_banner := Label.new()
    result_banner.text = "✦  VICTORY!  ✦" if passed else "✦  KEEP ADVENTURING!  ✦"
    result_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_banner.add_theme_font_size_override("font_size", 20)
    result_banner.add_theme_color_override("font_color", Color("#ffe69b") if passed else Color("#c5d8ff"))
    result_art_stack.add_child(result_banner)
    var mastery_wins: int = int(game_win_counts.get(id, 0))
    for tier in MASTERY_TIERS:
        if passed and mastery_wins == int(tier["wins"]):
            _card("NEW MASTERY RANK!", "%s reached %s mastery! Visit Games → Game Mastery to claim your reward." % [_game_name(id), str(tier["name"])])
            break
    if challenge_ready_notice != "":
        # One compact, visually distinct alert, shown once after the round.
        var reward_alert := PanelContainer.new()
        reward_alert.add_theme_stylebox_override("panel", _style(Color("#164d48"), 18))
        content.add_child(reward_alert)
        var alert_column := VBoxContainer.new()
        alert_column.add_theme_constant_override("separation", 7)
        reward_alert.add_child(alert_column)
        var alert_heading := Label.new()
        alert_heading.text = "★  CHALLENGE REWARD READY!"
        alert_heading.add_theme_font_size_override("font_size", 22)
        alert_heading.add_theme_color_override("font_color", Color("#a7f3d0"))
        alert_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        alert_column.add_child(alert_heading)
        var alert_message := Label.new()
        alert_message.text = challenge_ready_notice
        alert_message.add_theme_font_size_override("font_size", 18)
        alert_message.add_theme_color_override("font_color", Color("#e4fff4"))
        alert_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        alert_column.add_child(alert_message)
        alert_column.add_child(_button("COLLECT REWARDS", _rewards_hub, Color("#34d399"), 52))
        challenge_ready_notice = ""
    if discovery_notice != "":
        _card("FIRST PLAY BONUS!", discovery_notice)
        discovery_notice = ""
    if daily_feature_notice != "":
        _card("DAILY DASH", daily_feature_notice)
        daily_feature_notice = ""
    if level_up_notice != "":
        _card("NEW PLAYER LEVEL!", level_up_notice)
        level_up_notice = ""
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
        "rhythm": "Tip: Tap when notes enter the glowing catch zone.",
        "dodge": "Tip: Keep moving to avoid falling hazards."
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

func _grant_milestone_cosmetics(show_notice: bool = false) -> void:
    var newly_unlocked: Array[String] = []
    for item in SHOP_THEMES:
        var required: int = int(item.get("level_required", 0))
        var cosmetic_id: String = str(item["id"])
        if required > 0 and level >= required and not owned_themes.has(cosmetic_id):
            owned_themes[cosmetic_id] = true
            newly_unlocked.append(str(item["name"]))
    if show_notice and not newly_unlocked.is_empty():
        var names: String = ", ".join(newly_unlocked)
        level_up_notice += "\nExclusive theme unlocked: " + names + "! Find it in Shop > Themes."


# Increasing XP requirements keep early levels approachable without letting
# one unusually high score skip most of the early progression.
func _xp_for_level(player_level: int) -> int:
    var completed: int = maxi(0, player_level - 1)
    return 200 * completed + 50 * completed * (completed - 1) / 2

func _xp_to_next_level(player_level: int) -> int:
    return 200 + 50 * maxi(0, player_level - 1)

func _level_from_xp(total_xp: int) -> int:
    var result: int = 1
    while total_xp >= _xp_for_level(result + 1):
        result += 1
    return result

func _level_xp_progress() -> int:
    return maxi(0, xp - _xp_for_level(level))


func _apply_level_rewards() -> void:
    # This runs before each save, after gameplay or claimed XP changes.
    # Existing players are baselined at their saved level when first loading
    # this feature, so old progress is never rewarded twice.
    var actual_level: int = maxi(1, _level_from_xp(xp))
    level = actual_level
    if actual_level <= last_rewarded_level:
        return
    var total_bonus: int = 0
    var gained: int = actual_level - last_rewarded_level
    for earned_level in range(last_rewarded_level + 1, actual_level + 1):
        total_bonus += 20 + 5 * earned_level
    coins += total_bonus
    last_rewarded_level = actual_level
    level_up_notice = "LEVEL UP! Reached level %d (+%d levels). Bonus: +%d coins!" % [actual_level, gained, total_bonus]
    _grant_milestone_cosmetics(true)


func _save():
    _apply_level_rewards()
    _grant_milestone_cosmetics()
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify({"coins":coins,"xp":xp,"level":level,"xp_curve_version":2,"last_rewarded_level":last_rewarded_level,"best_scores":best_scores,"best_stars":best_stars,"recent_games":recent_games,"favorite_games":favorite_games,"discovery_rewards_claimed":discovery_rewards_claimed,"collection_milestones_claimed":collection_milestones_claimed,"seen_tutorials":seen_tutorials,"sound_enabled":sound_enabled,"show_background_glow":show_background_glow,"compact_menus":compact_menus,"show_header_tagline":show_header_tagline,"equipped_background":equipped_background,"equipped_banner":equipped_banner,"equipped_banner_decoration":equipped_banner_decoration,"custom_player_name":custom_player_name,"custom_player_motto":custom_player_motto,"equipped_name_style":equipped_name_style,"showcased_badge":showcased_badge,"showcased_game":showcased_game,"owned_name_styles":owned_name_styles,"owned_banner_decorations":owned_banner_decorations,"banner_animation_enabled":banner_animation_enabled,"owned_backgrounds":owned_backgrounds,"owned_banners":owned_banners,"achievement_claimed":achievement_claimed,"total_games_played":total_games_played,"total_wins":total_wins,"game_play_counts":game_play_counts,"game_win_counts":game_win_counts,"mastery_rewards_claimed":mastery_rewards_claimed,"game_achievement_claimed":game_achievement_claimed,"owned_themes":owned_themes,"equipped_theme":equipped_theme,"owned_avatars":owned_avatars,"equipped_avatar":equipped_avatar,"owned_avatar_frames":owned_avatar_frames,"equipped_avatar_frame":equipped_avatar_frame,"equipped_profile_badge":equipped_profile_badge,"cosmetic_rewards_claimed":cosmetic_rewards_claimed,"owned_effects":owned_effects,"equipped_effect":equipped_effect,"mission_day":mission_day,"mission_progress":mission_progress,"mission_claimed":mission_claimed,"daily_bonus_progress":daily_bonus_progress,"daily_bonus_claimed":daily_bonus_claimed,"login_last_claim":login_last_claim,"login_streak":login_streak,"login_total_claims":login_total_claims,"equipped_title":equipped_title,"weekly_key":weekly_key,"weekly_progress":weekly_progress,"weekly_claimed":weekly_claimed,"weekly_games":weekly_games,"challenge_streak":challenge_streak,"challenge_streak_last_day":challenge_streak_last_day,"daily_feature_reward_day":daily_feature_reward_day,"daily_feature_history":daily_feature_history}))
        f.close()

func _load_save():
    if not FileAccess.file_exists(SAVE_PATH): return
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not f: return
    var data = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(data) == TYPE_DICTIONARY:
        daily_feature_reward_day = str(data.get("daily_feature_reward_day", ""))
        daily_feature_history = data.get("daily_feature_history", {})
        if typeof(daily_feature_history) != TYPE_DICTIONARY:
            daily_feature_history = {}
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
        daily_bonus_progress = int(data.get("daily_bonus_progress", 0))
        daily_bonus_claimed = bool(data.get("daily_bonus_claimed", false))
        _mission_reset_if_needed()
        sound_enabled = bool(data.get("sound_enabled", true))
        show_background_glow = bool(data.get("show_background_glow", true))
        compact_menus = bool(data.get("compact_menus", false))
        show_header_tagline = bool(data.get("show_header_tagline", true))
        equipped_background = str(data.get("equipped_background", "midnight"))
        equipped_banner = str(data.get("equipped_banner", "starlight"))
        equipped_banner_decoration = str(data.get("equipped_banner_decoration", "sparkles"))
        custom_player_name = str(data.get("custom_player_name", "Player")).strip_edges().substr(0, 18)
        if custom_player_name.is_empty():
            custom_player_name = "Player"
        custom_player_motto = str(data.get("custom_player_motto", "Small games. Big fun."))
        equipped_name_style = str(data.get("equipped_name_style", "classic"))
        showcased_badge = str(data.get("showcased_badge", "none"))
        showcased_game = str(data.get("showcased_game", "none"))
        if showcased_game != "none":
            var valid_showcase_game: bool = false
            for g in GAMES:
                if str(g.id) == showcased_game:
                    valid_showcase_game = true
                    break
            if not valid_showcase_game:
                showcased_game = "none"
        if not ["none", "rookie", "explorer", "collector", "champion", "veteran", "legend"].has(showcased_badge):
            showcased_badge = "none"
        owned_name_styles = data.get("owned_name_styles", {})
        if typeof(owned_name_styles) != TYPE_DICTIONARY:
            owned_name_styles = {}
        if not ["classic", "sky", "rose", "mint", "gold", "royal", "legend"].has(equipped_name_style):
            equipped_name_style = "classic".strip_edges().substr(0, 48)
        owned_banner_decorations = data.get("owned_banner_decorations", {})
        if typeof(owned_banner_decorations) != TYPE_DICTIONARY:
            owned_banner_decorations = {}
        if not ["none", "sparkles", "hearts", "crown", "diamonds", "stars", "laurel", "master_flame", "master_gem"].has(equipped_banner_decoration):
            equipped_banner_decoration = "sparkles"
        banner_animation_enabled = bool(data.get("banner_animation_enabled", true))
        owned_backgrounds = data.get("owned_backgrounds", {})
        owned_banners = data.get("owned_banners", {})
        if typeof(owned_backgrounds) != TYPE_DICTIONARY:
            owned_backgrounds = {}
        if typeof(owned_banners) != TYPE_DICTIONARY:
            owned_banners = {}
        if not ["midnight", "nebula", "ocean", "forest", "sunset", "galaxy", "lava", "ice", "gold"].has(equipped_background):
            equipped_background = "midnight"
        if not ["starlight", "aurora", "royal", "ember", "prism", "champion", "explorer", "legend", "bronze_master", "diamond_master"].has(equipped_banner):
            equipped_banner = "starlight"
        coins = int(data.get("coins",0))
        xp = int(data.get("xp",0))
        level = int(data.get("level",1))
        if int(data.get("xp_curve_version", 1)) < 2:
            var old_level: int = maxi(1, level)
            var old_progress: int = clampi(xp - 100 * (old_level - 1), 0, 99)
            xp = _xp_for_level(old_level) + int(round(float(old_progress) * float(_xp_to_next_level(old_level)) / 100.0))
        last_rewarded_level = int(data.get("last_rewarded_level", level))
        last_rewarded_level = maxi(1, last_rewarded_level)
        favorite_games = data.get("favorite_games", {})
        if typeof(favorite_games) != TYPE_DICTIONARY:
            favorite_games = {}
        best_scores = data.get("best_scores",{})
        best_stars = data.get("best_stars",{})
        seen_tutorials = data.get("seen_tutorials",{})
        achievement_claimed = data.get("achievement_claimed", {})
        total_games_played = int(data.get("total_games_played", 0))
        total_wins = int(data.get("total_wins", 0))
        game_play_counts = data.get("game_play_counts", {})
        game_win_counts = data.get("game_win_counts", {})
        mastery_rewards_claimed = data.get("mastery_rewards_claimed", {})
        game_achievement_claimed = data.get("game_achievement_claimed", {})
        if typeof(game_achievement_claimed) != TYPE_DICTIONARY:
            game_achievement_claimed = {}
        if typeof(mastery_rewards_claimed) != TYPE_DICTIONARY:
            mastery_rewards_claimed = {}
        # Existing players already tried these games before this feature
        # existed; don't award retroactive first-play bonuses.
        collection_milestones_claimed = data.get("collection_milestones_claimed", {})
        if typeof(collection_milestones_claimed) != TYPE_DICTIONARY:
            collection_milestones_claimed = {}
        discovery_rewards_claimed = data.get("discovery_rewards_claimed", {})
        if typeof(discovery_rewards_claimed) != TYPE_DICTIONARY:
            discovery_rewards_claimed = {}
        for played_id in game_play_counts.keys():
            if int(game_play_counts[played_id]) > 0:
                discovery_rewards_claimed[str(played_id)] = true
        owned_themes = data.get("owned_themes", {"classic": true})
        owned_themes["classic"] = true
        _grant_milestone_cosmetics()
        owned_avatars = data.get("owned_avatars", {"star": true})
        owned_avatars["star"] = true
        owned_effects = data.get("owned_effects", {"classic": true})
        owned_effects["classic"] = true
        equipped_effect = str(data.get("equipped_effect", "classic"))
        if not owned_effects.has(equipped_effect):
            equipped_effect = "classic"
        equipped_avatar = str(data.get("equipped_avatar", "star"))
        owned_avatar_frames = data.get("owned_avatar_frames", {"classic": true})
        if typeof(owned_avatar_frames) != TYPE_DICTIONARY:
            owned_avatar_frames = {"classic": true}
        owned_avatar_frames["classic"] = true
        cosmetic_rewards_claimed = data.get("cosmetic_rewards_claimed", {})
        if typeof(cosmetic_rewards_claimed) != TYPE_DICTIONARY:
            cosmetic_rewards_claimed = {}
        equipped_profile_badge = str(data.get("equipped_profile_badge", "rookie"))
        if not _badge_unlocked(equipped_profile_badge):
            equipped_profile_badge = "rookie"
        equipped_avatar_frame = str(data.get("equipped_avatar_frame", "classic"))
        if not owned_avatar_frames.has(equipped_avatar_frame):
            equipped_avatar_frame = "classic"
        if not owned_avatars.has(equipped_avatar):
            equipped_avatar = "star"
        equipped_theme = str(data.get("equipped_theme", "classic"))
        if not owned_themes.has(equipped_theme):
            equipped_theme = "classic"
        recent_games.clear()
        for saved_id in data.get("recent_games", []):
            if _game_data(str(saved_id)).size() > 0 and recent_games.size() < 3:
                recent_games.append(str(saved_id))
