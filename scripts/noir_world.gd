extends Node2D

signal player_hit_hazard
signal light_collected
signal finish_reached

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

var wall_jump_obstacles: Array[Rect2] = [
	Rect2(2800, 200, 144, 24),
	Rect2(2920, 220, 24, 300),
	Rect2(3120, 120, 24, 480),
]

var special_platforms: Array[Rect2] = [
	Rect2(350, 410, 150, 20),
	Rect2(1280, 330, 130, 20),
	Rect2(2660, 300, 130, 20),
]

var crawl_obstacles: Array[Rect2] = [
	Rect2(2020, 526, 170, 24),
]

var spike_zones: Array[Rect2] = [
	Rect2(1615, 570, 65, 30),
	Rect2(2415, 570, 85, 30),
]

var light_points := PackedVector2Array([
	Vector2(425, 372),
	Vector2(930, 565),
	Vector2(1345, 292),
	Vector2(2110, 574),
	Vector2(2725, 262),
	Vector2(2870, 162),
])

var collected_lights: Dictionary = {}
var lamp_positions := PackedFloat32Array([430.0, 1120.0, 1900.0, 2760.0])
var buildings: Array[Rect2] = []


func _ready() -> void:
	_build_skyline()
	_add_solid(Rect2(0, GROUND_TOP, LEVEL_WIDTH, 160), "Ground")

	for index in range(platforms.size()):
		_add_solid(platforms[index], "Platform_%02d" % index)

	for index in range(wall_jump_obstacles.size()):
		_add_solid(
			wall_jump_obstacles[index],
			"WallJump_%02d" % index
		)

	for index in range(special_platforms.size()):
		_add_solid(
			special_platforms[index],
			"SpecialPlatform_%02d" % index
		)

	for index in range(crawl_obstacles.size()):
		_add_solid(crawl_obstacles[index], "CrawlTunnel_%02d" % index)

	for index in range(spike_zones.size()):
		_add_spike_zone(spike_zones[index], index)

	for index in range(light_points.size()):
		_add_light_pickup(light_points[index], index)

	_add_finish_zone()
	queue_redraw()


func _process(_delta: float) -> void:
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


func _add_spike_zone(rect: Rect2, index: int) -> void:
	var area := Area2D.new()
	area.name = "Spikes_%02d" % index
	area.monitoring = true
	area.body_entered.connect(_on_spike_body_entered)

	var shape := RectangleShape2D.new()
	shape.size = rect.size

	var collision := CollisionShape2D.new()
	collision.position = rect.get_center()
	collision.shape = shape

	area.add_child(collision)
	add_child(area)


func _on_spike_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_hit_hazard.emit()


func _add_light_pickup(position: Vector2, index: int) -> void:
	var area := Area2D.new()
	area.name = "Light_%02d" % index
	area.position = position
	area.monitoring = true
	area.body_entered.connect(_on_light_body_entered.bind(index, area))

	var shape := CircleShape2D.new()
	shape.radius = 17.0

	var collision := CollisionShape2D.new()
	collision.shape = shape
	area.add_child(collision)
	add_child(area)


func _on_light_body_entered(body: Node2D, index: int, area: Area2D) -> void:
	if not body.is_in_group("player") or collected_lights.has(index):
		return

	collected_lights[index] = true
	area.set_deferred("monitoring", false)
	area.queue_free()
	light_collected.emit()
	queue_redraw()


func get_total_lights() -> int:
	return light_points.size()


func _add_finish_zone() -> void:
	var area := Area2D.new()
	area.name = "FinishZone"
	area.position = Vector2(3175, 300)
	area.monitoring = true
	area.body_entered.connect(_on_finish_body_entered)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(50, 600)

	var collision := CollisionShape2D.new()
	collision.shape = shape
	area.add_child(collision)
	add_child(area)


func _on_finish_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		finish_reached.emit()


func _draw() -> void:
	_draw_background()
	_draw_skyline()
	_draw_warm_lights()
	_draw_platforms()
	_draw_special_platforms()
	_draw_wall_jump_obstacle()
	_draw_crawl_obstacles()
	_draw_ground()
	_draw_spikes()
	_draw_light_pickups()
	_draw_finish_gate()
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


