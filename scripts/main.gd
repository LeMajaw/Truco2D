extends Node

var current_scene: Node

func _ready():
	load_main_menu()

func load_main_menu():
	if current_scene:
		current_scene.queue_free()
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	current_scene = menu
	menu.start_game.connect(_on_start_game)

func _on_start_game(difficulty):
	if current_scene:
		current_scene.queue_free()

	var game = load("res://scenes/arena.tscn").instantiate()
	add_child(game)
	current_scene = game

	var game_manager = game.get_node("GameManager")
	var bot_manager = game_manager.get_node("BotManager")

	bot_manager.set_all_bot_difficulties(difficulty)
