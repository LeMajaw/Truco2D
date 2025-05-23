extends Node
class_name BotExpert

# Expert Bot - Uses advanced strategy with learning capabilities
# This bot features bluff logic, Truco timing, card memory, and calculated risks
# It also learns from past games to improve its strategy

# Reference to game manager for accessing game state
var game_manager: Node

# Memory of played cards in current game
var played_cards_memory = []

# Learning parameters
var learning_data = {
	"games_played": 0,
	"wins": 0,
	"losses": 0,
	"successful_trucos": 0,
	"failed_trucos": 0,
	"successful_bluffs": 0,
	"failed_bluffs": 0,
	"card_play_success": {}, # Track success rate of different card play strategies
	"opponent_patterns": {} # Track opponent patterns
}

# Strategy weights (adjusted through learning)
var strategy_weights = {
	"aggressive": 0.5, # Tendency to play aggressively
	"bluff": 0.3, # Tendency to bluff
	"conservative": 0.5, # Tendency to play conservatively
	"truco_timing": 0.5 # Optimal timing for truco calls
}

# Config file for persistent learning
const SAVE_PATH = "user://expert_bot_learning.cfg"

# Initialization
func setup(manager: Node):
	game_manager = manager
	_load_learning_data()

# Load learning data from file
func _load_learning_data():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)

	if err == OK:
		# Load basic stats
		learning_data.games_played = config.get_value("stats", "games_played", 0)
		learning_data.wins = config.get_value("stats", "wins", 0)
		learning_data.losses = config.get_value("stats", "losses", 0)
		learning_data.successful_trucos = config.get_value("stats", "successful_trucos", 0)
		learning_data.failed_trucos = config.get_value("stats", "failed_trucos", 0)
		learning_data.successful_bluffs = config.get_value("stats", "successful_bluffs", 0)
		learning_data.failed_bluffs = config.get_value("stats", "failed_bluffs", 0)

		# Load strategy weights
		strategy_weights.aggressive = config.get_value("weights", "aggressive", 0.5)
		strategy_weights.bluff = config.get_value("weights", "bluff", 0.3)
		strategy_weights.conservative = config.get_value("weights", "conservative", 0.5)
		strategy_weights.truco_timing = config.get_value("weights", "truco_timing", 0.5)

		# Load card play success data
		if config.has_section("card_play_success"):
			var keys = config.get_section_keys("card_play_success")
			for key in keys:
				learning_data.card_play_success[key] = config.get_value("card_play_success", key, {})

		# Load opponent patterns
		if config.has_section("opponent_patterns"):
			var keys = config.get_section_keys("opponent_patterns")
			for key in keys:
				learning_data.opponent_patterns[key] = config.get_value("opponent_patterns", key, {})

		print("🤖 Expert Bot loaded learning data from " + SAVE_PATH)
	else:
		print("🤖 Expert Bot initialized with default learning parameters")

# Save learning data to file
func save_learning_data():
	var config = ConfigFile.new()

	# Save basic stats
	config.set_value("stats", "games_played", learning_data.games_played)
	config.set_value("stats", "wins", learning_data.wins)
	config.set_value("stats", "losses", learning_data.losses)
	config.set_value("stats", "successful_trucos", learning_data.successful_trucos)
	config.set_value("stats", "failed_trucos", learning_data.failed_trucos)
	config.set_value("stats", "successful_bluffs", learning_data.successful_bluffs)
	config.set_value("stats", "failed_bluffs", learning_data.failed_bluffs)

	# Save strategy weights
	config.set_value("weights", "aggressive", strategy_weights.aggressive)
	config.set_value("weights", "bluff", strategy_weights.bluff)
	config.set_value("weights", "conservative", strategy_weights.conservative)
	config.set_value("weights", "truco_timing", strategy_weights.truco_timing)

	# Save card play success data
	for key in learning_data.card_play_success.keys():
		config.set_value("card_play_success", key, learning_data.card_play_success[key])

	# Save opponent patterns
	for key in learning_data.opponent_patterns.keys():
		config.set_value("opponent_patterns", key, learning_data.opponent_patterns[key])

	# Save to file
	var err = config.save(SAVE_PATH)
	if err == OK:
		print("🤖 Expert Bot saved learning data to " + SAVE_PATH)
	else:
		print("🤖 Expert Bot failed to save learning data")

