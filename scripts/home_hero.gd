extends Control

# Procedural, resolution-independent fantasy-island artwork for the mobile home screen.
func _ready() -> void:
    custom_minimum_size = Vector2(0, 190)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
    var w := size.x
    var h := size.y
    if w < 2.0 or h < 2.0:
        return
    # Deep sky gradient, drawn in horizontal bands so it works without imported textures.
    for i in range(20):
        var t := float(i) / 19.0
        var c := Color("#11134a").lerp(Color("#5b2b9a"), t * 0.72)
        draw_rect(Rect2(0, h * t, w, h / 19.0 + 1.0), c, true)
    # Stars
    var stars := [Vector2(.08,.18),Vector2(.18,.31),Vector2(.32,.13),Vector2(.48,.22),Vector2(.68,.12),Vector2(.83,.25),Vector2(.93,.15),Vector2(.75,.38),Vector2(.14,.47)]
    for s in stars:
        var p := Vector2(w * s.x, h * s.y)
        draw_circle(p, 2.0, Color("#ffffff", .85))
        draw_line(p - Vector2(5,0), p + Vector2(5,0), Color("#8cecff", .7), 1.0)
        draw_line(p - Vector2(0,5), p + Vector2(0,5), Color("#8cecff", .7), 1.0)
    # Distant floating islands
    _island(Vector2(w * .14, h * .70), w * .20, h * .48, Color("#44d7d2"), Color("#3861a8"))
    _island(Vector2(w * .87, h * .58), w * .24, h * .54, Color("#b1f17a"), Color("#4d63ba"))
    # Central magical world and orbit
    var center := Vector2(w * .51, h * .55)
    draw_arc(center, h * .30, 0.1, TAU - 0.1, 64, Color("#7deaff", .8), 2.0, true)
    draw_circle(center, h * .235, Color("#3d6cff", .22))
    draw_circle(center, h * .18, Color("#36b9ff", .35))
    draw_circle(center, h * .135, Color("#9b7bff"))
    draw_circle(center + Vector2(-h*.035,-h*.035), h * .075, Color("#ff9bea"))
    draw_circle(center + Vector2(-h*.055,-h*.065), h * .035, Color("#fff4c2"))
    # Foreground island under the world
    var island_top := Vector2(w*.51, h*.76)
    var island := PackedVector2Array([island_top+Vector2(-w*.20,0), island_top+Vector2(-w*.12,-h*.08), island_top+Vector2(-w*.05,-h*.13), island_top+Vector2(w*.08,-h*.10), island_top+Vector2(w*.19,0), island_top+Vector2(w*.10,h*.10), island_top+Vector2(w*.04,h*.30), island_top+Vector2(-w*.04,h*.23), island_top+Vector2(-w*.11,h*.32), island_top+Vector2(-w*.16,h*.12)])
    draw_colored_polygon(island, Color("#42d6a0"))
    draw_line(island[0], island[4], Color("#c4ff9a"), 3.0, true)
    # Tiny glowing trees
    for tree in [Vector2(-.10,-.06),Vector2(-.04,-.10),Vector2(.06,-.07),Vector2(.12,-.03)]:
        var p := island_top + Vector2(w*tree.x, h*tree.y)
        draw_line(p, p+Vector2(0,h*.10), Color("#7047a8"), 3.0)
        draw_circle(p, h*.035, Color("#a7ffb5"))

func _island(center: Vector2, width: float, height: float, top: Color, side: Color) -> void:
    var top_poly := PackedVector2Array([center+Vector2(-width*.5,0),center+Vector2(-width*.25,-height*.16),center+Vector2(width*.20,-height*.15),center+Vector2(width*.5,0),center+Vector2(width*.22,height*.10),center+Vector2(-width*.22,height*.10)])
    draw_colored_polygon(top_poly, top)
    var side_poly := PackedVector2Array([center+Vector2(-width*.22,height*.10),center+Vector2(width*.22,height*.10),center+Vector2(width*.12,height*.42),center+Vector2(0,height*.50),center+Vector2(-width*.12,height*.30)])
    draw_colored_polygon(side_poly, side)
    draw_line(center+Vector2(-width*.5,0),center+Vector2(width*.5,0),Color("#e2ffb1"),2.0,true)
