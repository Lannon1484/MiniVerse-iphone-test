extends Control
signal finished(game_id: String, score: int, extra: Dictionary)

const SKY := Color("#142755")
const AQUA := Color("#76e6c3")
const GOLD := Color("#ffe18c")
const WIDTH := 360.0
const HEIGHT := 610.0
const GRAVITY := 1150.0
const JUMP := -525.0
const SPEED := 235.0

var player := Vector2(180, 440)
var velocity := Vector2.ZERO
var platforms: Array[Vector2] = []
var stars: Array[Vector2] = []
var camera_y := 0.0
var highest := 0.0
var score := 0
var running := false
var left_down := false
var right_down := false
var drag_direction := 0.0
var touch_start := Vector2.ZERO
var rng := RandomNumberGenerator.new()
var arena: HopperArena
var score_label: Label
var message: Label
var finished_once := false

func start_game() -> void:
    rng.randomize()
    var layout := VBoxContainer.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout.add_theme_constant_override("separation", 8)
    add_child(layout)
    var title := Label.new()
    title.text = "SKY HOPPER"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 26)
    title.add_theme_color_override("font_color", GOLD)
    layout.add_child(title)
    score_label = Label.new()
    score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    score_label.add_theme_font_size_override("font_size", 19)
    layout.add_child(score_label)
    arena = HopperArena.new()
    arena.owner_game = self
    arena.custom_minimum_size = Vector2(0, 535)
    arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
    arena.mouse_filter = Control.MOUSE_FILTER_STOP
    arena.gui_input.connect(_arena_input)
    layout.add_child(arena)
    message = Label.new()
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message.text = "Hold LEFT / RIGHT or drag across the sky"
    layout.add_child(message)
    var controls := HBoxContainer.new()
    controls.add_theme_constant_override("separation", 12)
    layout.add_child(controls)
    for sign in [-1, 1]:
        var button := Button.new()
        button.text = "LEFT" if sign == -1 else "RIGHT"
        button.custom_minimum_size.y = 82
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size", 24)
        controls.add_child(button)
        button.button_down.connect(_set_button.bind(sign, true))
        button.button_up.connect(_set_button.bind(sign, false))
    var restart := Button.new()
    restart.text = "NEW RUN"
    restart.custom_minimum_size.y = 52
    restart.pressed.connect(_restart)
    layout.add_child(restart)
    _restart()

func _restart() -> void:
    player = Vector2(180, 440)
    velocity = Vector2(0, JUMP)
    platforms = [Vector2(180, 495)]
    stars.clear()
    for i in range(1, 30):
        var y: float = 495.0 - i * 102.0
        var x: float = rng.randf_range(70, 290)
        platforms.append(Vector2(x, y))
        if i % 2 == 0:
            stars.append(Vector2(x, y - 49))
    camera_y = 0.0
    highest = player.y
    score = 0
    running = true
    finished_once = false
    left_down = false
    right_down = false
    drag_direction = 0
    message.text = "Bounce automatically • Steer to floating islands"
    _refresh()

func _set_button(sign: int, down: bool) -> void:
    if sign < 0:
        left_down = down
    else:
        right_down = down

func _arena_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_start = event.position
            drag_direction = -1.0 if event.position.x < arena.size.x * 0.5 else 1.0
        else:
            drag_direction = 0.0
    elif event is InputEventScreenDrag:
        drag_direction = clampf(event.relative.x / 12.0, -1.0, 1.0)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        drag_direction = (-1.0 if event.position.x < arena.size.x * 0.5 else 1.0) if event.pressed else 0.0
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        drag_direction = -1.0 if event.position.x < arena.size.x * 0.5 else 1.0

