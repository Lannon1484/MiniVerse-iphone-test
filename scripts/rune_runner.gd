extends Control
# Rune Runner: three-lane, mobile-friendly fantasy runner.
signal finished(game_id: String, score: int)
signal gameplay_sound(kind: String)
const Difficulty = preload("res://scripts/difficulty.gd")
const ROUND_TIME := 40.0
const GOLD := Color("#ffe39a")
const AQUA := Color("#76edee")
const PINK := Color("#ff77ae")
var rng := RandomNumberGenerator.new()
var arena: Control
var hud: Label
var left_button: Button
var right_button: Button
var player_lane: int = 1
var objects: Array[Dictionary] = []
var elapsed: float = 0.0
var spawn_timer: float = 0.0
var score: int = 0
var goal: int = 60
var level: int = 1
var running: bool = false
var swipe_origin: Vector2 = Vector2.ZERO
var touch_active: bool = false
var pulse: float = 0.0

func start_game() -> void:
    rng.randomize()
    level = Difficulty.level("runner")
    goal = 60 + mini(level - 1, 4) * 15 if level <= 5 else int(round(120.0 * (1.0 + 0.10 * float(level - 5))))
    # Keep HUD and lane graphics below the top frame, even on short phones.
    var inset := MarginContainer.new()
    inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    # Keep HUD text safely inside the decorative game frame.
    inset.add_theme_constant_override("margin_top", 28)
    inset.add_theme_constant_override("margin_left", 12)
    inset.add_theme_constant_override("margin_right", 12)
    inset.add_theme_constant_override("margin_bottom", 12)
    add_child(inset)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 8)
    inset.add_child(root)
    hud = Label.new()
    hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud.add_theme_font_size_override("font_size", 18)
    hud.add_theme_color_override("font_color", GOLD)
    root.add_child(hud)
    var hint := Label.new()
    hint.text = "SWIPE OR TAP ARROWS  •  DODGE CRYSTALS  •  COLLECT RUNES"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.add_theme_font_size_override("font_size", 12)
    hint.add_theme_color_override("font_color", Color("#e5d7ff"))
    root.add_child(hint)
    arena = Control.new()
    arena.custom_minimum_size = Vector2(0, 290)
    arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
    arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    arena.mouse_filter = Control.MOUSE_FILTER_STOP
    arena.draw.connect(_draw_arena)
    arena.gui_input.connect(_arena_input)
    root.add_child(arena)
    var controls := HBoxContainer.new()
    controls.add_theme_constant_override("separation", 12)
    root.add_child(controls)
    left_button = _arrow_button("◀  LEFT", controls)
    right_button = _arrow_button("RIGHT  ▶", controls)
    left_button.pressed.connect(_change_lane.bind(-1))
    right_button.pressed.connect(_change_lane.bind(1))
    _reset_run()

func _arrow_button(caption: String, parent: HBoxContainer) -> Button:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size.y = 58
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", 20)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#6840a9")
    style.border_color = GOLD
    style.set_border_width_all(3)
    style.set_corner_radius_all(12)
    button.add_theme_stylebox_override("normal", style)
    var pressed_style := style.duplicate()
    pressed_style.bg_color = Color("#a167d2")
    button.add_theme_stylebox_override("pressed", pressed_style)
    parent.add_child(button)
    return button

func _reset_run() -> void:
    player_lane = 1
    objects.clear()
    elapsed = 0.0
    spawn_timer = 1.0
    score = 0
    pulse = 0.0
    running = true
    _update_hud()
    arena.queue_redraw()

func _change_lane(direction: int) -> void:
    if not running:
        return
    player_lane = clampi(player_lane + direction, 0, 2)
    arena.queue_redraw()

func _arena_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            swipe_origin = event.position
            touch_active = true
        elif touch_active:
            _handle_swipe(event.position)
            touch_active = false
        arena.accept_event()
    elif event is InputEventScreenDrag and touch_active:
        if absf(event.position.x - swipe_origin.x) > 48.0:
            _handle_swipe(event.position)
            swipe_origin = event.position
        arena.accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            swipe_origin = event.position
            touch_active = true
        elif touch_active:
            _handle_swipe(event.position)
            touch_active = false
        arena.accept_event()
    elif event is InputEventMouseMotion and touch_active and absf(event.position.x - swipe_origin.x) > 48.0:
        _handle_swipe(event.position)
        swipe_origin = event.position
        arena.accept_event()

func _handle_swipe(end_position: Vector2) -> void:
    var dx: float = end_position.x - swipe_origin.x
    if absf(dx) > 32.0:
        _change_lane(1 if dx > 0.0 else -1)

