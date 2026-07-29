extends Node2D

static var best_time: float = INF

@onready var player = $Player
@onready var world = $NoirWorld
@onready var world_fx = $WorldFX
@onready var hud = $HUD
@onready var game_audio = $GameAudio

var collected_lights := 0
var is_restarting := false
var is_finished := false
var elapsed_time := 0.0


func _enter_tree() -> void:
	_configure_input()


func _ready() -> void:
	player.dust_requested.connect(world_fx.spawn_dust)
	player.state_changed.connect(hud.set_state)
	player.sound_requested.connect(game_audio.play_sound)
	world.player_hit_hazard.connect(_on_player_hit_hazard)
	world.light_collected.connect(_on_light_collected)
	world.finish_reached.connect(_on_finish_reached)
	hud.set_state(player.get_state_label())
	hud.set_light_count(collected_lights, world.get_total_lights())
	hud.set_timer(elapsed_time, best_time)


func _process(delta: float) -> void:
	if not is_finished:
		elapsed_time += delta
		hud.set_timer(elapsed_time, best_time)

	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

	if player.global_position.y > 860.0:
		get_tree().reload_current_scene()


func _on_player_hit_hazard() -> void:
	if is_restarting:
		return
	is_restarting = true
	game_audio.play_sound(&"hurt")
	if get_tree().current_scene:
		await get_tree().create_timer(0.16).timeout
		get_tree().reload_current_scene()


func _on_light_collected() -> void:
	collected_lights += 1
	hud.set_light_count(collected_lights, world.get_total_lights())
	game_audio.play_sound(&"collect")
	if collected_lights == world.get_total_lights():
		hud.show_finish_message("TODAS AS LUZES • VÁ ATÉ O FIM")


func _on_finish_reached() -> void:
	if is_finished:
		return

	var missing_lights: int = world.get_total_lights() - collected_lights
	if missing_lights > 0:
		hud.show_finish_message(
			"FALTAM %d LUZES PARA TERMINAR" % missing_lights
		)
		return

	is_finished = true
	var is_new_record := elapsed_time < best_time
	if is_new_record:
		best_time = elapsed_time
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	hud.set_timer(elapsed_time, best_time)
	hud.show_finish_message(
		"FASE COMPLETA • NOVO RECORDE!"
		if is_new_record
		else "FASE COMPLETA"
	)
	game_audio.play_sound(&"special_jump")


func _configure_input() -> void:
	_ensure_action("move_left")
	_ensure_action("move_right")
	_ensure_action("slide")
	_ensure_action("jump")
	_ensure_action("restart")

	_bind_key("move_left", KEY_A, true)
	_bind_key("move_left", KEY_LEFT)
	_bind_key("move_right", KEY_D, true)
	_bind_key("move_right", KEY_RIGHT)
	_bind_key("slide", KEY_S, true)
	_bind_key("slide", KEY_DOWN)
	_bind_key("jump", KEY_SPACE)
	_bind_key("restart", KEY_R, true)

	_bind_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_bind_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_bind_joy_axis("slide", JOY_AXIS_LEFT_Y, 1.0)
	_bind_joy_button("jump", JOY_BUTTON_A)
	_bind_joy_button("restart", JOY_BUTTON_BACK)


func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.22)


func _bind_key(action: StringName, key: Key, physical := false) -> void:
	for current_event in InputMap.action_get_events(action):
		if current_event is InputEventKey:
			if physical and current_event.physical_keycode == key:
				return
			if not physical and current_event.keycode == key:
				return

	var event := InputEventKey.new()
	if physical:
		event.physical_keycode = key
	else:
		event.keycode = key
	InputMap.action_add_event(action, event)


func _bind_joy_axis(action: StringName, axis: JoyAxis, value: float) -> void:
	for current_event in InputMap.action_get_events(action):
		if (
			current_event is InputEventJoypadMotion
			and current_event.axis == axis
			and is_equal_approx(current_event.axis_value, value)
		):
			return

	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)


func _bind_joy_button(action: StringName, button: JoyButton) -> void:
	for current_event in InputMap.action_get_events(action):
		if (
			current_event is InputEventJoypadButton
			and current_event.button_index == button
		):
			return

	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)
