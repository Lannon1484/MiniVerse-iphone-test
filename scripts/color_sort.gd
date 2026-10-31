extends Control
class_name ColorSort

signal finished(game_id: String, score: int, extra: Dictionary)
signal gameplay_sound(kind: String)

const CAPACITY := 4
const Difficulty = preload("res://scripts/difficulty.gd")
var difficulty_level: int = 1
const PALETTE := [Color("#ff739f"), Color("#55d9ff"), Color("#ffd15b"), Color("#83e69b")]
const LABELS := ["PINK", "BLUE", "GOLD", "GREEN"]

var tubes: Array = []
var history: Array = []
var selected: int = -1
var moves: int = 0
var completed: bool = false
var animating: bool = false
var pour_effect: PourEffect
var buttons: Array[Button] = []
var status: Label
var move_label: Label
var tube_grid: GridContainer
var rng := RandomNumberGenerator.new()

func start_game() -> void:
    rng.randomize()
    _build_ui()
    _new_game()

func _build_ui() -> void:
    var layout := VBoxContainer.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout.add_theme_constant_override("separation", 15)
    add_child(layout)

    var title := Label.new()
    title.text = "COLOR SORT"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 29)
    title.add_theme_color_override("font_color", Color("#fff1a8"))
    layout.add_child(title)

    var instructions := Label.new()
    instructions.text = "Tap a tube, then another. Stack matching colors until every tube is sorted!"
    instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    instructions.add_theme_font_size_override("font_size", 16)
    instructions.add_theme_color_override("font_color", Color("#dce9ff"))
    layout.add_child(instructions)

    move_label = Label.new()
    move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    move_label.add_theme_font_size_override("font_size", 19)
    move_label.add_theme_color_override("font_color", Color("#ffe08a"))
    layout.add_child(move_label)

    tube_grid = GridContainer.new()
    tube_grid.columns = 3
    tube_grid.add_theme_constant_override("h_separation", 9)
    tube_grid.add_theme_constant_override("v_separation", 14)
    tube_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    layout.add_child(tube_grid)
    for i in range(6):
        var button := Button.new()
        button.custom_minimum_size = Vector2(0, 178)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.add_theme_stylebox_override("normal", _tube_style(false))
        button.add_theme_stylebox_override("hover", _tube_style(true))
        button.add_theme_stylebox_override("pressed", _tube_style(true))
        button.pressed.connect(_pick.bind(i))
        tube_grid.add_child(button)
        buttons.append(button)

    status = Label.new()
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status.add_theme_font_size_override("font_size", 17)
    status.add_theme_color_override("font_color", Color("#9df5d2"))
    layout.add_child(status)

    var undo := Button.new()
    undo.text = "UNDO LAST MOVE"
    undo.custom_minimum_size.y = 54
    undo.pressed.connect(_undo)
    layout.add_child(undo)

    var reset := Button.new()
    reset.text = "NEW PUZZLE"
    reset.custom_minimum_size.y = 54
    reset.pressed.connect(_new_game)
    layout.add_child(reset)

func _tube_style(highlight: bool) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#304a87") if highlight else Color("#172d60")
    style.border_color = Color("#ffe08a") if highlight else Color("#76dfff")
    style.set_border_width_all(3)
    style.set_corner_radius_all(18)
    style.content_margin_left = 3
    style.content_margin_right = 3
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style

func _new_game() -> void:
    difficulty_level = Difficulty.level("sort")
    selected = -1
    moves = 0
    completed = false
    animating = false
    if is_instance_valid(pour_effect):
        pour_effect.queue_free()
        pour_effect = null
    history.clear()
    tubes.clear()
    var pieces: Array[int] = []
    for color_id in range(4):
        for j in range(CAPACITY):
            pieces.append(color_id)
    pieces.shuffle()
    if difficulty_level <= 2:
        # Two already-sorted colors make the first puzzle easier to understand.
        pieces = [0, 0, 0, 0, 1, 1, 1, 1] + [2, 3, 2, 3, 2, 3, 2, 3]
    elif difficulty_level <= 4:
        pieces = [0, 0, 0, 0] + pieces.slice(4)
    for i in range(4):
        var tube: Array[int] = []
        for j in range(CAPACITY):
            tube.append(pieces[i * CAPACITY + j])
        tubes.append(tube)
    tubes.append([])
    tubes.append([])
    status.text = "Sort the colors! Select a tube to begin."
    _refresh()

func _pick(index: int) -> void:
    if completed or animating:
        return
    if selected == -1:
        if tubes[index].is_empty():
            status.text = "Choose a tube containing colors first."
            return
        selected = index
        status.text = "Now tap the tube you want to pour into."
        _refresh()
        return
    if index == selected:
        selected = -1
        status.text = "Selection cleared."
        _refresh()
        return
    var from: Array = tubes[selected]
    var to: Array = tubes[index]
    if to.size() >= CAPACITY or (not to.is_empty() and to.back() != from.back()):
        status.text = "You can only pour onto the same color or into an empty tube."
        selected = -1
        _refresh()
        return
    history.append(_snapshot())
    var source_index: int = selected
    var moved_color: int = from.back()
    while not from.is_empty() and from.back() == moved_color and to.size() < CAPACITY:
        to.append(from.pop_back())
    moves += 1
    gameplay_sound.emit("pour")
    selected = -1
    animating = true
    status.text = "Pouring..."
    # Leave the source and destination unchanged visually until the liquid travels.
    _play_pour_effect(source_index, index, moved_color)
    await get_tree().create_timer(0.52).timeout
    if not is_inside_tree():
        return
    animating = false
    if is_instance_valid(pour_effect):
        pour_effect.queue_free()
        pour_effect = null
    status.text = "Nice pour! Keep sorting."
    _refresh()
    if _solved():
        completed = true
        var score: int = maxi(100, 1200 - moves * 20)
        status.text = "PUZZLE COMPLETE! Score: %d" % score
        finished.emit("sort", score, {"moves": moves})

