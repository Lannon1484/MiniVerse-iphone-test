extends Control
# Bubble Burst: compact, touch-first column shooter. No external dependencies.
signal finished(game_id: String, score: int)
signal gameplay_sound(kind: String)
const Difficulty = preload("res://scripts/difficulty.gd")
const COLS := 7
const ROWS := 9
const PALETTE := [Color("#ff77b7"), Color("#65d9ff"), Color("#ffdb69"), Color("#9b83ff"), Color("#7ce6a3")]
var board: Array = []
var rng := RandomNumberGenerator.new()
var score := 0
var shots_left := 24
var next_color := 0
var running := false
var goal := 90
var cells: Control
var next_preview: TextureRect
var status: Label
var next_label: Label
var column_buttons: HBoxContainer

func start_game() -> void:
    rng.randomize()
    var level: int = Difficulty.level("bubble")
    var goals := [90, 120, 150, 180, 210]
    goal = goals[level - 1] if level <= goals.size() else int(round(210.0 * (1.0 + 0.1 * float(level - 5))))
    shots_left = 24 + mini(8, maxi(0, level - 1))
    score = 0
    running = true
    board.clear()
    for row in range(ROWS):
        var line: Array[int] = []
        for col in range(COLS):
            line.append(rng.randi_range(0, mini(PALETTE.size() - 1, 2 + level / 3)) if row < 3 else -1)
        board.append(line)
    next_color = rng.randi_range(0, mini(PALETTE.size() - 1, 2 + level / 3))
    _build_ui()
    _refresh()

func _build_ui() -> void:
    var outer := VBoxContainer.new()
    outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    outer.add_theme_constant_override("separation", 7)
    outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(outer)

    status = Label.new()
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.add_theme_font_size_override("font_size", 20)
    status.add_theme_color_override("font_color", Color("#fff1ba"))
    outer.add_child(status)

    var hint := Label.new()
    hint.text = "Tap a lane to launch • Match 3+"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.add_theme_color_override("font_color", Color("#f4e5ff"))
    outer.add_child(hint)

    # The grid, next-bubble preview, and launch buttons share one centered
    # fixed-width column. This keeps each arrow directly under its bubble lane.
    # A height cap protects short phone displays; the width cap protects narrow ones.
    var view_size: Vector2 = get_viewport_rect().size
    # Make use of the available vertical play area, not just 46% of the
    # viewport. The nine-row board remains proportional and its seven
    # buttons share the exact same width. Leave room for the HUD, preview,
    # controls, and mobile browser chrome.
    var board_height_limit: float = minf(530.0, view_size.y * 0.70)
    var board_width: float = minf(view_size.x - 48.0, board_height_limit * float(COLS) / float(ROWS))
    board_width = maxf(140.0, board_width)
    var board_height: float = board_width * float(ROWS) / float(COLS)

    var centered_column := CenterContainer.new()
    centered_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    outer.add_child(centered_column)
    var game_column := VBoxContainer.new()
    game_column.custom_minimum_size.x = board_width
    game_column.add_theme_constant_override("separation", 6)
    centered_column.add_child(game_column)

    cells = preload("res://scripts/bubble_board.gd").new()
    cells.set("board_data", board)
    cells.set("palette", PALETTE)
    cells.custom_minimum_size = Vector2(board_width, board_height)
    cells.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    game_column.add_child(cells)

    var preview_row := HBoxContainer.new()
    preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
    preview_row.add_theme_constant_override("separation", 10)
    game_column.add_child(preview_row)
    next_label = Label.new()
    next_label.text = "NEXT BUBBLE"
    next_label.add_theme_font_size_override("font_size", 17)
    next_label.add_theme_color_override("font_color", Color("#ffe1a0"))
    preview_row.add_child(next_label)
    next_preview = TextureRect.new()
    next_preview.texture = preload("res://assets/lobby/bubble_orb_white.png")
    next_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    next_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    next_preview.custom_minimum_size = Vector2(36, 36)
    next_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    preview_row.add_child(next_preview)

    column_buttons = HBoxContainer.new()
    column_buttons.add_theme_constant_override("separation", 2)
    column_buttons.custom_minimum_size.x = board_width
    game_column.add_child(column_buttons)
    for col in range(COLS):
        var button := Button.new()
        button.text = "↑"
        button.custom_minimum_size = Vector2(0, 46)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.size_flags_stretch_ratio = 1.0
        button.add_theme_font_size_override("font_size", 22)
        button.add_theme_color_override("font_color", Color("#fff4c6"))
        var style := StyleBoxFlat.new()
        style.bg_color = Color("#6941ad")
        style.border_color = Color("#ffd978")
        style.set_border_width_all(2)
        style.set_corner_radius_all(10)
        button.add_theme_stylebox_override("normal", style)
        var hover_style := style.duplicate()
        hover_style.bg_color = Color("#9460d2")
        button.add_theme_stylebox_override("hover", hover_style)
        var pressed_style := style.duplicate()
        pressed_style.bg_color = Color("#aa70e2")
        button.add_theme_stylebox_override("pressed", pressed_style)
        button.pressed.connect(_shoot.bind(col))
        column_buttons.add_child(button)

