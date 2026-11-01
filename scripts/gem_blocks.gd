extends Control
# Gem Blocks: touch-first, 8x8 block placement puzzle.
signal finished(game_id: String, score: int)
signal gameplay_sound(kind: String)
const Difficulty = preload("res://scripts/difficulty.gd")
const SIZE := 8
const COLORS := [Color("#ff7bb7"), Color("#70dcf7"), Color("#ffd36e"), Color("#a68aff"), Color("#78e6ad")]
const SHAPES := [
    [Vector2i(0,0)], [Vector2i(0,0),Vector2i(1,0)],
    [Vector2i(0,0),Vector2i(0,1)], [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],
    [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(1,1)],
    [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)]
]
var board: Array = []
var offers: Array[int] = []
var selected := -1
var score := 0
var goal := 100
var running := false
var rng := RandomNumberGenerator.new()
var cell_buttons: Array[Button] = []
var offer_buttons: Array[Button] = []
var score_label: Label
var help_label: Label

func start_game() -> void:
    rng.randomize()
    var level: int = Difficulty.level("gems")
    var targets := [100, 150, 200, 250, 300]
    goal = targets[level - 1] if level <= 5 else int(round(300.0 * (1.0 + 0.10 * float(level - 5))))
    score = 0
    selected = -1
    running = true
    board.clear()
    cell_buttons.clear()
    offer_buttons.clear()
    for y in range(SIZE):
        var row: Array[int] = []
        for x in range(SIZE):
            row.append(-1)
        board.append(row)
    _refill_offers()
    _build_ui()
    _refresh()

func _build_ui() -> void:
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 7)
    add_child(root)
    score_label = Label.new()
    score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    score_label.add_theme_font_size_override("font_size", 19)
    score_label.add_theme_color_override("font_color", Color("#ffe3a1"))
    root.add_child(score_label)
    help_label = Label.new()
    help_label.text = "Choose a shape, then tap the board to place it."
    help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help_label.add_theme_font_size_override("font_size", 14)
    help_label.add_theme_color_override("font_color", Color("#e4d5ff"))
    root.add_child(help_label)

    var center := CenterContainer.new()
    center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.add_child(center)
    var grid := GridContainer.new()
    grid.columns = SIZE
    grid.add_theme_constant_override("h_separation", 3)
    grid.add_theme_constant_override("v_separation", 3)
    center.add_child(grid)
    # Board is intentionally capped to keep shape choices visible on iPhone.
    var viewport: Vector2 = get_viewport_rect().size
    # Cap by both dimensions: the board and all three piece choices
    # must fit on short phones without pushing controls below the fold.
    var width: float = minf(minf(370.0, viewport.x - 52.0), viewport.y * 0.46)
    var side: float = maxf(24.0, floorf((width - 21.0) / float(SIZE)))
    for y in range(SIZE):
        for x in range(SIZE):
            var cell := Button.new()
            cell.custom_minimum_size = Vector2(side, side)
            cell.focus_mode = Control.FOCUS_NONE
            cell.pressed.connect(_place.bind(x,y))
            grid.add_child(cell)
            cell_buttons.append(cell)

    var title := Label.new()
    title.text = "CHOOSE A GEM SHAPE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 17)
    title.add_theme_color_override("font_color", Color("#ffde94"))
    root.add_child(title)
    var offer_row := HBoxContainer.new()
    offer_row.alignment = BoxContainer.ALIGNMENT_CENTER
    offer_row.add_theme_constant_override("separation", 8)
    root.add_child(offer_row)
    for i in range(3):
        var offer := Button.new()
        offer.custom_minimum_size = Vector2(94, 76)
        offer.focus_mode = Control.FOCUS_NONE
        offer.add_theme_font_size_override("font_size", 22)
        offer.pressed.connect(_select.bind(i))
        offer_row.add_child(offer)
        offer_buttons.append(offer)

func _refill_offers() -> void:
    offers.clear()
    # Mix small and large shapes; a single-cell piece ensures new players
    # can usually recover from a crowded board.
    offers.append(0)
    offers.append(rng.randi_range(1, SHAPES.size()-1))
    offers.append(rng.randi_range(1, SHAPES.size()-1))
    offers.shuffle()

