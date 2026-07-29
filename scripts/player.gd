extends CharacterBody2D

signal state_changed(label: String)
signal dust_requested(origin: Vector2, direction: float, strength: float)

enum MotionState {
	IDLE,
	WALK,
	RUN,
	SKID,
	SLIDE,
	AIR,
}

const WALK_SPEED := 185.0
const RUN_SPEED := 400.0
const GROUND_ACCELERATION := 1450.0
const AIR_ACCELERATION := 720.0
const GROUND_FRICTION := 1750.0
const SKID_BRAKE := 980.0
const SLIDE_FRICTION := 285.0
const SLIDE_MIN_SPEED := 138.0
const GRAVITY := 1800.0
const JUMP_SPEED := 650.0
const DOUBLE_TAP_WINDOW := 0.29
const SKID_DURATION := 0.34
const SLIDE_MIN_DURATION := 0.42
const STANDING_COLLISION_POSITION := Vector2(0, -38)
const SLIDE_COLLISION_POSITION := Vector2(0, -17)
const SLIDE_COLLISION_SIZE := Vector2(68, 34)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_state := MotionState.IDLE
var facing := 1.0
var is_running := false
var last_tap_direction := 0.0
var last_tap_time := -10.0
var skid_direction := 0.0
var pending_direction := 0.0
var skid_time_left := 0.0
var dust_time_left := 0.0
var slide_direction := 0.0
var slide_elapsed := 0.0
var motion_phase := 0.0
var visual_bob := 0.0
var visual_lean := 0.0
var standing_shape: Shape2D
var slide_shape := RectangleShape2D.new()


func _ready() -> void:
	standing_shape = collision_shape.shape
	slide_shape.size = SLIDE_COLLISION_SIZE
	queue_redraw()


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()
	var input_direction := Input.get_axis("move_left", "move_right")
	var just_pressed_direction := _get_just_pressed_direction()

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if (
		Input.is_action_just_pressed("jump")
		and is_on_floor()
		and current_state != MotionState.SKID
		and current_state != MotionState.SLIDE
	):
		velocity.y = -JUMP_SPEED
		is_running = is_running and absf(input_direction) > 0.1

	if current_state == MotionState.SLIDE:
		_process_slide(input_direction, delta)
	elif current_state == MotionState.SKID:
		_process_skid(delta)
	else:
		if (
			Input.is_action_just_pressed("slide")
			and is_on_floor()
			and is_running
			and absf(velocity.x) > WALK_SPEED * 1.35
		):
			_begin_slide()
		elif (
			just_pressed_direction != 0.0
			and is_on_floor()
			and is_running
			and absf(velocity.x) > WALK_SPEED * 1.35
			and just_pressed_direction == -signf(velocity.x)
		):
			_begin_skid(just_pressed_direction)
		else:
			if just_pressed_direction != 0.0:
				_register_direction_tap(just_pressed_direction)
			_process_regular_movement(input_direction, delta)

	move_and_slide()

	if not was_on_floor and is_on_floor():
		dust_requested.emit(global_position + Vector2(0, -2), facing, 0.35)

	_update_state()
	_update_visuals(delta)


func _process_regular_movement(input_direction: float, delta: float) -> void:
	var acceleration := GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION

	if absf(input_direction) > 0.1:
		facing = signf(input_direction)
		var target_speed := WALK_SPEED
		if is_running:
			target_speed = RUN_SPEED
		velocity.x = move_toward(
			velocity.x,
			facing * target_speed,
			acceleration * delta
		)
	else:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)
			if absf(velocity.x) <= WALK_SPEED:
				is_running = false
		else:
			velocity.x = move_toward(velocity.x, 0.0, AIR_ACCELERATION * 0.18 * delta)


func _begin_skid(new_direction: float) -> void:
	skid_direction = signf(velocity.x)
	pending_direction = new_direction
	skid_time_left = SKID_DURATION
	dust_time_left = 0.0
	is_running = false
	_set_state(MotionState.SKID)
	dust_requested.emit(
		global_position + Vector2(-skid_direction * 12.0, -3.0),
		skid_direction,
		1.0
	)


