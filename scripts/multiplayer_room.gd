extends CanvasLayer

signal start_multiplayer_game(players)
signal leave_room

# Room properties
var room_code = ""
var is_host = false
var player_name = ""
var players = []
var bots = []

# Bot difficulty enum (must match the one in bot_ai.gd)
enum BotDifficulty {EASY, NORMAL, HARD, EXPERT}
var bot_difficulty = BotDifficulty.NORMAL

# Player slots
var player_slots = [
	{"index": 0, "container": null, "name_label": null, "status_label": null, "add_bot_button": null},
	{"index": 1, "container": null, "name_label": null, "status_label": null, "add_bot_button": null},
	{"index": 2, "container": null, "name_label": null, "status_label": null, "add_bot_button": null},
	{"index": 3, "container": null, "name_label": null, "status_label": null, "add_bot_button": null}
]

func _ready():
	# Initialize player slots
	player_slots[0]["container"] = $Panel/VBoxContainer/PlayersGrid/Player1Container
	player_slots[0]["name_label"] = $Panel/VBoxContainer/PlayersGrid/Player1Container/VBoxContainer/NameLabel
	player_slots[0]["status_label"] = $Panel/VBoxContainer/PlayersGrid/Player1Container/VBoxContainer/StatusLabel
	
	player_slots[1]["container"] = $Panel/VBoxContainer/PlayersGrid/Player2Container
	player_slots[1]["name_label"] = $Panel/VBoxContainer/PlayersGrid/Player2Container/VBoxContainer/NameLabel
	player_slots[1]["add_bot_button"] = $Panel/VBoxContainer/PlayersGrid/Player2Container/VBoxContainer/AddBotButton
	
	player_slots[2]["container"] = $Panel/VBoxContainer/PlayersGrid/Player3Container
	player_slots[2]["name_label"] = $Panel/VBoxContainer/PlayersGrid/Player3Container/VBoxContainer/NameLabel
	player_slots[2]["add_bot_button"] = $Panel/VBoxContainer/PlayersGrid/Player3Container/VBoxContainer/AddBotButton
	
	player_slots[3]["container"] = $Panel/VBoxContainer/PlayersGrid/Player4Container
	player_slots[3]["name_label"] = $Panel/VBoxContainer/PlayersGrid/Player4Container/VBoxContainer/NameLabel
	player_slots[3]["add_bot_button"] = $Panel/VBoxContainer/PlayersGrid/Player4Container/VBoxContainer/AddBotButton
	
	# Load bot difficulty if available
	var config = ConfigFile.new()
	var err = config.load("user://player_settings.cfg")
	if err == OK and config.has_section_key("game", "difficulty"):
		bot_difficulty = config.get_value("game", "difficulty", BotDifficulty.NORMAL)

func initialize(p_name: String, p_room_code: String, p_is_host: bool):
	player_name = p_name
	room_code = p_room_code
	is_host = p_is_host
	
	# Update UI
	$Panel/VBoxContainer/RoomInfoContainer/RoomCodeLabel.text = room_code
	
	# Add self as first player
	add_player(player_name, 0, true)
	
	# Show/hide host controls
	update_host_controls()
	
	# Update status
	if is_host:
		$Panel/VBoxContainer/StatusLabel.text = "Waiting for players to join..."
	else:
		$Panel/VBoxContainer/StatusLabel.text = "Waiting for host to start the game..."

func update_host_controls():
	# Only host can add bots and start game
	var show_host_controls = is_host
	
	for i in range(1, 4):  # Skip player 1 (self)
		if player_slots[i]["add_bot_button"]:
			player_slots[i]["add_bot_button"].visible = show_host_controls
	
	$Panel/VBoxContainer/ButtonsContainer/StartGameButton.visible = show_host_controls
	
	# Enable start button only if all slots are filled
	if show_host_controls:
		var all_slots_filled = true
		for i in range(4):
			if not players.any(func(p): return p["slot"] == i) and not bots.any(func(b): return b["slot"] == i):
				all_slots_filled = false
				break
		
		$Panel/VBoxContainer/ButtonsContainer/StartGameButton.disabled = not all_slots_filled

func add_player(name: String, slot: int, is_self: bool = false):
	# Add player to list
	players.append({
		"name": name,
		"slot": slot,
		"is_self": is_self
	})
	
	# Update UI
	player_slots[slot]["name_label"].text = name + (" (You)" if is_self else "")
	
	if player_slots[slot].has("status_label") and player_slots[slot]["status_label"]:
		player_slots[slot]["status_label"].text = "Ready"
	
	if player_slots[slot].has("add_bot_button") and player_slots[slot]["add_bot_button"]:
		player_slots[slot]["add_bot_button"].visible = false
	
	# Update start button state
	update_host_controls()

func add_bot(slot: int):
	if not is_host:
		return
	
	# Check if slot is already taken
	if players.any(func(p): return p["slot"] == slot) or bots.any(func(b): return b["slot"] == slot):
		return
	
	# Add bot to list
	var bot_name = "Bot " + str(slot)
	bots.append({
		"name": bot_name,
		"slot": slot,
		"difficulty": bot_difficulty
	})
	
	# Update UI
	player_slots[slot]["name_label"].text = bot_name + " (AI)"
	
	if player_slots[slot].has("add_bot_button") and player_slots[slot]["add_bot_button"]:
		player_slots[slot]["add_bot_button"].visible = false
	
	# Update start button state
	update_host_controls()
	
	# In a real multiplayer implementation, we would sync this with other players
	# For now, we'll just update the UI

func _on_copy_button_pressed():
	# Copy room code to clipboard
	DisplayServer.clipboard_set(room_code)
	$Panel/VBoxContainer/StatusLabel.text = "Room code copied to clipboard!"

func _on_add_bot_button_pressed(slot):
	add_bot(slot)

func _on_start_game_button_pressed():
	if not is_host:
		return
	
	# Check if all slots are filled
	var all_slots_filled = true
	for i in range(4):
		if not players.any(func(p): return p["slot"] == i) and not bots.any(func(b): return b["slot"] == i):
			all_slots_filled = false
			break
	
	if not all_slots_filled:
		$Panel/VBoxContainer/StatusLabel.text = "All player slots must be filled!"
		return
	
	# Start the game
	var game_players = []
	
	# Add human players
	for player in players:
		game_players.append({
			"name": player["name"],
			"slot": player["slot"],
			"is_bot": false,
			"is_self": player["is_self"]
		})
	
	# Add bot players
	for bot in bots:
		game_players.append({
			"name": bot["name"],
			"slot": bot["slot"],
			"is_bot": true,
			"difficulty": bot["difficulty"]
		})
	
	# Sort players by slot
	game_players.sort_custom(func(a, b): return a["slot"] < b["slot"])
	
	# Emit signal to start game
	start_multiplayer_game.emit(game_players)
	queue_free()

func _on_leave_room_button_pressed():
	# In a real multiplayer implementation, we would notify other players
	leave_room.emit()
	queue_free()
