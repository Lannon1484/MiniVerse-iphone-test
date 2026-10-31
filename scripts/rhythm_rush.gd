extends Control
const Difficulty = preload("res://scripts/difficulty.gd")
signal finished(game_id: String, score: int, extra: Dictionary)
const COLORS := [Color("#ff82bd"), Color("#76d9ff"), Color("#ffe18b"), Color("#a58bff")]
# Early levels are slower and more forgiving; later rounds ramp up gently.
var level := 1
var beat_interval := 0.9
var note_total := 18
var hit_window := 0.30
var perfect_window := 0.13
var active_lanes := 2
var travel_time := 2.2
# Original eight-note melody, played one note at a time by the player.
const MELODY_SOUNDS := [
    preload("res://assets/sfx/melody_0.wav"),
    preload("res://assets/sfx/melody_1.wav"),
    preload("res://assets/sfx/melody_2.wav"),
    preload("res://assets/sfx/melody_3.wav"),
    preload("res://assets/sfx/melody_4.wav"),
    preload("res://assets/sfx/melody_5.wav"),
    preload("res://assets/sfx/melody_6.wav"),
    preload("res://assets/sfx/melody_7.wav")
]
# Five original pentatonic phrases. Later levels use longer, more varied tunes.
# Each entry indexes the eight generated bell sounds above.
const SONG_NAMES := ["First Steps", "Little Lanterns", "Cloud Parade", "Starlight Dance", "Sky Festival"]
const SONGS := [
    [0, 2, 3, 2, 0, 2, 3, 0],
    [0, 1, 2, 3, 2, 1, 0, 3, 2, 3, 4, 3, 2, 1, 0, 0],
    [0, 2, 4, 3, 2, 1, 3, 2, 1, 3, 5, 4, 3, 2, 1, 0],
    [2, 3, 5, 3, 4, 3, 2, 1, 0, 2, 3, 4, 5, 4, 3, 2],
    [0, 2, 3, 5, 4, 3, 2, 0, 1, 3, 4, 5, 6, 5, 4, 3]
]
var song_name := "First Steps"
var sound_enabled := true
var note_players: Array[AudioStreamPlayer] = []
var notes: Array[Dictionary] = []
var elapsed := 0.0
var score := 0
var combo := 0
var hits := 0
var misses := 0
var running := false
var arena: BeatBoard
var stats: Label
var feedback: Label
var rng := RandomNumberGenerator.new()

func start_game() -> void:
    rng.randomize()
    for i in range(MELODY_SOUNDS.size()):
        var player := AudioStreamPlayer.new()
        player.stream = MELODY_SOUNDS[i]
        player.volume_db = -8.0
        add_child(player)
        note_players.append(player)
    var layout := VBoxContainer.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout.add_theme_constant_override("separation", 8)
    add_child(layout)
    var title := Label.new()
    title.text = "RHYTHM RUSH"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 27)
    title.add_theme_color_override("font_color", Color("#ffe29e"))
    layout.add_child(title)
    stats = Label.new()
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(stats)
    arena = BeatBoard.new()
    arena.game = self
    arena.custom_minimum_size = Vector2(0, 495)
    arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
    arena.gui_input.connect(_arena_input)
    layout.add_child(arena)
    feedback = Label.new()
    feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(feedback)
    var controls := HBoxContainer.new()
    controls.add_theme_constant_override("separation", 5)
    layout.add_child(controls)
    for i in range(4):
        var b := Button.new()
        b.text = ["PINK", "BLUE", "GOLD", "PURPLE"][i]
        b.custom_minimum_size.y = 82
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.add_theme_font_size_override("font_size", 12)
        b.add_theme_color_override("font_color", COLORS[i])
        b.pressed.connect(_hit.bind(i))
        controls.add_child(b)
    var restart := Button.new()
    restart.text = "RETRY LEVEL"
    restart.custom_minimum_size.y = 54
    restart.pressed.connect(_restart)
    layout.add_child(restart)
    level = Difficulty.level("rhythm")
    _restart()

func _restart() -> void:
    beat_interval = maxf(0.52, 1.10 - (level - 1) * 0.09)
    note_total = mini(48, 10 + (level - 1) * 4)
    # Larger timing window for beginner levels; gently narrows as skill grows.
    hit_window = maxf(0.18, 0.52 - (level - 1) * 0.065)
    perfect_window = maxf(0.075, 0.22 - (level - 1) * 0.025)
    active_lanes = mini(4, 2 + int((level - 1) / 2.0))
    travel_time = maxf(1.65, 2.4 - (level - 1) * 0.09)
    elapsed = 0.0
    score = 0
    combo = 0
    hits = 0
    misses = 0
    running = true
    notes.clear()
    var song_index: int = mini(level - 1, SONGS.size() - 1)
    song_name = SONG_NAMES[song_index]
    var song: Array = SONGS[song_index]
    var lane := rng.randi_range(0, active_lanes - 1)
    for i in range(note_total):
        # Level 1 teaches a predictable left/right rhythm.
        # Later levels introduce changing lanes and repeated-note patterns.
        if level == 1:
            lane = i % 2
        elif level == 2:
            lane = int(i / 2) % 2
        elif active_lanes > 1:
            lane = rng.randi_range(0, active_lanes - 1)
        notes.append({"lane": lane, "time": 2.6 + i * beat_interval, "state": 0, "pitch": int(song[i % song.size()])})
    feedback.text = "LEVEL %d - %s: Catch notes to play the tune!" % [level, song_name]
    _refresh()

