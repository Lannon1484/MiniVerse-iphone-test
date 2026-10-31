extends Control
class_name ConnectDots

signal finished(game_id: String, score: int, extra: Dictionary)
signal gameplay_sound(kind: String)

const GRID := 5
const Difficulty = preload("res://scripts/difficulty.gd")
const COLORS := [Color("#ff79b2"), Color("#5fe0ff"), Color("#ffd36d"), Color("#a88bff")]
# Every puzzle is built from four non-overlapping routes on a 5x5 board.
# A seeded shuffle creates a reproducible, effectively unlimited level sequence.
const PUZZLE_SEED := 827491
var current_endpoints: Array = []
var puzzle_rng := RandomNumberGenerator.new()


var board: DotBoard
var paths: Array = []
var active_color := -1
var level := 0
var moves := 0
var won := false
var reward_claimed := false
var claim_button: Button
var score_label: Label
var message: Label

func start_game() -> void:
    var layout := VBoxContainer.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout.add_theme_constant_override("separation", 12)
    add_child(layout)
    var title := Label.new()
    title.text = "CONNECT THE DOTS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 27)
    title.add_theme_color_override("font_color", Color("#ffe89a"))
    layout.add_child(title)
    var instructions := Label.new()
    instructions.text = "Drag between matching colored dots. Paths cannot cross!"
    instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    instructions.add_theme_font_size_override("font_size", 17)
    layout.add_child(instructions)
    score_label = Label.new()
    score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    score_label.add_theme_font_size_override("font_size", 19)
    layout.add_child(score_label)
    board = DotBoard.new()
    board.custom_minimum_size = Vector2(0, 490)
    board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    board.mouse_filter = Control.MOUSE_FILTER_STOP
    board.cell_touched.connect(_touch_cell)
    board.drag_ended.connect(_end_drag)
    layout.add_child(board)
    message = Label.new()
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message.add_theme_font_size_override("font_size", 17)
    message.add_theme_color_override("font_color", Color("#8df4cf"))
    layout.add_child(message)
    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 10)
    layout.add_child(actions)
    for item in [["RESET", "reset"], ["NEXT PUZZLE", "next"]]:
        var button := Button.new()
        button.text = item[0]
        button.custom_minimum_size.y = 65
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.pressed.connect(_action.bind(item[1]))
        actions.add_child(button)
    claim_button = Button.new()
    claim_button.text = "CLAIM REWARD"
    claim_button.custom_minimum_size.y = 65
    claim_button.visible = false
    claim_button.pressed.connect(_claim_reward)
    layout.add_child(claim_button)
    _setup_level()

func _generate_puzzle(puzzle_index: int) -> Array:
    # Snake through every square, then divide that valid continuous route
    # into four separate colored paths. Each pair is guaranteed connectable.
    puzzle_rng.seed = PUZZLE_SEED + puzzle_index * 7919
    var route: Array[Vector2i] = []
    var vertical: bool = puzzle_rng.randi_range(0, 1) == 1
    for outer in range(GRID):
        for inner in range(GRID):
            var offset: int = inner if outer % 2 == 0 else GRID - 1 - inner
            route.append(Vector2i(offset, outer) if not vertical else Vector2i(outer, offset))
    var flip_x: bool = puzzle_rng.randi_range(0, 1) == 1
    var flip_y: bool = puzzle_rng.randi_range(0, 1) == 1
    for i in range(route.size()):
        var pt: Vector2i = route[i]
        route[i] = Vector2i(GRID - 1 - pt.x if flip_x else pt.x, GRID - 1 - pt.y if flip_y else pt.y)
    # Split the 25-cell route into four lengths (each at least 3).
    # Leave one cell between paths so endpoints never overlap.
    var lengths: Array[int] = [3, 3, 3, 3]
    var spare: int = GRID * GRID - 3 - 12
    # Easy early levels favor short connections; harder levels spread out.
    if puzzle_index < 3:
        spare = 0
    elif puzzle_index < 6:
        spare = 4
    for i in range(spare):
        lengths[puzzle_rng.randi_range(0, 3)] += 1
    var endpoints: Array = []
    var cursor: int = 0
    for length in lengths:
        var first: Vector2i = route[cursor]
        var last: Vector2i = route[cursor + length - 1]
        if puzzle_rng.randi_range(0, 1) == 1:
            var temp: Vector2i = first
            first = last
            last = temp
        endpoints.append([first.x, first.y, last.x, last.y])
        cursor += length + 1
    for i in range(endpoints.size() - 1, 0, -1):
        var j: int = puzzle_rng.randi_range(0, i)
        var tmp: Array = endpoints[i]
        endpoints[i] = endpoints[j]
        endpoints[j] = tmp
    return endpoints

func _setup_level() -> void:
    paths.clear()
    for i in range(COLORS.size()):
        paths.append([])
    active_color = -1
    moves = 0
    won = false
    reward_claimed = false
    if is_instance_valid(claim_button):
        claim_button.visible = false
    current_endpoints = _generate_puzzle(level)
    board.endpoints = current_endpoints
    board.paths = paths
    message.text = "Connect each matching pair!"
    _refresh()

func _refresh() -> void:
    score_label.text = "PUZZLE %d   •   MOVES %d   •   PAIRS %d / 4" % [level + 1, moves, _connected_count()]
    board.paths = paths
    board.queue_redraw()

