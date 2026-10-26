extends Control

var tower: Array[Rect2] = []
var moving_x: float = 0.0
var moving_width: float = 220.0
var block_height: float = 30.0
var running: bool = true
var impact_time: float = 0.0
var impact_position: Vector2 = Vector2.ZERO
var impact_color: Color = Color("#fbbf24")
var colors: Array[Color] = [Color("#fbbf24"), Color("#f9738f"), Color("#60a5fa"), Color("#86efac"), Color("#c4b5fd")]

func trigger_drop_effect(block_x: float, block_level: int, tint: Color) -> void:
    impact_position = Vector2(block_x, size.y - block_height - 10.0 - float(block_level) * block_height + block_height * 0.5)
    impact_color = tint
    impact_time = 0.30
    queue_redraw()

func _process(delta: float) -> void:
    if impact_time > 0.0:
        impact_time = maxf(0.0, impact_time - delta)
        queue_redraw()

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    if w <= 1.0 or h <= 1.0:
        return
    # A bright floating-island sky, matching the new mobile art direction.
    draw_rect(Rect2(Vector2.ZERO, size), Color("#10295c"), true)
    draw_circle(Vector2(w * 0.18, h * 0.18), minf(w, h) * 0.42, Color("#38bdf8", 0.18))
    draw_circle(Vector2(w * 0.88, h * 0.36), minf(w, h) * 0.32, Color("#a78bfa", 0.16))
    # Soft clouds in the distance.
    for i in range(5):
        var cx: float = fposmod(float(i) * 91.0 + 30.0, w)
        var cy: float = 36.0 + float(i % 3) * 43.0
        draw_circle(Vector2(cx, cy), 19.0, Color("#dbeafe", 0.10))
        draw_circle(Vector2(cx + 17.0, cy + 4.0), 14.0, Color("#dbeafe", 0.08))
    for i in range(22):
        var sx: float = fposmod(float(i) * 67.0 + 14.0, w)
        var sy: float = fposmod(float(i) * 97.0 + 21.0, h * 0.68)
        draw_circle(Vector2(sx, sy), 1.5 if i % 4 else 2.5, Color("#ffffff", 0.38))
    # Floating island silhouettes near the lower corners.
    _draw_island(Vector2(w * 0.14, h * 0.73), 0.72)
    _draw_island(Vector2(w * 0.87, h * 0.59), 0.48)
    # Ground glow and a subtle central guide.
    draw_rect(Rect2(Vector2(0, h * 0.78), Vector2(w, h * 0.22)), Color("#071a3a", 0.30), true)
    draw_line(Vector2(w * 0.5, 0), Vector2(w * 0.5, h), Color("#bae6fd", 0.10), 1.0)
    for i in range(tower.size()):
        var r: Rect2 = tower[i]
        var x: float = (w - r.size.x) / 2.0 if i == 0 else r.position.x
        var y: float = h - block_height - 28.0 - float(i) * block_height
        _draw_block(Rect2(Vector2(x, y), Vector2(r.size.x, block_height)), colors[i % colors.size()])
    if running and not tower.is_empty():
        var y: float = h - block_height - 28.0 - float(tower.size()) * block_height
        var moving := Rect2(Vector2(moving_x, y), Vector2(moving_width, block_height))
        draw_rect(moving.grow(8.0), Color("#67e8f9", 0.18), true)
        _draw_block(moving, colors[tower.size() % colors.size()])
    # Stone platform under the tower.
    var base_y: float = h - 25.0
    var platform := PackedVector2Array([Vector2(w * 0.16, base_y - 8), Vector2(w * 0.5, base_y - 22), Vector2(w * 0.84, base_y - 8), Vector2(w * 0.5, base_y + 5)])
    draw_colored_polygon(platform, Color("#94a3b8"))
    draw_polyline(PackedVector2Array([platform[0], platform[1], platform[2]]), Color("#e0f2fe"), 2.0, true)
    if impact_time > 0.0:
        var progress: float = 1.0 - impact_time / 0.30
        var ring_radius: float = 10.0 + progress * 48.0
        var alpha: float = (1.0 - progress) * 0.85
        draw_arc(impact_position, ring_radius, 0.0, TAU, 36, Color(impact_color.r, impact_color.g, impact_color.b, alpha), 3.0, true)
        draw_circle(impact_position, 4.0 + (1.0 - progress) * 5.0, Color(impact_color.r, impact_color.g, impact_color.b, alpha))
        for i in range(8):
            var angle: float = float(i) * TAU / 8.0
            var travel: float = 14.0 + progress * 32.0
            var particle_pos: Vector2 = impact_position + Vector2(cos(angle), sin(angle)) * travel
            draw_circle(particle_pos, 2.4 * (1.0 - progress), Color(impact_color.r, impact_color.g, impact_color.b, alpha))

func _draw_block(r: Rect2, c: Color) -> void:
    var depth: float = minf(10.0, r.size.y * 0.34)
    var top := PackedVector2Array([r.position + Vector2(0, depth), r.position + Vector2(depth, 0), r.position + Vector2(r.size.x, 0), r.position + Vector2(r.size.x - depth, depth)])
    var front := PackedVector2Array([r.position + Vector2(0, depth), r.position + Vector2(r.size.x - depth, depth), r.position + Vector2(r.size.x - depth, r.size.y), r.position + Vector2(0, r.size.y)])
    var side := PackedVector2Array([r.position + Vector2(r.size.x - depth, depth), r.position + Vector2(r.size.x, 0), r.position + Vector2(r.size.x, r.size.y - depth), r.position + Vector2(r.size.x - depth, r.size.y)])
    draw_rect(r.grow(5.0), Color(c.r, c.g, c.b, 0.12), true)
    draw_colored_polygon(front, c)
    draw_colored_polygon(side, c.darkened(0.28))
    draw_colored_polygon(top, c.lightened(0.32))
    draw_polyline(PackedVector2Array([top[0], top[1], top[2], top[3], top[0]]), Color("#ffffff", 0.78), 1.5, true)
    draw_line(front[0], front[1], Color("#ffffff", 0.40), 1.0)

func _draw_island(center: Vector2, scale_factor: float) -> void:
    var half_w: float = 34.0 * scale_factor
    var half_h: float = 13.0 * scale_factor
    var top := PackedVector2Array([center + Vector2(-half_w, 0), center + Vector2(0, -half_h), center + Vector2(half_w, 0), center + Vector2(0, half_h)])
    draw_colored_polygon(top, Color("#4ade80", 0.62))
    var underside := PackedVector2Array([center + Vector2(-half_w, 0), center + Vector2(0, half_h), center + Vector2(half_w, 0), center + Vector2(half_w * 0.36, half_h * 2.5), center + Vector2(-half_w * 0.24, half_h * 2.0)])
    draw_colored_polygon(underside, Color("#475569", 0.72))
    draw_line(top[0], top[1], Color("#bbf7d0", 0.75), 1.5)
    draw_line(top[1], top[2], Color("#bbf7d0", 0.75), 1.5)
