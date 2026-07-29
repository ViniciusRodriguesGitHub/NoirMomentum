extends CanvasLayer

var state_label: Label


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
		"A/D ou ←/→  •  toque duplo: correr  •  ↓ durante a corrida: deslizar"
		+ "  •  direção contrária: derrapar  •  Espaço: pular  •  R: reiniciar"
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


func set_state(label: String) -> void:
	if state_label:
		state_label.text = "ESTADO • " + label


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
