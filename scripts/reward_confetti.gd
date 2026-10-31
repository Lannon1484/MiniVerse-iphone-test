extends Control

# Decorative overlay only; never intercepts taps or swipes.
const PALETTE := [Color("#ffd86e"), Color("#f987c5"), Color("#78e8ff"), Color("#a58bff"), Color("#8ff2b5")]
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
            "color": PALETTE[i % PALETTE.size()],
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
        draw_rect(Rect2(x, y, side, side * 0.55), c, true)
