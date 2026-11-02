extends Node2D
## Stage 1 world: gather -> farm -> build nest -> unlock scent -> mark posts.
## Tunable numbers live in scripts/config.gd.

const Config = preload("res://scripts/config.gd")
const PlayerScript = preload("res://scripts/player.gd")
const HudScript = preload("res://scripts/hud.gd")

const TEX_RESOURCE = {
	"wood": preload("res://assets/items/tree.png"),
	"grass": preload("res://assets/items/icon_grass.png"),
	"leaves": preload("res://assets/items/icon_leaf.png"),
}
const TEX_PLOT_EMPTY = preload("res://assets/items/plot_empty.png")
const TEX_PLOT_SEEDED = preload("res://assets/items/plot_seeded.png")
const TEX_PLOT_SPROUT = preload("res://assets/items/plot_sprout.png")
const TEX_PLOT_GROWING = preload("res://assets/items/plot_growing.png")
const TEX_PLOT_RIPE = preload("res://assets/items/plot_ripe.png")
const TEX_STUMP = preload("res://assets/items/stump.png")
const PLOT_SIZE = Vector2(150, 90)
const PLOT_PAD = Vector2(11, 44)     # transparent margin around the soil in the plot textures

const CROP_EMPTY = 0
const CROP_GROWING = 1
const CROP_READY = 2

var player: Node2D
var hud: CanvasLayer

var inventory := {"wood": 0, "grass": 0, "leaves": 0, "crops": 0}
var nest_deposited := {"wood": 0, "grass": 0, "leaves": 0}
var total_gathered := 0
var crop_state := CROP_EMPTY
var crop_timer := 0.0
var crop_harvested := false
var resources: Array = []
var posts: Array = []
var scent_unlocked := false
var scent_on := false
var won := false
var time := 0.0
var last_tier := 0
var current_prompt := ""

var nest_pos := Vector2(444, 354)
var plot_rect := Rect2()
var scent_trail := PackedVector2Array()
var speckles := PackedVector2Array()

func _ready() -> void:
	var t: Rect2 = Config.TERRITORY
	plot_rect = Rect2(t.position.x + 50, t.end.y - PLOT_SIZE.y - 44.0, PLOT_SIZE.x, PLOT_SIZE.y)
	_add_resources()
	_add_posts(t)
	_add_trail()
	_add_speckles(t)
	hud = HudScript.new()
	add_child(hud)
	player = PlayerScript.new()
	player.bounds = t.grow(-Config.PLAYER_RADIUS)
	player.position = nest_pos + Vector2(0, 90)
	add_child(player)
	hud.toast("Welcome! You are uncategorised: the virus left no Alpha, Beta or Omega traits. Gather wood, grass and leaves with E.")

func _add_resources() -> void:
	# Leaf bushes grow beside the trees; grass is scattered around the territory.
	var defs := [
		["wood", Vector2(100, 240)], ["leaves", Vector2(176, 288)],
		["wood", Vector2(270, 240)], ["leaves", Vector2(346, 288)],
		["wood", Vector2(440, 235)], ["leaves", Vector2(516, 283)],
		["grass", Vector2(330, 430)], ["grass", Vector2(560, 200)], ["grass", Vector2(650, 450)],
	]
	for d in defs:
		resources.append({"type": d[0], "pos": d[1], "charges": Config.RESOURCE_CHARGES, "regrow": 0.0, "total": Config.RESPAWN_SECONDS[d[0]]})

func _add_posts(t: Rect2) -> void:
	var inset := 32.0
	for p in [
		Vector2(t.position.x + inset, t.position.y + inset),
		Vector2(t.end.x - inset, t.position.y + inset),
		Vector2(t.position.x + inset, t.end.y - inset),
		Vector2(t.end.x - inset, t.end.y - inset),
	]:
		posts.append({"pos": p, "marked": false})

func _add_trail() -> void:
	# Pre-placed sample trail (single character, so no real NPC scents yet).
	for i in 36:
		scent_trail.append(Vector2(100.0 + i * 19.5, 300.0 + sin(i * 0.45) * 60.0))

