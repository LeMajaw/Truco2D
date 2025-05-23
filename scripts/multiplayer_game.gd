extends Node

# Multiplayer game scene script

var multiplayer_controller
var game_instance
var player_labels = []
var players = []
var my_slot = 0

func _ready():
	# Get references
	multiplayer_controller = get_node("/root/MultiplayerController")
	game_instance = $GameInstance
	
	# Set up player labels
	player_labels = [
		$MultiplayerOverlay/PlayerLabels/Player1Label,
		$MultiplayerOverlay/PlayerLabels/Player2Label,
		$MultiplayerOverlay/PlayerLabels/Player3Label,
		$MultiplayerOverlay/PlayerLabels/Player4Label
	]
	
	# Connect to multiplayer signals
	if multiplayer_controller.multiplayer_manager:
		multiplayer_controller.multiplayer_manager.player_left.connect(_on_player_left)
		
	# Initialize game with multiplayer settings
	_initialize_multiplayer_game()
	
	# Hide connection panel initially
	$MultiplayerOverlay/ConnectionPanel.visible = false

func _initialize_multiplayer_game():
	# Get players from multiplayer manager
	if multiplayer_controller.multiplayer_manager:
		players = multiplayer_controller.multiplayer_manager.players
		
		# Find my slot
		for player in players:
			if player.get("is_self", false):
				my_slot = player.get("slot", 0)
				break
		
		# Update player labels
		_update_player_labels()
		
		# Initialize game instance with multiplayer mode
		if game_instance.has_method("initialize_multiplayer"):
			game_instance.initialize_multiplayer(players, my_slot)

func _update_player_labels():
	# Clear all labels first
	for label in player_labels:
		label.text = "Waiting..."
	
	# Update with player names
	for player in players:
		var slot = player.get("slot", -1)
		if slot >= 0 and slot < player_labels.size():
			var name_text = player.get("name", "Unknown")
			if player.get("is_self", false):
				name_text += " (You)"
			elif player.get("is_bot", false):
				name_text += " (AI)"
			player_labels[slot].text = name_text

# Handle game state update from multiplayer
func update_game_state(state):
	if game_instance.has_method("update_multiplayer_state"):
		game_instance.update_multiplayer_state(state)

# Handle card played in multiplayer
func handle_card_played(player_id, card_data):
	if game_instance.has_method("handle_multiplayer_card_played"):
		game_instance.handle_multiplayer_card_played(player_id, card_data)

# Handle truco called in multiplayer
func handle_truco_called(player_id):
	if game_instance.has_method("handle_multiplayer_truco_called"):
		game_instance.handle_multiplayer_truco_called(player_id)

# Handle player disconnection
func _on_player_left(player_id):
	# Show reconnection panel
	$MultiplayerOverlay/ConnectionPanel.visible = true
	$MultiplayerOverlay/ConnectionPanel/VBoxContainer/StatusLabel.text = "A player has disconnected. Waiting for reconnection..."

func _on_reconnect_button_pressed():
	# Attempt to reconnect
	$MultiplayerOverlay/ConnectionPanel/VBoxContainer/StatusLabel.text = "Attempting to reconnect..."
	
	# In a real implementation, we would attempt to reconnect here
	# For now, just hide the panel
	$MultiplayerOverlay/ConnectionPanel.visible = false

func _on_leave_button_pressed():
	# Leave the multiplayer game
	if multiplayer_controller:
		multiplayer_controller.leave_room()
