extends Control

signal finished(game_id: String, score: int, extra: Dictionary)

const ARENA := Color("#26134f")
const CYAN := Color("#55f0ed")
const PINK := Color("#ff668f")
const GOLD := Color("#ffdf8b")
const ROUND_LENGTH := 35.0

var arena: Control
var hud: Label
var player_x: float = 0.5
var hazards: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var elapsed: float = 0.0
var spawn_clock: float = 0.0
var running: bool = false
var touch_down: bool = false
var score: int = 0
var dodge_glow: float = 0.0

func start_game() -> void:
    rng.randomize()
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 12)
    add_child(root)
    var title := Label.new()
    title.text = "NEON DODGE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 27)
    title.add_theme_color_override("font_color", CYAN)
    root.add_child(title)
    hud = Label.new()
    hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud.add_theme_font_size_override("font_size", 22)
    hud.add_theme_color_override("font_color", GOLD)
    root.add_child(hud)
    arena = Control.new()
    arena.custom_minimum_size = Vector2(0, 460)
    arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
    arena.mouse_filter = Control.MOUSE_FILTER_STOP
    arena.draw.connect(_draw_arena)
    arena.gui_input.connect(_arena_input)
    root.add_child(arena)
    var tip := Label.new()
    tip.text = "DRAG TO MOVE  •  AVOID PINK BLOCKS"
    tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tip.add_theme_font_size_override("font_size", 17)
    tip.add_theme_color_override("font_color", Color("#c9d9ff"))
    root.add_child(tip)
    var restart := Button.new()
    restart.text = "RESTART RUN"
    restart.custom_minimum_size.y = 52
    restart.pressed.connect(_restart)
    root.add_child(restart)
    _restart()

func _restart() -> void:
    player_x = 0.5
    elapsed = 0.0
    spawn_clock = 0.4
    hazards.clear()
    score = 0
    running = true
    touch_down = false
    _update_hud()
    if is_instance_valid(arena):
        arena.queue_redraw()

func _arena_input(event: InputEvent) -> void:
    if not running:
        return
    if event is InputEventScreenTouch:
        touch_down = event.pressed
        if event.pressed:
            _move_to(event.position.x)
            arena.accept_event()
    elif event is InputEventScreenDrag:
        _move_to(event.position.x)
        arena.accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        touch_down = event.pressed
        if event.pressed:
            _move_to(event.position.x)
            arena.accept_event()
    elif event is InputEventMouseMotion and touch_down:
        _move_to(event.position.x)
        arena.accept_event()

func _move_to(x: float) -> void:
    player_x = clampf(x / maxf(arena.size.x, 1.0), 0.06, 0.94)
    arena.queue_redraw()

func _process(delta: float) -> void:
    if not running or not is_instance_valid(arena):
        return
    elapsed += delta
    score = mini(35, int(elapsed))
    spawn_clock -= delta
    if spawn_clock <= 0.0:
        _spawn_hazard()
        spawn_clock = maxf(0.38, 0.91 - elapsed * 0.010)
    var arena_height: float = maxf(arena.size.y, 1.0)
    var speed: float = 175.0 + elapsed * 4.3
    for index in range(hazards.size() - 1, -1, -1):
        var hazard: Dictionary = hazards[index]
        hazard["y"] = float(hazard["y"]) + speed * delta / arena_height
        hazards[index] = hazard
        if float(hazard["y"]) > 1.12:
            hazards.remove_at(index)
        elif absf(float(hazard["y"]) - 0.86) < 0.048 and absf(float(hazard["x"]) - player_x) < 0.072:
            _finish_run()
            return
    _update_hud()
    arena.queue_redraw()
    if elapsed >= ROUND_LENGTH:
        _finish_run()

func _spawn_hazard() -> void:
    var x: float = rng.randf_range(0.09, 0.91)
    # Avoid forcing an immediate unavoidable hit at the player position.
    hazards.append({"x":x,"y":-0.05})

func _update_hud() -> void:
    if is_instance_valid(hud):
        hud.text = "SURVIVED  %02d / 35 SEC" % score

func _finish_run() -> void:
    if not running:
        return
    running = false
    finished.emit("dodge", score, {"survived_seconds":score})

func _draw_arena() -> void:
    var w: float = arena.size.x
    var h: float = arena.size.y
    arena.draw_rect(Rect2(Vector2.ZERO, Vector2(w,h)), ARENA, true)
    arena.draw_rect(Rect2(Vector2(3,3), Vector2(w-6,h-6)), Color("#ffd77e",0.86), false, 3.0)
    for i in range(1, 6):
        var gx: float = w * float(i) / 6.0
        arena.draw_line(Vector2(gx, 0), Vector2(gx,h), Color("#c18cff",0.19), 1.0)
    for i in range(1, 10):
        var gy: float = h * float(i) / 10.0
        arena.draw_line(Vector2(0,gy), Vector2(w,gy), Color("#c18cff",0.14), 1.0)
    for hazard in hazards:
        var center := Vector2(float(hazard["x"]) * w, float(hazard["y"]) * h)
        var radius: float = minf(w * 0.045, 18.0)
        arena.draw_rect(Rect2(center - Vector2(radius-3.0,radius-3.0), Vector2(radius * 2.0-6.0,radius * 2.0-6.0)), PINK, true)
        arena.draw_rect(Rect2(center - Vector2(radius,radius), Vector2(radius * 2.0,radius * 2.0)), Color("#ffe2a0"), false, 3.0)
        arena.draw_rect(Rect2(center - Vector2(radius * 0.58,radius * 0.58), Vector2(radius * 1.16,radius * 1.16)), Color("#ffb1c5"), false, 2.0)
    var player_pos := Vector2(player_x * w, h * 0.86)
    var pulse: float = 0.5 + 0.5 * sin(elapsed * 8.0)
    arena.draw_circle(player_pos, 27.0 + pulse * 5.0, Color("#6bf6ff", 0.10 + 0.12 * pulse))
    arena.draw_arc(player_pos, 24.0 + pulse * 3.0, 0.0, TAU, 36, Color("#ffde86", 0.40 + 0.32 * pulse), 2.0)
    arena.draw_circle(player_pos, 21.0, Color(0.25,0.95,0.9,0.17))
    arena.draw_circle(player_pos, 16.0, Color("#ffe49b"))
    arena.draw_circle(player_pos, 12.0, CYAN)
    arena.draw_circle(player_pos + Vector2(-3.0,-3.0), 5.0, Color.WHITE)
    arena.draw_arc(player_pos, 19.0, 0.0, TAU, 28, CYAN, 2.0)
