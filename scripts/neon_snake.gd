extends Control

signal finished(game_id: String, score: int, extra: Dictionary)

const GRID_SIZE := 15
const SKY := Color("#10183c")
const AQUA := Color("#58edc4")
const GOLD := Color("#ffcc67")
const PINK := Color("#ff8ccf")

var snake: Array[Vector2i] = []
var direction: Vector2i = Vector2i.RIGHT
var next_direction: Vector2i = Vector2i.RIGHT
var food: Vector2i = Vector2i(9, 7)
var score: int = 0
var eaten: int = 0
var playing: bool = false
var accumulator: float = 0.0
var touch_start: Vector2 = Vector2.ZERO
var swipe_anchor: Vector2 = Vector2.ZERO
var touch_active: bool = false
var queued_turns: Array[Vector2i] = []
var rng := RandomNumberGenerator.new()
var score_label: Label
var hint_label: Label
var board: SnakeBoard

func start_game() -> void:
    rng.randomize()
    _build_ui()
    _restart()

func _build_ui() -> void:
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 5)
    add_child(root)
    var title := Label.new()
    title.text = "NEON SNAKE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 23)
    title.add_theme_color_override("font_color", AQUA)
    root.add_child(title)
    score_label = Label.new()
    score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    score_label.add_theme_font_size_override("font_size", 20)
    score_label.add_theme_color_override("font_color", GOLD)
    root.add_child(score_label)
    board = SnakeBoard.new()
    # Allow the square arena to occupy the full available content width.
    # Extra height prevents it from shrinking when placed in a ScrollContainer.
    board.custom_minimum_size = Vector2(0, 540)
    board.size_flags_vertical = Control.SIZE_EXPAND_FILL
    board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    board.mouse_filter = Control.MOUSE_FILTER_STOP
    board.gui_input.connect(_board_input)
    root.add_child(board)
    hint_label = Label.new()
    hint_label.text = "Swipe to steer • Collect stars"
    hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.add_theme_color_override("font_color", Color("#d7e4ff"))
    root.add_child(hint_label)
    var controls := GridContainer.new()
    controls.columns = 3
    controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.add_child(controls)
    # Familiar D-pad arrangement: up above left/down/right.
    _add_spacer(controls)
    _add_control(controls, "▲", Vector2i.UP)
    _add_spacer(controls)
    _add_control(controls, "◀", Vector2i.LEFT)
    _add_control(controls, "▼", Vector2i.DOWN)
    _add_control(controls, "▶", Vector2i.RIGHT)
    var restart := Button.new()
    restart.text = "↻  NEW RUN"
    restart.custom_minimum_size.y = 46
    restart.pressed.connect(_restart)
    root.add_child(restart)

func _add_spacer(parent: GridContainer) -> void:
    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(0, 52)
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(spacer)

func _add_control(parent: GridContainer, label_text: String, heading: Vector2i) -> void:
    var b := Button.new()
    b.text = label_text
    b.custom_minimum_size = Vector2(0, 52)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.pressed.connect(_steer.bind(heading))
    parent.add_child(b)

func _restart() -> void:
    snake.clear()
    snake.append(Vector2i(6, 7))
    snake.append(Vector2i(5, 7))
    snake.append(Vector2i(4, 7))
    direction = Vector2i.RIGHT
    next_direction = direction
    score = 0
    eaten = 0
    accumulator = 0.0
    queued_turns.clear()
    touch_active = false
    playing = true
    _spawn_food()
    hint_label.text = "Swipe to turn. Collect stars and avoid walls!"
    _refresh()
    set_process(true)

func _process(delta: float) -> void:
    if not playing:
        return
    accumulator += minf(delta, 0.1)
    var step_time: float = maxf(0.095, 0.19 - float(eaten) * 0.006)
    if accumulator >= step_time:
        accumulator -= step_time
        _step()

func _step() -> void:
    if not queued_turns.is_empty():
        next_direction = queued_turns.pop_front()
    direction = next_direction
    var head: Vector2i = snake[0] + direction
    if head.x < 0 or head.y < 0 or head.x >= GRID_SIZE or head.y >= GRID_SIZE:
        _end_run()
        return
    var eating: bool = head == food
    var body_length: int = snake.size() if eating else snake.size() - 1
    for i in range(body_length):
        if head == snake[i]:
            _end_run()
            return
    snake.insert(0, head)
    if eating:
        eaten += 1
        score += 10 + mini(eaten, 20)
        if snake.size() >= GRID_SIZE * GRID_SIZE:
            _end_run()
            return
        _spawn_food()
    else:
        snake.pop_back()
    _refresh()

