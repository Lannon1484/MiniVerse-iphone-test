extends Control

# Decorative overlay only; never intercepts taps or swipes.
const PALETTE := [Color("#ffd86e"), Color("#f987c5"), Color("#78e8ff"), Color("#a58bff"), Color("#8ff2b5")]
var effect_style := "classic"
var pieces: Array[Dictionary] = []
var elapsed: float = 0.0
var duration: float = 2.8
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    rng.randomize()
    for i in range(54):
        pieces.append({
            "x": rng.randf_range(0.04, 0.96),
            "start": rng.randf_range(-0.45, -0.04),
            "speed": rng.randf_range(0.35, 0.75),
            "drift": rng.randf_range(-0.13, 0.13),
            "size": rng.randf_range(4.0, 9.0),
            "color": _particle_color(i),
            "phase": rng.randf_range(0.0, 6.28)
        })
    set_process(true)

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()
    if elapsed >= duration:
        queue_free()

func _draw() -> void:
    if size.x <= 0.0 or size.y <= 0.0:
        return
    var alpha: float = clampf((duration - elapsed) / 0.65, 0.0, 1.0)
    for p in pieces:
        var y: float = (float(p["start"]) + elapsed * float(p["speed"])) * size.y
        if y < -20.0 or y > size.y + 20.0:
            continue
        var x: float = (float(p["x"]) + elapsed * float(p["drift"]) + sin(elapsed * 5.0 + float(p["phase"])) * 0.012) * size.x
        var c: Color = p["color"]
        c.a = alpha
        var side: float = float(p["size"])
        if effect_style == "starlight":
            _draw_star(Vector2(x, y), side * 1.2, c)
        elif effect_style == "ocean":
            draw_circle(Vector2(x, y), side * 0.65, c)
            draw_arc(Vector2(x, y), side * 0.65, 0.0, TAU, 14, Color(1, 1, 1, alpha * 0.45), 1.4)
        elif effect_style == "hearts":
            _draw_heart(Vector2(x, y), side, c)
        else:
            draw_rect(Rect2(x, y, side, side * 0.55), c, true)

func _particle_color(i: int) -> Color:
    match effect_style:
        "starlight":
            return [Color("#ffe58a"), Color("#fff4c4"), Color("#f9b84d")][i % 3]
        "ocean":
            return [Color("#67e8f9"), Color("#38bdf8"), Color("#a5f3fc")][i % 3]
        "hearts":
            return [Color("#fb7185"), Color("#fda4af"), Color("#fecdd3")][i % 3]
    return PALETTE[i % PALETTE.size()]

func _draw_star(center: Vector2, radius: float, color: Color) -> void:
    var points := PackedVector2Array()
    for j in range(10):
        var angle := -PI / 2.0 + float(j) * PI / 5.0
        var r := radius if j % 2 == 0 else radius * 0.44
        points.append(center + Vector2(cos(angle), sin(angle)) * r)
    draw_colored_polygon(points, color)

func _draw_heart(center: Vector2, radius: float, color: Color) -> void:
    var points := PackedVector2Array()
    for j in range(24):
        var t := float(j) * TAU / 24.0
        var x := 16.0 * pow(sin(t), 3.0)
        var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
        points.append(center + Vector2(x, y) * radius / 19.0)
    draw_colored_polygon(points, color)
