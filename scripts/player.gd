extends CharacterBody2D

signal state_changed(label: String)
signal dust_requested(origin: Vector2, direction: float, strength: float)
signal sound_requested(kind: StringName)

enum MotionState {
	IDLE,
	WALK,
	RUN,
	SKID,
	SLIDE,
	CROUCH,
	CHARGE,
	WALL_SLIDE,
	AIR,
}

const WALK_SPEED := 185.0
const RUN_SPEED := 400.0
const GROUND_ACCELERATION := 1450.0
const AIR_ACCELERATION := 720.0
const GROUND_FRICTION := 1750.0
const SKID_BRAKE := 980.0
const SLIDE_FRICTION := 285.0
const SLIDE_TURN_ACCELERATION := 1450.0
const SLIDE_MIN_SPEED := 138.0
const CROUCH_SPEED := 92.0
const GRAVITY := 1800.0
const JUMP_SPEED := 650.0
const SHORT_JUMP_RELEASE_SPEED := 285.0
const COMBO_JUMP_SPEED := 790.0
const CHARGED_JUMP_SPEED := 850.0
const WALL_SLIDE_SPEED := 115.0
const WALL_JUMP_SPEED := 735.0
const WALL_JUMP_HORIZONTAL_SPEED := 470.0
const JUMP_CHARGE_DURATION := 1.0
const COMBO_JUMP_WINDOW := 0.18
const COMBO_ANIMATION_DURATION := 0.28
const WALL_JUMP_ANIMATION_DURATION := 0.24
const SOMERSAULT_DURATION := 0.5
const DOUBLE_TAP_WINDOW := 0.29
const SKID_DURATION := 0.34
const SLIDE_MIN_DURATION := 0.42
const STANDING_COLLISION_POSITION := Vector2(0, -38)
const SLIDE_COLLISION_POSITION := Vector2(0, -17)
const SLIDE_COLLISION_SIZE := Vector2(68, 34)
const CROUCH_COLLISION_POSITION := Vector2(0, -27)
const CROUCH_COLLISION_SIZE := Vector2(46, 54)
const VISUAL_PIVOT := Vector2(0, -38)

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
var visual_shake := 0.0
var visual_scale := Vector2.ONE
var jump_charge_elapsed := 0.0
var jump_is_charged := false
var combo_jump_time_left := 0.0
var combo_animation_time_left := 0.0
var wall_jump_animation_time_left := 0.0
var jump_started_moving := false
var can_cut_jump_short := false
var is_somersaulting := false
var somersault_elapsed := 0.0
var somersault_angle := 0.0
var somersault_direction := 1.0
var standing_shape: Shape2D
var slide_shape := RectangleShape2D.new()
var crouch_shape := RectangleShape2D.new()


func _ready() -> void:
	standing_shape = collision_shape.shape
	slide_shape.size = SLIDE_COLLISION_SIZE
	crouch_shape.size = CROUCH_COLLISION_SIZE
	queue_redraw()


func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()
	var input_direction := Input.get_axis("move_left", "move_right")
	var just_pressed_direction := _get_just_pressed_direction()

	combo_jump_time_left = maxf(combo_jump_time_left - delta, 0.0)
	combo_animation_time_left = maxf(combo_animation_time_left - delta, 0.0)
	wall_jump_animation_time_left = maxf(
		wall_jump_animation_time_left - delta,
		0.0
	)
	_update_somersault(delta)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
		if is_on_wall() and velocity.y > WALL_SLIDE_SPEED:
			velocity.y = WALL_SLIDE_SPEED

	if Input.is_action_just_pressed("jump"):
		if not is_on_floor() and is_on_wall():
			_perform_wall_jump()
		elif (
			is_on_floor()
			and current_state != MotionState.SKID
			and current_state != MotionState.SLIDE
			and current_state != MotionState.CHARGE
		):
			if current_state == MotionState.CROUCH:
				_set_crouch_collision(false)
			if combo_jump_time_left > 0.0 and absf(input_direction) > 0.1:
				_perform_jump(
					COMBO_JUMP_SPEED,
					input_direction,
					true,
					false,
					true
				)
			else:
				_perform_jump(JUMP_SPEED, input_direction)

	if (
		Input.is_action_just_released("jump")
		and can_cut_jump_short
		and velocity.y < -SHORT_JUMP_RELEASE_SPEED
	):
		velocity.y = -SHORT_JUMP_RELEASE_SPEED
		can_cut_jump_short = false

	_process_current_state(input_direction, just_pressed_direction, delta)

	move_and_slide()

	if not was_on_floor and is_on_floor():
		dust_requested.emit(global_position + Vector2(0, -2), facing, 0.35)
		can_cut_jump_short = false
		if jump_started_moving:
			combo_jump_time_left = COMBO_JUMP_WINDOW
		jump_started_moving = false

	_update_state()
	_update_visuals(delta)


