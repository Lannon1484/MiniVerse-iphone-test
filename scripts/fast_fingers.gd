extends Control
class_name FastFingers
const ArcadeField = preload("res://scripts/arcade_field.gd")
const TARGET_PICTURE = preload("res://assets/classic_games/fast_target.png")
signal finished(game_id: String, score: int, extra: Dictionary)
var time_left := 20.0
var score := 0
var combo := 0
var running := false
var area: Control
var target: Button
var timer_label: Label
var score_label: Label
var combo_label: Label
var rng := RandomNumberGenerator.new()

func start_game():
    rng.randomize()
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 12)
    add_child(root)
    var title := Label.new()
    title.text = "FAST FINGERS"
    title.add_theme_color_override("font_color", Color("#fda4af"))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 25)
    root.add_child(title)
    var desc := Label.new()
    desc.text = "Tap as many targets as you can in 20 seconds."
    desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    desc.add_theme_color_override("font_color", Color("#aeb8df"))
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(desc)
    var stats := HBoxContainer.new()
    root.add_child(stats)
    timer_label = _stat("TIME 20")
    score_label = _stat("SCORE 0")
    combo_label = _stat("COMBO 0")
    stats.add_child(timer_label); stats.add_child(score_label); stats.add_child(combo_label)
    area = ArcadeField.new()
    area.accent = Color("#f9738f")
    area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    area.size_flags_vertical = Control.SIZE_EXPAND_FILL
    area.custom_minimum_size.y = 450
    area.clip_contents = true
    root.add_child(area)
    var hint := Label.new()
    hint.text = "Consecutive hits increase your combo."
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_color_override("font_color", Color("#aeb8df"))
    root.add_child(hint)
    running = true
    _spawn()

func _stat(t: String) -> Label:
    var l := Label.new()
    l.text = t
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", 15)
    l.add_theme_color_override("font_color", Color("#e8ecff"))
    return l

func _process(delta):
    if is_instance_valid(area): area.queue_redraw()
    if not running: return
    time_left -= delta
    timer_label.text = "TIME %02d" % ceili(maxf(time_left,0))
    if time_left <= 0:
        running = false
        if is_instance_valid(target): target.hide()
        finished.emit("fast",score,{"combo":combo})

func _spawn():
    if is_instance_valid(target): target.queue_free()
    target = Button.new()
    target.text = ""
    target.icon = TARGET_PICTURE
    target.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    target.expand_icon = true
    target.custom_minimum_size = Vector2(92,92)
    target.add_theme_font_size_override("font_size",32)
    target.add_theme_color_override("font_color", Color("#17172b"))
    target.add_theme_stylebox_override("hover", _round(Color("#ffffff")))
    target.add_theme_stylebox_override("pressed", _round(Color("#e0e7ff")))
    target.add_theme_stylebox_override("normal",_round(Color("#33376b")))
    area.add_child(target)
    target.position = Vector2(rng.randf_range(0,maxf(0,area.size.x-92)),rng.randf_range(0,maxf(0,area.size.y-92)))
    target.pivot_offset = Vector2(46, 46)
    target.scale = Vector2(0.55, 0.55)
    var appear := create_tween()
    appear.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    appear.tween_property(target, "scale", Vector2.ONE, 0.18)
    target.pressed.connect(_hit)

func _round(c: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = c
    s.corner_radius_top_left=40; s.corner_radius_top_right=40; s.corner_radius_bottom_left=40; s.corner_radius_bottom_right=40
    return s

func _hit():
    if not running: return
    var hit_position: Vector2 = target.position + target.size * 0.5
    _floating_score(hit_position, 10 + mini(combo, 10) * 2)
    combo += 1
    score += 10 + mini(combo-1,10)*2
    score_label.text = "SCORE %d" % score
    combo_label.text = "COMBO %d" % combo
    var pulse := create_tween()
    pulse.tween_property(score_label, "scale", Vector2(1.18, 1.18), 0.08)
    pulse.tween_property(score_label, "scale", Vector2.ONE, 0.14)
    _spawn()

func _floating_score(at: Vector2, points: int) -> void:
    var popup := Label.new()
    popup.text = "+%d" % points
    popup.position = at - Vector2(22, 24)
    popup.add_theme_font_size_override("font_size", 22)
    popup.add_theme_color_override("font_color", Color("#fef08a"))
    popup.add_theme_color_override("font_shadow_color", Color("#0e1024", 0.8))
    popup.add_theme_constant_override("shadow_offset_x", 2)
    popup.add_theme_constant_override("shadow_offset_y", 2)
    popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
    area.add_child(popup)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(popup, "position", popup.position - Vector2(0, 42), 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    tween.tween_property(popup, "modulate:a", 0.0, 0.48)
    tween.chain().tween_callback(popup.queue_free)
