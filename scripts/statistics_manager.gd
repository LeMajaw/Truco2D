extends Node

# Game Statistics Manager for Truco Paulista
# Tracks and saves player statistics across game sessions

signal statistics_updated

# Statistics categories
var stats = {
	"games_played": 0,
	"games_won": 0,
	"games_lost": 0,
	"rounds_played": 0,
	"rounds_won": 0,
	"rounds_lost": 0,
	"truco_called": 0,
	"truco_accepted": 0,
	"truco_declined": 0,
	"truco_raised": 0,
	"highest_score": 0,
	"cards_played": 0,
	"manilhas_played": 0,
	"bot_difficulty_wins": {
		"easy": 0,
		"normal": 0,
		"hard": 0,
		"expert": 0
	},
	"last_played": "",
	"total_play_time": 0
}

# Session tracking
var session_start_time = 0
var current_bot_difficulty = 1  # 0=Easy, 1=Normal, 2=Hard, 3=Expert

# Configuration
var config_path = "user://player_statistics.cfg"

func _ready():
	# Load existing statistics
	load_statistics()
	
	# Start session timer
	session_start_time = Time.get_unix_time_from_system()
	
	# Connect to game events
	connect_to_game_events()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Save statistics when game is closed
		update_play_time()
		save_statistics()

func connect_to_game_events():
	# Find game manager to connect signals
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		# Connect to relevant signals
		if game_manager.has_signal("round_ended"):
			game_manager.round_ended.connect(_on_round_ended)
		if game_manager.has_signal("game_ended"):
			game_manager.game_ended.connect(_on_game_ended)
		if game_manager.has_signal("truco_called"):
			game_manager.truco_called.connect(_on_truco_called)
		if game_manager.has_signal("truco_response"):
			game_manager.truco_response.connect(_on_truco_response)
		if game_manager.has_signal("card_played"):
			game_manager.card_played.connect(_on_card_played)

func load_statistics():
	var config = ConfigFile.new()
	var err = config.load(config_path)
	
	if err == OK:
		# Load all statistics from config
		for category in stats.keys():
			if category == "bot_difficulty_wins":
				for difficulty in stats[category].keys():
					stats[category][difficulty] = config.get_value("statistics", "bot_wins_" + difficulty, 0)
			else:
				stats[category] = config.get_value("statistics", category, stats[category])

func save_statistics():
	var config = ConfigFile.new()
	
	# Update timestamp
	stats["last_played"] = Time.get_datetime_string_from_system()
	
	# Save all statistics to config
	for category in stats.keys():
		if category == "bot_difficulty_wins":
			for difficulty in stats[category].keys():
				config.set_value("statistics", "bot_wins_" + difficulty, stats[category][difficulty])
		else:
			config.set_value("statistics", category, stats[category])
	
	config.save(config_path)
	
	# Emit signal
	statistics_updated.emit()

func update_play_time():
	var current_time = Time.get_unix_time_from_system()
	var session_duration = current_time - session_start_time
	stats["total_play_time"] += int(session_duration)
	session_start_time = current_time  # Reset for next update

# Event handlers
func _on_round_ended(winner_team):
	stats["rounds_played"] += 1
	
	if winner_team == "we":
		stats["rounds_won"] += 1
	else:
		stats["rounds_lost"] += 1
	
	save_statistics()

func _on_game_ended(winner_team):
	stats["games_played"] += 1
	
	if winner_team == "we":
		stats["games_won"] += 1
		
		# Track wins by difficulty
		match current_bot_difficulty:
			0: stats["bot_difficulty_wins"]["easy"] += 1
			1: stats["bot_difficulty_wins"]["normal"] += 1
			2: stats["bot_difficulty_wins"]["hard"] += 1
			3: stats["bot_difficulty_wins"]["expert"] += 1
	else:
		stats["games_lost"] += 1
	
	# Update highest score
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		var our_score = game_manager.team_points["we"]
		stats["highest_score"] = max(stats["highest_score"], our_score)
	
	# Update play time
	update_play_time()
	
	save_statistics()

func _on_truco_called(caller, level):
	stats["truco_called"] += 1
	save_statistics()

func _on_truco_response(responder, response, level):
	match response:
		0:  # Accept
			stats["truco_accepted"] += 1
		1:  # Decline
			stats["truco_declined"] += 1
		2:  # Raise
			stats["truco_raised"] += 1
	
	save_statistics()

func _on_card_played(player, card_data):
	stats["cards_played"] += 1
	
	# Check if manilha was played
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and card_data["value"] == game_manager.manilha_value:
		stats["manilhas_played"] += 1
	
	save_statistics()

# Set current bot difficulty
func set_bot_difficulty(difficulty):
	current_bot_difficulty = difficulty

# Get formatted statistics for display
func get_formatted_statistics():
	var result = {}
	
	# Format play time
	var hours = stats["total_play_time"] / 3600
	var minutes = (stats["total_play_time"] % 3600) / 60
	var seconds = stats["total_play_time"] % 60
	result["play_time"] = "%02d:%02d:%02d" % [hours, minutes, seconds]
	
	# Calculate win rate
	var win_rate = 0.0
	if stats["games_played"] > 0:
		win_rate = float(stats["games_won"]) / float(stats["games_played"]) * 100.0
	result["win_rate"] = "%.1f%%" % win_rate
	
	# Calculate truco success rate
	var truco_success = 0.0
	if stats["truco_called"] > 0:
		truco_success = float(stats["truco_accepted"]) / float(stats["truco_called"]) * 100.0
	result["truco_success"] = "%.1f%%" % truco_success
	
	# Add other stats
	result["games_played"] = stats["games_played"]
	result["games_won"] = stats["games_won"]
	result["games_lost"] = stats["games_lost"]
	result["highest_score"] = stats["highest_score"]
	result["truco_called"] = stats["truco_called"]
	result["truco_raised"] = stats["truco_raised"]
	result["cards_played"] = stats["cards_played"]
	result["manilhas_played"] = stats["manilhas_played"]
	result["last_played"] = stats["last_played"]
	result["bot_difficulty_wins"] = stats["bot_difficulty_wins"]
	
	return result

# Reset all statistics
func reset_statistics():
	for category in stats.keys():
		if category == "bot_difficulty_wins":
			for difficulty in stats[category].keys():
				stats[category][difficulty] = 0
		else:
			if typeof(stats[category]) == TYPE_INT:
				stats[category] = 0
			elif typeof(stats[category]) == TYPE_STRING:
				stats[category] = ""
	
	save_statistics()
