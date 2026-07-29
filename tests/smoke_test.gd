extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	var slide_game = packed_scene.instantiate()
	root.add_child(slide_game)

	for _frame in range(5):
		await physics_frame

	var slide_player = slide_game.get_node("Player")

	Input.action_press("move_right")
	for _frame in range(2):
		await physics_frame
	Input.action_release("move_right")
	for _frame in range(2):
		await physics_frame
	Input.action_press("move_right")
	await create_timer(0.35, false, true).timeout

	if slide_player.get_state_label() != "CORRENDO":
		push_error(
			"Teste de corrida falhou. Estado atual: "
			+ slide_player.get_state_label()
		)
		quit(1)
		return

	slide_player.global_position = Vector2(640, 600)
	slide_player.velocity.x = 400.0
	Input.action_press("slide")
	for _frame in range(2):
		await physics_frame

	if slide_player.get_state_label() != "DESLIZANDO":
		push_error(
			"Teste de deslizada falhou. Estado atual: "
			+ slide_player.get_state_label()
		)
		quit(1)
		return

	var active_shape = slide_player.get_node("CollisionShape2D").shape
	if not active_shape is RectangleShape2D:
		push_error("A colisão não foi reduzida durante a deslizada.")
		quit(1)
		return

	for _frame in range(135):
		await physics_frame

	if slide_player.global_position.x <= 1060.0:
		push_error(
			"O personagem não atravessou a passagem baixa. Posição X: "
			+ str(slide_player.global_position.x)
		)
		quit(1)
		return

	Input.action_release("slide")
	Input.action_release("move_right")
	for _frame in range(32):
		await physics_frame

	slide_game.queue_free()
	await process_frame

	var game = packed_scene.instantiate()
	root.add_child(game)
	for _frame in range(5):
		await physics_frame

	var player = game.get_node("Player")

	Input.action_press("move_right")
	for _frame in range(2):
		await physics_frame
	Input.action_release("move_right")
	for _frame in range(2):
		await physics_frame
	Input.action_press("move_right")
	for _frame in range(18):
		await physics_frame

	Input.action_press("move_left")
	for _frame in range(2):
		await physics_frame

	if player.get_state_label() != "DERRAPANDO":
		push_error(
			"Teste de derrapagem falhou. Estado atual: " + player.get_state_label()
		)
		quit(1)
		return

	Input.action_release("move_left")
	Input.action_release("move_right")

	for _frame in range(28):
		await physics_frame

	Input.action_press("jump")
	for _frame in range(2):
		await physics_frame
	Input.action_release("jump")
	for _frame in range(2):
		await physics_frame

	if (
		player.velocity.y >= 0.0
		or player.velocity.y < -400.0
		or player.get_state_label() != "NO AR"
	):
		push_error(
			"Teste de pulo curto falhou. Velocidade Y: "
			+ str(player.velocity.y)
		)
		quit(1)
		return

	while not player.is_on_floor():
		await physics_frame

	Input.action_press("slide")
	for _frame in range(65):
		await physics_frame

	if player.get_state_label() != "CARREGANDO":
		push_error(
			"Teste de carga falhou. Estado atual: " + player.get_state_label()
		)
		quit(1)
		return

	Input.action_release("slide")
	for _frame in range(2):
		await physics_frame

	var charged_jump_velocity: float = player.velocity.y
	if (
		charged_jump_velocity >= -800.0
		or player.get_state_label() != "NO AR"
		or not player.is_somersaulting
	):
		push_error(
			"Teste de pulo carregado/cambalhota falhou. Velocidade Y: "
			+ str(charged_jump_velocity)
		)
		quit(1)
		return

	while not player.is_on_floor():
		await physics_frame

	Input.action_press("move_right")
	Input.action_press("jump")
	for _frame in range(2):
		await physics_frame
	Input.action_release("jump")
	for _frame in range(2):
		await physics_frame

	while not player.is_on_floor():
		await physics_frame

	Input.action_press("jump")
	for _frame in range(2):
		await physics_frame

	var combo_jump_velocity: float = player.velocity.y
	if (
		combo_jump_velocity >= -740.0
		or combo_jump_velocity <= charged_jump_velocity
		or player.get_state_label() != "NO AR"
		or not player.is_somersaulting
	):
		push_error(
			"Teste de segundo pulo/cambalhota falhou. Velocidade Y: "
			+ str(combo_jump_velocity)
		)
		quit(1)
		return

	Input.action_release("jump")
	Input.action_release("move_right")
	game.queue_free()
	await process_frame

	var wall_game = packed_scene.instantiate()
	root.add_child(wall_game)
	for _frame in range(5):
		await physics_frame

	if (
		not wall_game.has_node("GameAudio")
		or not wall_game.has_node("NoirWorld/SpecialPlatform_02")
		or not wall_game.has_node("NoirWorld/Light_05")
		or wall_game.get_node("NoirWorld").get_total_lights() != 6
	):
		push_error("Plataformas especiais, luzes ou áudio não foram criados.")
		quit(1)
		return

	if not wall_game.has_node("NoirWorld/WallJump_02"):
		push_error("O obstáculo de salto na parede não foi criado.")
		quit(1)
		return

	if (
		not wall_game.has_node("NoirWorld/CrawlTunnel_00")
		or not wall_game.has_node("NoirWorld/Spikes_00")
	):
		push_error("O túnel baixo ou os espinhos não foram criados.")
		quit(1)
		return

	var wall_player = wall_game.get_node("Player")
	wall_player.global_position = Vector2(930, 600)
	for _frame in range(3):
		await physics_frame

	if (
		wall_game.collected_lights != 1
		or wall_game.get_node("HUD").light_label.text != "LUZES  1 / 6"
	):
		push_error(
			"A coleta de luz ou o contador do HUD falhou. Coletadas: "
			+ str(wall_game.collected_lights)
			+ ", HUD: "
			+ wall_game.get_node("HUD").light_label.text
			+ ", área presente: "
			+ str(wall_game.has_node("NoirWorld/Light_01"))
		)
		quit(1)
		return

	wall_player.global_position = Vector2(3097, 430)
	wall_player.velocity = Vector2(0, 90)
	Input.action_press("move_right")
	for _frame in range(12):
		await physics_frame

	if (
		wall_player.get_state_label() != "NA PAREDE"
		or wall_player.velocity.y > 120.0
	):
		push_error(
			"Teste de descida na parede falhou. Estado: "
			+ wall_player.get_state_label()
			+ ", velocidade Y: "
			+ str(wall_player.velocity.y)
		)
		quit(1)
		return

	Input.action_press("jump")
	for _frame in range(2):
		await physics_frame

	if wall_player.velocity.x >= -400.0 or wall_player.velocity.y >= -680.0:
		push_error(
			"Teste de salto na parede falhou. Velocidade: "
			+ str(wall_player.velocity)
		)
		quit(1)
		return

	Input.action_release("jump")
	Input.action_release("move_right")

	wall_player.global_position = Vector2(1200, 600)
	wall_player.velocity = Vector2.ZERO
	wall_player.is_running = false
	for _frame in range(5):
		await physics_frame

	Input.action_press("move_right")
	for _frame in range(2):
		await physics_frame
	Input.action_press("slide")
	for _frame in range(12):
		await physics_frame

	var crouch_shape = wall_player.get_node("CollisionShape2D").shape
	if (
		wall_player.get_state_label() != "AGACHADO"
		or not crouch_shape is RectangleShape2D
		or not is_equal_approx(crouch_shape.size.y, 54.0)
		or wall_player.velocity.x <= 0.0
	):
		push_error("O movimento agachado para a direita falhou.")
		quit(1)
		return

	Input.action_release("move_right")
	Input.action_press("move_left")
	for _frame in range(12):
		await physics_frame

	if wall_player.get_state_label() != "AGACHADO" or wall_player.velocity.x >= 0.0:
		push_error("A troca de direção agachado falhou.")
		quit(1)
		return

	Input.action_release("slide")
	Input.action_release("move_left")
	for _frame in range(5):
		await physics_frame

	if not wall_player.get_node("CollisionShape2D").shape is CapsuleShape2D:
		push_error("A colisão em pé não foi restaurada após agachar.")
		quit(1)
		return

	wall_player.global_position = Vector2(1200, 600)
	wall_player.velocity = Vector2(400, 0)
	wall_player.is_running = true
	Input.action_press("move_right")
	Input.action_press("slide")
	for _frame in range(3):
		await physics_frame
	Input.action_release("move_right")
	Input.action_press("move_left")
	for _frame in range(30):
		await physics_frame

	if (
		wall_player.get_state_label() != "DESLIZANDO"
		or wall_player.velocity.x >= 0.0
	):
		push_error(
			"A troca de direção durante a deslizada falhou. Estado: "
			+ wall_player.get_state_label()
			+ ", velocidade: "
			+ str(wall_player.velocity)
			+ ", direção: "
			+ str(wall_player.slide_direction)
		)
		quit(1)
		return

	Input.action_release("slide")
	Input.action_release("move_left")
	for _frame in range(20):
		await physics_frame

	wall_player.global_position = Vector2(1980, 600)
	wall_player.velocity = Vector2.ZERO
	wall_player.is_running = false
	for _frame in range(5):
		await physics_frame

	Input.action_press("move_right")
	for _frame in range(30):
		await physics_frame
	Input.action_release("move_right")

	if wall_player.global_position.x >= 2020.0:
		push_error(
			"O personagem atravessou o túnel baixo em pé. Posição X: "
			+ str(wall_player.global_position.x)
		)
		quit(1)
		return

	wall_player.global_position = Vector2(1980, 600)
	for _frame in range(3):
		await physics_frame

	wall_player.velocity = Vector2(400, 0)
	wall_player.is_running = true
	Input.action_press("move_right")
	Input.action_press("slide")
	for _frame in range(90):
		await physics_frame
	Input.action_release("slide")
	Input.action_release("move_right")

	if wall_player.global_position.x <= 2190.0:
		push_error(
			"O personagem não atravessou o túnel baixo deslizando. Posição X: "
			+ str(wall_player.global_position.x)
			+ ", estado: "
			+ wall_player.get_state_label()
			+ ", velocidade: "
			+ str(wall_player.velocity)
			+ ", colisão: "
			+ wall_player.get_node("CollisionShape2D").shape.get_class()
		)
		quit(1)
		return

	wall_player.global_position = Vector2(3170, 600)
	for _frame in range(3):
		await physics_frame

	if (
		wall_game.is_finished
		or not wall_game.get_node("HUD").finish_label.text.begins_with("FALTAM")
	):
		push_error("A fase terminou sem coletar todas as luzes.")
		quit(1)
		return

	wall_player.global_position = Vector2(3050, 600)
	for _frame in range(3):
		await physics_frame
	wall_game.collected_lights = wall_game.get_node("NoirWorld").get_total_lights()
	wall_game.get_node("HUD").set_light_count(
		wall_game.collected_lights,
		wall_game.get_node("NoirWorld").get_total_lights()
	)
	wall_player.global_position = Vector2(3170, 600)
	for _frame in range(3):
		await physics_frame

	if (
		not wall_game.is_finished
		or not is_finite(wall_game.best_time)
		or not wall_game.get_node("HUD").finish_label.text.begins_with("FASE COMPLETA")
	):
		push_error("A conclusão da fase ou o melhor tempo falhou.")
		quit(1)
		return

	await create_timer(0.35).timeout
	wall_game.queue_free()
	await process_frame
	await create_timer(0.1).timeout

	print(
		"SMOKE TEST OK: corrida, deslizada, passagem baixa, "
		+ "agachamento, derrapagem, pulos, carga, parede, túnel, espinhos, "
		+ "plataformas especiais, luzes, HUD, áudio e cronômetro funcionando."
	)
	quit(0)
