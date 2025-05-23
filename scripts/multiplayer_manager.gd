extends Node

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
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	rpc_config("rpc_register_player", {"rpc_mode": MultiplayerAPI.RPC_MODE_AUTHORITY})
	rpc_config("rpc_start_game", {"rpc_mode": MultiplayerAPI.RPC_MODE_AUTHORITY})
	rpc_config("rpc_sync_game_state", {"rpc_mode": MultiplayerAPI.RPC_MODE_AUTHORITY})
	rpc_config("rpc_play_card", {"rpc_mode": MultiplayerAPI.RPC_MODE_AUTHORITY})
	rpc_config("rpc_call_truco", {"rpc_mode": MultiplayerAPI.RPC_MODE_AUTHORITY})

# Host a new game
func create_room(p_room_code: String, player_name: String):
	room_code = p_room_code
	is_host = true

	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(DEFAULT_PORT, MAX_PLAYERS - 1)
	if error != OK:
		print("Failed to create server: ", error)
		return false

	multiplayer.multiplayer_peer = peer
	player_id = 1

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

	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip_address, DEFAULT_PORT)
	if error != OK:
		print("Failed to create client: ", error)
		return false

	multiplayer.multiplayer_peer = peer
	await multiplayer.connected_to_server

	player_id = multiplayer.get_unique_id()

	players.append({
		"id": player_id,
		"name": player_name,
		"slot": - 1,
		"is_self": true
	})

	rpc_id(1, "rpc_register_player", player_id, player_name)
	print("Joined room with code: ", room_code)
	return true

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

func add_bot(bot_name: String, slot: int, difficulty: int):
	if not is_host:
		return false

	if players.any(func(p): return p["slot"] == slot) or bots.any(func(b): return b["slot"] == slot):
		return false

	bots.append({
		"name": bot_name,
		"slot": slot,
		"difficulty": difficulty
	})

	rpc("rpc_sync_bots", bots)
	return true

func start_game():
	if not is_host:
		return false

	var filled_slots = []
	for player in players:
		filled_slots.append(player["slot"])
	for bot in bots:
		filled_slots.append(bot["slot"])

	if filled_slots.size() < 4:
		print("Not all slots are filled")
		return false

	var initial_state = _generate_initial_game_state()
	rpc("rpc_start_game", initial_state)
	_handle_game_start(initial_state)
	return true

func play_card(card_data):
	if not game_in_progress:
		return false

	if is_host:
		_handle_card_played(player_id, card_data)
	else:
		rpc_id(1, "rpc_play_card", player_id, card_data)
	return true

func call_truco():
	if not game_in_progress:
		return false

	if is_host:
		_handle_truco_called(player_id)
	else:
		rpc_id(1, "rpc_call_truco", player_id)
	return true

func _generate_initial_game_state():
	return {
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

func _handle_game_start(initial_state):
	game_in_progress = true
	game_started.emit(initial_state)

func _handle_card_played(p_player_id, card_data):
	if is_host:
		rpc("rpc_sync_card_played", p_player_id, card_data)
	card_played.emit(p_player_id, card_data)

func _handle_truco_called(p_player_id):
	if is_host:
		rpc("rpc_sync_truco_called", p_player_id)
	truco_called.emit(p_player_id)

# RPC METHODS

@rpc("any_peer")
func rpc_register_player(p_player_id, player_name):
	if not is_host:
		return

	var slot = -1
	for i in range(4):
		if not players.any(func(p): return p["slot"] == i) and not bots.any(func(b): return b["slot"] == i):
			slot = i
			break

	if slot == -1:
		return

	var player_data = {
		"id": p_player_id,
		"name": player_name,
		"slot": slot,
		"is_self": false
	}
	players.append(player_data)

	rpc("rpc_sync_players", players)
	rpc_id(p_player_id, "rpc_sync_bots", bots)
	player_joined.emit(player_data)

@rpc("authority")
func rpc_sync_players(p_players):
	var self_player = players.filter(func(p): return p["is_self"])[0]
	players = p_players
	for p in players:
		if p["id"] == player_id:
			self_player["slot"] = p["slot"]
			break

	for i in range(players.size()):
		players[i]["is_self"] = players[i]["id"] == player_id

@rpc("authority")
func rpc_sync_bots(p_bots):
	bots = p_bots

@rpc("authority")
func rpc_start_game(initial_state):
	_handle_game_start(initial_state)

@rpc("authority")
func rpc_sync_game_state(state):
	game_state_updated.emit(state)

@rpc("authority")
func rpc_play_card(p_player_id, card_data):
	_handle_card_played(p_player_id, card_data)

@rpc("authority")
func rpc_call_truco(p_player_id):
	_handle_truco_called(p_player_id)

@rpc("authority")
func rpc_sync_card_played(p_player_id, card_data):
	card_played.emit(p_player_id, card_data)

@rpc("authority")
func rpc_sync_truco_called(p_player_id):
	truco_called.emit(p_player_id)

func _on_peer_connected(id):
	print("Peer connected: ", id)

func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)
	var player_to_remove = null
	for p in players:
		if p["id"] == id:
			player_to_remove = p
			break

	if player_to_remove:
		players.erase(player_to_remove)
		if is_host:
			rpc("rpc_sync_players", players)
		player_left.emit(id)
