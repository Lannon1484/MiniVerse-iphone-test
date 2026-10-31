extends Control
class_name MemoryMatch

signal finished(game_id: String, score: int, extra: Dictionary)

const CARD_BACK = preload("res://assets/memory_symbols/card_back.png")
const SYMBOLS := ["star", "heart", "moon", "diamond", "flower", "sun", "rocket", "cloud"]
const PICTURES := {
    "star": preload("res://assets/memory_symbols/star.png"),
    "heart": preload("res://assets/memory_symbols/heart.png"),
    "moon": preload("res://assets/memory_symbols/moon.png"),
    "diamond": preload("res://assets/memory_symbols/diamond.png"),
    "flower": preload("res://assets/memory_symbols/flower.png"),
    "sun": preload("res://assets/memory_symbols/sun.png"),
    "rocket": preload("res://assets/memory_symbols/rocket.png"),
    "cloud": preload("res://assets/memory_symbols/cloud.png")
}
const FACE_COLORS := [Color("#f97373"), Color("#38bdf8"), Color("#fbbf24"), Color("#c084fc"), Color("#34d399"), Color("#fb923c"), Color("#f472b6"), Color("#a3e635")]
const CARD := Color("#40549a")
const ACCENT := Color("#34d399")

var cards: Array[String] = []
var buttons: Array[Button] = []
var matched: Array[bool] = []
var first_pick := -1
var lock_board := false
var moves := 0
var pairs_found := 0
var score := 0
var status_label: Label
var moves_label: Label
var score_label: Label
var grid: GridContainer
var running := true

func start_game() -> void:
    _build_ui()
    _new_round()

func _build_ui() -> void:
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 16)
    add_child(root)
    var title := Label.new()
    title.text = "MEMORY MATCH"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    title.add_theme_color_override("font_color", Color("#d1fae5"))
    root.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "Match the colorful pictures! Find all 8 pairs."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.add_theme_color_override("font_color", Color("#c4cbe8"))
    root.add_child(subtitle)
    var stats := HBoxContainer.new()
    stats.add_theme_constant_override("separation", 8)
    root.add_child(stats)
    moves_label = _stat_label("Moves: 0")
    score_label = _stat_label("Score: 0")
    stats.add_child(moves_label)
    stats.add_child(score_label)
    grid = GridContainer.new()
    grid.columns = 4
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    root.add_child(grid)
    status_label = Label.new()
    status_label.text = "Tap any card to reveal it."
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_color_override("font_color", ACCENT)
    root.add_child(status_label)
    var restart := Button.new()
    restart.text = "↻  SHUFFLE & RESTART"
    restart.custom_minimum_size.y = 68
    restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    restart.pressed.connect(_new_round)
    root.add_child(restart)

func _stat_label(value: String) -> Label:
    var label := Label.new()
    label.text = value
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 23)
    label.add_theme_color_override("font_color", Color("#f8fafc"))
    return label

func _new_round() -> void:
    cards.clear(); buttons.clear(); matched.clear()
    first_pick = -1; lock_board = false; moves = 0; pairs_found = 0; score = 0; running = true
    for symbol in SYMBOLS:
        cards.append(symbol); cards.append(symbol)
    cards.shuffle()
    for child in grid.get_children(): child.queue_free()
    for i in range(cards.size()):
        matched.append(false)
        var button := Button.new()
        button.text = ""
        button.icon = CARD_BACK
        button.expand_icon = true
        button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
        button.alignment = HORIZONTAL_ALIGNMENT_CENTER
        button.custom_minimum_size = Vector2(0, 125)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size", 54)
        button.add_theme_color_override("font_color", Color("#ffffff"))
        button.add_theme_color_override("font_hover_color", Color("#ffffff"))
        button.add_theme_color_override("font_pressed_color", Color("#ffffff"))
        button.add_theme_color_override("font_disabled_color", Color("#ffffff"))
        button.add_theme_stylebox_override("normal", _card_style(CARD))
        button.add_theme_stylebox_override("hover", _card_style(Color("#3b4b80")))
        button.add_theme_stylebox_override("pressed", _card_style(Color("#4f46e5")))
        button.pressed.connect(_pick.bind(i))
        grid.add_child(button); buttons.append(button)
    _refresh_stats()
    status_label.text = "Tap any card to reveal it."

func _card_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_width_left = 3
    style.border_width_right = 3
    style.border_width_top = 3
    style.border_width_bottom = 3
    style.border_color = Color("#e0e7ff")
    style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
    style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
    style.content_margin_top = 5; style.content_margin_bottom = 5
    return style

func _pick(index: int) -> void:
    if not running or lock_board or matched[index] or index == first_pick: return
    buttons[index].text = ""
    buttons[index].icon = PICTURES[cards[index]]
    var face_color: Color = FACE_COLORS[SYMBOLS.find(cards[index])]
    buttons[index].add_theme_stylebox_override("normal", _card_style(face_color))
    if first_pick == -1:
        first_pick = index
        return
    moves += 1
    if cards[first_pick] == cards[index]:
        matched[first_pick] = true; matched[index] = true
        buttons[first_pick].add_theme_stylebox_override("disabled", _card_style(Color("#167c64")))
        buttons[index].add_theme_stylebox_override("disabled", _card_style(Color("#167c64")))
        buttons[first_pick].disabled = true; buttons[index].disabled = true
        pairs_found += 1
        score += maxi(20, 100 - moves * 2)
        first_pick = -1
        status_label.text = "Match found! %d of 8 pairs." % pairs_found
        _refresh_stats()
        if pairs_found == 8:
            running = false
            score += maxi(0, 200 - moves * 5)
            _refresh_stats()
            status_label.text = "✨ All pairs found in %d moves!" % moves
            finished.emit("memory", score, {"moves": moves, "pairs": pairs_found})
    else:
        lock_board = true
        status_label.text = "Not a match — try again!"
        var old_pick := first_pick
        first_pick = -1
        _refresh_stats()
        await get_tree().create_timer(0.75).timeout
        if not is_inside_tree(): return
        if not matched[old_pick]:
            buttons[old_pick].text = ""
            buttons[old_pick].icon = CARD_BACK
            buttons[old_pick].add_theme_stylebox_override("normal", _card_style(CARD))
        if not matched[index]:
            buttons[index].text = ""
            buttons[index].icon = CARD_BACK
            buttons[index].add_theme_stylebox_override("normal", _card_style(CARD))
        lock_board = false

func _refresh_stats() -> void:
    moves_label.text = "Moves: %d" % moves
    score_label.text = "Score: %d" % score