func _add_speckles(t: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 140:
		speckles.append(Vector2(rng.randf_range(t.position.x + 8, t.end.x - 8), rng.randf_range(t.position.y + 8, t.end.y - 8)))

# ---------- derived values ----------

func nest_completion() -> float:
	var have := 0
	var need := 0
	for k in Config.NEST_COST:
		need += Config.NEST_COST[k]
		have += mini(nest_deposited[k], Config.NEST_COST[k])
	return float(have) / float(need) * 100.0

func nest_tier() -> int:
	return mini(int(nest_completion() / float(Config.NEST_MILESTONE_STEP)), 100 / Config.NEST_MILESTONE_STEP)

func happiness() -> float:
	var h: float = nest_completion() * Config.HAPPINESS_PER_NEST_PERCENT
	if crop_harvested:
		h += Config.HAPPINESS_CROP_BONUS
	return clampf(h, 0.0, 100.0)

func influence() -> float:
	return happiness() * Config.INFLUENCE_FROM_HAPPINESS   # PROVISIONAL stand-in

func scent_range() -> float:
	return Config.SCENT_BASE_RANGE + influence() * Config.SCENT_RANGE_PER_INFLUENCE

func posts_marked() -> int:
	var n := 0
	for p in posts:
		if p["marked"]:
			n += 1
	return n

func objectives() -> Array:
	return [
		["Gather materials (%d/%d)" % [mini(total_gathered, Config.GATHER_OBJECTIVE_AMOUNT), Config.GATHER_OBJECTIVE_AMOUNT], total_gathered >= Config.GATHER_OBJECTIVE_AMOUNT],
		["Build the nest to 100%", nest_completion() >= 100.0],
		["Unlock scent (nest %d%%)" % int(Config.SCENT_UNLOCK_NEST_PERCENT), scent_unlocked],
		["Mark all %d posts (%d/%d)" % [Config.POSTS_TO_MARK, posts_marked(), Config.POSTS_TO_MARK], posts_marked() >= Config.POSTS_TO_MARK],
		["Harvest the crop", crop_harvested],
	]

# ---------- interaction ----------

func find_target() -> Dictionary:
	var p: Vector2 = player.position
	var best := {}
	var best_d: float = Config.INTERACT_RANGE
	for r in resources:
		if r["charges"] <= 0:
			continue
		var d: float = p.distance_to(r["pos"]) - 28.0
		if d < best_d:
			best_d = d
			best = {"kind": "resource", "ref": r, "label": "E: chop tree" if r["type"] == "wood" else "E: gather " + r["type"]}
	# farm plot (closest point on rectangle)
	var cp := Vector2(clampf(p.x, plot_rect.position.x, plot_rect.end.x), clampf(p.y, plot_rect.position.y, plot_rect.end.y))
	var dp: float = p.distance_to(cp)
	if dp < best_d and crop_state != CROP_GROWING:
		best_d = dp
		best = {"kind": "plot", "label": "E: plant crop" if crop_state == CROP_EMPTY else "E: harvest crop"}
	# nest
	if nest_completion() < 100.0:
		var dn: float = p.distance_to(nest_pos) - Config.NEST_RADIUS
		if dn < best_d:
			best_d = dn
			best = {"kind": "nest", "label": "E: add materials to nest"}
	# boundary posts
	for post in posts:
		if post["marked"]:
			continue
		var dq: float = p.distance_to(post["pos"]) - 10.0
		if dq < best_d:
			best_d = dq
			best = {"kind": "post", "ref": post, "label": "E: mark post" if scent_unlocked else "Post (scent locked)"}
	return best

func interact() -> void:
	if won or player == null:
		return
	var t := find_target()
	if t.is_empty():
		return
	match t["kind"]:
		"resource":
			_gather(t["ref"])
		"plot":
			_use_plot()
		"nest":
			_deposit()
		"post":
			_mark_post(t["ref"])

func _gather(r: Dictionary) -> void:
	if r["charges"] <= 0:
		return
	var type: String = r["type"]
	if inventory[type] >= Config.INVENTORY_CAP_PER_TYPE:
		hud.toast("Your pack is full of %s." % type)
		return
	r["charges"] -= 1
	if player != null:
		player.play_action("chop" if type == "wood" else "pick")
	if r["charges"] <= 0:
		r["regrow"] = r["total"]
	inventory[type] += 1
	total_gathered += 1
	hud.toast("+1 %s" % type)

func _use_plot() -> void:
	if crop_state == CROP_EMPTY:
		crop_state = CROP_GROWING
		crop_timer = Config.CROP_GROW_SECONDS
		player.play_action("plant")
		hud.toast("Planted a crop. It will be ready in %d seconds." % int(Config.CROP_GROW_SECONDS))
	elif crop_state == CROP_READY:
		crop_state = CROP_EMPTY
		player.play_action("harvest")
		inventory["crops"] += 1
		if not crop_harvested:
			hud.toast("First harvest! Happiness +%d (provisional)." % int(Config.HAPPINESS_CROP_BONUS))
		else:
			hud.toast("Harvested another crop.")
		crop_harvested = true

func _deposit() -> void:
	var moved := 0
	for k in Config.NEST_COST:
		var room: int = Config.NEST_COST[k] - nest_deposited[k]
		var n: int = mini(inventory[k], room)
		if n > 0:
			inventory[k] -= n
			nest_deposited[k] += n
			moved += n
	if moved == 0:
		hud.toast("The nest needs wood, grass and leaves. Gather some first!")
	else:
		hud.toast("Added %d materials. Nest %d%% complete." % [moved, int(nest_completion())])

func _mark_post(post: Dictionary) -> void:
	if post["marked"]:
		return
	if not scent_unlocked:
		hud.toast("Scent is locked until the nest reaches %d%% (provisional)." % int(Config.SCENT_UNLOCK_NEST_PERCENT))
		return
	post["marked"] = true
	hud.toast("Post marked (%d/%d)." % [posts_marked(), Config.POSTS_TO_MARK])

func toggle_scent() -> void:
	if not scent_unlocked:
		hud.toast("Scent is locked until the nest reaches %d%% (provisional)." % int(Config.SCENT_UNLOCK_NEST_PERCENT))
		return
	scent_on = not scent_on

func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_E:
			interact()
		KEY_Q:
			toggle_scent()
		KEY_R:
			get_tree().reload_current_scene()

# ---------- per-frame ----------

func _process(delta: float) -> void:
	time += delta
	if crop_state == CROP_GROWING:
		crop_timer -= delta
		if crop_timer <= 0.0:
			crop_timer = 0.0
			crop_state = CROP_READY
			hud.toast("Your crop is ready to harvest!")
	for r in resources:
		if r["charges"] <= 0:
			r["regrow"] -= delta
			if r["regrow"] <= 0.0:
				r["charges"] = Config.RESOURCE_CHARGES
	if not scent_unlocked and nest_completion() >= Config.SCENT_UNLOCK_NEST_PERCENT:
		scent_unlocked = true
		scent_on = true
		hud.toast("Scent unlocked! Press Q to toggle the glowing trail.")
	var tier := nest_tier()
	if tier > last_tier:
		hud.toast("Nest milestone: %d%%! It looks cosier." % (tier * Config.NEST_MILESTONE_STEP))
	last_tier = tier
	if not won and objectives().all(func(o): return o[1]):
		won = true
	var target := find_target()
	current_prompt = "" if (won or target.is_empty()) else str(target["label"])
	hud.update_view({
		"inventory": inventory,
		"nest_pct": nest_completion(),
		"happiness": happiness(),
		"influence": influence(),
		"scent_unlocked": scent_unlocked,
		"scent_on": scent_on,
		"posts_marked": posts_marked(),
		"objectives": objectives(),
		"prompt": current_prompt,
		"player_pos": player.position,
		"won": won,
	})
	queue_redraw()

# ---------- drawing (primitive placeholder art) ----------

func _draw() -> void:
	var t: Rect2 = Config.TERRITORY
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Config.COL_BG)
	draw_rect(t, Config.COL_GRASS)
	for s in speckles:
		draw_line(s, s + Vector2(3, -6), Config.COL_SPECKLE, 2.0)
	draw_rect(t, Config.COL_BORDER, false, 4.0)
	_draw_plot()
	for r in resources:
		_draw_resource(r)
	_draw_nest()
	for p in posts:
		_draw_post(p)
	if scent_unlocked and scent_on and player != null:
		_draw_scent()