func _draw_special_platforms() -> void:
	for platform in special_platforms:
		draw_rect(platform, Color(0.07, 0.055, 0.06, 1.0), true)
		draw_rect(
			Rect2(platform.position, Vector2(platform.size.x, 4.0)),
			Color(0.92, 0.48, 0.22, 0.95),
			true
		)
		for x in range(
			int(platform.position.x) + 12,
			int(platform.end.x) - 6,
			24
		):
			draw_circle(
				Vector2(x, platform.position.y + 10.0),
				2.2,
				Color(0.84, 0.42, 0.2, 0.7)
			)


func _draw_wall_jump_obstacle() -> void:
	for obstacle in wall_jump_obstacles:
		draw_rect(obstacle, Color(0.045, 0.042, 0.048, 1.0), true)
		draw_rect(
			Rect2(obstacle.position, Vector2(obstacle.size.x, 4.0)),
			Color(0.44, 0.23, 0.13, 0.95),
			true
		)

	for y in range(255, 510, 42):
		draw_line(
			Vector2(2944, y),
			Vector2(2960, y + 8),
			Color(0.84, 0.43, 0.21, 0.72),
			3.0
		)
		draw_line(
			Vector2(3104, y + 8),
			Vector2(3120, y),
			Color(0.84, 0.43, 0.21, 0.72),
			3.0
		)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(2958, 560),
		"PAREDE",
		HORIZONTAL_ALIGNMENT_LEFT,
		130.0,
		13,
		Color(0.66, 0.42, 0.28, 0.9)
	)


func _draw_crawl_obstacles() -> void:
	for obstacle in crawl_obstacles:
		draw_rect(obstacle, Color(0.05, 0.046, 0.052, 1.0), true)
		draw_rect(
			Rect2(obstacle.position, Vector2(obstacle.size.x, 4.0)),
			Color(0.5, 0.25, 0.13, 0.9),
			true
		)
		draw_line(
			Vector2(obstacle.position.x + 8.0, obstacle.end.y - 5.0),
			Vector2(obstacle.end.x - 8.0, obstacle.end.y - 5.0),
			Color(0.17, 0.1, 0.08, 0.9),
			2.0
		)


func _draw_spikes() -> void:
	for zone in spike_zones:
		var spike_width := 17.0
		var x := zone.position.x
		while x < zone.end.x:
			var right := minf(x + spike_width, zone.end.x)
			var points := PackedVector2Array([
				Vector2(x, GROUND_TOP),
				Vector2((x + right) * 0.5, zone.position.y),
				Vector2(right, GROUND_TOP),
			])
			draw_colored_polygon(
				points,
				Color(0.46, 0.2, 0.13, 1.0)
			)
			draw_polyline(
				PackedVector2Array([points[0], points[1], points[2]]),
				Color(0.94, 0.48, 0.24, 0.9),
				2.0
			)
			x += spike_width


func _draw_light_pickups() -> void:
	var elapsed := Time.get_ticks_msec() / 1000.0
	for index in range(light_points.size()):
		if collected_lights.has(index):
			continue

		var position := light_points[index]
		var pulse := 1.0 + sin(elapsed * 3.2 + index) * 0.12
		for ring in range(4, 0, -1):
			draw_circle(
				position,
				float(ring) * 7.0 * pulse,
				Color(1.0, 0.55, 0.24, 0.018 * (5 - ring))
			)
		draw_circle(
			position,
			7.0 * pulse,
			Color(1.0, 0.72, 0.34, 0.95)
		)
		draw_circle(
			position + Vector2(-2.0, -2.0),
			2.2,
			Color(1.0, 0.94, 0.72, 1.0)
		)


func _draw_finish_gate() -> void:
	var gate_x := 3160.0
	draw_line(
		Vector2(gate_x, 600),
		Vector2(gate_x, 155),
		Color(0.12, 0.08, 0.07, 1.0),
		8.0
	)
	draw_line(
		Vector2(gate_x - 34, 155),
		Vector2(gate_x + 34, 155),
		Color(0.94, 0.47, 0.22, 0.9),
		5.0
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(gate_x - 52, 140),
		"FIM",
		HORIZONTAL_ALIGNMENT_CENTER,
		104.0,
		18,
		Color(1.0, 0.7, 0.36, 1.0)
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
