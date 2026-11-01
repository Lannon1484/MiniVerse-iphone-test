extends Control

signal finished(game_id: String, score: int, extra: Dictionary)

const ROUND_SECONDS := 40.0
const BG := Color("#27164f")
const FRUIT_COLORS := [Color("#ff638e"), Color("#ffd45f"), Color("#76e6aa"), Color("#ffac68")]
const BOMB_COLOR := Color("#35324c")

var arena: Control
var hud: Label
var rng := RandomNumberGenerator.new()
var objects: Array[Dictionary] = []
var player_x: float = 0.5
var elapsed: float = 0.0
var spawn_timer: float = 0.0
var score: int = 0
var fruit_caught: int = 0
var bombs_hit: int = 0
var running: bool = false
var pointer_down: bool = false
var catch_flash: float = 0.0
var catch_x: float = 0.5

func start_game() -> void:
    rng.randomize()
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 10)
    add_child(root)
    var title := Label.new()
    title.text = "FRUIT CATCH"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 29)
    title.add_theme_color_override("font_color", Color("#ffcd79"))
    root.add_child(title)
    hud = Label.new()
    hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud.add_theme_font_size_override("font_size", 20)
    hud.add_theme_color_override("font_color", Color("#f6f1e8"))
    root.add_child(hud)
    arena = Control.new()
    arena.custom_minimum_size = Vector2(0, 440)
    arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
    arena.mouse_filter = Control.MOUSE_FILTER_STOP
    arena.draw.connect(_draw_arena)
    arena.gui_input.connect(_arena_input)
    root.add_child(arena)
    var tip := Label.new()
    tip.text = "DRAG THE BASKET  •  CATCH FRUIT  •  AVOID BOMBS"
    tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tip.add_theme_font_size_override("font_size", 17)
    root.add_child(tip)
    var restart := Button.new()
    restart.text = "RESTART ROUND"
    restart.custom_minimum_size.y = 52
    restart.pressed.connect(_restart)
    root.add_child(restart)
    _restart()

func _restart() -> void:
    objects.clear()
    player_x = 0.5
    elapsed = 0.0
    spawn_timer = 0.5
    score = 0
    fruit_caught = 0
    bombs_hit = 0
    running = true
    pointer_down = false
    catch_flash = 0.0
    _update_hud()
    if is_instance_valid(arena):
        arena.queue_redraw()

func _arena_input(event: InputEvent) -> void:
    if not running:
        return
    if event is InputEventScreenTouch:
        pointer_down = event.pressed
        if event.pressed:
            _move_basket(event.position.x)
            arena.accept_event()
    elif event is InputEventScreenDrag:
        _move_basket(event.position.x)
        arena.accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        pointer_down = event.pressed
        if event.pressed:
            _move_basket(event.position.x)
            arena.accept_event()
    elif event is InputEventMouseMotion and pointer_down:
        _move_basket(event.position.x)
        arena.accept_event()

func _move_basket(x: float) -> void:
    player_x = clampf(x / maxf(arena.size.x, 1.0), 0.09, 0.91)
    arena.queue_redraw()

func _process(delta: float) -> void:
    if not running or not is_instance_valid(arena):
        return
    elapsed += delta
    catch_flash = maxf(0.0, catch_flash - delta)
    spawn_timer -= delta
    if spawn_timer <= 0.0:
        _spawn_object()
        spawn_timer = maxf(0.32, 0.82 - elapsed * 0.008)
    var speed: float = 160.0 + elapsed * 4.0
    var arena_height: float = maxf(arena.size.y, 1.0)
    for i in range(objects.size() - 1, -1, -1):
        var item: Dictionary = objects[i]
        item["y"] = float(item["y"]) + speed * delta / arena_height
        objects[i] = item
        if float(item["y"]) >= 0.86 and float(item["y"]) <= 0.97 and absf(float(item["x"]) - player_x) < 0.115:
            if bool(item["bomb"]):
                bombs_hit += 1
                objects.remove_at(i)
                _finish()
                return
            score += 10
            fruit_caught += 1
            catch_flash = 0.36
            catch_x = float(item["x"])
            objects.remove_at(i)
        elif float(item["y"]) > 1.08:
            objects.remove_at(i)
    _update_hud()
    arena.queue_redraw()
    if elapsed >= ROUND_SECONDS:
        _finish()