func _process(delta: float) -> void:
    if not running:
        return
    elapsed += delta
    for i in range(notes.size()):
        if int(notes[i]["state"]) == 0 and elapsed > float(notes[i]["time"]) + hit_window:
            notes[i]["state"] = 2
            misses += 1
            combo = 0
            feedback.text = "MISS"
    if elapsed > float(notes.back()["time"]) + hit_window + 0.2:
        running = false
        feedback.text = "ROUND FINISHED! %d HIT / %d MISSED" % [hits, misses]
        finished.emit("rhythm", score, {"hits": hits, "misses": misses, "notes": note_total})
    _refresh()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        var lane := -1
        match event.keycode:
            KEY_A, KEY_1: lane = 0
            KEY_S, KEY_2: lane = 1
            KEY_D, KEY_3: lane = 2
            KEY_F, KEY_4: lane = 3
        if lane >= 0:
            _hit(lane)
            get_viewport().set_input_as_handled()

func _arena_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        _hit(clampi(int(event.position.x / maxf(arena.size.x, 1.0) * 4.0), 0, 3))
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _hit(clampi(int(event.position.x / maxf(arena.size.x, 1.0) * 4.0), 0, 3))

func _hit(lane: int) -> void:
    if not running:
        return
    var candidate := -1
    var distance := 999.0
    for i in range(notes.size()):
        if int(notes[i]["state"]) != 0 or int(notes[i]["lane"]) != lane:
            continue
        var d: float = absf(elapsed - float(notes[i]["time"]))
        if d < distance:
            distance = d
            candidate = i
    if candidate < 0 or distance > hit_window:
        feedback.text = "WAIT FOR THE LINE"
        return
    notes[candidate]["state"] = 1
    # Each successful note plays its assigned musical pitch, forming a tune.
    var pitch: int = int(notes[candidate]["pitch"])
    if sound_enabled and pitch >= 0 and pitch < note_players.size():
        note_players[pitch].play()
    hits += 1
    combo += 1
    var perfect: bool = distance < perfect_window
    score += (100 if perfect else 60) + mini(combo, 25) * 3
    feedback.text = "PERFECT!" if perfect else "GREAT!"
    _refresh()

func _refresh() -> void:
    if is_instance_valid(stats):
        stats.text = "LV %d  %s  |  SCORE %d  COMBO %d  %d/%d" % [level, song_name, score, combo, hits + misses, note_total]
    if is_instance_valid(arena):
        arena.queue_redraw()

class BeatBoard extends Control:
    var game: Control
    func _draw() -> void:
        if game == null:
            return
        var w: float = size.x
        var h: float = size.y
        draw_rect(Rect2(Vector2.ZERO, size), Color("#111936"))
        var lane_w: float = w / 4.0
        for i in range(4):
            var left: float = i * lane_w
            var color: Color = COLORS[i]
            draw_rect(Rect2(left + 2, 0, lane_w - 4, h), Color(color.r, color.g, color.b, 0.09))
            draw_line(Vector2(left, 0), Vector2(left, h), Color("#65749e", 0.5), 2)
        var hit_y: float = h * 0.81
        # Draw the *actual* hittable area, derived from the same timing window
        # used by _hit() and _process(). Early levels have a larger zone.
        var zone_half_height: float = hit_y * game.hit_window / game.travel_time
        var zone_top: float = maxf(0.0, hit_y - zone_half_height)
        var zone_bottom: float = minf(h, hit_y + zone_half_height)
        draw_rect(Rect2(0, zone_top, w, zone_bottom - zone_top), Color("#b8f9ff", 0.16))
        draw_line(Vector2(0, zone_top), Vector2(w, zone_top), Color("#b8f9ff", 0.55), 2)
        draw_line(Vector2(0, zone_bottom), Vector2(w, zone_bottom), Color("#b8f9ff", 0.55), 2)
        draw_line(Vector2(0, hit_y), Vector2(w, hit_y), Color("#b8f9ff"), 4)
        for note in game.notes:
            if int(note["state"]) != 0:
                continue
            var dt: float = float(note["time"]) - game.elapsed
            if dt > game.travel_time or dt < -game.hit_window:
                continue
            var x: float = (float(note["lane"]) + 0.5) * lane_w
            var y: float = hit_y * (1.0 - dt / game.travel_time)
            var color: Color = COLORS[int(note["lane"])]
            draw_circle(Vector2(x, y), minf(lane_w * 0.33, 25.0), Color(color.r, color.g, color.b, 0.25))
            draw_circle(Vector2(x, y), minf(lane_w * 0.25, 18.0), color)
            draw_circle(Vector2(x - 5, y - 5), 5, Color("#ffffff", 0.85))
        draw_rect(Rect2(Vector2.ZERO, size), Color("#7ca7ed", 0.6), false, 2)