func _begin_slide() -> void:
	slide_direction = signf(velocity.x)
	if slide_direction == 0.0:
		slide_direction = facing

	facing = slide_direction
	slide_elapsed = 0.0
	dust_time_left = 0.0
	is_running = false
	_set_slide_collision(true)
	_set_state(MotionState.SLIDE)
	dust_requested.emit(
		global_position + Vector2(-slide_direction * 20.0, -3.0),
		slide_direction,
		1.15
	)


func _process_slide(input_direction: float, delta: float) -> void:
	slide_elapsed += delta
	dust_time_left -= delta

	var can_finish := (
		slide_elapsed >= SLIDE_MIN_DURATION
		and not Input.is_action_pressed("slide")
		and _can_stand()
	)

	if can_finish:
		_end_slide(input_direction)
		return

	var keep_moving := (
		Input.is_action_pressed("slide")
		or not _can_stand()
		or absf(input_direction) > 0.1
	)
	var target_speed := SLIDE_MIN_SPEED if keep_moving else 0.0
	velocity.x = move_toward(
		velocity.x,
		slide_direction * target_speed,
		SLIDE_FRICTION * delta
	)

	if dust_time_left <= 0.0 and absf(velocity.x) > SLIDE_MIN_SPEED:
		dust_time_left = 0.085
		dust_requested.emit(
			global_position + Vector2(-slide_direction * 24.0, -3.0),
			slide_direction,
			0.5
		)


func _end_slide(input_direction: float) -> void:
	_set_slide_collision(false)
	if absf(input_direction) > 0.1:
		facing = signf(input_direction)
	_set_state(MotionState.WALK)


func _set_slide_collision(sliding: bool) -> void:
	if sliding:
		collision_shape.shape = slide_shape
		collision_shape.position = SLIDE_COLLISION_POSITION
	else:
		collision_shape.shape = standing_shape
		collision_shape.position = STANDING_COLLISION_POSITION


func _can_stand() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = standing_shape
	query.transform = Transform2D(
		0.0,
		global_position + STANDING_COLLISION_POSITION + Vector2(0, -0.5)
	)
	query.collision_mask = collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [get_rid()]

	var collisions := get_world_2d().direct_space_state.intersect_shape(query, 1)
	return collisions.is_empty()


func _process_skid(delta: float) -> void:
	skid_time_left -= delta
	dust_time_left -= delta
	velocity.x = move_toward(velocity.x, 0.0, SKID_BRAKE * delta)

	if dust_time_left <= 0.0:
		dust_time_left = 0.055
		dust_requested.emit(
			global_position + Vector2(-skid_direction * 12.0, -3.0),
			skid_direction,
			0.72
		)

	if skid_time_left <= 0.0 or absf(velocity.x) < 55.0:
		facing = pending_direction
		velocity.x = facing * WALK_SPEED * 0.32
		_set_state(MotionState.WALK)