func _spawn_object() -> void:
    var bomb_chance: float = minf(0.24, 0.10 + elapsed * 0.003)
    objects.append({
        "x": rng.randf_range(0.10, 0.90),
        "y": -0.05,
        "bomb": rng.randf() < bomb_chance,
        "color": rng.randi_range(0, FRUIT_COLORS.size() - 1)
    })

func _update_hud() -> void:
    if is_instance_valid(hud):
        hud.text = "SCORE %d    FRUIT %d    TIME %ds" % [score, fruit_caught, maxi(0, int(ceil(ROUND_SECONDS - elapsed)))]

func _draw_arena() -> void:
    var w: float = arena.size.x
    var h: float = arena.size.y
    arena.draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), BG)
    arena.draw_rect(Rect2(Vector2(3,3), Vector2(w-6,h-6)), Color("#ffdc87",0.84), false, 3.0)
    for i in range(1, 6):
        var gx: float = w * float(i) / 6.0
        arena.draw_line(Vector2(gx, 0), Vector2(gx, h), Color("#ab7fd2",0.20), 1.0)
    for item in objects:
        var pos := Vector2(float(item["x"]) * w, float(item["y"]) * h)
        if bool(item["bomb"]):
            arena.draw_circle(pos, 22.0, Color("#ffb3d7",0.30))
            arena.draw_circle(pos, 19.0, BOMB_COLOR)
            arena.draw_arc(pos, 19.0, 0.0, TAU, 28, Color("#ffdc87"), 2.5)
            arena.draw_circle(pos + Vector2(-6, -5), 4.0, Color("#aaa8c4"))
            arena.draw_line(pos + Vector2(4, -16), pos + Vector2(11, -27), Color("#ffcd79"), 3.0)
        else:
            arena.draw_circle(pos, 21.0, Color("#ffe6a8"))
            arena.draw_circle(pos, 18.0, FRUIT_COLORS[int(item["color"])])
            arena.draw_circle(pos + Vector2(-5, -6), 5.0, Color(1, 1, 1, 0.28))
            arena.draw_line(pos + Vector2(1, -18), pos + Vector2(5, -26), Color("#8ce9a0"), 4.0)
    if catch_flash > 0.0:
        var flash: float = catch_flash / 0.36
        var sparkle_center := Vector2(catch_x * w, h * 0.88)
        arena.draw_circle(sparkle_center, 32.0 * (1.0 - flash) + 9.0, Color("#ffe28c", 0.32 * flash))
        arena.draw_arc(sparkle_center, 30.0 * (1.0 - flash) + 12.0, 0.0, TAU, 32, Color("#fff4b9", flash), 3.0)
    var center := Vector2(player_x * w, h * 0.9)
    arena.draw_rect(Rect2(center + Vector2(-39, -7), Vector2(78, 28)), Color("#9651ae"))
    arena.draw_line(center + Vector2(-36, 14), center + Vector2(36, 14), Color("#ffe6aa"), 3.0)
    arena.draw_rect(Rect2(center + Vector2(-43, -11), Vector2(86, 10)), Color("#ffcd79"))
    arena.draw_arc(center + Vector2(0, -9), 38.0, PI, TAU, 24, Color("#ffe1a0"), 3.0)

func _finish() -> void:
    if not running:
        return
    running = false
    finished.emit("fruit", score, {"fruit_caught": fruit_caught, "bombs_hit": bombs_hit, "completed": bombs_hit == 0})
