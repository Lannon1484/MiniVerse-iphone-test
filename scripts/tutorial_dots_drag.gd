extends Control
## A tiny practice board that uses the same press-drag-release gesture
## as Connect the Dots. Works with touch and mouse.
signal completed

var dragging := false
var solved := false
var current_position := Vector2.ZERO
var reached_end := false

func _left() -> Vector2:
    return Vector2(43.0, size.y * 0.5)

func _right() -> Vector2:
    return Vector2(size.x - 43.0, size.y * 0.5)

func _near(point: Vector2, target: Vector2) -> bool:
    return point.distance_to(target) <= 32.0

func _gui_input(event: InputEvent) -> void:
    if solved:
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            _begin(event.position)
        else:
            _end(event.position)
        accept_event()
    elif event is InputEventScreenDrag:
        if dragging:
            _move(event.position)
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _begin(event.position)
        else:
            _end(event.position)
        accept_event()
    elif event is InputEventMouseMotion and dragging:
        _move(event.position)
        accept_event()

func _begin(point: Vector2) -> void:
    dragging = _near(point, _left())
    reached_end = false
    current_position = _left()
    queue_redraw()

func _move(point: Vector2) -> void:
    current_position = point
    if _near(point, _right()):
        reached_end = true
    queue_redraw()

func _end(point: Vector2) -> void:
    if not dragging:
        return
    if _near(point, _right()):
        reached_end = true
    dragging = false
    if reached_end:
        solved = true
        completed.emit()
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("#11224c"), true)
    var a := _left()
    var b := _right()
    var blue := Color("#5fe0ff")
    if solved:
        draw_line(a, b, Color(0.37, 0.88, 1.0, 0.25), 24.0, true)
        draw_line(a, b, blue, 11.0, true)
    elif dragging:
        draw_line(a, current_position, Color(0.37, 0.88, 1.0, 0.25), 24.0, true)
        draw_line(a, current_position, blue, 10.0, true)
    for point in [a, b]:
        draw_circle(point, 24.0, Color(0.37, 0.88, 1.0, 0.22))
        draw_circle(point, 17.0, blue)
        draw_circle(point + Vector2(-4, -5), 5.0, Color.WHITE)
