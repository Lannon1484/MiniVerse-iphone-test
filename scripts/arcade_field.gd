extends Control

var accent: Color = Color("#a78bfa")

func _draw() -> void:
    var w := size.x
    var h := size.y
    if w <= 1.0 or h <= 1.0:
        return
    draw_rect(Rect2(Vector2.ZERO, size), Color("#10152d"), true)
    var grid_color := Color(accent.r, accent.g, accent.b, 0.12)
    var step := 36.0
    # Keep the background grid stationary to avoid distracting flicker/motion.
    var offset := 0.0
    for x in range(-1, int(w / step) + 2):
        var px := float(x) * step + offset
        draw_line(Vector2(px, 0), Vector2(px, h), grid_color, 1.0)
    for y in range(-1, int(h / step) + 2):
        var py := float(y) * step + offset
        draw_line(Vector2(0, py), Vector2(w, py), grid_color, 1.0)
    for i in range(8):
        var px := fposmod(float(i) * 97.0 + 31.0, w)
        var py := fposmod(float(i) * 139.0 + 47.0, h)
        draw_circle(Vector2(px, py), 2.0, Color(accent.r, accent.g, accent.b, 0.45))
