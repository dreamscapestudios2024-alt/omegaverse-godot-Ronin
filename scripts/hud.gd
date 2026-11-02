extends CanvasLayer
## HUD: inventory, nest %, happiness, influence, scent status, objectives, prompts.
## Built in code with rounded pastel panels. Receives a plain Dictionary each frame.

const Config = preload("res://scripts/config.gd")

var inv_label: Label
var nest_bar: ProgressBar
var nest_value: Label
var happy_bar: ProgressBar
var happy_value: Label
var influence_label: Label
var status_label: Label
var obj_label: Label
var prompt_label: Label
var toast_label: Label
var toast_panel: PanelContainer
var banner: PanelContainer
var toast_time := 0.0

func _ready() -> void:
	_build()

func _style(bg: Color, border: Color = Color("a18aca")) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(10)
	sb.set_border_width_all(2)
	sb.border_color = border
	return sb

func _panel(pos: Vector2, min_w: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = pos
	p.custom_minimum_size = Vector2(min_w, 0)
	p.add_theme_stylebox_override("panel", _style(Color(1.0, 0.97, 0.98, 0.94)))
	add_child(p)
	return p

func _label(text: String, size: int = 15) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Config.COL_TEXT)
	return l

func _wrap(l: Label, width: float) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l

func _bar(fill: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0.0
	b.max_value = 100.0
	b.show_percentage = false
	b.custom_minimum_size = Vector2(130, 16)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("eadbe6")
	bg.set_corner_radius_all(8)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(8)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b

func _build() -> void:
	# Top bar
	var top := _panel(Vector2(12, 8), 780)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	top.add_child(vb)
	inv_label = _label("")
	vb.add_child(inv_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	row.add_child(_label("Nest"))
	nest_bar = _bar(Config.COL_PINK)
	row.add_child(nest_bar)
	nest_value = _label("0%")
	nest_value.custom_minimum_size = Vector2(40, 0)
	row.add_child(nest_value)
	row.add_child(_label("Happiness"))
	happy_bar = _bar(Config.COL_MINT)
	row.add_child(happy_bar)
	happy_value = _label("0%")
	happy_value.custom_minimum_size = Vector2(40, 0)
	row.add_child(happy_value)
	influence_label = _label("")
	row.add_child(influence_label)
	status_label = _label("", 14)
	vb.add_child(status_label)

	# Objectives
	var obj := _panel(Vector2(824, 124), 304)
	var ovb := VBoxContainer.new()
	obj.add_child(ovb)
	ovb.add_child(_label("Objectives", 18))
	obj_label = _wrap(_label(""), 280)
	ovb.add_child(obj_label)

	# Controls
	var ctl := _panel(Vector2(824, 336), 304)
	ctl.add_child(_wrap(_label("WASD / Arrows: move\nE: interact (gather, plant, harvest, deposit, mark)\nQ: toggle scent (once unlocked)\nR: restart", 14), 280))

	# Toast
	toast_panel = _panel(Vector2(824, 470), 304)
	toast_label = _wrap(_label(""), 280)
	toast_panel.add_child(toast_label)
	toast_panel.visible = false

	# Floating prompt near the player
	prompt_label = _label("", 15)
	prompt_label.add_theme_color_override("font_outline_color", Color.WHITE)
	prompt_label.add_theme_constant_override("outline_size", 8)
	add_child(prompt_label)

	# Success banner
	banner = PanelContainer.new()
	banner.position = Vector2(150, 250)
	banner.custom_minimum_size = Vector2(500, 0)
	banner.add_theme_stylebox_override("panel", _style(Color(0.88, 0.97, 0.92, 0.97), Color("6fbf8f")))
	var bvb := VBoxContainer.new()
	banner.add_child(bvb)
	var title := _label("Your nest is home. All objectives complete!", 24)
	bvb.add_child(_wrap(title, 470))
	bvb.add_child(_wrap(_label("A gentle first chapter finished. Press R to play again.", 16), 470))
	banner.visible = false
	add_child(banner)

func toast(text: String) -> void:
	toast_label.text = text
	toast_panel.visible = true
	toast_time = 4.0

func _process(delta: float) -> void:
	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast_panel.visible = false

func update_view(s: Dictionary) -> void:
	var inv: Dictionary = s["inventory"]
	inv_label.text = "Wood %d    Grass %d    Leaves %d    Crops %d" % [inv["wood"], inv["grass"], inv["leaves"], inv["crops"]]
	nest_bar.value = s["nest_pct"]
	nest_value.text = "%d%%" % int(s["nest_pct"])
	happy_bar.value = s["happiness"]
	happy_value.text = "%d%%" % int(s["happiness"])
	influence_label.text = "Influence %d (provisional)" % int(s["influence"])
	if s["scent_unlocked"]:
		status_label.text = "Scent: %s (Q)    Posts marked: %d/%d" % ["ON" if s["scent_on"] else "off", s["posts_marked"], Config.POSTS_TO_MARK]
	else:
		status_label.text = "Scent locked until nest reaches %d%% (provisional)    Posts marked: %d/%d" % [int(Config.SCENT_UNLOCK_NEST_PERCENT), s["posts_marked"], Config.POSTS_TO_MARK]
	var lines := PackedStringArray()
	for o in s["objectives"]:
		lines.append(("[x] " if o[1] else "[ ] ") + o[0])
	obj_label.text = "\n".join(lines)
	var pr: String = s["prompt"]
	prompt_label.text = pr
	prompt_label.visible = pr != ""
	var pp: Vector2 = s["player_pos"]
	prompt_label.position = Vector2(maxf(pp.x - 70.0, 4.0), pp.y - 46.0)
	banner.visible = s["won"]
