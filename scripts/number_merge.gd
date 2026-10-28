extends Control
class_name NumberMerge
signal finished(game_id: String, score: int, extra: Dictionary)
const N := 4
var board: Array = []
var score := 0
var moves := 0
var selected := Vector2i(-1,-1)
var rng := RandomNumberGenerator.new()
var grid: GridContainer
var score_label: Label
var moves_label: Label
var status: Label
var running := true

func start_game():
    rng.randomize()
    _new_board()

func _new_board():
    board.clear(); score=0; moves=0; selected=Vector2i(-1,-1); running=true
    # Start with a full 4x4 board rather than only two tiles.
    # Weighted values keep early moves approachable, and the top-left pair
    # guarantees that at least one merge is available on every new board.
    for y in range(N):
        var row := []
        for x in range(N):
            var roll := rng.randi_range(0, 5)
            var value := 2
            if roll >= 4:
                value = 4
            elif roll == 3:
                value = 8
            row.append(value)
        board.append(row)
    board[0][0] = 2
    board[0][1] = 2
    for c in get_children(): c.queue_free()
    custom_minimum_size = Vector2(0, 820)
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation",10)
    add_child(root)
    var title := Label.new()
    title.text="NUMBER MERGE"; title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size",25); title.add_theme_color_override("font_color",Color("#93c5fd"))
    root.add_child(title)
    var desc := Label.new()
    desc.text="Tap a tile, then an adjacent matching tile to merge."
    desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; desc.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; desc.add_theme_color_override("font_color",Color("#aeb8df"))
    root.add_child(desc)
    var stats := HBoxContainer.new(); root.add_child(stats)
    score_label=Label.new(); score_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; score_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    moves_label=Label.new(); moves_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; moves_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    score_label.add_theme_color_override("font_color",Color("#fcd34d")); moves_label.add_theme_color_override("font_color",Color("#67e8f9"))
    stats.add_child(score_label); stats.add_child(moves_label)
    var board_panel := PanelContainer.new()
    board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    board_panel.add_theme_stylebox_override("panel", _tile_style(Color("#1a2040")))
    root.add_child(board_panel)
    grid=GridContainer.new(); grid.columns=N; grid.size_flags_vertical=Control.SIZE_EXPAND_FILL; grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation",8); grid.add_theme_constant_override("v_separation",8); board_panel.add_child(grid)
    status=Label.new(); status.text="Select two adjacent matching tiles."; status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; status.add_theme_color_override("font_color",Color("#aeb8df"))
    root.add_child(status)
    var buttons := HBoxContainer.new(); root.add_child(buttons)
    var reset := Button.new(); reset.text="NEW BOARD"; reset.size_flags_horizontal=Control.SIZE_EXPAND_FILL; reset.pressed.connect(_new_board); buttons.add_child(reset)
    var help := Button.new(); help.text="HOW TO PLAY"; help.size_flags_horizontal=Control.SIZE_EXPAND_FILL; help.pressed.connect(func(): status.text="Tiles must match and share an edge. Merging doubles the tile.")
    buttons.add_child(help)
    _refresh()

func _add_tile():
    var spots: Array[Vector2i]=[]
    for y in range(N):
        for x in range(N):
            if board[y][x]==0: spots.append(Vector2i(x,y))
    if spots.is_empty(): return
    var p=spots[rng.randi_range(0,spots.size()-1)]
    board[p.y][p.x]=2 if rng.randf()<0.9 else 4

func _refresh():
    if not is_instance_valid(grid): return
    for c in grid.get_children(): c.queue_free()
    for y in range(N):
        for x in range(N):
            var v: int=board[y][x]
            var b:=Button.new(); b.text="" if v==0 else str(v); b.custom_minimum_size=Vector2(50,70)
            b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; b.size_flags_vertical=Control.SIZE_EXPAND_FILL
            b.add_theme_font_size_override("font_size",22)
            b.add_theme_color_override("font_color",Color("#17172b"))
            var tile_color := _tile_color(v)
            if selected == Vector2i(x,y): tile_color = Color("#fbbf24")
            b.add_theme_stylebox_override("normal",_tile_style(tile_color))
            b.add_theme_stylebox_override("hover",_tile_style(tile_color.lightened(0.12)))
            b.add_theme_stylebox_override("pressed",_tile_style(tile_color.darkened(0.08)))
            b.pressed.connect(_press.bind(x,y)); grid.add_child(b)
            b.pivot_offset = Vector2(35, 35)
            b.scale = Vector2(0.88, 0.88)
            var tile_tween := create_tween()
            tile_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
            tile_tween.tween_property(b, "scale", Vector2.ONE, 0.16)
    score_label.text="SCORE %d"%score; moves_label.text="MOVES %d"%moves

func _tile_color(v: int) -> Color:
    match v:
        0: return Color("#292e4c")
        2: return Color("#dbeafe")
        4: return Color("#bfdbfe")
        8: return Color("#93c5fd")
        16: return Color("#60a5fa")
        32: return Color("#a5b4fc")
        64: return Color("#c4b5fd")
        128: return Color("#f0abfc")
        256: return Color("#f9a8d4")
        512: return Color("#fda4af")
        1024: return Color("#fdba74")
        _: return Color("#fcd34d")

func _tile_style(c: Color) -> StyleBoxFlat:
    var s:=StyleBoxFlat.new(); s.bg_color=c; s.corner_radius_top_left=12; s.corner_radius_top_right=12; s.corner_radius_bottom_left=12; s.corner_radius_bottom_right=12
    s.content_margin_left=5; s.content_margin_right=5; s.content_margin_top=5; s.content_margin_bottom=5
    s.border_width_left=1; s.border_width_right=1; s.border_width_top=1; s.border_width_bottom=1; s.border_color=Color("#ffffff",0.18)
    return s

func _press(x: int,y: int):
    if not running: return
    var p:=Vector2i(x,y)
    if board[y][x]==0:
        status.text="That space is empty."; return
    if selected.x<0:
        selected=p; status.text="Selected %d. Now tap an adjacent tile with the same number." % board[y][x]; _refresh(); return
    if p==selected:
        selected=Vector2i(-1,-1); status.text="Selection cleared."; _refresh(); return
    var adjacent=abs(p.x-selected.x)+abs(p.y-selected.y)==1
    if adjacent and board[y][x]==board[selected.y][selected.x]:
        var value: int=board[y][x]*2
        board[y][x]=value; board[selected.y][selected.x]=0; score+=value; moves+=1; selected=Vector2i(-1,-1); _add_tile()
        status.text="✦ NICE MERGE! +%d ✦" % value
        status.add_theme_color_override("font_color", Color("#fef08a"))
        status.scale = Vector2(0.9, 0.9)
        var merge_tween := create_tween()
        merge_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        merge_tween.tween_property(status, "scale", Vector2(1.06, 1.06), 0.10)
        merge_tween.tween_property(status, "scale", Vector2.ONE, 0.14)
    else:
        selected=p; status.text="Tiles must match and share an edge."
    _refresh()
    if not (adjacent and board[y][x] != 0):
        status.add_theme_color_override("font_color", Color("#aeb8df"))
    if _full() and not _has_merge():
        running=false; status.text="Board full! Final score: %d"%score
        finished.emit("merge",score,{"moves":moves})

func _full() -> bool:
    for row in board:
        for v in row:
            if v==0: return false
    return true

func _has_merge() -> bool:
    for y in range(N):
        for x in range(N):
            if x+1<N and board[y][x]==board[y][x+1]: return true
            if y+1<N and board[y][x]==board[y+1][x]: return true
    return false
