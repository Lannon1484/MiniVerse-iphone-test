extends Control
# Decorative, input-transparent gameplay feedback shared by all ten games.
# Observes score changes without modifying game rules or difficulty.
var tracked_game: Control
var previous_score: int = 0
var ready_to_track: bool = false
var particles: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    rng.randomize()
    if is_instance_valid(tracked_game):
        var initial: Variant = tracked_game.get("score")
        if initial is int or initial is float:
            previous_score = int(initial)
            ready_to_track = true

func _process(delta: float) -> void:
    if not is_instance_valid(tracked_game):
        return
    var value: Variant = tracked_game.get("score")
    if value is int or value is float:
        var current: int = int(value)
        if ready_to_track and current > previous_score:
            _burst()
        previous_score = current
        ready_to_track = true
    for i in range(particles.size() - 1, -1, -1):
        var particle: Dictionary = particles[i]
        particle["life"] = float(particle["life"]) - delta
        particle["position"] = Vector2(particle["position"]) + Vector2(particle["velocity"]) * delta
        particle["velocity"] = Vector2(particle["velocity"]) + Vector2(0.0, 85.0) * delta
        if float(particle["life"]) <= 0.0:
            particles.remove_at(i)
        else:
            particles[i] = particle
    if not particles.is_empty():
        queue_redraw()

func _burst() -> void:
    var center := Vector2(size.x * 0.5, size.y * 0.37)
    var colors := [Color("#ffdc7a"), Color("#7ee8ff"), Color("#ff9cdb"), Color("#bda2ff")]
    for i in range(12):
        var angle: float = rng.randf_range(0.0, TAU)
        var speed: float = rng.randf_range(80.0, 190.0)
        particles.append({
            "position": center + Vector2(rng.randf_range(-15.0, 15.0), rng.randf_range(-12.0, 12.0)),
            "velocity": Vector2(cos(angle), sin(angle)) * speed,
            "life": 0.62,
            "color": colors[i % colors.size()],
            "radius": rng.randf_range(3.0, 6.0)
        })
    queue_redraw()

func _draw() -> void:
    for particle in particles:
        var alpha: float = clampf(float(particle["life"]) / 0.62, 0.0, 1.0)
        var c: Color = particle["color"]
        c.a = alpha
        draw_circle(particle["position"], float(particle["radius"]) * alpha, c)
