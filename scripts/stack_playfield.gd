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
    draw_rect(Rect2(Vector2.ZERO, size), Color("#0c1228"), true)
    # Soft horizon glow and a subtle technical grid make the playfield feel arcade-like.
    draw_rect(Rect2(Vector2(0, h * 0.72), Vector2(w, h * 0.28)), Color("#18254a", 0.42), true)
    for i in range(9):
        var y: float = float(i) * h / 8.0
        draw_line(Vector2(0, y), Vector2(w, y), Color("#344064", 0.42), 1.0)
    for i in range(11):
        var x: float = float(i) * w / 10.0
        draw_line(Vector2(x, 0), Vector2(x, h), Color("#283456", 0.28), 1.0)
    draw_line(Vector2(w * 0.5, 0), Vector2(w * 0.5, h), Color("#67e8f9", 0.2), 1.0)
    for i in range(tower.size()):
        var r: Rect2 = tower[i]
        var x: float = (w - r.size.x) / 2.0 if i == 0 else r.position.x
        var y: float = h - block_height - 10.0 - float(i) * block_height
        var drawn := Rect2(Vector2(x, y), Vector2(r.size.x, block_height))
        draw_rect(drawn.grow(3.0), Color(colors[i % colors.size()].r, colors[i % colors.size()].g, colors[i % colors.size()].b, 0.12), true)
        draw_rect(drawn, colors[i % colors.size()], true)
        draw_rect(Rect2(drawn.position, Vector2(drawn.size.x, 4.0)), Color("#ffffff", 0.58), true)
        draw_rect(drawn, Color("#ffffff", 0.82), false, 2.0)
    if running and not tower.is_empty():
        var y: float = h - block_height - 10.0 - float(tower.size()) * block_height
        var moving := Rect2(Vector2(moving_x, y), Vector2(moving_width, block_height))
        draw_rect(moving.grow(5.0), Color("#67e8f9", 0.13), true)
        draw_rect(moving, colors[tower.size() % colors.size()], true)
        draw_rect(Rect2(moving.position, Vector2(moving.size.x, 4.0)), Color("#ffffff", 0.72), true)
        draw_rect(moving, Color("#ffffff", 0.95), false, 2.0)
    if impact_time > 0.0:
        var progress: float = 1.0 - impact_time / 0.30
        var ring_radius: float = 10.0 + progress * 48.0
        var alpha: float = (1.0 - progress) * 0.85
        draw_arc(impact_position, ring_radius, 0.0, TAU, 36, Color(impact_color.r, impact_color.g, impact_color.b, alpha), 3.0, true)
        draw_circle(impact_position, 4.0 + (1.0 - progress) * 5.0, Color(impact_color.r, impact_color.g, impact_color.b, alpha))
        for i in range(6):
            var angle: float = float(i) * TAU / 6.0
            var travel: float = 14.0 + progress * 28.0
            var particle_pos: Vector2 = impact_position + Vector2(cos(angle), sin(angle)) * travel
            draw_circle(particle_pos, 2.0 * (1.0 - progress), Color(impact_color.r, impact_color.g, impact_color.b, alpha))