func _connected_count() -> int:
    var count := 0
    for i in range(paths.size()):
        if paths[i].size() >= 2 and (paths[i].back() == _endpoint(i, 1) if paths[i][0] == _endpoint(i, 0) else paths[i].back() == _endpoint(i, 0)):
            count += 1
    return count

func _endpoint(color_index: int, which: int) -> Vector2i:
    var p: Array = current_endpoints[color_index]
    return Vector2i(p[0], p[1]) if which == 0 else Vector2i(p[2], p[3])

func _touch_cell(cell: Vector2i, beginning: bool) -> void:
    if won:
        return
    if beginning:
        active_color = -1
        for i in range(COLORS.size()):
            if cell == _endpoint(i, 0) or cell == _endpoint(i, 1):
                active_color = i
                paths[i] = [cell]
                moves += 1
                _refresh()
                return
        return
    if active_color == -1:
        return
    var path: Array = paths[active_color]
    if path.is_empty():
        return
    # Once a pair is connected, do not extend the path beyond its destination.
    var destination: Vector2i = _endpoint(active_color, 1) if path[0] == _endpoint(active_color, 0) else _endpoint(active_color, 0)
    if path.back() == destination:
        return
    var previous: Vector2i = path.back()
    if abs(cell.x - previous.x) + abs(cell.y - previous.y) != 1:
        return
    if path.size() >= 2 and cell == path[path.size() - 2]:
        path.pop_back()
        _refresh()
        return
    if path.has(cell):
        return
    for i in range(paths.size()):
        if i != active_color and paths[i].has(cell):
            return
    for i in range(COLORS.size()):
        if i != active_color and (cell == _endpoint(i, 0) or cell == _endpoint(i, 1)):
            return
    if cell == _endpoint(active_color, 0) and path[0] == _endpoint(active_color, 0):
        return
    if cell == _endpoint(active_color, 1) and path[0] == _endpoint(active_color, 1):
        return
    path.append(cell)
    if cell == destination:
        gameplay_sound.emit("connect")
    _refresh()
    if _connected_count() == COLORS.size():
        won = true
        var score: int = maxi(100, 900 - moves * 30)
        message.text = "ALL CONNECTED! +%d points! Claim reward or try the next puzzle." % score
        claim_button.visible = true

func _claim_reward() -> void:
    if not won or reward_claimed:
        return
    reward_claimed = true
    var score: int = maxi(100, 900 - moves * 30)
    finished.emit("dots", score, {"coins": maxi(5, int(score / 75.0)), "xp": 30})

func _end_drag() -> void:
    active_color = -1

func _action(which: String) -> void:
    if which == "next":
        level += 1
    _setup_level()

class DotBoard extends Control:
    signal cell_touched(cell: Vector2i, beginning: bool)
    signal drag_ended
    var endpoints: Array = []
    var paths: Array = []
    var dragging := false
    var last_cell := Vector2i(-1, -1)

    func _geometry() -> Dictionary:
        var side: float = minf(size.x - 12.0, size.y - 12.0)
        var step: float = side / 5.0
        return {"step": step, "origin": (size - Vector2(side, side)) * 0.5 + Vector2(step * 0.5, step * 0.5)}

    func _cell_at(pos: Vector2) -> Vector2i:
        var g := _geometry()
        var v: Vector2 = (pos - g.origin) / g.step
        var c := Vector2i(roundi(v.x), roundi(v.y))
        if c.x < 0 or c.x >= 5 or c.y < 0 or c.y >= 5:
            return Vector2i(-1, -1)
        return c

    func _input_cell(pos: Vector2, beginning: bool) -> void:
        var cell := _cell_at(pos)
        if cell.x < 0:
            return
        if beginning or cell != last_cell:
            last_cell = cell
            cell_touched.emit(cell, beginning)

    func _gui_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch:
            if event.pressed:
                dragging = true
                _input_cell(event.position, true)
            else:
                dragging = false
                drag_ended.emit()
            accept_event()
        elif event is InputEventScreenDrag and dragging:
            _input_cell(event.position, false)
            accept_event()
        elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
            dragging = event.pressed
            if dragging:
                _input_cell(event.position, true)
            else:
                drag_ended.emit()
            accept_event()
        elif event is InputEventMouseMotion and dragging:
            _input_cell(event.position, false)
            accept_event()

    func _draw() -> void:
        var g := _geometry()
        var step: float = g.step
        var origin: Vector2 = g.origin
        draw_rect(Rect2(Vector2.ZERO, size), Color("#11224c"), true)
        for x in range(5):
            for y in range(5):
                draw_circle(origin + Vector2(x, y) * step, 4.0, Color("#5275a6", 0.65))
        for i in range(paths.size()):
            var path: Array = paths[i]
            for j in range(1, path.size()):
                var a: Vector2 = origin + Vector2(path[j - 1]) * step
                var b: Vector2 = origin + Vector2(path[j]) * step
                draw_line(a, b, Color(COLORS[i].r, COLORS[i].g, COLORS[i].b, 0.20), 27.0, true)
                draw_line(a, b, COLORS[i], 13.0, true)
        for i in range(endpoints.size()):
            var p: Array = endpoints[i]
            for c in [Vector2i(p[0], p[1]), Vector2i(p[2], p[3])]:
                var center: Vector2 = origin + Vector2(c) * step
                draw_circle(center, 24.0, Color(COLORS[i].r, COLORS[i].g, COLORS[i].b, 0.24))
                draw_circle(center, 16.0, COLORS[i])
                draw_circle(center + Vector2(-4, -5), 5.0, Color("#ffffff", 0.82))
