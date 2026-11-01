extends Control
# Width-driven seven-column board. Each cell is drawn as a circle,
# not as a square ColorRect, with a glossy highlight and gold rim.
const COLS := 7
const ROWS := 9
var board_data: Array = []
var palette: Array = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(_sync_height)
    _sync_height()

func _sync_height() -> void:
    if size.x <= 0.0:
        return
    var desired: float = size.x * float(ROWS) / float(COLS)
    if absf(custom_minimum_size.y - desired) > 1.0:
        custom_minimum_size.y = desired
    queue_redraw()

func _draw() -> void:
    if board_data.size() < ROWS:
        return
    var diameter: float = size.x / float(COLS)
    var radius: float = diameter * 0.44
    for row in range(ROWS):
        for col in range(COLS):
            var center := Vector2((float(col) + 0.5) * diameter, (float(row) + 0.5) * diameter)
            var kind: int = int(board_data[row][col])
            if kind < 0:
                draw_circle(center, radius, Color("#1b103c", 0.76))
                draw_arc(center, radius, 0.0, TAU, 32, Color("#ae83e4", 0.56), 1.5, true)
            else:
                var color: Color = palette[kind]
                draw_circle(center + Vector2(0, diameter * 0.045), radius, Color("#140e38", 0.72))
                draw_circle(center, radius, Color("#ffe6aa"))
                draw_circle(center, radius - 2.0, color.darkened(0.23))
                draw_circle(center + Vector2(-diameter * 0.045, -diameter * 0.06), radius * 0.77, color)
                draw_circle(center + Vector2(-radius * 0.34, -radius * 0.39), radius * 0.32, Color(1, 1, 1, 0.68))
                draw_circle(center + Vector2(radius * 0.32, radius * 0.35), radius * 0.13, Color(1, 1, 1, 0.24))
