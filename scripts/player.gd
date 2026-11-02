extends Node2D
## Player: smooth WASD / arrow movement inside the territory. The character starts
## uncategorised (no Alpha/Beta/Omega traits), so it is drawn in a neutral lavender-grey.

const Config = preload("res://scripts/config.gd")

var bounds := Rect2()
var facing := Vector2.DOWN

func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		facing = dir
		position += dir * Config.PLAYER_SPEED * delta
	if bounds.size != Vector2.ZERO:
		position = Vector2(
			clampf(position.x, bounds.position.x, bounds.end.x),
			clampf(position.y, bounds.position.y, bounds.end.y))
	queue_redraw()

func _draw() -> void:
	var r: float = Config.PLAYER_RADIUS
	draw_circle(Vector2(0, r * 0.8), r * 0.9, Color(0.35, 0.29, 0.4, 0.18))   # soft shadow
	draw_circle(Vector2.ZERO, r, Color("c4bad6"))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color("8f7fb0"), 2.5)
	var eye_off := facing * 4.0
	draw_circle(eye_off + Vector2(-4, -2), 2.2, Color("5b4b66"))
	draw_circle(eye_off + Vector2(4, -2), 2.2, Color("5b4b66"))