func _process_current_state(
	input_direction: float,
	just_pressed_direction: float,
	delta: float
) -> void:
	match current_state:
		MotionState.SKID:
			_process_skid(delta)
		MotionState.SLIDE:
			_process_slide(input_direction, delta)
		MotionState.CROUCH:
			_process_crouch(input_direction, delta)
		MotionState.CHARGE:
			_process_jump_charge(input_direction, delta)
		MotionState.IDLE, MotionState.WALK, MotionState.RUN, MotionState.WALL_SLIDE, MotionState.AIR:
			_process_regular_state(
				input_direction,
				just_pressed_direction,
				delta
			)


func _process_regular_state(
	input_direction: float,
	just_pressed_direction: float,
	delta: float
) -> void:
	if (
		Input.is_action_just_pressed("slide")
		and is_on_floor()
		and absf(input_direction) <= 0.1
		and absf(velocity.x) < 8.0
		and not is_running
	):
		_begin_jump_charge()
	elif (
		Input.is_action_just_pressed("slide")
		and is_on_floor()
		and is_running
		and absf(velocity.x) > WALK_SPEED * 1.35
	):
		_begin_slide()
	elif Input.is_action_just_pressed("slide") and is_on_floor():
		_begin_crouch()
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


func _begin_jump_charge() -> void:
	jump_charge_elapsed = 0.0
	jump_is_charged = false
	_set_state(MotionState.CHARGE)


func _process_jump_charge(input_direction: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)
	jump_charge_elapsed = minf(
		jump_charge_elapsed + delta,
		JUMP_CHARGE_DURATION
	)
	jump_is_charged = jump_charge_elapsed >= JUMP_CHARGE_DURATION

	if absf(input_direction) > 0.1:
		jump_charge_elapsed = 0.0
		jump_is_charged = false
		_begin_crouch()
	elif Input.is_action_just_released("slide"):
		if jump_is_charged:
			_perform_jump(
				CHARGED_JUMP_SPEED,
				0.0,
				false,
				false,
				true
			)
		else:
			jump_charge_elapsed = 0.0
			_set_state(MotionState.IDLE)


func _begin_crouch() -> void:
	is_running = false
	_set_crouch_collision(true)
	_set_state(MotionState.CROUCH)


func _process_crouch(input_direction: float, delta: float) -> void:
	if not is_on_floor():
		_set_crouch_collision(false)
		_set_state(MotionState.AIR)
		return

	if not Input.is_action_pressed("slide") and _can_stand():
		_set_crouch_collision(false)
		_set_state(MotionState.WALK if absf(input_direction) > 0.1 else MotionState.IDLE)
		return

	if absf(input_direction) > 0.1:
		facing = signf(input_direction)
		velocity.x = move_toward(
			velocity.x,
			facing * CROUCH_SPEED,
			GROUND_ACCELERATION * delta
		)
	else:
		velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)


func _perform_jump(
	jump_speed: float,
	input_direction: float,
	is_combo_jump := false,
	allow_short_jump := true,
	do_somersault := false
) -> void:
	velocity.y = -jump_speed
	can_cut_jump_short = allow_short_jump
	is_running = is_running and absf(input_direction) > 0.1
	jump_started_moving = absf(input_direction) > 0.1 or absf(velocity.x) > 8.0
	jump_charge_elapsed = 0.0
	jump_is_charged = false
	combo_jump_time_left = 0.0
	if is_combo_jump:
		combo_animation_time_left = COMBO_ANIMATION_DURATION
		dust_requested.emit(
			global_position + Vector2(0, -2),
			facing,
			0.9
		)
	sound_requested.emit(&"special_jump" if do_somersault else &"jump")
	if do_somersault:
		_start_somersault()
	_set_state(MotionState.AIR)


func _start_somersault() -> void:
	is_somersaulting = true
	somersault_elapsed = 0.0
	somersault_angle = 0.0
	somersault_direction = facing


func _update_somersault(delta: float) -> void:
	if not is_somersaulting:
		somersault_angle = 0.0
		return

	somersault_elapsed = minf(
		somersault_elapsed + delta,
		SOMERSAULT_DURATION
	)
	var progress := somersault_elapsed / SOMERSAULT_DURATION
	somersault_angle = progress * TAU * somersault_direction

	if is_equal_approx(progress, 1.0):
		is_somersaulting = false
		somersault_angle = 0.0


