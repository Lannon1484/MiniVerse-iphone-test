extends Control

# Small, scalable neon illustrations used by the MiniVerse game cards.
var game_id: String = "fast"
var accent: Color = Color("#f9738f")

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    if w < 2.0 or h < 2.0:
        return
    draw_rect(Rect2(Vector2.ZERO, size), Color("#11162f"), true)
    # Soft corner lights and a restrained grid tie the mini-game art together.
    for i in range(4):
        var gx: float = w * (0.18 + 0.22 * float(i))
        draw_line(Vector2(gx, 0), Vector2(gx, h), Color(accent.r, accent.g, accent.b, 0.10), 1.0)
    for i in range(4):
        var gy: float = h * (0.18 + 0.22 * float(i))
        draw_line(Vector2(0, gy), Vector2(w, gy), Color(accent.r, accent.g, accent.b, 0.10), 1.0)
    var center := Vector2(w * 0.5, h * 0.5)
    if game_id == "fast":
        draw_circle(center, minf(w, h) * 0.36, Color(accent.r, accent.g, accent.b, 0.10))
        draw_arc(center, minf(w, h) * 0.34, 0.0, TAU, 48, accent, 3.0, true)
        draw_arc(center, minf(w, h) * 0.23, 0.0, TAU, 48, Color("#fef08a"), 2.0, true)
        draw_circle(center, minf(w, h) * 0.10, Color("#fef08a"))
        var star: PackedVector2Array = PackedVector2Array()
        for i in range(10):
            var angle: float = -PI * 0.5 + float(i) * PI / 5.0
            var radius: float = minf(w, h) * (0.085 if i % 2 == 0 else 0.04)
            star.append(center + Vector2(cos(angle), sin(angle)) * radius)
        draw_colored_polygon(star, Color("#ffffff"))
    elif game_id == "merge":
        var cell: float = minf(w, h) * 0.22
        var gap: float = minf(w, h) * 0.045
        var start := Vector2((w - (cell * 3.0 + gap * 2.0)) * 0.5, (h - (cell * 3.0 + gap * 2.0)) * 0.5)
        var tile_colors: Array[Color] = [Color("#dbeafe"), Color("#60a5fa"), Color("#c4b5fd"), Color("#f0abfc"), Color("#fcd34d"), Color("#93c5fd"), Color("#a5b4fc"), Color("#f9a8d4"), Color("#bfdbfe")]
        var values: Array[String] = ["2", "4", "8", "2", "16", "4", "8", "2", "32"]
        for i in range(9):
            var pos := start + Vector2(float(i % 3) * (cell + gap), float(i / 3) * (cell + gap))
            var tile := Rect2(pos, Vector2(cell, cell))
            draw_rect(tile.grow(2.0), Color(accent.r, accent.g, accent.b, 0.12), true)
            draw_rect(tile, tile_colors[i], true)
            draw_rect(tile, Color("#ffffff", 0.75), false, 1.0)
            var font := ThemeDB.fallback_font
            if font:
                draw_string(font, pos + Vector2(cell * 0.18, cell * 0.68), values[i], HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, int(cell * 0.45)), Color("#17172b"))
    elif game_id == "dots":
        var points: Array[Vector2] = [Vector2(w * 0.22, h * 0.24), Vector2(w * 0.78, h * 0.24), Vector2(w * 0.22, h * 0.72), Vector2(w * 0.78, h * 0.72)]
        draw_line(points[0], points[1], Color("#ff79b2"), 11.0, true)
        draw_line(points[2], points[3], Color("#5fe0ff"), 11.0, true)
        for i in range(points.size()):
            draw_circle(points[i], 13.0, Color("#ff79b2") if i < 2 else Color("#5fe0ff"))
            draw_circle(points[i] + Vector2(-3, -3), 4.0, Color.WHITE)
    elif game_id == "snake":
        var cell: float = minf(w, h) * 0.18
        var origin := center - Vector2(cell * 1.5, cell * 0.5)
        for i in range(4):
            var pos := origin + Vector2(cell * float(i), sin(float(i) * 0.8) * cell * 0.35)
            draw_circle(pos, cell * 0.55, Color("#4ce3bd") if i == 3 else Color("#40bddf"))
            draw_arc(pos, cell * 0.55, 0.0, TAU, 24, Color("#e3fff9"), 2.0)
        draw_circle(origin + Vector2(cell * 3.0, 0), cell * 0.12, Color("#10264b"))
        var star := center + Vector2(cell * 1.6, -cell * 1.4)
        draw_circle(star, cell * 0.45, Color("#ffd56e"))
    elif game_id == "sort":
        var tube_colors: Array[Color] = [Color("#ff739f"), Color("#55d9ff"), Color("#ffd15b"), Color("#83e69b")]
        for i in range(3):
            var tw: float = w * 0.18
            var tx: float = w * (0.18 + 0.27 * float(i))
            var ty: float = h * 0.20
            var th: float = h * 0.60
            draw_rect(Rect2(tx, ty, tw, th), Color("#15264c"), true)
            for j in range(3):
                draw_rect(Rect2(tx + 3, ty + th - float(j + 1) * th / 4.0, tw - 6, th / 4.0), tube_colors[(i + j) % 4], true)
            draw_rect(Rect2(tx, ty, tw, th), Color("#b5f0ff"), false, 3.0)
    elif game_id == "whack":
        var hole_radius: float = minf(w, h) * 0.13
        for i in range(6):
            var center_hole := Vector2(w * (0.25 + 0.25 * float(i % 3)), h * (0.38 + 0.28 * float(int(i / 3))))
            draw_circle(center_hole, hole_radius, Color("#26365d"))
            draw_arc(center_hole, hole_radius, 0, TAU, 32, Color("#7894c8"), 2.0)
            if i == 1 or i == 5:
                draw_circle(center_hole + Vector2(0, -4), hole_radius * 0.8, Color("#38d9b4"))
                draw_circle(center_hole + Vector2(-5, -6), 2.0, Color("#173c3a"))
                draw_circle(center_hole + Vector2(5, -6), 2.0, Color("#173c3a"))
            elif i == 3:
                draw_circle(center_hole + Vector2(0, -4), hole_radius * 0.8, Color("#fb7185"))
    elif game_id == "memory":
        # Four playful face-up cards with distinct symbols for Memory Match.
        var card_w: float = w * 0.28
        var card_h: float = h * 0.30
        var gap: float = w * 0.045
        var symbols: Array[String] = ["★", "♥", "☾", "◆"]
        var card_colors: Array[Color] = [Color("#34d399"), Color("#f472b6"), Color("#60a5fa"), Color("#fbbf24")]
        for i in range(4):
            var row_i: int = int(i / 2)
            var col_i: int = i % 2
            var pos := Vector2(w * 0.5 - card_w - gap * 0.5 + float(col_i) * (card_w + gap),
                h * 0.5 - card_h - gap * 0.5 + float(row_i) * (card_h + gap))
            var card_rect := Rect2(pos, Vector2(card_w, card_h))
            draw_rect(card_rect.grow(2.0), Color(card_colors[i].r, card_colors[i].g, card_colors[i].b, 0.18), true)
            draw_rect(card_rect, card_colors[i], true)
            draw_rect(card_rect, Color("#ffffff", 0.85), false, 1.5)
            var font := ThemeDB.fallback_font
            if font:
                draw_string(font, pos + Vector2(card_w * 0.20, card_h * 0.68), symbols[i], HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(12, int(card_h * 0.55)), Color("#17172b"))
    else:
        var block_h: float = maxf(7.0, h * 0.12)
        var widths: Array[float] = [w * 0.68, w * 0.60, w * 0.50, w * 0.42]
        var stack_colors: Array[Color] = [Color("#fbbf24"), Color("#f9738f"), Color("#60a5fa"), Color("#86efac")]
        for i in range(widths.size()):
            var bw: float = widths[i]
            var pos := Vector2((w - bw) * 0.5, h * 0.78 - float(i) * (block_h + 2.0))
            var block := Rect2(pos, Vector2(bw, block_h))
            draw_rect(block.grow(3.0), Color(stack_colors[i].r, stack_colors[i].g, stack_colors[i].b, 0.12), true)
            draw_rect(block, stack_colors[i], true)
            draw_rect(Rect2(pos, Vector2(bw, 2.0)), Color("#ffffff", 0.75), true)
    draw_rect(Rect2(Vector2.ZERO, size), Color(accent.r, accent.g, accent.b, 0.38), false, 2.0)
