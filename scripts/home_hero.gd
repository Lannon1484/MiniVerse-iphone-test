extends Control

# Illustrated fantasy lobby hero with the original floating-islands / portal theme.
const HERO = preload("res://assets/lobby/fantasy_portal.png")

func _ready() -> void:
    custom_minimum_size = Vector2(0, 260)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    if size.x < 2.0 or size.y < 2.0:
        return
    draw_texture_rect(HERO, Rect2(Vector2.ZERO, size), false)
    draw_rect(Rect2(Vector2.ZERO, size), Color("#9edcff", 0.55), false, 2.0)