func _process(delta: float) -> void:
    if not running or not is_instance_valid(arena):
        return
    elapsed = minf(ROUND_TIME, elapsed + delta)
    pulse += delta
    spawn_timer -= delta
    if spawn_timer <= 0.0:
        _spawn_object()
        spawn_timer = maxf(0.49, 1.05 - float(level - 1) * 0.035 - elapsed * 0.004)
    var speed: float = 0.31 + float(level - 1) * 0.012 + elapsed * 0.003
    for i in range(objects.size() - 1, -1, -1):
        var item: Dictionary = objects[i]
        item["y"] = float(item["y"]) + speed * delta
        if float(item["y"]) >= 0.84 and not bool(item["hit"]):
            item["hit"] = true
            if int(item["lane"]) == player_lane:
                if str(item["type"]) == "hazard":
                    _end_run()
                    return
                score += 12
                gameplay_sound.emit("collect")
                objects.remove_at(i)
                continue
        if float(item["y"]) > 1.12:
            objects.remove_at(i)
        else:
            objects[i] = item
    # Time contributes a modest survival score without overwhelming
    # rune-collection skill.
    score = maxi(score, int(elapsed))
    _update_hud()
    arena.queue_redraw()
    if elapsed >= ROUND_TIME:
        _end_run()

func _spawn_object() -> void:
    # Never block all lanes. A single obstacle always leaves two escape lanes.
    var lane: int = rng.randi_range(0, 2)
    # Guarantee the first two spawns are collectibles so players can
    # learn lane changes before hazards appear.
    var kind: String = "rune" if elapsed < 3.0 or rng.randf() < 0.62 else "hazard"
    objects.append({"lane":lane,"y":-0.07,"type":kind,"hit":false})

func _update_hud() -> void:
    if is_instance_valid(hud):
        hud.text = "SCORE %d / %d   •   TIME %02d / 40" % [score, goal, int(elapsed)]

func _end_run() -> void:
    if not running:
        return
    running = false
    finished.emit("runner", score)

func _draw_arena() -> void:
    var w: float = arena.size.x
    var h: float = arena.size.y
    var left: float = w * 0.08
    var span: float = w * 0.84
    arena.draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color("#291650"), true)
    arena.draw_rect(Rect2(Vector2(3, 3), Vector2(w - 6, h - 6)), GOLD, false, 3.0)
    for lane in range(3):
        var lane_x: float = left + span * (float(lane) + 0.5) / 3.0
        var half_width: float = span / 6.0
        arena.draw_rect(Rect2(Vector2(lane_x - half_width + 4.0, 10), Vector2(half_width * 2.0 - 8.0, h - 20.0)), Color("#6b3bb0", 0.26), true)
        arena.draw_line(Vector2(lane_x, 0), Vector2(lane_x, h), Color("#bd83ff", 0.20), 2.0)
        for step in range(9):
            var yy: float = fposmod(float(step) * 75.0 + elapsed * 110.0, h)
            arena.draw_line(Vector2(lane_x - half_width + 9.0, yy), Vector2(lane_x + half_width - 9.0, yy), Color("#ffd988", 0.28), 2.0)
    for item in objects:
        var x: float = left + span * (float(int(item["lane"])) + 0.5) / 3.0
        var y: float = float(item["y"]) * h
        var r: float = minf(span / 11.0, 23.0)
        if str(item["type"]) == "rune":
            arena.draw_circle(Vector2(x, y), r + 5.0, Color("#ff77ae", 0.20))
            arena.draw_colored_polygon(PackedVector2Array([Vector2(x,y-r),Vector2(x+r*0.70,y),Vector2(x,y+r),Vector2(x-r*0.70,y)]), PINK)
            arena.draw_circle(Vector2(x, y), 5.0, GOLD)
        else:
            arena.draw_colored_polygon(PackedVector2Array([Vector2(x,y-r),Vector2(x+r,y+r),Vector2(x-r,y+r)]), AQUA)
            arena.draw_line(Vector2(x, y-r), Vector2(x+r,y+r), GOLD, 3.0)
            arena.draw_line(Vector2(x+r,y+r), Vector2(x-r,y+r), GOLD, 3.0)
    var hero_x: float = left + span * (float(player_lane) + 0.5) / 3.0
    var hero_y: float = h * 0.84
    var glow: float = 3.0 + 2.0 * sin(pulse * 6.0)
    arena.draw_circle(Vector2(hero_x, hero_y), 22.0 + glow, Color("#65efff", 0.18))
    arena.draw_circle(Vector2(hero_x, hero_y), 19.0, GOLD)
    arena.draw_circle(Vector2(hero_x, hero_y), 15.0, Color("#aa68f1"))
    arena.draw_colored_polygon(PackedVector2Array([Vector2(hero_x,hero_y-13),Vector2(hero_x+10,hero_y+8),Vector2(hero_x-10,hero_y+8)]), Color("#f4e5ff"))