func _refresh() -> void:
    if not is_instance_valid(cells):
        return
    status.text = "SCORE %d / %d    •    SHOTS %d" % [score, goal, shots_left]
    cells.set("board_data", board)
    cells.queue_redraw()
    next_preview.modulate = PALETTE[next_color]
    for button in column_buttons.get_children():
        button.disabled = not running

func _shoot(col: int) -> void:
    if not running:
        return
    var landing := -1
    for row in range(ROWS - 1, -1, -1):
        if int(board[row][col]) >= 0:
            landing = row + 1
            break
    if landing == -1:
        landing = 0
    if landing >= ROWS:
        _end_round()
        return
    board[landing][col] = next_color
    shots_left -= 1
    var group: Array[Vector2i] = _connected(landing, col, next_color)
    if group.size() >= 3:
        for cell in group:
            board[cell.y][cell.x] = -1
        score += group.size() * 15 + maxi(0, group.size() - 3) * 5
        gameplay_sound.emit("collect")
        _drop_floating()
    else:
        gameplay_sound.emit("pour")
    var level: int = Difficulty.level("bubble")
    next_color = rng.randi_range(0, mini(PALETTE.size() - 1, 2 + level / 3))
    if score >= goal or shots_left <= 0 or _bottom_occupied():
        _end_round()
    else:
        _refresh()

func _connected(start_row: int, start_col: int, kind: int) -> Array[Vector2i]:
    var found: Array[Vector2i] = []
    var queue: Array[Vector2i] = [Vector2i(start_col, start_row)]
    var visited := {}
    while not queue.is_empty():
        var cell: Vector2i = queue.pop_front()
        if cell.x < 0 or cell.x >= COLS or cell.y < 0 or cell.y >= ROWS:
            continue
        if visited.has(cell) or int(board[cell.y][cell.x]) != kind:
            continue
        visited[cell] = true
        found.append(cell)
        queue.append(cell + Vector2i(1, 0))
        queue.append(cell + Vector2i(-1, 0))
        queue.append(cell + Vector2i(0, 1))
        queue.append(cell + Vector2i(0, -1))
    return found

func _drop_floating() -> void:
    var visited := {}
    var queue: Array[Vector2i] = []
    for col in range(COLS):
        if int(board[0][col]) >= 0:
            queue.append(Vector2i(col, 0))
    while not queue.is_empty():
        var cell: Vector2i = queue.pop_front()
        if cell.x < 0 or cell.x >= COLS or cell.y < 0 or cell.y >= ROWS:
            continue
        if visited.has(cell) or int(board[cell.y][cell.x]) < 0:
            continue
        visited[cell] = true
        queue.append(cell + Vector2i(1, 0))
        queue.append(cell + Vector2i(-1, 0))
        queue.append(cell + Vector2i(0, 1))
        queue.append(cell + Vector2i(0, -1))
    for row in range(ROWS):
        for col in range(COLS):
            if int(board[row][col]) >= 0 and not visited.has(Vector2i(col, row)):
                board[row][col] = -1
                score += 10

func _bottom_occupied() -> bool:
    for col in range(COLS):
        if int(board[ROWS - 1][col]) >= 0:
            return true
    return false

func _end_round() -> void:
    running = false
    _refresh()
    finished.emit("bubble", score)
