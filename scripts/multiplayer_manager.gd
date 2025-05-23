extends Node

class_name MultiplayerManager

signal player_joined(player_data)
signal player_left(player_id)
signal game_started(initial_state)
signal game_state_updated(state)
signal card_played(player_id, card_data)
signal truco_called(player_id)

# Networking constants
const DEFAULT_PORT = 7777
const MAX_PLAYERS = 4

# Game state
var room_code = ""
var is_host = false
var player_id = 0
var players = []
var bots = []
var game_in_progress = false

# Networking objects
var peer = null

func _ready():
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Set up RPC methods
	rpc_config("register_player", MultiplayerAPI.RPC_MODE_AUTHORITY)
	rpc_config("start_game", MultiplayerAPI.RPC_MODE_AUTHORITY)
	rpc_config("sync_game_state", MultiplayerAPI.RPC_MODE_AUTHORITY)
	rpc_config("play_card", MultiplayerAPI.RPC_MODE_AUTHORITY)
	rpc_config("call_truco", MultiplayerAPI.RPC_MODE_AUTHORITY)

# Host a new game
func create_room(p_room_code: String, player_name: String):
	room_code = p_room_code
	is_host = true
	
	# Create server
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(DEFAULT_PORT, MAX_PLAYERS - 1)  # -1 because host counts as a player
	
	if error != OK:
		print("Failed to create server: ", error)
		return false
	
	multiplayer.multiplayer_peer = peer
	player_id = 1  # Host is always ID 1
	
	# Add self as first player
	players.append({
		"id": player_id,
		"name": player_name,
		"slot": 0,
		"is_self": true
	})
	
	print("Room created with code: ", room_code)
	return true

# Join an existing game
func join_room(p_room_code: String, player_name: String, ip_address: String):
	room_code = p_room_code
	is_host = false
	
	# Create client
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, DEFAULT_PORT)
	
	if error != OK:
		print("Failed to create client: ", error)
		return false
	
	multiplayer.multiplayer_peer = peer
	
	# Wait for connection established and ID assigned
	await multiplayer.connected_to_server
	
	player_id = multiplayer.get_unique_id()
	
	# Add self as player (slot will be assigned by host)
	players.append({
		"id": player_id,
		"name": player_name,
		"slot": -1,  # Temporary until assigned by host
		"is_self": true
	})
	
	# Register with host
	rpc_id(1, "register_player", player_id, player_name)
	
	print("Joined room with code: ", room_code)
	return true

# Leave the current game
func leave_room():
	if peer:
		peer.close()
		peer = null
	
	multiplayer.multiplayer_peer = null
	
	room_code = ""
	is_host = false
	player_id = 0
	players.clear()
	bots.clear()
	game_in_progress = false
	
	print("Left room")

# Add a bot to the game (host only)
func add_bot(bot_name: String, slot: int, difficulty: int):
	if not is_host:
		return false
	
	# Check if slot is already taken
	if players.any(func(p): return p["slot"] == slot) or bots.any(func(b): return b["slot"] == slot):
		return false
	
	# Add bot
	bots.append({
		"name": bot_name,
		"slot": slot,
		"difficulty": difficulty
	})
	
	# Notify all clients
	rpc("sync_bots", bots)
	
	return true

# Start the game (host only)
func start_game():
	if not is_host:
		return false
	
	# Check if all slots are filled
	var filled_slots = []
	for player in players:
		filled_slots.append(player["slot"])
	
	for bot in bots:
		filled_slots.append(bot["slot"])
	
	if filled_slots.size() < 4:
		print("Not all slots are filled")
		return false
	
	# Generate initial game state
	var initial_state = _generate_initial_game_state()
	
	# Notify all clients
	rpc("start_game", initial_state)
	
	# Start locally
	_handle_game_start(initial_state)
	
	return true

# Play a card
func play_card(card_data):
	if not game_in_progress:
		return false
	
	# In a real implementation, we would validate the move
	
	# Send to host (or process locally if we are host)
	if is_host:
		_handle_card_played(player_id, card_data)
	else:
		rpc_id(1, "play_card", player_id, card_data)
	
	return true

