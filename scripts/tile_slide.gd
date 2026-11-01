extends Control

signal finished(game_id: String, score: int, extra: Dictionary)

const Difficulty = preload("res://scripts/difficulty.gd")
const SIZE := 3
const TILE_COLORS := [Color("#a46cf4"), Color("#52c9e7"), Color("#e877c8"), Color("#65d7a3")]
var board: Array[int] = []
var cells: Array[Button] = []
var status: Label
var moves: int = 0
var running: bool = false
var rng := RandomNumberGenerator.new()

func start_game() -> void:
    rng.randomize()
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 16)
    add_child(root)
    var title := Label.new()
    title.text = "TILE SLIDE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 29)
    title.add_theme_color_override("font_color", Color("#ffe1a0"))
    root.add_child(title)
    status = Label.new()
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.add_theme_font_size_override("font_size", 20)
    root.add_child(status)
    var grid := GridContainer.new()
    grid.columns = SIZE
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.add_child(grid)
    for index in range(SIZE * SIZE):
        var cell := Button.new()
        cell.custom_minimum_size = Vector2(85, 92)
        cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        cell.add_theme_font_size_override("font_size", 31)
        var target: int = index
        cell.pressed.connect(func(): _tap(target))
        grid.add_child(cell)
        cells.append(cell)
    var hint := Label.new()
    hint.text = "TAP A TILE BESIDE THE EMPTY SPACE"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.add_theme_font_size_override("font_size", 17)
    root.add_child(hint)
    var reshuffle := Button.new()
    reshuffle.text = "NEW PUZZLE"
    reshuffle.custom_minimum_size.y = 54
    reshuffle.pressed.connect(_new_puzzle)
    root.add_child(reshuffle)
    _new_puzzle()

func _new_puzzle() -> void:
    board.clear()
    for value in range(1, SIZE * SIZE):
        board.append(value)
    board.append(0)
    var previous_empty: int = -1
    # Difficulty grows gradually while every puzzle remains solvable:
    # shuffle by legal moves starting from the solved configuration.
    var shuffle_moves: int = 20 + mini(24, maxi(0, Difficulty.level("slide") - 1) * 3)
    for turn in range(shuffle_moves):
        var empty: int = board.find(0)
        var choices: Array[int] = _neighbors(empty)
        if choices.size() > 1:
            choices.erase(previous_empty)
        var selected: int = choices[rng.randi_range(0, choices.size() - 1)]
        board[empty] = board[selected]
        board[selected] = 0
        previous_empty = empty
    # Avoid handing out a solved board after a random walk.
    if _solved():
        var empty: int = board.find(0)
        var neighbor: int = _neighbors(empty)[0]
        board[empty] = board[neighbor]
        board[neighbor] = 0
    moves = 0
    running = true
    _refresh()

func _neighbors(index: int) -> Array[int]:
    var result: Array[int] = []
    var x: int = index % SIZE
    var y: int = int(index / SIZE)
    if x > 0: result.append(index - 1)
    if x < SIZE - 1: result.append(index + 1)
    if y > 0: result.append(index - SIZE)
    if y < SIZE - 1: result.append(index + SIZE)
    return result

func _tap(index: int) -> void:
    if not running:
        return
    var empty: int = board.find(0)
    if not _neighbors(empty).has(index):
        return
    board[empty] = board[index]
    board[index] = 0
    moves += 1
    # Quick jewel-tile pulse on each valid slide, without delaying input.
    var moved_cell: Button = cells[empty]
    moved_cell.pivot_offset = moved_cell.size * 0.5
    var slide_tween := create_tween()
    slide_tween.tween_property(moved_cell, "scale", Vector2(1.06, 1.06), 0.10)
    slide_tween.tween_property(moved_cell, "scale", Vector2.ONE, 0.13)
    if _solved():
        running = false
        _refresh()
        finished.emit("slide", maxi(25, 500 - moves * 8), {"won": true, "completed": true, "moves": moves})
    else:
        _refresh()

func _solved() -> bool:
    for index in range(SIZE * SIZE - 1):
        if board[index] != index + 1:
            return false
    return board[SIZE * SIZE - 1] == 0

func _refresh() -> void:
    status.text = ("PUZZLE SOLVED!  " if not running else "MOVES: ") + str(moves)
    for index in range(cells.size()):
        var cell: Button = cells[index]
        var value: int = board[index]
        cell.text = "" if value == 0 else str(value)
        cell.disabled = not running or value == 0
        cell.focus_mode = Control.FOCUS_NONE
        var bg: Color = Color("#253052") if value == 0 else TILE_COLORS[(value - 1) % TILE_COLORS.size()]
        var style := StyleBoxFlat.new()
        style.bg_color = bg
        style.set_corner_radius_all(16)
        style.border_width_left = 4
        style.border_width_right = 4
        style.border_width_top = 4
        style.border_width_bottom = 4
        style.border_color = Color("#ffdc88") if value != 0 else Color("#6e4c9a")
        style.shadow_color = Color("#4b1d85", 0.72)
        style.shadow_size = 7
        style.shadow_offset = Vector2(0, 3)
        style.set_content_margin_all(10)
        cell.add_theme_stylebox_override("normal", style)
        cell.add_theme_stylebox_override("hover", style)
        cell.add_theme_stylebox_override("pressed", style)
        cell.add_theme_stylebox_override("disabled", style)
        cell.add_theme_color_override("font_color", Color("#fff7dc"))
        cell.add_theme_color_override("font_disabled_color", Color.WHITE)
