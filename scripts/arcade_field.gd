extends Control

var accent: Color = Color("#22d3ee")

func _draw() -> void:
    var w := size.x
    var h := size.y
    if w <= 1.0 or h <= 1.0:
        return
    # Deep jewel-toned arcade sky, with soft ambient light pools.
    draw_rect(Rect2(Vector2.ZERO, size), Color("#07132f"), true)
    draw_circle(Vector2(w * 0.18, h * 0.18), minf(w, h) * 0.42, Color("#164e9a", 0.22))
    draw_circle(Vector2(w * 0.82, h * 0.52), minf(w, h) * 0.36, Color("#86198f", 0.16))
    draw_circle(Vector2(w * 0.50, h * 0.88), minf(w, h) * 0.30, Color("#0891b2", 0.12))
    # Small, fixed stars keep the background lively without distracting motion.
    for i in range(34):
        var px := fposmod(float(i) * 73.0 + 19.0, w)
        var py := fposmod(float(i) * 127.0 + 31.0, h)
        var radius := 1.0 if i % 4 != 0 else 2.0
        draw_circle(Vector2(px, py), radius, Color("#dbeafe", 0.42 if i % 3 == 0 else 0.22))
    for i in range(7):
        var px := fposmod(float(i) * 109.0 + 45.0, w)
        var py := fposmod(float(i) * 83.0 + 70.0, h)
        var c: Color = [Color("#22d3ee"), Color("#f472b6"), Color("#a78bfa")][i % 3]
        draw_line(Vector2(px - 4, py), Vector2(px + 4, py), Color(c, 0.65), 1.5)
        draw_line(Vector2(px, py - 4), Vector2(px, py + 4), Color(c, 0.65), 1.5)