func _spawn_food() -> void:
    var open: Array[Vector2i] = []
    for y in range(GRID_SIZE):
        for x in range(GRID_SIZE):
            var candidate := Vector2i(x, y)
            if not snake.has(candidate):
                open.append(candidate)
    if not open.is_empty():
        food = open[rng.randi_range(0, open.size() - 1)]

func _steer(heading: Vector2i) -> void:
    if not playing:
        return
    # Queue up to two turns, so quick gestures are not lost between ticks.
    var previous: Vector2i = queued_turns.back() if not queued_turns.is_empty() else next_direction
    if heading == previous or heading + previous == Vector2i.ZERO:
        return
    if queued_turns.size() < 2:
        queued_turns.append(heading)

func _board_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_active = true
            swipe_anchor = event.position
        else:
            if touch_active:
                _consume_swipe(event.position)
            touch_active = false
    elif event is InputEventScreenDrag and touch_active:
        _consume_swipe(event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            touch_active = true
            swipe_anchor = event.position
        else:
            if touch_active:
                _consume_swipe(event.position)
            touch_active = false
    elif event is InputEventMouseMotion and touch_active:
        _consume_swipe(event.position)

func _consume_swipe(position: Vector2) -> void:
    var vector: Vector2 = position - swipe_anchor
    if vector.length() < 16.0:
        return
    if absf(vector.x) > absf(vector.y):
        _steer(Vector2i.RIGHT if vector.x > 0.0 else Vector2i.LEFT)
    else:
        _steer(Vector2i.DOWN if vector.y > 0.0 else Vector2i.UP)
    swipe_anchor = position

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed:
        return
    match event.keycode:
        KEY_UP, KEY_W: _steer(Vector2i.UP)
        KEY_DOWN, KEY_S: _steer(Vector2i.DOWN)
        KEY_LEFT, KEY_A: _steer(Vector2i.LEFT)
        KEY_RIGHT, KEY_D: _steer(Vector2i.RIGHT)

func _refresh() -> void:
    score_label.text = "SCORE  %d     STARS  %d" % [score, eaten]
    board.snake = snake.duplicate()
    board.food = food
    board.queue_redraw()

func _end_run() -> void:
    if not playing:
        return
    playing = false
    hint_label.text = "Run complete! Tap NEW RUN to try again."
    finished.emit("snake", score, {"stars": eaten})

class SnakeBoard extends Control:
    var snake: Array[Vector2i] = []
    var food: Vector2i = Vector2i(9, 7)

    func _draw() -> void:
        var side: float = minf(size.x, size.y) - 8.0
        if side < 20.0:
            return
        var cell: float = side / 15.0
        var origin: Vector2 = (size - Vector2(side, side)) * 0.5
        draw_rect(Rect2(origin, Vector2(side, side)), Color("#17234f"), true)
        draw_rect(Rect2(origin, Vector2(side, side)), Color("#a9c5ff"), false, 3.0)
        for i in range(1, 15):
            var offset: float = float(i) * cell
            draw_line(origin + Vector2(offset, 0), origin + Vector2(offset, side), Color("#536a9a", 0.24), 1.0)
            draw_line(origin + Vector2(0, offset), origin + Vector2(side, offset), Color("#536a9a", 0.24), 1.0)
        var center: Vector2 = origin + (Vector2(food) + Vector2(0.5, 0.5)) * cell
        var star_points := PackedVector2Array()
        for i in range(10):
            var angle: float = -PI / 2.0 + float(i) * PI / 5.0
            var radius: float = cell * (0.48 if i % 2 == 0 else 0.22)
            star_points.append(center + Vector2(cos(angle), sin(angle)) * radius)
        draw_circle(center, cell * 0.49, Color("#ffd369", 0.24))
        draw_colored_polygon(star_points, Color("#ffda68"))
        for i in range(snake.size() - 1, -1, -1):
            var pos: Vector2 = origin + Vector2(snake[i]) * cell + Vector2.ONE * cell * 0.5
            var radius: float = cell * (0.45 if i == 0 else 0.39)
            draw_circle(pos + Vector2(0, cell * 0.07), radius, Color("#08152e", 0.7))
            draw_circle(pos, radius, Color("#59eec1") if i == 0 else Color("#35c8df"))
            draw_arc(pos, radius, 0.0, TAU, 24, Color("#c8fff4", 0.85), 2.0)
            if i == 0:
                draw_circle(pos + Vector2(-cell * 0.14, -cell * 0.10), cell * 0.075, Color("#122c4e"))
                draw_circle(pos + Vector2(cell * 0.14, -cell * 0.10), cell * 0.075, Color("#122c4e"))
