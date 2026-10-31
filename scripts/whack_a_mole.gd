extends Control
class_name WhackAMole

signal finished(game_id: String, score: int, extra: Dictionary)

const ROUND_SECONDS := 45.0
const MOLE_IMAGE := preload("res://assets/whack/mole.png")
const SNAKE_IMAGE := preload("res://assets/whack/snake.png")
const HOLE_IMAGE := preload("res://assets/whack/hole.png")
const GOOD := Color("#38d9b4")
const BAD := Color("#fb7185")
const BASE := Color("#27345e")

var rng := RandomNumberGenerator.new()
var slots: Array[Button] = []
var active_slot := -1
var active_decoy := false
var seconds_left := ROUND_SECONDS
var next_spawn := 0.4
var visible_for := 0.0
var score := 0
var combo := 0
var hits := 0
var misses := 0
var playing := false
var time_label: Label
var score_label: Label
var message_label: Label

func start_game() -> void:
    rng.randomize()
    _build()
    _restart()

func _build() -> void:
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 15)
    add_child(root)
    var heading := Label.new()
    heading.text = "WHACK-A-MOLE"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 29)
    heading.add_theme_color_override("font_color", Color("#fff2b0"))
    root.add_child(heading)
    var instruction := Label.new()
    instruction.text = "Whack the moles! Do NOT tap the snakes."
    instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    instruction.add_theme_font_size_override("font_size", 17)
    root.add_child(instruction)
    var stats := HBoxContainer.new()
    root.add_child(stats)
    time_label = _label("TIME 45", 19)
    score_label = _label("SCORE 0", 19)
    stats.add_child(time_label)
    stats.add_child(score_label)
    var grid := GridContainer.new()
    grid.columns = 3
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 9)
    grid.add_theme_constant_override("v_separation", 9)
    root.add_child(grid)
    for i in range(9):
        var b := Button.new()
        b.custom_minimum_size = Vector2(0, 102)
        b.icon = HOLE_IMAGE
        b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
        b.expand_icon = true
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.add_theme_font_size_override("font_size", 36)
        b.add_theme_stylebox_override("normal", _style(BASE))
        b.add_theme_stylebox_override("hover", _style(BASE.lightened(0.1)))
        b.add_theme_stylebox_override("pressed", _style(Color("#4f5c96")))
        b.pressed.connect(_tap.bind(i))
        grid.add_child(b)
        slots.append(b)
    message_label = _label("Ready? Go!", 19)
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(message_label)
    var restart := Button.new()
    restart.text = "RESTART ROUND"
    restart.custom_minimum_size.y = 56
    restart.add_theme_font_size_override("font_size", 18)
    restart.pressed.connect(_restart)
    root.add_child(restart)

func _label(value: String, font_size: int) -> Label:
    var l := Label.new()
    l.text = value
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", Color("#f8fafc"))
    return l

func _style(color: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.set_corner_radius_all(19)
    s.set_border_width_all(3)
    s.border_color = Color("#7684c4")
    return s

func _restart() -> void:
    playing = true
    seconds_left = ROUND_SECONDS
    next_spawn = 0.4
    visible_for = 0.0
    active_slot = -1
    score = 0
    combo = 0
    hits = 0
    misses = 0
    _clear_target()
    message_label.text = "Whack moles, avoid snakes!"
    _update_labels()
    set_process(true)

func _process(delta: float) -> void:
    if not playing:
        return
    seconds_left -= delta
    if seconds_left <= 0.0:
        seconds_left = 0.0
        playing = false
        _clear_target()
        _update_labels()
        message_label.text = "Round complete!"
        set_process(false)
        finished.emit("whack", score, {"hits": hits, "misses": misses})
        return
    if active_slot >= 0:
        visible_for -= delta
        if visible_for <= 0.0:
            if not active_decoy:
                combo = 0
                misses += 1
            _clear_target()
            next_spawn = 0.15
    else:
        next_spawn -= delta
        if next_spawn <= 0.0:
            _spawn()
    _update_labels()

func _spawn() -> void:
    active_slot = rng.randi_range(0, 8)
    active_decoy = rng.randf() < 0.18
    visible_for = maxf(0.65, 1.35 - float(hits) * 0.018)
    var b := slots[active_slot]
    b.text = ""
    b.icon = SNAKE_IMAGE if active_decoy else MOLE_IMAGE
    b.add_theme_color_override("font_color", Color("#ffffff"))
    b.add_theme_stylebox_override("normal", _style(BAD if active_decoy else GOOD))
    b.add_theme_stylebox_override("hover", _style((BAD if active_decoy else GOOD).lightened(0.1)))

func _tap(index: int) -> void:
    if not playing:
        return
    if index == active_slot:
        if active_decoy:
            combo = 0
            score = maxi(0, score - 25)
            message_label.text = "Oops! You hit a snake: -25"
        else:
            hits += 1
            combo += 1
            var points := 10 + mini(combo, 10) * 2
            score += points
            message_label.text = "+%d points! Combo x%d" % [points, combo]
        _clear_target()
        next_spawn = 0.15
    else:
        combo = 0
        misses += 1
        message_label.text = "Empty hole! Keep looking."
    _update_labels()

func _clear_target() -> void:
    active_slot = -1
    for b in slots:
        b.text = ""
        b.icon = HOLE_IMAGE
        b.add_theme_stylebox_override("normal", _style(BASE))
        b.add_theme_stylebox_override("hover", _style(BASE.lightened(0.1)))

func _update_labels() -> void:
    time_label.text = "TIME %d" % ceili(seconds_left)
    score_label.text = "SCORE %d" % score