func _register_direction_tap(direction: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var is_double_tap := (
		direction == last_tap_direction
		and now - last_tap_time <= DOUBLE_TAP_WINDOW
	)

	if is_double_tap:
		is_running = true
		facing = direction
		last_tap_time = -10.0
		last_tap_direction = 0.0
	else:
		last_tap_direction = direction
		last_tap_time = now


func _get_just_pressed_direction() -> float:
	var left_pressed := Input.is_action_just_pressed("move_left")
	var right_pressed := Input.is_action_just_pressed("move_right")

	if left_pressed and not right_pressed:
		return -1.0
	if right_pressed and not left_pressed:
		return 1.0
	return 0.0


func _update_state() -> void:
	if current_state == MotionState.SKID or current_state == MotionState.SLIDE:
		return

	if not is_on_floor():
		_set_state(MotionState.AIR)
	elif absf(velocity.x) < 8.0:
		_set_state(MotionState.IDLE)
	elif is_running and absf(velocity.x) > WALK_SPEED * 1.15:
		_set_state(MotionState.RUN)
	else:
		_set_state(MotionState.WALK)


func _set_state(new_state: MotionState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(get_state_label())


func get_state_label() -> String:
	match current_state:
		MotionState.IDLE:
			return "PARADO"
		MotionState.WALK:
			return "CAMINHANDO"
		MotionState.RUN:
			return "CORRENDO"
		MotionState.SKID:
			return "DERRAPANDO"
		MotionState.SLIDE:
			return "DESLIZANDO"
		MotionState.AIR:
			return "NO AR"
	return ""


func _update_visuals(delta: float) -> void:
	var horizontal_speed := absf(velocity.x)
	motion_phase += horizontal_speed * delta * 0.038

	match current_state:
		MotionState.IDLE:
			visual_bob = sin(Time.get_ticks_msec() * 0.0024) * 1.2
			visual_lean = move_toward(visual_lean, 0.0, delta * 1.8)
		MotionState.WALK:
			visual_bob = absf(sin(motion_phase)) * -2.2
			visual_lean = move_toward(
				visual_lean,
				facing * 0.045,
				delta * 2.8
			)
		MotionState.RUN:
			visual_bob = absf(sin(motion_phase * 1.25)) * -3.5
			visual_lean = move_toward(
				visual_lean,
				facing * 0.13,
				delta * 4.0
			)
		MotionState.SKID:
			visual_bob = -1.0
			visual_lean = move_toward(
				visual_lean,
				-skid_direction * 0.19,
				delta * 5.0
			)
		MotionState.SLIDE:
			visual_bob = 0.0
			visual_lean = move_toward(visual_lean, 0.0, delta * 8.0)
		MotionState.AIR:
			visual_bob = -2.0
			visual_lean = move_toward(
				visual_lean,
				clampf(velocity.x / RUN_SPEED, -1.0, 1.0) * 0.09,
				delta * 2.0
			)

	queue_redraw()


func _draw() -> void:
	if current_state == MotionState.SLIDE:
		_draw_slide_pose()
		return

	_draw_ellipse(
		Vector2(0, -1),
		Vector2(29.0 + absf(velocity.x) * 0.018, 5.0),
		Color(0.0, 0.0, 0.0, 0.48)
	)

	draw_set_transform(Vector2(0, visual_bob), visual_lean, Vector2.ONE)

	var rim_color := Color(0.96, 0.58, 0.30, 0.24)
	if current_state == MotionState.RUN:
		rim_color.a = 0.38
	elif current_state == MotionState.SKID:
		rim_color = Color(1.0, 0.72, 0.42, 0.46)

	draw_circle(Vector2(0, -23), 24.5, rim_color)
	draw_circle(Vector2(0, -23), 22.5, Color(0.055, 0.057, 0.068, 1.0))
	draw_arc(
		Vector2(0, -23),
		22.5,
		-1.45,
		1.55,
		32,
		Color(0.74, 0.42, 0.23, 0.34),
		1.6
	)

	draw_circle(Vector2(0, -60), 15.2, rim_color)
	draw_circle(Vector2(0, -60), 13.4, Color(0.035, 0.037, 0.047, 1.0))
	draw_arc(
		Vector2(0, -60),
		13.4,
		-1.35,
		1.5,
		24,
		Color(0.85, 0.49, 0.26, 0.4),
		1.4
	)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_slide_pose() -> void:
	var stretch := 34.0 + absf(velocity.x) * 0.025
	_draw_ellipse(
		Vector2(0, -1),
		Vector2(stretch, 4.5),
		Color(0.0, 0.0, 0.0, 0.52)
	)

	var rim_color := Color(1.0, 0.66, 0.34, 0.42)
	var body_center := Vector2(-slide_direction * 8.0, -18.0)
	var head_center := Vector2(slide_direction * 22.0, -17.0)

	draw_circle(body_center, 18.5, rim_color)
	draw_circle(body_center, 16.8, Color(0.052, 0.054, 0.065, 1.0))
	draw_arc(
		body_center,
		16.8,
		-1.55,
		1.55,
		26,
		Color(0.82, 0.47, 0.25, 0.42),
		1.5
	)

	draw_circle(head_center, 13.6, rim_color)
	draw_circle(head_center, 11.9, Color(0.034, 0.036, 0.046, 1.0))
	draw_arc(
		head_center,
		11.9,
		-1.45,
		1.45,
		22,
		Color(0.91, 0.53, 0.28, 0.48),
		1.4
	)


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(28):
		var angle := TAU * float(index) / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