func _perform_wall_jump() -> void:
	var wall_normal := get_wall_normal()
	if is_zero_approx(wall_normal.x):
		wall_normal.x = -facing

	velocity.x = wall_normal.x * WALL_JUMP_HORIZONTAL_SPEED
	velocity.y = -WALL_JUMP_SPEED
	facing = wall_normal.x
	is_running = false
	jump_charge_elapsed = 0.0
	jump_is_charged = false
	can_cut_jump_short = false
	combo_jump_time_left = 0.0
	wall_jump_animation_time_left = WALL_JUMP_ANIMATION_DURATION
	jump_started_moving = true
	sound_requested.emit(&"wall_jump")
	dust_requested.emit(
		global_position + Vector2(-wall_normal.x * 18.0, -35.0),
		-wall_normal.x,
		0.75
	)
	_set_state(MotionState.AIR)


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
	sound_requested.emit(&"skid")
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
	sound_requested.emit(&"slide")
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
	var slide_acceleration := SLIDE_FRICTION
	if absf(input_direction) > 0.1:
		var requested_direction := signf(input_direction)
		if requested_direction != slide_direction:
			slide_direction = requested_direction
			facing = slide_direction
		if signf(velocity.x) != requested_direction:
			slide_acceleration = SLIDE_TURN_ACCELERATION

	var target_speed := SLIDE_MIN_SPEED if keep_moving else 0.0
	velocity.x = move_toward(
		velocity.x,
		slide_direction * target_speed,
		slide_acceleration * delta
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


func _set_crouch_collision(crouching: bool) -> void:
	if crouching:
		collision_shape.shape = crouch_shape
		collision_shape.position = CROUCH_COLLISION_POSITION
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
	if (
		current_state == MotionState.SKID
		or current_state == MotionState.SLIDE
		or current_state == MotionState.CROUCH
		or current_state == MotionState.CHARGE
	):
		return

	if not is_on_floor():
		if is_on_wall() and velocity.y >= 0.0:
			_set_state(MotionState.WALL_SLIDE)
		else:
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
		MotionState.CROUCH:
			return "AGACHADO"
		MotionState.CHARGE:
			return "CARREGANDO"
		MotionState.WALL_SLIDE:
			return "NA PAREDE"
		MotionState.AIR:
			return "NO AR"
	return ""


func _update_visuals(delta: float) -> void:
	var horizontal_speed := absf(velocity.x)
	motion_phase += horizontal_speed * delta * 0.038
	visual_shake = 0.0
	visual_scale = Vector2.ONE

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
		MotionState.CROUCH:
			visual_bob = absf(sin(motion_phase * 0.8)) * -1.3
			visual_lean = move_toward(
				visual_lean,
				facing * 0.035,
				delta * 4.0
			)
		MotionState.CHARGE:
			var charge_ratio := jump_charge_elapsed / JUMP_CHARGE_DURATION
			var shake_strength := lerpf(0.7, 3.2, charge_ratio)
			if jump_is_charged:
				shake_strength = 4.2
			visual_shake = sin(Time.get_ticks_msec() * 0.055) * shake_strength
			visual_bob = lerpf(0.0, 4.0, charge_ratio)
			visual_scale = Vector2(
				lerpf(1.0, 1.08, charge_ratio),
				lerpf(1.0, 0.88, charge_ratio)
			)
			visual_lean = move_toward(visual_lean, 0.0, delta * 5.0)
		MotionState.WALL_SLIDE:
			visual_bob = sin(Time.get_ticks_msec() * 0.018) * 1.0
			visual_scale = Vector2(0.92, 1.06)
			visual_lean = move_toward(
				visual_lean,
				-get_wall_normal().x * 0.12,
				delta * 7.0
			)
		MotionState.AIR:
			visual_bob = -2.0
			visual_lean = move_toward(
				visual_lean,
				clampf(velocity.x / RUN_SPEED, -1.0, 1.0) * 0.09,
				delta * 2.0
			)
			if combo_animation_time_left > 0.0:
				var combo_ratio := (
					combo_animation_time_left / COMBO_ANIMATION_DURATION
				)
				visual_shake = sin(Time.get_ticks_msec() * 0.08) * combo_ratio * 2.4
				visual_scale = Vector2(
					lerpf(1.0, 0.88, combo_ratio),
					lerpf(1.0, 1.16, combo_ratio)
				)
			elif wall_jump_animation_time_left > 0.0:
				var wall_jump_ratio := (
					wall_jump_animation_time_left
					/ WALL_JUMP_ANIMATION_DURATION
				)
				visual_scale = Vector2(
					lerpf(1.0, 1.14, wall_jump_ratio),
					lerpf(1.0, 0.9, wall_jump_ratio)
				)
				visual_lean += facing * wall_jump_ratio * 0.12

	queue_redraw()


func _draw() -> void:
	if current_state == MotionState.SLIDE:
		_draw_slide_pose()
		return
	if current_state == MotionState.CROUCH:
		_draw_crouch_pose()
		return

	var body_center := Vector2(0, -23) - VISUAL_PIVOT
	var head_center := Vector2(0, -60) - VISUAL_PIVOT
	draw_set_transform(
		VISUAL_PIVOT + Vector2(visual_shake, visual_bob),
		visual_lean + somersault_angle,
		visual_scale
	)

	var rim_color := Color(0.96, 0.58, 0.30, 0.24)
	if current_state == MotionState.RUN:
		rim_color.a = 0.38
	elif current_state == MotionState.SKID:
		rim_color = Color(1.0, 0.72, 0.42, 0.46)
	elif current_state == MotionState.CHARGE:
		var charge_ratio := jump_charge_elapsed / JUMP_CHARGE_DURATION
		rim_color = Color(1.0, 0.63, 0.28, lerpf(0.32, 0.72, charge_ratio))
	elif current_state == MotionState.WALL_SLIDE:
		rim_color = Color(0.88, 0.48, 0.24, 0.58)
	elif combo_animation_time_left > 0.0:
		var combo_ratio := combo_animation_time_left / COMBO_ANIMATION_DURATION
		rim_color = Color(1.0, 0.76, 0.38, lerpf(0.3, 0.82, combo_ratio))
	elif wall_jump_animation_time_left > 0.0:
		var wall_jump_ratio := (
			wall_jump_animation_time_left / WALL_JUMP_ANIMATION_DURATION
		)
		rim_color = Color(1.0, 0.58, 0.26, lerpf(0.3, 0.72, wall_jump_ratio))

	draw_circle(body_center, 24.5, rim_color)
	draw_circle(body_center, 22.5, Color(0.055, 0.057, 0.068, 1.0))
	draw_arc(
		body_center,
		22.5,
		-1.45,
		1.55,
		32,
		Color(0.74, 0.42, 0.23, 0.34),
		1.6
	)

	draw_circle(head_center, 15.2, rim_color)
	draw_circle(head_center, 13.4, Color(0.035, 0.037, 0.047, 1.0))
	draw_arc(
		head_center,
		13.4,
		-1.35,
		1.5,
		24,
		Color(0.85, 0.49, 0.26, 0.4),
		1.4
	)
	_draw_eye(head_center, facing)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_slide_pose() -> void:
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
	_draw_eye(head_center, slide_direction)


func _draw_crouch_pose() -> void:
	draw_set_transform(
		Vector2(0, visual_bob),
		visual_lean,
		Vector2.ONE
	)

	var rim_color := Color(0.96, 0.58, 0.3, 0.34)
	var body_center := Vector2(-facing * 3.0, -23.0)
	var head_center := Vector2(facing * 8.0, -47.0)

	draw_circle(body_center, 20.5, rim_color)
	draw_circle(body_center, 18.5, Color(0.052, 0.054, 0.065, 1.0))
	draw_arc(
		body_center,
		18.5,
		-1.5,
		1.5,
		28,
		Color(0.82, 0.47, 0.25, 0.4),
		1.5
	)

	draw_circle(head_center, 14.2, rim_color)
	draw_circle(head_center, 12.5, Color(0.034, 0.036, 0.046, 1.0))
	draw_arc(
		head_center,
		12.5,
		-1.4,
		1.45,
		22,
		Color(0.91, 0.53, 0.28, 0.45),
		1.4
	)
	_draw_eye(head_center, facing)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_eye(head_center: Vector2, look_direction: float) -> void:
	var direction := signf(look_direction)
	if is_zero_approx(direction):
		direction = 1.0

	var eye_center := head_center + Vector2(direction * 5.2, -1.2)
	var pupil_center := eye_center + Vector2(direction * 1.5, 0.2)
	draw_circle(eye_center, 4.4, Color(0.91, 0.73, 0.55, 0.96))
	draw_circle(pupil_center, 2.1, Color(0.035, 0.025, 0.025, 1.0))
	draw_circle(
		pupil_center + Vector2(direction * 0.5, -0.65),
		0.65,
		Color(1.0, 0.82, 0.62, 0.9)
	)
	draw_line(
		eye_center + Vector2(-direction * 4.6, -4.8),
		eye_center + Vector2(direction * 3.8, -4.1),
		Color(0.65, 0.34, 0.2, 0.9),
		1.5
	)