# Call truco
func call_truco():
	if not game_in_progress:
		return false
	
	# In a real implementation, we would validate the move
	
	# Send to host (or process locally if we are host)
	if is_host:
		_handle_truco_called(player_id)
	else:
		rpc_id(1, "call_truco", player_id)
	
	return true

# Generate initial game state
func _generate_initial_game_state():
	# In a real implementation, this would create the deck, deal cards, etc.
	var state = {
		"deck": [],
		"vira": null,
		"manilha": "",
		"player_hands": {},
		"current_turn": 0,
		"pe_index": 0,
		"score": {"we": 0, "them": 0},
		"current_score_value": 1,
		"truco_called": false
	}
	
	return state

# Handle game start
func _handle_game_start(initial_state):
	game_in_progress = true
	
	# Emit signal
	game_started.emit(initial_state)

# Handle card played
func _handle_card_played(p_player_id, card_data):
	# In a real implementation, we would update the game state
	
	# If we're the host, broadcast to all clients
	if is_host:
		rpc("sync_card_played", p_player_id, card_data)
	
	# Emit signal
	card_played.emit(p_player_id, card_data)

# Handle truco called
func _handle_truco_called(p_player_id):
	# In a real implementation, we would update the game state
	
	# If we're the host, broadcast to all clients
	if is_host:
		rpc("sync_truco_called", p_player_id)
	
	# Emit signal
	truco_called.emit(p_player_id)

# RPC methods (called remotely)

# Register a new player (called on host)
@rpc("any_peer")
func register_player(p_player_id, player_name):
	if not is_host:
		return
	
	# Find an available slot
	var slot = -1
	for i in range(4):
		if not players.any(func(p): return p["slot"] == i) and not bots.any(func(b): return b["slot"] == i):
			slot = i
			break
	
	if slot == -1:
		# No slots available
		# In a real implementation, we would notify the player and disconnect them
		return
	
	# Add player
	var player_data = {
		"id": p_player_id,
		"name": player_name,
		"slot": slot,
		"is_self": false
	}
	
	players.append(player_data)
	
	# Notify all clients about the new player
	rpc("sync_players", players)
	
	# Notify about existing bots
	rpc_id(p_player_id, "sync_bots", bots)
	
	# Emit signal
	player_joined.emit(player_data)

# Sync players list (called on clients)
@rpc("authority")
func sync_players(p_players):
	# Update local players list, preserving is_self flag
	var self_player = players.filter(func(p): return p["is_self"])[0]
	
	players = p_players
	
	# Update self player's slot from server data
	for p in players:
		if p["id"] == player_id:
			self_player["slot"] = p["slot"]
			break
	
	# Make sure our self player is marked correctly
	for i in range(players.size()):
		if players[i]["id"] == player_id:
			players[i]["is_self"] = true
		else:
			players[i]["is_self"] = false

# Sync bots list (called on clients)
@rpc("authority")
func sync_bots(p_bots):
	bots = p_bots

# Start game (called on clients)
@rpc("authority")
func start_game(initial_state):
	_handle_game_start(initial_state)

# Sync game state (called on clients)
@rpc("authority")
func sync_game_state(state):
	game_state_updated.emit(state)

# Sync card played (called on clients)
@rpc("authority")
func sync_card_played(p_player_id, card_data):
	card_played.emit(p_player_id, card_data)

# Sync truco called (called on clients)
@rpc("authority")
func sync_truco_called(p_player_id):
	truco_called.emit(p_player_id)

# Connection callbacks

func _on_peer_connected(id):
	print("Peer connected: ", id)

func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)
	
	# Remove player
	var player_to_remove = null
	for p in players:
		if p["id"] == id:
			player_to_remove = p
			break
	
	if player_to_remove:
		players.erase(player_to_remove)
		
		# If we're the host, notify all clients
		if is_host:
			rpc("sync_players", players)
		
		# Emit signal
		player_left.emit(id)
