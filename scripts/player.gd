extends Node2D
## Player: smooth WASD / arrow movement inside the territory. The character starts
## uncategorised (no Alpha/Beta/Omega traits), so it is drawn in a neutral lavender-grey.

const Config = preload("res://scripts/config.gd")

const SHEET = preload("res://assets/player/player_sheet.png")
const CELL = Vector2(70, 110)        # one sprite cell in the sheet
const DRAW_SCALE = 0.85              # on-screen size relative to the sheet cell
const WALK_FRAME_SECONDS = 0.16
# Sheet layout: columns = front(down), back(up), left, right; row 0 = standing, row 1 = walking.

var bounds := Rect2()
var facing := Vector2.DOWN
var moving := false
var walk_time := 0.0

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
	moving = dir != Vector2.ZERO
	if moving:
		dir = dir.normalized()
		facing = dir
		walk_time += delta
		position += dir * Config.PLAYER_SPEED * delta
	if bounds.size != Vector2.ZERO:
		position = Vector2(
			clampf(position.x, bounds.position.x, bounds.end.x),
			clampf(position.y, bounds.position.y, bounds.end.y))
	queue_redraw()

func _direction_column() -> int:
	if absf(facing.x) > absf(facing.y):
		return 2 if facing.x < 0.0 else 3
	return 1 if facing.y < 0.0 else 0

func _draw() -> void:
	var r: float = Config.PLAYER_RADIUS
	# soft ground shadow
	draw_set_transform(Vector2(0, r - 2.0), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, r * 1.1, Color(0.35, 0.29, 0.4, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# sprite: standing frame when still, alternate standing/walking frames when moving
	var row := 0
	if moving and int(walk_time / WALK_FRAME_SECONDS) % 2 == 1:
		row = 1
	var src := Rect2(Vector2(_direction_column() * CELL.x, row * CELL.y), CELL)
	var size := CELL * DRAW_SCALE
	var bob := -1.5 if (moving and row == 1) else 0.0
	draw_texture_rect_region(SHEET, Rect2(Vector2(-size.x / 2.0, r - size.y + bob), size), src)
