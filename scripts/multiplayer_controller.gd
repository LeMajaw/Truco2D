extends Node

# Autoload script to manage multiplayer game integration

var multiplayer_manager = null
var main_scene = preload("res://scenes/main.tscn")
var multiplayer_game_scene = preload("res://scenes/multiplayer_game.tscn")

func _ready():
	# Initialize multiplayer manager
	multiplayer_manager = load("res://scripts/multiplayer_manager.gd").new()
	add_child(multiplayer_manager)

	# Connect signals
	multiplayer_manager.game_started.connect(_on_game_started)
	multiplayer_manager.game_state_updated.connect(_on_game_state_updated)
	multiplayer_manager.card_played.connect(_on_card_played)
	multiplayer_manager.truco_called.connect(_on_truco_called)

# Create a new multiplayer room
func create_room(player_name: String, room_code: String):
	var success = multiplayer_manager.create_room(room_code, player_name)
	return success

# Join an existing multiplayer room
func join_room(player_name: String, room_code: String):
	# In a real implementation, we would resolve the room code to an IP address
	# For this prototype, we'll use localhost
	var ip_address = "127.0.0.1"
	var success = multiplayer_manager.join_room(room_code, player_name, ip_address)
	return success

# Leave the current multiplayer room
func leave_room():
	multiplayer_manager.leave_room()

	# Return to main menu
	get_tree().change_scene_to_packed(main_scene)

# Add a bot to the game (host only)
func add_bot(bot_name: String, slot: int, difficulty: int):
	return multiplayer_manager.add_bot(bot_name, slot, difficulty)

# Start the multiplayer game (host only)
func start_game():
	return multiplayer_manager.start_game()

# Play a card in multiplayer game
func play_card(card_data):
	return multiplayer_manager.play_card(card_data)

# Call truco in multiplayer game
func call_truco():
	return multiplayer_manager.call_truco()

# Signal handlers

func _on_game_started(initial_state):
	# Load multiplayer game scene
	get_tree().change_scene_to_packed(multiplayer_game_scene)

	# The scene will initialize itself using the initial state

func _on_game_state_updated(state):
	# Update game state in the current scene
	var current_scene = get_tree().current_scene
	if current_scene.has_method("update_game_state"):
		current_scene.update_game_state(state)

func _on_card_played(player_id, card_data):
	# Handle card played in the current scene
	var current_scene = get_tree().current_scene
	if current_scene.has_method("handle_card_played"):
		current_scene.handle_card_played(player_id, card_data)

func _on_truco_called(player_id):
	# Handle truco called in the current scene
	var current_scene = get_tree().current_scene
	if current_scene.has_method("handle_truco_called"):
		current_scene.handle_truco_called(player_id)