func _draw_plot() -> void:
	var tex: Texture2D = TEX_PLOT_EMPTY
	if crop_state == CROP_GROWING:
		var prog := 1.0 - crop_timer / Config.CROP_GROW_SECONDS
		if prog < 0.34:
			tex = TEX_PLOT_SEEDED
		elif prog < 0.67:
			tex = TEX_PLOT_SPROUT
		else:
			tex = TEX_PLOT_GROWING
	elif crop_state == CROP_READY:
		tex = TEX_PLOT_RIPE
	draw_texture(tex, plot_rect.position - PLOT_PAD)
	if crop_state == CROP_READY:
		_draw_star(Vector2(plot_rect.end.x - 6.0, plot_rect.position.y - 34.0), 9.0 + 2.0 * sin(time * 4.0))
		_draw_star(Vector2(plot_rect.position.x + 8.0, plot_rect.position.y - 12.0), 6.0 + 1.5 * sin(time * 5.0 + 1.0))

func _draw_star(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0 - PI / 2.0
		var rad := r if i % 2 == 0 else r * 0.3
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	draw_colored_polygon(pts, Color("ffe38a"))

func _draw_resource(r: Dictionary) -> void:
	var pos: Vector2 = r["pos"]
	var type: String = r["type"]
	var tex: Texture2D = TEX_RESOURCE[type]
	var base := pos + Vector2(0, 20)       # ground point under the node
	var grown: bool = r["charges"] > 0
	var p := 1.0 if grown else clampf(1.0 - r["regrow"] / r["total"], 0.0, 1.0)   # regrowth progress 0..1
	if type == "wood":
		if grown or p >= 0.5:
			var sc := 1.0 if grown else 0.4 + 0.6 * ((p - 0.5) / 0.5)           # sapling grows back
			var size := tex.get_size() * sc
			draw_texture_rect(tex, Rect2(base - Vector2(size.x / 2.0, size.y), size), false)
		else:
			draw_texture(TEX_STUMP, base - Vector2(TEX_STUMP.get_size().x / 2.0, TEX_STUMP.get_size().y))
	else:
		var sc2 := 1.0 if grown else 0.3 + 0.7 * p                              # regrows from a tiny shoot
		var size2 := tex.get_size() * sc2
		draw_texture_rect(tex, Rect2(pos + Vector2(-size2.x / 2.0, 12.0 - size2.y), size2), false, Color(1, 1, 1, 1.0 if grown else 0.75))

func _draw_nest() -> void:
	var tier := nest_tier()
	var c := nest_pos
	var rad: float = Config.NEST_RADIUS
	draw_circle(c, rad * 0.9, Color(0.85, 0.73, 0.61, nest_completion() / 200.0))
	draw_arc(c, rad, 0.0, TAU, 48, Color("c9a7b8"), 3.0)
	if tier >= 1:
		draw_circle(c, rad * 0.9, Color("d9b99b"))
	if tier >= 2:
		draw_circle(c, rad * 0.62, Color("f6c9d8"))
	if tier >= 3:
		draw_arc(c + Vector2(0, -4), rad * 0.95, PI, TAU, 32, Config.COL_LAVENDER, 8.0)
	if tier >= 4:
		for i in 6:
			var a := TAU * i / 6.0 + time * 0.5
			draw_circle(c + Vector2(cos(a), sin(a)) * (rad + 14.0), 6.0, Color("ff9fc0"))

func _draw_post(p: Dictionary) -> void:
	var pos: Vector2 = p["pos"]
	if p["marked"]:
		var pulse := 0.5 + 0.5 * sin(time * 3.0)
		draw_circle(pos, 22.0 + 4.0 * pulse, Color(1.0, 0.65, 0.8, 0.25))
	draw_rect(Rect2(pos.x - 4, pos.y - 14, 8, 30), Color("c9a98f"))
	draw_circle(pos + Vector2(0, -16), 7.0, Config.COL_PINK if p["marked"] else Color("e6d6cc"))

func _draw_scent() -> void:
	var rng_d := scent_range()
	var pp: Vector2 = player.position
	draw_arc(pp, rng_d, 0.0, TAU, 64, Color(1.0, 0.7, 0.85, 0.3), 2.0)
	for i in scent_trail.size():
		var pt := scent_trail[i]
		var d := pt.distance_to(pp)
		if d > rng_d:
			continue
		var fade := 1.0 - d / rng_d
		var pulse := 0.75 + 0.25 * sin(time * 3.0 + i * 0.5)
		draw_circle(pt, 14.0 * pulse, Color(1.0, 0.75, 0.9, 0.22 * fade + 0.05))
		draw_circle(pt, 6.0, Color(1.0, 0.6, 0.8, 0.35 + 0.55 * fade))
