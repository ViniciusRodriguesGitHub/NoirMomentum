extends Node2D

const LEVEL_WIDTH := 3200.0

var smoke_puffs: Array[Dictionary] = []
var motes: Array[Dictionary] = []
var dust_particles: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 11703
	_create_ambient_smoke()
	_create_motes()
	queue_redraw()


func _process(delta: float) -> void:
	_update_smoke(delta)
	_update_motes(delta)
	_update_dust(delta)
	queue_redraw()


func spawn_dust(origin: Vector2, direction: float, strength: float) -> void:
	var particle_count := int(8.0 + strength * 15.0)

	for _index in range(particle_count):
		var life := rng.randf_range(0.28, 0.58) * (0.8 + strength * 0.35)
		dust_particles.append({
			"position": origin + Vector2(
				rng.randf_range(-13.0, 13.0),
				rng.randf_range(-5.0, 2.0)
			),
			"velocity": Vector2(
				-direction * rng.randf_range(45.0, 155.0) * (0.7 + strength * 0.5),
				-rng.randf_range(18.0, 92.0) * strength
			),
			"life": life,
			"max_life": life,
			"size": rng.randf_range(2.2, 6.5) * (0.65 + strength * 0.35),
		})


func _create_ambient_smoke() -> void:
	for _index in range(44):
		smoke_puffs.append({
			"position": Vector2(
				rng.randf_range(0.0, LEVEL_WIDTH),
				rng.randf_range(410.0, 610.0)
			),
			"radius": rng.randf_range(42.0, 125.0),
			"speed": rng.randf_range(4.0, 15.0),
			"alpha": rng.randf_range(0.012, 0.038),
			"phase": rng.randf_range(0.0, TAU),
		})


func _create_motes() -> void:
	for _index in range(90):
		motes.append({
			"position": Vector2(
				rng.randf_range(0.0, LEVEL_WIDTH),
				rng.randf_range(70.0, 590.0)
			),
			"speed": rng.randf_range(5.0, 24.0),
			"drift": rng.randf_range(-7.0, 7.0),
			"size": rng.randf_range(0.7, 2.1),
			"alpha": rng.randf_range(0.09, 0.34),
		})


func _update_smoke(delta: float) -> void:
	var elapsed := Time.get_ticks_msec() / 1000.0

	for index in range(smoke_puffs.size()):
		var puff := smoke_puffs[index]
		var position: Vector2 = puff["position"]
		position.x += float(puff["speed"]) * delta
		position.y += sin(elapsed * 0.32 + float(puff["phase"])) * 1.7 * delta

		if position.x - float(puff["radius"]) > LEVEL_WIDTH:
			position.x = -float(puff["radius"])

		puff["position"] = position
		smoke_puffs[index] = puff


func _update_motes(delta: float) -> void:
	for index in range(motes.size()):
		var mote := motes[index]
		var position: Vector2 = mote["position"]
		position.y -= float(mote["speed"]) * delta
		position.x += float(mote["drift"]) * delta

		if position.y < 55.0:
			position.y = 615.0
			position.x = rng.randf_range(0.0, LEVEL_WIDTH)
		if position.x < 0.0:
			position.x = LEVEL_WIDTH
		elif position.x > LEVEL_WIDTH:
			position.x = 0.0

		mote["position"] = position
		motes[index] = mote


func _update_dust(delta: float) -> void:
	for index in range(dust_particles.size() - 1, -1, -1):
		var particle := dust_particles[index]
		var position: Vector2 = particle["position"]
		var particle_velocity: Vector2 = particle["velocity"]
		var life: float = particle["life"]

		life -= delta
		if life <= 0.0:
			dust_particles.remove_at(index)
			continue

		particle_velocity.y += 165.0 * delta
		particle_velocity.x = move_toward(particle_velocity.x, 0.0, 85.0 * delta)
		position += particle_velocity * delta

		particle["position"] = position
		particle["velocity"] = particle_velocity
		particle["life"] = life
		dust_particles[index] = particle


func _draw() -> void:
	for puff in smoke_puffs:
		var position: Vector2 = puff["position"]
		var radius: float = puff["radius"]
		var alpha: float = puff["alpha"]
		draw_circle(position, radius, Color(0.23, 0.22, 0.24, alpha))
		draw_circle(
			position + Vector2(radius * 0.42, -radius * 0.08),
			radius * 0.68,
			Color(0.32, 0.27, 0.25, alpha * 0.65)
		)

	for mote in motes:
		var position: Vector2 = mote["position"]
		var size: float = mote["size"]
		var alpha: float = mote["alpha"]
		draw_line(
			position,
			position + Vector2(0.0, size * 3.0),
			Color(0.92, 0.61, 0.35, alpha),
			size
		)

	for particle in dust_particles:
		var position: Vector2 = particle["position"]
		var life_ratio: float = particle["life"] / particle["max_life"]
		var size: float = particle["size"] * (0.6 + (1.0 - life_ratio) * 0.9)
		draw_circle(
			position,
			size,
			Color(0.66, 0.49, 0.36, life_ratio * 0.52)
		)

