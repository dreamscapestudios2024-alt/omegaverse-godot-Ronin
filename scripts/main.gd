extends Node2D

# Minimal project smoke test. Claude will replace this with the first playable loop.
func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("f7e7ed"))
    draw_circle(Vector2(576, 324), 28.0, Color("a18aca"))
