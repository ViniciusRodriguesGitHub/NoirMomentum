extends Node2D

const LEVEL_WIDTH := 3200.0
const GROUND_TOP := 600.0

var platforms: Array[Rect2] = [
	Rect2(690, 520, 340, 24),
	Rect2(1120, 455, 240, 24),
	Rect2(1390, 525, 190, 24),
	Rect2(1760, 470, 260, 24),
	Rect2(2190, 520, 190, 24),
	Rect2(2520, 445, 250, 24),
]

var lamp_positions := PackedFloat32Array([430.0, 1120.0, 1900.0, 2760.0])
var buildings: Array[Rect2] = []


func _ready() -> void:
	_build_skyline()
	_add_solid(Rect2(0, GROUND_TOP, LEVEL_WIDTH, 160), "Ground")

	for index in range(platforms.size()):
		_add_solid(platforms[index], "Platform_%02d" % index)

	queue_redraw()


func _build_skyline() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91357
	var x := -40.0

	while x < LEVEL_WIDTH + 80.0:
		var width := rng.randf_range(105.0, 225.0)
		var height := rng.randf_range(150.0, 370.0)
		buildings.append(Rect2(x, GROUND_TOP - height, width, height))
		x += width - rng.randf_range(8.0, 22.0)


func _add_solid(rect: Rect2, body_name: String) -> void:
	var body := StaticBody2D.new()
	body.name = body_name

	var shape := RectangleShape2D.new()
	shape.size = rect.size

	var collision := CollisionShape2D.new()
	collision.position = rect.get_center()
	collision.shape = shape

	body.add_child(collision)
	add_child(body)


func _draw() -> void:
	_draw_background()
	_draw_skyline()
	_draw_warm_lights()
	_draw_platforms()
	_draw_ground()
	_draw_lamps()


func _draw_background() -> void:
	draw_rect(
		Rect2(0, 0, LEVEL_WIDTH, 720),
		Color(0.014, 0.015, 0.022, 1.0),
		true
	)

	for band in range(12):
		var band_height := 60.0
		var shade := 0.014 + float(band) * 0.0017
		draw_rect(
			Rect2(0, band * band_height, LEVEL_WIDTH, band_height + 1.0),
			Color(shade, shade * 0.97, shade * 1.1, 1.0),
			true
		)

	var moon_center := Vector2(310, 155)
	for ring in range(8, 0, -1):
		draw_circle(
			moon_center,
			float(ring) * 15.0,
			Color(0.82, 0.60, 0.42, 0.008 + (8 - ring) * 0.006)
		)
	draw_circle(moon_center, 27.0, Color(0.56, 0.45, 0.37, 0.16))


func _draw_skyline() -> void:
	for index in range(buildings.size()):
		var building := buildings[index]
		var depth_shift := float(index % 4) * 0.004
		draw_rect(
			building,
			Color(
				0.028 + depth_shift,
				0.029 + depth_shift,
				0.037 + depth_shift,
				1.0
			),
			true
		)

		draw_line(
			Vector2(building.position.x, building.position.y),
			Vector2(building.end.x, building.position.y),
			Color(0.13, 0.10, 0.09, 0.35),
			2.0
		)

		var window_y := building.position.y + 30.0
		var row := 0
		while window_y < building.end.y - 45.0:
			var window_x := building.position.x + 24.0
			var column := 0
			while window_x < building.end.x - 18.0:
				if (index * 5 + row * 3 + column * 7) % 11 == 0:
					draw_rect(
						Rect2(window_x, window_y, 8, 13),
						Color(0.84, 0.48, 0.22, 0.32),
						true
					)
				else:
					draw_rect(
						Rect2(window_x, window_y, 7, 12),
						Color(0.08, 0.075, 0.085, 0.45),
						true
					)
				window_x += 31.0
				column += 1
			window_y += 34.0
			row += 1


func _draw_warm_lights() -> void:
	for lamp_x in lamp_positions:
		var glow_center := Vector2(lamp_x, 360)
		for ring in range(11, 0, -1):
			var glow_radius := float(ring) * 21.0
			var alpha := 0.006 + float(11 - ring) * 0.005
			draw_circle(
				glow_center,
				glow_radius,
				Color(0.96, 0.49, 0.21, alpha)
			)


func _draw_platforms() -> void:
	for index in range(platforms.size()):
		var platform := platforms[index]
		draw_rect(platform, Color(0.055, 0.051, 0.055, 1.0), true)
		draw_rect(
			Rect2(platform.position, Vector2(platform.size.x, 4)),
			Color(0.29, 0.18, 0.12, 0.9),
			true
		)
		draw_line(
			Vector2(platform.position.x + 10, platform.end.y - 5),
			Vector2(platform.end.x - 10, platform.end.y - 5),
			Color(0.12, 0.09, 0.08, 0.65),
			2.0
		)

		if index == 0:
			var marker := Vector2(platform.get_center().x, platform.position.y - 22.0)
			draw_line(
				marker + Vector2(-12, -8),
				marker,
				Color(0.92, 0.53, 0.27, 0.82),
				3.0
			)
			draw_line(
				marker + Vector2(12, -8),
				marker,
				Color(0.92, 0.53, 0.27, 0.82),
				3.0
			)


func _draw_ground() -> void:
	draw_rect(
		Rect2(0, GROUND_TOP, LEVEL_WIDTH, 160),
		Color(0.027, 0.027, 0.032, 1.0),
		true
	)
	draw_rect(
		Rect2(0, GROUND_TOP, LEVEL_WIDTH, 5),
		Color(0.32, 0.19, 0.12, 0.88),
		true
	)

	for row in range(4):
		var y := GROUND_TOP + 20.0 + row * 31.0
		draw_line(
			Vector2(0, y),
			Vector2(LEVEL_WIDTH, y),
			Color(0.09, 0.075, 0.07, 0.55),
			1.0
		)
		var offset := 34.0 if row % 2 == 0 else 0.0
		var x := offset
		while x < LEVEL_WIDTH:
			draw_line(
				Vector2(x, y - 29.0),
				Vector2(x, y),
				Color(0.075, 0.065, 0.065, 0.5),
				1.0
			)
			x += 68.0


func _draw_lamps() -> void:
	for lamp_x in lamp_positions:
		draw_line(
			Vector2(lamp_x, GROUND_TOP),
			Vector2(lamp_x, 371),
			Color(0.075, 0.064, 0.062, 1.0),
			8.0
		)
		draw_line(
			Vector2(lamp_x - 25, GROUND_TOP),
			Vector2(lamp_x + 25, GROUND_TOP),
			Color(0.09, 0.07, 0.065, 1.0),
			5.0
		)
		draw_rect(
			Rect2(lamp_x - 24, 340, 48, 38),
			Color(0.075, 0.057, 0.05, 1.0),
			true
		)
		draw_rect(
			Rect2(lamp_x - 17, 347, 34, 24),
			Color(0.95, 0.53, 0.24, 0.72),
			true
		)
		draw_line(
			Vector2(lamp_x - 29, 340),
			Vector2(lamp_x + 29, 340),
			Color(0.15, 0.095, 0.07, 1.0),
			4.0
		)