func _shape_text(shape_id: int) -> String:
    var cells: Array = SHAPES[shape_id]
    var width := 0
    var height := 0
    for p in cells:
        width = maxi(width, p.x + 1)
        height = maxi(height, p.y + 1)
    var result := ""
    for y in range(height):
        if y > 0:
            result += "\n"
        for x in range(width):
            result += "◆" if Vector2i(x,y) in cells else " "
    return result

func _style(color: Color, active: bool = false) -> StyleBoxFlat:
    var st := StyleBoxFlat.new()
    st.bg_color = color
    st.border_color = Color("#fff0b0") if active else Color("#8b67c5")
    st.set_border_width_all(3 if active else 2)
    st.set_corner_radius_all(8)
    return st

func _refresh() -> void:
    score_label.text = "SCORE %d / %d  •  CLEAR FULL LINES" % [score,goal]
    for y in range(SIZE):
        for x in range(SIZE):
            var index: int = y*SIZE+x
            var color_id: int = board[y][x]
            var cell := cell_buttons[index]
            cell.text = "◆" if color_id >= 0 else ""
            cell.add_theme_font_size_override("font_size", 24)
            cell.add_theme_color_override("font_color", Color("#fff7d8"))
            cell.add_theme_stylebox_override("normal", _style(COLORS[color_id] if color_id >= 0 else Color("#30205c")))
            cell.add_theme_stylebox_override("hover", _style(COLORS[color_id] if color_id >= 0 else Color("#513382"), true))
            cell.add_theme_stylebox_override("pressed", _style(Color("#8159bf"), true))
            cell.disabled = not running
    for i in range(3):
        var button := offer_buttons[i]
        var has_piece: bool = offers[i] >= 0
        button.text = _shape_text(offers[i]) if has_piece else "USED"
        button.disabled = not running or not has_piece
        button.add_theme_color_override("font_color", Color("#fff2be"))
        button.add_theme_stylebox_override("normal", _style(Color("#7440a7") if has_piece else Color("#30254a"), selected == i))
        button.add_theme_stylebox_override("hover", _style(Color("#9461ca"), true))

func _select(i: int) -> void:
    if not running or offers[i] < 0:
        return
    selected = i
    help_label.text = "Tap the top-left square for this shape."
    _refresh()

func _fits(shape_id: int, ox: int, oy: int) -> bool:
    for p in SHAPES[shape_id]:
        var x: int = ox + p.x
        var y: int = oy + p.y
        if x < 0 or y < 0 or x >= SIZE or y >= SIZE or board[y][x] != -1:
            return false
    return true

func _place(x: int, y: int) -> void:
    if not running:
        return
    if selected < 0 or offers[selected] < 0:
        help_label.text = "Choose one of the shapes first!"
        return
    var shape_id: int = offers[selected]
    if not _fits(shape_id, x, y):
        help_label.text = "That shape won't fit there. Choose an empty area."
        gameplay_sound.emit("error")
        return
    for p in SHAPES[shape_id]:
        board[y+p.y][x+p.x] = (shape_id + selected) % COLORS.size()
    score += SHAPES[shape_id].size() * 5
    offers[selected] = -1
    selected = -1
    var cleared := _clear_lines()
    if cleared > 0:
        score += cleared * 40
        help_label.text = "%d line(s) cleared! +%d bonus" % [cleared,cleared*40]
        gameplay_sound.emit("collect")
    else:
        help_label.text = "Nice placement! Complete a line for bonus points."
        gameplay_sound.emit("tap")
    if score >= goal:
        _end()
        return
    if offers[0] < 0 and offers[1] < 0 and offers[2] < 0:
        _refill_offers()
    if not _has_moves():
        _end()
        return
    _refresh()

func _clear_lines() -> int:
    var rows: Array[int] = []
    var cols: Array[int] = []
    for y in range(SIZE):
        var full := true
        for x in range(SIZE):
            if board[y][x] < 0:
                full = false
        if full:
            rows.append(y)
    for x in range(SIZE):
        var full := true
        for y in range(SIZE):
            if board[y][x] < 0:
                full = false
        if full:
            cols.append(x)
    for y in rows:
        for x in range(SIZE):
            board[y][x] = -1
    for x in cols:
        for y in range(SIZE):
            board[y][x] = -1
    return rows.size() + cols.size()

func _has_moves() -> bool:
    for shape_id in offers:
        if shape_id < 0:
            continue
        for y in range(SIZE):
            for x in range(SIZE):
                if _fits(shape_id,x,y):
                    return true
    return false

func _end() -> void:
    running = false
    _refresh()
    finished.emit("gems",score)
