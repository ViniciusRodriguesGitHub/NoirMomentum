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

	for _frame in range(18):
		await physics_frame

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

	if player.velocity.y >= 0.0 or player.get_state_label() != "NO AR":
		push_error(
			"Teste de pulo falhou. Estado atual: " + player.get_state_label()
		)
		quit(1)
		return

	print(
		"SMOKE TEST OK: corrida, deslizada, passagem baixa, "
		+ "derrapagem e pulo funcionando."
	)
	quit(0)