func _physics_process(delta: float) -> void:
    if not running:
        return
    var steering: float = float(int(right_down) - int(left_down))
    if absf(drag_direction) > 0.05:
        steering = drag_direction
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        steering = -1.0
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        steering = 1.0
    player.x = wrapf(player.x + steering * SPEED * delta, 8.0, WIDTH - 8.0)
    var old_y: float = player.y
    velocity.y += GRAVITY * delta
    player.y += velocity.y * delta
    if velocity.y > 0.0:
        for platform in platforms:
            if old_y + 15.0 <= platform.y and player.y + 15.0 >= platform.y and absf(player.x - platform.x) < 49.0:
                player.y = platform.y - 15.0
                velocity.y = JUMP
                break
    if player.y < highest:
        highest = player.y
    camera_y = minf(camera_y, player.y - 260.0)
    for i in range(stars.size() - 1, -1, -1):
        if player.distance_to(stars[i]) < 30.0:
            stars.remove_at(i)
            score += 75
    score = maxi(score, int((440.0 - highest) / 6.0))
    if player.y - camera_y > HEIGHT + 60:
        _game_over()
    # Extend the sky indefinitely as the player climbs.
    if platforms.back().y > camera_y - 250.0:
        for i in range(12):
            var y: float = platforms.back().y - 102.0
            var x: float = rng.randf_range(70, 290)
            platforms.append(Vector2(x, y))
            if rng.randf() < 0.55:
                stars.append(Vector2(x, y - 49.0))
    _refresh()

func _refresh() -> void:
    if is_instance_valid(score_label):
        score_label.text = "SCORE  %d   •   HEIGHT  %dm" % [score, maxi(0, int((440.0 - highest) / 10.0))]
    if is_instance_valid(arena):
        arena.queue_redraw()

func _game_over() -> void:
    if finished_once:
        return
    running = false
    finished_once = true
    message.text = "Great climb! Tap NEW RUN to try again."
    finished.emit("hopper", score, {"coins": maxi(5, int(score / 80.0)), "xp": 35})

class HopperArena extends Control:
    var owner_game: Control
    func _draw() -> void:
        var g = owner_game
        if g == null:
            return
        var scale_factor: float = minf(size.x / WIDTH, size.y / HEIGHT)
        var offset: Vector2 = (size - Vector2(WIDTH, HEIGHT) * scale_factor) * 0.5
        draw_rect(Rect2(Vector2.ZERO, size), SKY, true)
        for i in range(22):
            var sx: float = fposmod(float(i * 97), WIDTH)
            var sy: float = fposmod(float(i * 167) - g.camera_y * 0.17, HEIGHT)
            draw_circle(offset + Vector2(sx, sy) * scale_factor, 2.0 * scale_factor, Color("#c2e9ff", 0.55))
        for platform in g.platforms:
            var y: float = platform.y - g.camera_y
            if y < -50 or y > HEIGHT + 50:
                continue
            var pos: Vector2 = offset + Vector2(platform.x, y) * scale_factor
            draw_rect(Rect2(pos + Vector2(-49, -2) * scale_factor, Vector2(98, 18) * scale_factor), Color("#8762b3"), true)
            draw_rect(Rect2(pos + Vector2(-49, -7) * scale_factor, Vector2(98, 10) * scale_factor), AQUA, true)
            draw_circle(pos + Vector2(-35, -9) * scale_factor, 5 * scale_factor, Color("#d3ffe3"))
        for star in g.stars:
            var y: float = star.y - g.camera_y
            if y < -40 or y > HEIGHT + 40:
                continue
            var pos: Vector2 = offset + Vector2(star.x, y) * scale_factor
            draw_circle(pos, 13 * scale_factor, Color("#fff3a5", 0.20))
            draw_circle(pos, 8 * scale_factor, GOLD)
            draw_circle(pos + Vector2(-2, -2) * scale_factor, 2 * scale_factor, Color.WHITE)
        var hero: Vector2 = offset + Vector2(g.player.x, g.player.y - g.camera_y) * scale_factor
        draw_circle(hero, 18 * scale_factor, Color("#ffa8dd", 0.22))
        draw_circle(hero, 14 * scale_factor, Color("#ffaddd"))
        draw_circle(hero + Vector2(-5, -3) * scale_factor, 2.4 * scale_factor, Color("#213454"))
        draw_circle(hero + Vector2(5, -3) * scale_factor, 2.4 * scale_factor, Color("#213454"))
        draw_arc(hero, 13 * scale_factor, 0, TAU, 32, Color("#ffffff", 0.8), 1.5 * scale_factor)
