extends RefCounted

# Shared press feedback for buttons across the hub and mini-games.
# A gentle tint gives immediate feedback without scaling controls or shifting layouts.
static func attach(button: Button, pressed_tint: Color = Color(0.82, 0.88, 1.0, 1.0)) -> void:
    if not is_instance_valid(button):
        return
    button.button_down.connect(func():
        if not is_instance_valid(button):
            return
        var tween := button.create_tween()
        tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(button, "modulate", pressed_tint, 0.06)
    )
    var restore := func():
        if not is_instance_valid(button):
            return
        var tween := button.create_tween()
        tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(button, "modulate", Color.WHITE, 0.10)
    button.button_up.connect(restore)
    button.mouse_exited.connect(restore)
