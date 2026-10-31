extends RefCounted
## Shared, lightweight score feedback for the six Phase 15 completion games.
static func celebrate(label: Label, words: String, color: Color) -> void:
    if not is_instance_valid(label) or not label.is_inside_tree():
        return
    label.text = words
    label.add_theme_color_override("font_color", color)
    label.pivot_offset = label.size * 0.5
    label.scale = Vector2(1.16, 1.16)
    var tween := label.create_tween()
    tween.tween_property(label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
