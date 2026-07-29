extends CanvasLayer

var state_label: Label
var light_label: Label
var timer_label: Label
var finish_label: Label


func _ready() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var title_panel := PanelContainer.new()
	title_panel.anchor_left = 0.0
	title_panel.anchor_top = 0.0
	title_panel.anchor_right = 0.0
	title_panel.anchor_bottom = 0.0
	title_panel.offset_left = 24.0
	title_panel.offset_top = 22.0
	title_panel.offset_right = 330.0
	title_panel.offset_bottom = 94.0
	title_panel.add_theme_stylebox_override("panel", _make_panel_style())
	root.add_child(title_panel)

	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 2)
	title_panel.add_child(title_box)

	var title := Label.new()
	title.text = "NOIR MOMENTUM"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.94, 0.70, 0.48, 1.0))
	title_box.add_child(title)

	state_label = Label.new()
	state_label.text = "ESTADO • PARADO"
	state_label.add_theme_font_size_override("font_size", 13)
	state_label.add_theme_color_override(
		"font_color",
		Color(0.68, 0.66, 0.65, 0.95)
	)
	title_box.add_child(state_label)

	var hint_panel := PanelContainer.new()
	hint_panel.anchor_left = 0.5
	hint_panel.anchor_top = 1.0
	hint_panel.anchor_right = 0.5
	hint_panel.anchor_bottom = 1.0
	hint_panel.offset_left = -410.0
	hint_panel.offset_top = -69.0
	hint_panel.offset_right = 410.0
	hint_panel.offset_bottom = -20.0
	hint_panel.add_theme_stylebox_override("panel", _make_panel_style())
	root.add_child(hint_panel)

	var controls := Label.new()
	controls.text = (
		"A/D ou ←/→  •  toque duplo: correr  •  ↓ correndo: deslizar"
		+ "  •  ↓ parado: carregar  •  ↓ + direção: agachar"
		+ "  •  toque em Espaço: salto curto"
		+ "  •  segure Espaço: salto normal  •  R: reiniciar"
	)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_color_override(
		"font_color",
		Color(0.82, 0.80, 0.78, 1.0)
	)
	hint_panel.add_child(controls)

	var prototype := Label.new()
	prototype.anchor_left = 1.0
	prototype.anchor_top = 0.0
	prototype.anchor_right = 1.0
	prototype.anchor_bottom = 0.0
	prototype.offset_left = -210.0
	prototype.offset_top = 28.0
	prototype.offset_right = -25.0
	prototype.offset_bottom = 54.0
	prototype.text = "PROTÓTIPO 01"
	prototype.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prototype.add_theme_font_size_override("font_size", 13)
	prototype.add_theme_color_override(
		"font_color",
		Color(0.55, 0.50, 0.47, 0.9)
	)
	root.add_child(prototype)

	light_label = Label.new()
	light_label.anchor_left = 1.0
	light_label.anchor_top = 0.0
	light_label.anchor_right = 1.0
	light_label.anchor_bottom = 0.0
	light_label.offset_left = -250.0
	light_label.offset_top = 55.0
	light_label.offset_right = -25.0
	light_label.offset_bottom = 88.0
	light_label.text = "LUZES  0 / 0"
	light_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	light_label.add_theme_font_size_override("font_size", 18)
	light_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.68, 0.32, 1.0)
	)
	root.add_child(light_label)

	timer_label = Label.new()
	timer_label.anchor_left = 0.5
	timer_label.anchor_top = 0.0
	timer_label.anchor_right = 0.5
	timer_label.anchor_bottom = 0.0
	timer_label.offset_left = -240.0
	timer_label.offset_top = 25.0
	timer_label.offset_right = 240.0
	timer_label.offset_bottom = 55.0
	timer_label.text = "TEMPO  00:00.000   •   MELHOR  --:--.---"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 16)
	timer_label.add_theme_color_override(
		"font_color",
		Color(0.84, 0.8, 0.76, 0.95)
	)
	root.add_child(timer_label)

	finish_label = Label.new()
	finish_label.anchor_left = 0.5
	finish_label.anchor_top = 0.42
	finish_label.anchor_right = 0.5
	finish_label.anchor_bottom = 0.42
	finish_label.offset_left = -330.0
	finish_label.offset_top = -45.0
	finish_label.offset_right = 330.0
	finish_label.offset_bottom = 45.0
	finish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	finish_label.add_theme_font_size_override("font_size", 25)
	finish_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.68, 0.32, 1.0)
	)
	root.add_child(finish_label)


func set_state(label: String) -> void:
	if state_label:
		state_label.text = "ESTADO • " + label


func set_light_count(collected: int, total: int) -> void:
	if light_label:
		light_label.text = "LUZES  %d / %d" % [collected, total]


func set_timer(current_time: float, best_time: float) -> void:
	if not timer_label:
		return

	var best_text := "--:--.---"
	if is_finite(best_time):
		best_text = _format_time(best_time)
	timer_label.text = (
		"TEMPO  "
		+ _format_time(current_time)
		+ "   •   MELHOR  "
		+ best_text
	)


func show_finish_message(message: String) -> void:
	if finish_label:
		finish_label.text = message


func _format_time(value: float) -> String:
	var total_milliseconds := int(value * 1000.0)
	var minutes := total_milliseconds / 60000
	var seconds := (total_milliseconds / 1000) % 60
	var milliseconds := total_milliseconds % 1000
	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.019, 0.025, 0.88)
	style.border_color = Color(0.42, 0.25, 0.16, 0.58)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style