# Select a card from the bot's hand
func select_card(bot_name: String, hand: Array) -> Dictionary:
	if hand.size() == 0:
		push_error("Bot " + bot_name + " has no cards to play!")
		return {}

	# Get current game state
	var current_turn = game_manager.current_turn
	var manilha_value = game_manager.manilha_value
	var value_order = game_manager.value_order
	var suit_order = game_manager.suit_order
	var turn_winners = game_manager.turn_winners
	var played_cards = game_manager.used_cards
	var truco_called = game_manager.truco_called

	# Update memory of played cards
	_update_memory(played_cards)

	# Sort cards by power (highest to lowest)
	var sorted_hand = hand.duplicate()
	sorted_hand.sort_custom(func(a, b):
		var power_a = _get_card_power(a, manilha_value, value_order, suit_order)
		var power_b = _get_card_power(b, manilha_value, value_order, suit_order)
		return power_a > power_b
	)

	# Generate possible strategies
	var strategies = {
		"highest": sorted_hand[0],
		"lowest": sorted_hand[sorted_hand.size() - 1],
		"middle": _get_middle_card(sorted_hand),
		"bluff": _select_bluff_card(sorted_hand, current_turn),
		"strategic": _select_strategic_card(sorted_hand, current_turn, turn_winners, bot_name)
	}

	# Choose strategy based on game state and learning
	var strategy_name = _choose_best_strategy(strategies, hand, current_turn, turn_winners, bot_name, truco_called)
	var selected_card = strategies[strategy_name]

	# Record the strategy for learning
	var strategy_key = "turn" + str(current_turn) + "_" + strategy_name
	if not learning_data.card_play_success.has(strategy_key):
		learning_data.card_play_success[strategy_key] = {"uses": 0, "wins": 0}
	learning_data.card_play_success[strategy_key].uses += 1

	print("🤖 Expert Bot " + bot_name + " selected card: " + selected_card.value + " of " + selected_card.suit + " using " + strategy_name + " strategy")

	return selected_card

# Update memory of played cards
func _update_memory(played_cards: Array):
	for card in played_cards:
		if not _card_in_memory(card):
			played_cards_memory.append(card.duplicate())

# Check if card is in memory
func _card_in_memory(card: Dictionary) -> bool:
	for memory_card in played_cards_memory:
		if memory_card.value == card.value and memory_card.suit == card.suit:
			return true
	return false

# Calculate card power (similar to game manager's logic)
func _get_card_power(card: Dictionary, manilha_value: String, value_order: Array, suit_order: Array) -> int:
	if card.value == manilha_value:
		return 100 + suit_order.size() - suit_order.find(card.suit)
	var index = value_order.find(card.value)
	return value_order.size() - index if index != -1 else 0

# Get middle card from sorted hand
func _get_middle_card(sorted_hand: Array) -> Dictionary:
	var middle_index = float(sorted_hand.size()) / 2
	return sorted_hand[middle_index]

# Select a card for bluffing
func _select_bluff_card(sorted_hand: Array, current_turn: int) -> Dictionary:
	# For bluffing, we want to play a weak card but make it seem strong
	if current_turn == 0 and sorted_hand.size() >= 2:
		# First turn bluff: play second-weakest card
		return sorted_hand[sorted_hand.size() - 2]
	else:
		# Later turns: play weakest card
		return sorted_hand[sorted_hand.size() - 1]

# Select card strategically based on turn and game state
func _select_strategic_card(sorted_hand: Array, current_turn: int, turn_winners: Array, bot_name: String) -> Dictionary:
	var team = "we" if bot_name in ["player", "bot2"] else "them"
	var opponent_team = "them" if team == "we" else "we"

	# Check if we already won a turn
	var team_won = turn_winners.has(team)
	var opponent_won = turn_winners.has(opponent_team)

	if team_won and not opponent_won:
		# We're ahead, play conservatively
		if sorted_hand.size() >= 2:
			# Play second-best card to preserve best for last turn if needed
			return sorted_hand[1]
		else:
			return sorted_hand[0]
	elif opponent_won and not team_won:
		# We're behind, must play strongest card
		return sorted_hand[0]
	elif current_turn == 2:
		# Last turn, play strongest card
		return sorted_hand[0]
	else:
		# First turn or tied, use balanced approach
		if sorted_hand.size() >= 3:
			return sorted_hand[1] # Middle-high card
		else:
			return sorted_hand[0]

