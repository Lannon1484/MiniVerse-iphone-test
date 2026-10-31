extends Control

# Scale to the available width without cropping or stretching the illustration.
const HERO = preload("res://assets/lobby/fantasy_portal.png")

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(0, 1)
    resized.connect(_resize_to_image_ratio)
    call_deferred("_resize_to_image_ratio")

func _resize_to_image_ratio() -> void:
    if size.x <= 1.0:
        return
    var correct_height: float = size.x * float(HERO.get_height()) / float(HERO.get_width())
    if absf(custom_minimum_size.y - correct_height) > 0.5:
        custom_minimum_size.y = correct_height
    queue_redraw()

func _draw() -> void:
    if size.x < 2.0 or size.y < 2.0:
        return
    # Image uses the full available width; its height follows its real aspect ratio.
    draw_texture_rect(HERO, Rect2(Vector2.ZERO, size), false)