func _play_pour_effect(source_index: int, target_index: int, color_id: int) -> void:
    pour_effect = PourEffect.new()
    pour_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    pour_effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(pour_effect)
    # Coordinates are local to this game's root Control, not the button.
    var source_rect: Rect2 = buttons[source_index].get_global_rect()
    var target_rect: Rect2 = buttons[target_index].get_global_rect()
    pour_effect.start_point = source_rect.get_center() - global_position
    pour_effect.end_point = target_rect.get_center() - global_position
    pour_effect.liquid_color = PALETTE[color_id]
    var tween := create_tween()
    tween.tween_property(pour_effect, "progress", 1.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _snapshot() -> Array:
    var copy: Array = []
    for tube in tubes:
        copy.append(tube.duplicate())
    return copy

func _undo() -> void:
    if history.is_empty() or completed or animating:
        status.text = "No move to undo."
        return
    tubes = history.pop_back()
    moves = maxi(0, moves - 1)
    selected = -1
    status.text = "Last move undone."
    _refresh()

func _solved() -> bool:
    for tube in tubes:
        if tube.is_empty():
            continue
        if tube.size() != CAPACITY:
            return false
        for color_id in tube:
            if color_id != tube[0]:
                return false
    return true

func _refresh() -> void:
    move_label.text = "MOVES: %d" % moves
    for i in range(buttons.size()):
        var button := buttons[i]
        button.add_theme_stylebox_override("normal", _tube_style(i == selected))
        button.text = ""
        # An illustrated liquid-filled glass tube, drawn by a child Control.
        for child in button.get_children():
            child.queue_free()
        var art := TubeArt.new()
        art.contents = tubes[i].duplicate()
        art.colors = PALETTE
        art.mouse_filter = Control.MOUSE_FILTER_IGNORE
        art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        button.add_child(art)

class TubeArt extends Control:
    var contents: Array = []
    var colors: Array = []

    func _draw() -> void:
        var w: float = size.x
        var h: float = size.y
        if w < 12 or h < 12:
            return
        var tube_w: float = minf(w * 0.70, 72.0)
        var x: float = (w - tube_w) * 0.5
        var top: float = 16.0
        var bottom: float = h - 15.0
        var inner := Rect2(x + 5, top + 8, tube_w - 10, bottom - top - 17)
        draw_rect(inner, Color("#071738", 0.85), true)
        var slot_h: float = inner.size.y / 4.0
        for i in range(contents.size()):
            var color_id: int = int(contents[i])
            var y: float = inner.end.y - float(i + 1) * slot_h
            var liquid := Rect2(inner.position.x, y, inner.size.x, slot_h + 0.5)
            draw_rect(liquid, colors[color_id], true)
            draw_rect(Rect2(liquid.position + Vector2(3, 2), Vector2(liquid.size.x - 6, 4)), Color("#ffffff", 0.32), true)
        draw_line(Vector2(x + 4, top + 6), Vector2(x + 4, bottom - 12), Color("#b4f1ff", 0.9), 5.0)
        draw_line(Vector2(x + tube_w - 4, top + 6), Vector2(x + tube_w - 4, bottom - 12), Color("#b4f1ff", 0.9), 5.0)
        draw_arc(Vector2(x + tube_w * 0.5, bottom - 12), tube_w * 0.5 - 4, 0, PI, 24, Color("#b4f1ff", 0.9), 5.0)
        draw_line(Vector2(x, top + 6), Vector2(x + tube_w, top + 6), Color("#ffffff", 0.95), 5.0)

# A colorful animated liquid droplet that arcs between tubes.
class PourEffect extends Control:
    var start_point: Vector2 = Vector2.ZERO
    var end_point: Vector2 = Vector2.ZERO
    var liquid_color: Color = Color.WHITE
    var progress: float = 0.0:
        set(value):
            progress = value
            queue_redraw()

    func _draw() -> void:
        if progress <= 0.0 or progress >= 1.0:
            return
        var midpoint: Vector2 = (start_point + end_point) * 0.5 + Vector2(0, -72)
        var t: float = progress
        var inv: float = 1.0 - t
        var pos: Vector2 = inv * inv * start_point + 2.0 * inv * t * midpoint + t * t * end_point
        draw_circle(pos, 17.0, Color(liquid_color.r, liquid_color.g, liquid_color.b, 0.25))
        draw_circle(pos, 10.0, liquid_color)
        draw_circle(pos + Vector2(-3, -3), 3.5, Color("#ffffff", 0.9))