# Choose best strategy based on learning and game state
func _choose_best_strategy(strategies: Dictionary, hand: Array, current_turn: int, turn_winners: Array, bot_name: String, truco_called: bool) -> String:
	# Calculate hand strength
	var hand_strength = _calculate_hand_strength(hand)

	# Base probabilities for each strategy
	var probabilities = {
		"highest": 0.3,
		"lowest": 0.05,
		"middle": 0.2,
		"bluff": 0.15,
		"strategic": 0.3
	}

	# Adjust based on hand strength
	if hand_strength > 0.7:
		# Strong hand: favor highest and strategic
		probabilities.highest += 0.2
		probabilities.strategic += 0.1
		probabilities.bluff -= 0.1
		probabilities.lowest -= 0.1
	elif hand_strength < 0.4:
		# Weak hand: favor bluff and strategic
		probabilities.bluff += 0.2
		probabilities.strategic += 0.1
		probabilities.highest -= 0.2

	# Adjust based on game state
	var team = "we" if bot_name in ["player", "bot2"] else "them"
	var team_won = turn_winners.has(team)

	if team_won:
		# We already won a turn: more conservative
		probabilities.strategic += 0.1
		probabilities.highest -= 0.1

	if truco_called:
		# Truco was called: favor stronger plays
		probabilities.highest += 0.15
		probabilities.lowest -= 0.05
		probabilities.bluff -= 0.05

	# Adjust based on learning data
	for strategy in probabilities.keys():
		var strategy_key = "turn" + str(current_turn) + "_" + strategy
		if learning_data.card_play_success.has(strategy_key):
			var data = learning_data.card_play_success[strategy_key]
			if data.uses > 0:
				var success_rate = float(data.wins) / float(data.uses)
				# Boost strategies that worked well in the past
				probabilities[strategy] += success_rate * 0.2

	# Adjust based on strategy weights from learning
	probabilities.highest *= (1.0 + strategy_weights.aggressive - 0.5)
	probabilities.bluff *= (1.0 + strategy_weights.bluff - 0.3)
	probabilities.strategic *= (1.0 + strategy_weights.conservative - 0.5)

	# Normalize probabilities
	var total = 0.0
	for strategy in probabilities.keys():
		total += probabilities[strategy]

	for strategy in probabilities.keys():
		probabilities[strategy] /= total

	# Choose strategy based on probabilities
	var roll = randf()
	var cumulative = 0.0

	for strategy in probabilities.keys():
		cumulative += probabilities[strategy]
		if roll <= cumulative:
			return strategy

	# Fallback to strategic
	return "strategic"

# Calculate hand strength (0.0 to 1.0)
func _calculate_hand_strength(hand: Array) -> float:
	var manilha_value = game_manager.manilha_value
	var value_order = game_manager.value_order
	var suit_order = game_manager.suit_order

	var total_power = 0
	var max_possible_power = 0
	var has_manilha = false

	# Calculate actual power
	for card in hand:
		var power = _get_card_power(card, manilha_value, value_order, suit_order)
		total_power += power
		if card.value == manilha_value:
			has_manilha = true

	# Calculate theoretical maximum power
	for i in range(hand.size()):
		if i == 0:
			# Best possible card: highest manilha
			max_possible_power += 100 + suit_order.size()
		else:
			# Next best cards: highest non-manilha
			max_possible_power += value_order.size()

	# Bonus for having manilha
	var manilha_bonus = 0.15 if has_manilha else 0.0

	# Calculate strength ratio and add manilha bonus
	var strength = float(total_power) / float(max_possible_power) + manilha_bonus

	# Cap at 1.0
	return min(strength, 1.0)

# Decide whether to call truco
func should_call_truco(bot_name: String) -> bool:
	# Get bot's hand
	var hand = game_manager.player_hands[bot_name]
	if hand.size() == 0:
		return false

	# Calculate hand strength
	var hand_strength = _calculate_hand_strength(hand)

	# Consider game state
	var current_turn = game_manager.current_turn
	var turn_winners = game_manager.turn_winners
	var team = "we" if bot_name in ["player", "bot2"] else "them"

	# Base probability of calling truco
	var truco_probability = 0.0

	# Adjust based on hand strength
	if hand_strength > 0.8:
		truco_probability = 0.9 # Very strong hand
	elif hand_strength > 0.6:
		truco_probability = 0.7 # Strong hand
	elif hand_strength > 0.5:
		truco_probability = 0.5 # Decent hand
	elif hand_strength > 0.4:
		truco_probability = 0.3 # Mediocre hand
	else:
		truco_probability = 0.1 # Weak hand (bluff)

	# Adjust based on game state
	if turn_winners.has(team):
		truco_probability += 0.2 # More likely if we won a turn

	# Adjust based on turn
	if current_turn == 0:
		truco_probability *= strategy_weights.truco_timing # Adjust based on learned timing
	elif current_turn == 1:
		truco_probability *= (1.0 + strategy_weights.truco_timing) # More likely in middle of round

	# Adjust based on learning
	var success_rate = 0.5 # Default
	if learning_data.successful_trucos + learning_data.failed_trucos > 0:
		success_rate = float(learning_data.successful_trucos) / float(learning_data.successful_trucos + learning_data.failed_trucos)

	truco_probability *= (0.5 + success_rate)

	# Bluff factor
	if hand_strength < 0.4 and randf() < strategy_weights.bluff:
		truco_probability += 0.3 # Sometimes bluff with weak hands

	# Final decision
	var call_truco = randf() < truco_probability

	if call_truco:
		print("🤖 Expert Bot " + bot_name + " decided to call truco with hand strength: " + str(hand_strength) + " (probability: " + str(truco_probability) + ")")

	return call_truco

