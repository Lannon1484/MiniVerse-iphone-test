extends Control
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
const NOTE_SOUNDS := [preload("res://assets/sfx/note_pink.wav"), preload("res://assets/sfx/note_blue.wav"), preload("res://assets/sfx/note_gold.wav"), preload("res://assets/sfx/note_purple.wav")]
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
    for i in range(4):
        var player := AudioStreamPlayer.new()
        player.stream = NOTE_SOUNDS[i]
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
    var next := Button.new()
    next.text = "NEXT LEVEL"
    next.custom_minimum_size.y = 50
    next.pressed.connect(_next_level)
    layout.add_child(next)
    layout.add_child(restart)
    _restart()

func _restart() -> void:
    beat_interval = maxf(0.49, 0.90 - (level - 1) * 0.07)
    note_total = mini(48, 18 + (level - 1) * 6)
    hit_window = maxf(0.19, 0.30 - (level - 1) * 0.018)
    perfect_window = maxf(0.075, 0.13 - (level - 1) * 0.009)
    active_lanes = mini(4, 2 + int((level - 1) / 2.0))
    travel_time = maxf(1.65, 2.2 - (level - 1) * 0.09)
    elapsed = 0.0
    score = 0
    combo = 0
    hits = 0
    misses = 0
    running = true
    notes.clear()
    var lane := rng.randi_range(0, active_lanes - 1)
    for i in range(note_total):
        if active_lanes > 1:
            lane = (lane + rng.randi_range(1, active_lanes - 1)) % active_lanes
        notes.append({"lane": lane, "time": 2.6 + i * beat_interval, "state": 0})
    feedback.text = "LEVEL %d — Tap notes on the glowing line!" % level
    _refresh()

func _next_level() -> void:
    if running:
        feedback.text = "Finish this round to unlock the next level."
        return
    level += 1
    _restart()

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
        feedback.text = "LEVEL %d COMPLETE! %d HIT / %d MISSED — NEXT LEVEL!" % [level, hits, misses]
        finished.emit("rhythm", score, {"coins": maxi(5, int(score / 100.0)), "xp": 40})
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
    if sound_enabled and lane < note_players.size():
        note_players[lane].play()
    hits += 1
    combo += 1
    var perfect: bool = distance < perfect_window
    score += (100 if perfect else 60) + mini(combo, 25) * 3
    feedback.text = "PERFECT!" if perfect else "GREAT!"
    _refresh()

func _refresh() -> void:
    if is_instance_valid(stats):
        stats.text = "LV %d  SCORE %d  COMBO %d  %d/%d" % [level, score, combo, hits + misses, note_total]
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
        draw_rect(Rect2(0, hit_y - 5, w, 10), Color("#b8f9ff", 0.18))
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
