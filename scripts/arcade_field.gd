extends Control

var accent: Color = Color("#a78bfa")

func _draw() -> void:
    var w := size.x
    var h := size.y
    if w <= 1.0 or h <= 1.0:
        return
    # Illustrated candy-sky playfield rather than the old technical grid.
    draw_rect(Rect2(Vector2.ZERO, size), Color("#6b91e9"), true)
    draw_rect(Rect2(Vector2(0, h * 0.62), Vector2(w, h * 0.38)), Color("#9e91ef"), true)
    draw_circle(Vector2(w * 0.80, h * 0.18), 43.0, Color("#ffefb4", 0.88))
    for i in range(7):
        var cx: float = fposmod(35.0 + float(i) * 151.0, w)
        var cy: float = h * (0.14 + float(i % 4) * 0.18)
        draw_circle(Vector2(cx, cy), 19.0, Color("#ffffff", 0.58))
        draw_circle(Vector2(cx + 18.0, cy + 4.0), 15.0, Color("#ffffff", 0.58))
        draw_circle(Vector2(cx - 17.0, cy + 6.0), 13.0, Color("#ffffff", 0.58))
    for i in range(11):
        var px: float = fposmod(float(i) * 97.0 + 31.0, w)
        var py: float = fposmod(float(i) * 139.0 + 47.0, h)
        draw_circle(Vector2(px, py), 3.0, Color("#fff6cc", 0.78))