# Decide whether to accept truco
func should_accept_truco(bot_name: String) -> bool:
	# Get bot's hand
	var hand = game_manager.player_hands[bot_name]
	if hand.size() == 0:
		return false

	# Calculate hand strength
	var hand_strength = _calculate_hand_strength(hand)

	# Consider game state
	var current_turn = game_manager.current_turn
	var turn_winners = game_manager.turn_winners
	var team = "we" if bot_name in ["player", "bot2"] else "them"

	# Base probability of accepting truco
	var accept_probability = 0.0

	# Adjust based on hand strength
	if hand_strength > 0.7:
		accept_probability = 0.95 # Very strong hand
	elif hand_strength > 0.5:
		accept_probability = 0.8 # Strong hand
	elif hand_strength > 0.4:
		accept_probability = 0.6 # Decent hand
	elif hand_strength > 0.3:
		accept_probability = 0.4 # Mediocre hand
	else:
		accept_probability = 0.2 # Weak hand

	# Adjust based on game state
	if turn_winners.has(team):
		accept_probability += 0.2 # More likely if we won a turn

	# Adjust based on turn
	if current_turn == 0:
		accept_probability += 0.1 # More likely to accept at start
	elif current_turn == 2:
		accept_probability -= 0.1 # Less likely to accept at end if not strong

	# Adjust based on learning
	var success_rate = 0.5 # Default
	if learning_data.wins + learning_data.losses > 0:
		success_rate = float(learning_data.wins) / float(learning_data.wins + learning_data.losses)

	accept_probability *= (0.8 + success_rate * 0.4)

	# Final decision
	var accept_truco = randf() < accept_probability

	if accept_truco:
		print("🤖 Expert Bot " + bot_name + " decided to accept truco with hand strength: " + str(hand_strength) + " (probability: " + str(accept_probability) + ")")
	else:
		print("🤖 Expert Bot " + bot_name + " decided to decline truco with hand strength: " + str(hand_strength) + " (probability: " + str(accept_probability) + ")")

	return accept_truco

# Record game result for learning
func record_game_result(won: bool, truco_called_by_bot: bool, truco_successful: bool):
	learning_data.games_played += 1

	if won:
		learning_data.wins += 1

		# Update strategy success
		for key in learning_data.card_play_success.keys():
			learning_data.card_play_success[key].wins += 1
	else:
		learning_data.losses += 1

	# Update truco success
	if truco_called_by_bot:
		if truco_successful:
			learning_data.successful_trucos += 1
			# Increase truco timing weight slightly
			strategy_weights.truco_timing = min(1.0, strategy_weights.truco_timing + 0.05)
		else:
			learning_data.failed_trucos += 1
			# Decrease truco timing weight slightly
			strategy_weights.truco_timing = max(0.0, strategy_weights.truco_timing - 0.05)

	# Adjust strategy weights based on game outcome
	if won:
		# Reinforce successful strategies
		strategy_weights.aggressive = _adjust_weight(strategy_weights.aggressive, 0.02)
		strategy_weights.bluff = _adjust_weight(strategy_weights.bluff, 0.01)
		strategy_weights.conservative = _adjust_weight(strategy_weights.conservative, 0.02)
	else:
		# Try different strategies
		strategy_weights.aggressive = _adjust_weight(strategy_weights.aggressive, -0.02)
		strategy_weights.bluff = _adjust_weight(strategy_weights.bluff, -0.01)
		strategy_weights.conservative = _adjust_weight(strategy_weights.conservative, -0.02)

	# Save learning data
	save_learning_data()

# Adjust weight with bounds
func _adjust_weight(weight: float, delta: float) -> float:
	return clamp(weight + delta, 0.1, 0.9)

# Get bot name for display
func get_bot_name() -> String:
	return "Expert Bot"

# Get bot difficulty level (1-4)
func get_difficulty_level() -> int:
	return 4
