extends Control
class_name PerfectStack
const StackPlayfield = preload("res://scripts/stack_playfield.gd")
signal finished(game_id: String, score: int, extra: Dictionary)
var score := 0
var running := true
var block_width := 220.0
var block_height := 30.0
var block_x := 0.0
var direction := 1.0
var speed := 220.0
var area
var score_label: Label
var hint: Label
var tower: Array[Rect2] = []
var colors := [Color("#fbbf24"),Color("#f9738f"),Color("#60a5fa"),Color("#86efac"),Color("#c4b5fd")]

func start_game():
    var root:=VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation",10); add_child(root)
    var title:=Label.new(); title.text="PERFECT STACK"; title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size",25); title.add_theme_color_override("font_color",Color("#f5f7ff")); root.add_child(title)
    var desc:=Label.new(); desc.text="Tap DROP to place each moving block. Keep your tower wide."; desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; desc.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; desc.add_theme_color_override("font_color",Color("#aeb8df")); root.add_child(desc)
    score_label=Label.new(); score_label.text="HEIGHT 0"; score_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; score_label.add_theme_font_size_override("font_size",20); score_label.add_theme_color_override("font_color",Color("#fbbf24")); root.add_child(score_label)
    area=StackPlayfield.new(); area.name="StackPlayfield"; area.size_flags_horizontal=Control.SIZE_EXPAND_FILL; area.size_flags_vertical=Control.SIZE_EXPAND_FILL; area.custom_minimum_size=Vector2(280, 400); area.clip_contents=true; root.add_child(area)
    hint=Label.new(); hint.text="Time your drop. Overhang is trimmed away."; hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; hint.add_theme_color_override("font_color",Color("#aeb8df")); root.add_child(hint)
    var buttons:=HBoxContainer.new(); root.add_child(buttons)
    var drop:=Button.new(); drop.text="DROP BLOCK"; drop.custom_minimum_size.y=60; drop.size_flags_horizontal=Control.SIZE_EXPAND_FILL; drop.add_theme_font_size_override("font_size",18); drop.add_theme_color_override("font_color",Color("#17172b")); drop.add_theme_stylebox_override("normal",_button_style(Color("#fbbf24"))); drop.add_theme_stylebox_override("hover",_button_style(Color("#fde68a"))); drop.pressed.connect(_drop); buttons.add_child(drop)
    var reset:=Button.new(); reset.text="RESTART"; reset.custom_minimum_size.y=60; reset.add_theme_stylebox_override("normal",_button_style(Color("#252b4c"))); reset.add_theme_stylebox_override("hover",_button_style(Color("#353d66"))); reset.pressed.connect(_restart); buttons.add_child(reset)
    # Wait for the container layout pass so area.size is valid before
    # calculating the base block position and width.
    _setup_after_layout()

func _setup_after_layout():
    # Container sizes are not reliable until at least one layout frame has run.
    await get_tree().process_frame
    await get_tree().process_frame
    _restart()

func _restart():
    if not is_instance_valid(area) or area.size.x <= 0.0:
        _setup_after_layout()
        return
    score = 0
    running = true
    # Use the actual playfield width for BOTH the moving block and the base.
    # A wider fallback width here can put the base outside the visible playfield.
    var play_width: float = area.size.x
    block_width = minf(220.0, play_width * 0.68)
    var centered_x: float = maxf(0.0, (play_width - block_width) / 2.0)
    block_x = centered_x
    direction = 1.0
    speed = 160.0
    tower.clear()
    tower.append(Rect2(centered_x, 0.0, block_width, block_height))
    score_label.text = "HEIGHT 0"
    hint.text = "The block moves automatically. Tap DROP BLOCK to stack it."
    _sync_playfield()

func _process(delta):
    if not running or not is_instance_valid(area): return
    block_x+=direction*speed*delta
    var max_x=maxf(0,area.size.x-block_width)
    if block_x<0: block_x=0; direction=1
    if block_x>max_x: block_x=max_x; direction=-1
    _sync_playfield()

func _sync_playfield():
    if not is_instance_valid(area):
        return
    area.tower = tower.duplicate()
    area.moving_x = block_x
    area.moving_width = block_width
    area.block_height = block_height
    area.running = running
    area.queue_redraw()

func _drop():
    if not running or tower.is_empty():
        hint.text = "Round ended. Press RESTART to play again."
        return
    if area.size.x <= 0.0:
        hint.text = "Preparing playfield… try DROP again in a moment."
        _setup_after_layout()
        return
    var previous: Rect2 = tower[tower.size() - 1]
    # Make the tutorial's first placement forgiving: it always lands centered,
    # so players can confirm the button and stacking visuals work before timing.
    if score == 0:
        block_x = previous.position.x
    # Every tower block stores its real horizontal position. Do not infer the
    # base position from a guessed width: that can create a false instant miss.
    var previous_x: float = previous.position.x
    var left: float = maxf(block_x, previous_x)
    var right: float = minf(block_x + block_width, previous_x + previous.size.x)
    var overlap: float = right - left
    if overlap <= 8.0:
        running = false
        hint.text = "Missed! Final height: %d — press RESTART to try again." % score
        finished.emit("stack", score, {"height": score})
        _sync_playfield()
        return
    block_x = left
    block_width = overlap
    tower.append(Rect2(block_x, 0.0, block_width, block_height))
    if is_instance_valid(area) and area.has_method("trigger_drop_effect"):
        area.trigger_drop_effect(block_x + block_width * 0.5, tower.size() - 1, colors[(tower.size() - 1) % colors.size()])
    score+=1; speed+=20
    score_label.text="HEIGHT %d"%score; hint.text="✦ BLOCK PLACED! Height %d — time your next drop." % score
    score_label.scale = Vector2(0.85, 0.85)
    var score_tween := create_tween()
    score_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    score_tween.tween_property(score_label, "scale", Vector2(1.12, 1.12), 0.10)
    score_tween.tween_property(score_label, "scale", Vector2.ONE, 0.14)
    if block_width<32 or score>=30:
        running=false; hint.text="Tower complete! Final height: %d"%score; finished.emit("stack",score,{"height":score})
    _sync_playfield()

func _button_style(c: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = c
    s.corner_radius_top_left = 14
    s.corner_radius_top_right = 14
    s.corner_radius_bottom_left = 14
    s.corner_radius_bottom_right = 14
    s.content_margin_left = 12
    s.content_margin_right = 12
    s.content_margin_top = 10
    s.content_margin_bottom = 10
    return s
