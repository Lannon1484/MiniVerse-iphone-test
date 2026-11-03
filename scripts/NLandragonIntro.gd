extends Control
## NLandragon Studios cinematic splash for Godot 4.x.
## Uses the studio's supplied emblem without altering its artwork.
signal intro_finished

@export var intro_duration: float = 4.4
@export var allow_skip: bool = true

const LOBBY_SCENE := "res://scenes/main.tscn"
const EMBLEM := preload("res://assets/branding/Dragon_Emblem.png")
const BACKGROUND := Color("#05070d")
const GOLD := Color("#e8bb65")

var _finished := false
var _closing := false
var _sequence: Tween
var _fade: ColorRect
var _emblem: TextureRect
var _wordmark: Label
var _subtitle: Label
var _skip: Button
var _logo_group: VBoxContainer

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_PASS
    _build_scene()
    resized.connect(_fit_layout)
    _fit_layout()
    _animate()

func _build_scene() -> void:
    var background := ColorRect.new()
    background.color = BACKGROUND
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var center := CenterContainer.new()
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    _logo_group = VBoxContainer.new()
    _logo_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _logo_group.alignment = BoxContainer.ALIGNMENT_CENTER
    _logo_group.add_theme_constant_override("separation", 10)
    _logo_group.modulate.a = 0.0
    center.add_child(_logo_group)

    _emblem = TextureRect.new()
    _emblem.texture = EMBLEM
    _emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _emblem.pivot_offset = Vector2.ZERO
    _logo_group.add_child(_emblem)

    _wordmark = Label.new()
    _wordmark.text = "NLANDRAGON"
    _wordmark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _wordmark.add_theme_color_override("font_color", Color("#eef0f4"))
    _wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _logo_group.add_child(_wordmark)

    _subtitle = Label.new()
    _subtitle.text = "S T U D I O S"
    _subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _subtitle.add_theme_color_override("font_color", GOLD)
    _subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _logo_group.add_child(_subtitle)

    # A subtle gold divider gives the studio lockup a finished look.
    var line_center := CenterContainer.new()
    line_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _logo_group.add_child(line_center)
    var line := ColorRect.new()
    line.color = Color("#9f743b")
    line.custom_minimum_size = Vector2(104, 2)
    line.mouse_filter = Control.MOUSE_FILTER_IGNORE
    line_center.add_child(line)

    _fade = ColorRect.new()
    _fade.color = BACKGROUND
    _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_fade)

    _skip = Button.new()
    _skip.text = "SKIP ›"
    _skip.focus_mode = Control.FOCUS_NONE
    _skip.visible = allow_skip
    _skip.anchor_left = 1.0
    _skip.anchor_right = 1.0
    _skip.offset_left = -136
    _skip.offset_right = -18
    _skip.offset_top = 18
    _skip.offset_bottom = 68
    _skip.add_theme_font_size_override("font_size", 18)
    _skip.add_theme_color_override("font_color", Color("#f1d59d"))
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#1d2130")
    style.border_color = Color("#8b6c40")
    style.set_border_width_all(1)
    style.set_corner_radius_all(12)
    _skip.add_theme_stylebox_override("normal", style)
    _skip.pressed.connect(_begin_exit)
    add_child(_skip)

func _fit_layout() -> void:
    if not is_instance_valid(_emblem):
        return
    var w: float = maxf(320.0, size.x)
    var h: float = maxf(480.0, size.y)
    var emblem_side: float = minf(410.0, minf(w * 0.68, h * 0.43))
    _emblem.custom_minimum_size = Vector2(emblem_side, emblem_side)
    _wordmark.add_theme_font_size_override("font_size", int(clampf(w * 0.052, 25.0, 39.0)))
    _subtitle.add_theme_font_size_override("font_size", int(clampf(w * 0.028, 16.0, 21.0)))

func _animate() -> void:
    # Entrance -> hold -> graceful fade to lobby. Total approx. 4.4 sec.
    _sequence = create_tween()
    _sequence.set_parallel(false)
    _sequence.tween_property(_fade, "modulate:a", 0.0, 0.75).set_trans(Tween.TRANS_SINE)
    _sequence.parallel().tween_property(_logo_group, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)
    _sequence.parallel().tween_property(_logo_group, "scale", Vector2.ONE, 1.15).from(Vector2(0.965, 0.965)).set_trans(Tween.TRANS_SINE)
    _sequence.tween_interval(maxf(0.0, intro_duration - 2.1))
    _sequence.tween_callback(_begin_exit)

func _unhandled_input(event: InputEvent) -> void:
    if not allow_skip or _closing:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        _begin_exit()
    # Mobile players can use the visible SKIP button. Avoid swallowing
    # incidental screen taps during initial loading.

func _begin_exit() -> void:
    if _closing or _finished:
        return
    _closing = true
    _skip.disabled = true
    _skip.visible = false
    if is_instance_valid(_sequence) and _sequence.is_running():
        _sequence.kill()
    var outro := create_tween()
    outro.tween_property(_fade, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
    outro.parallel().tween_property(_logo_group, "modulate:a", 0.0, 0.45)
    outro.tween_callback(_finish)

func _finish() -> void:
    if _finished:
        return
    _finished = true
    intro_finished.emit()
    get_tree().change_scene_to_file(LOBBY_SCENE)
