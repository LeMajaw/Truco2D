extends Node

# Bot difficulty levels
enum BotDifficulty {EASY, NORMAL, HARD, EXPERT}

# Store difficulty for each bot
var bot_difficulty = {
	"bot1": BotDifficulty.NORMAL,
	"bot2": BotDifficulty.NORMAL,
	"bot3": BotDifficulty.NORMAL
}

# Card evaluation constants
const MANILHA_BASE_VALUE = 100
const HIGH_CARD_THRESHOLD = 7 # Cards with value >= 7 are considered high
const MEDIUM_CARD_THRESHOLD = 4 # Cards with value >= 4 are considered medium

# Bluff probability based on difficulty
const BLUFF_PROBABILITY = {
	BotDifficulty.EASY: 0.0, # Never bluffs
	BotDifficulty.NORMAL: 0.1, # Rarely bluffs
	BotDifficulty.HARD: 0.25, # Sometimes bluffs
	BotDifficulty.EXPERT: 0.4 # Often bluffs strategically
}

# Truco call probability based on difficulty and hand strength
const TRUCO_PROBABILITY = {
	BotDifficulty.EASY: {
		"weak": 0.0,
		"medium": 0.05,
		"strong": 0.1
	},
	BotDifficulty.NORMAL: {
		"weak": 0.05,
		"medium": 0.2,
		"strong": 0.4
	},
	BotDifficulty.HARD: {
		"weak": 0.1,
		"medium": 0.3,
		"strong": 0.6
	},
	BotDifficulty.EXPERT: {
		"weak": 0.2, # May bluff with weak hand
		"medium": 0.5,
		"strong": 0.8
	}
}

# Memory factors (how well bots remember cards)
const MEMORY_FACTOR = {
	BotDifficulty.EASY: 0.0, # No memory
	BotDifficulty.NORMAL: 0.3, # Poor memory
	BotDifficulty.HARD: 0.7, # Good memory
	BotDifficulty.EXPERT: 1.0 # Perfect memory
}

# Reference to game manager
var game_manager

func _ready():
	# Find game manager in the scene
	game_manager = get_parent()

# Main function to select a card based on bot difficulty
func select_card(bot_name: String, available_cards: Array) -> Dictionary:
	var difficulty = bot_difficulty[bot_name]

	match difficulty:
		BotDifficulty.EASY:
			return select_card_easy(available_cards)
		BotDifficulty.NORMAL:
			return select_card_normal(available_cards)
		BotDifficulty.HARD:
			return select_card_hard(bot_name, available_cards)
		BotDifficulty.EXPERT:
			return select_card_expert(bot_name, available_cards)
		_:
			return select_card_normal(available_cards) # Default to normal

# EASY: Random or lowest-value logic
func select_card_easy(available_cards: Array) -> Dictionary:
	# 70% chance to play randomly, 30% chance to play lowest card
	if randf() < 0.7:
		# Play a random card
		return available_cards[randi() % available_cards.size()]
	else:
		# Play the lowest value card
		var lowest_card = available_cards[0]
		var lowest_power = get_card_power(lowest_card)

		for card in available_cards:
			var power = get_card_power(card)
			if power < lowest_power:
				lowest_card = card
				lowest_power = power

		return lowest_card

# NORMAL: Basic card ranking comparison
func select_card_normal(available_cards: Array) -> Dictionary:
	# Get current turn and played cards
	var current_turn = game_manager.current_turn
	var turn_winners = game_manager.turn_winners

	# If this is the first card of the turn
	if is_first_card_of_turn():
		# Play middle-strength card (not highest, not lowest)
		var sorted_cards = sort_cards_by_power(available_cards)

		if sorted_cards.size() == 1:
			return sorted_cards[0]
		elif sorted_cards.size() == 2:
			return sorted_cards[0] # Play lower of two
		else:
			return sorted_cards[1] # Play middle card of three

	# If not first card, try to win the turn if possible
	var highest_played = get_highest_played_card()
	var highest_power = get_card_power(highest_played)

	# Find a card that can beat the highest played card
	var winning_cards = []
	var lowest_power = null
	for card in available_cards:
		if get_card_power(card) > highest_power:
			winning_cards.append(card)

	# If we have cards that can win
	if winning_cards.size() > 0:
		# Play the lowest winning card
		var lowest_winner = winning_cards[0]
		lowest_power = get_card_power(lowest_winner)

		for card in winning_cards:
			var power = get_card_power(card)
			if power < lowest_power:
				lowest_winner = card
				lowest_power = power

		return lowest_winner

	# If we can't win, play the lowest card
	var lowest_card = available_cards[0]
	lowest_power = get_card_power(lowest_card)

	for card in available_cards:
		var power = get_card_power(card)
		if power < lowest_power:
			lowest_card = card
			lowest_power = power

	return lowest_card

# HARD: Considers manilha, opponent risk, and hand strength
func select_card_hard(bot_name: String, available_cards: Array) -> Dictionary:
	# Get current turn and played cards
	var current_turn = game_manager.current_turn
	var turn_winners = game_manager.turn_winners

	# Calculate hand strength
	var hand_strength = calculate_hand_strength(available_cards)

	# If this is the first card of the turn
	if is_first_card_of_turn():
		# If we have a strong hand, play a medium card
		if hand_strength == "strong":
			return get_medium_strength_card(available_cards)
		# If we have a medium hand, play our lowest card
		elif hand_strength == "medium":
			return get_lowest_card(available_cards)
		# If we have a weak hand, play our highest card
		else:
			return get_highest_card(available_cards)

	# If not first card, consider team strategy
	var team = get_bot_team(bot_name)
	var opponent_team = "them" if team == "we" else "we"

	# Check if our team is winning the current turn
	var is_team_winning = is_team_winning_current_turn(team)

	# If our team is already winning this turn
	if is_team_winning:
		# Play our lowest card
		return get_lowest_card(available_cards)

	# If our team is not winning, try to win the turn
	var highest_played = get_highest_played_card()
	var highest_power = get_card_power(highest_played)

	# Find a card that can beat the highest played card
	var winning_cards = []
	for card in available_cards:
		if get_card_power(card) > highest_power:
			winning_cards.append(card)

	# If we have cards that can win
	if winning_cards.size() > 0:
		# If it's the last turn or we lost the first turn, play to win
		if current_turn == 2 and turn_winners[0] == opponent_team:
			return get_highest_card(winning_cards)
		# Otherwise play the lowest winning card
		else:
			return get_lowest_card(winning_cards)

	# If we can't win, play the lowest card
	return get_lowest_card(available_cards)

# EXPERT: Bluff logic, Truco timing, card memory, calculated risks
func select_card_expert(bot_name: String, available_cards: Array) -> Dictionary:
	# Get current turn and played cards
	var current_turn = game_manager.current_turn
	var turn_winners = game_manager.turn_winners

	# Calculate hand strength
	var hand_strength = calculate_hand_strength(available_cards)

	# Consider bluffing based on game state
	var should_bluff = consider_bluff(bot_name, hand_strength)

	# If this is the first card of the turn
	if is_first_card_of_turn():
		# If bluffing, play a card that appears stronger than it is
		if should_bluff:
			# If we have a weak hand but want to bluff, play a medium card confidently
			if hand_strength == "weak":
				return get_medium_strength_card(available_cards)
			# If we have a medium hand, play our lowest card to save strength
			else:
				return get_lowest_card(available_cards)
		else:
			# Normal strategic play
			if hand_strength == "strong":
				# With strong hand, play strategically based on round state
				if current_turn == 0:
					# First turn of round, play medium to hide strength
					return get_medium_strength_card(available_cards)
				else:
					# Later turns, play to win if needed
					return get_highest_card(available_cards)
			elif hand_strength == "medium":
				# With medium hand, be conservative
				return get_lowest_card(available_cards)
			else:
				# With weak hand, play highest card to try to win at least one turn
				return get_highest_card(available_cards)

	# If not first card, use advanced team strategy
	var team = get_bot_team(bot_name)
	var opponent_team = "them" if team == "we" else "we"

	# Check if our team is winning the current turn
	var is_team_winning = is_team_winning_current_turn(team)

	# If our team is already winning this turn
	if is_team_winning:
		# Play our lowest card
		return get_lowest_card(available_cards)

	# If our team is not winning, consider the game state carefully
	var highest_played = get_highest_played_card()
	var highest_power = get_card_power(highest_played)

	# Find cards that can beat the highest played card
	var winning_cards = []
	for card in available_cards:
		if get_card_power(card) > highest_power:
			winning_cards.append(card)

	# If we have cards that can win
	if winning_cards.size() > 0:
		# Consider the turn and round state
		if current_turn == 0:
			# First turn is important, win it if we can
			return get_lowest_card(winning_cards)
		elif current_turn == 1:
			# If we won first turn, save strength
			if turn_winners[0] == team:
				return get_lowest_card(winning_cards)
			# If we lost first turn, play to win
			else:
				return get_highest_card(winning_cards)
		else: # current_turn == 2
			# Last turn, play to win if needed
			if turn_winners.count(team) < turn_winners.count(opponent_team):
				return get_highest_card(winning_cards)
			else:
				return get_lowest_card(winning_cards)

	# If we can't win, play strategically
	if current_turn < 2 and hand_strength != "weak":
		# If we have a decent hand and it's not the last turn,
		# consider sacrificing this turn to win later
		return get_lowest_card(available_cards)
	else:
		# Otherwise play our highest remaining card as a last effort
		return get_highest_card(available_cards)

# Helper function to get card power (same as in gameManager)
func get_card_power(card: Dictionary) -> int:
	var manilha_value = game_manager.manilha_value
	var value_order = game_manager.value_order
	var suit_order = game_manager.suit_order

	if card["value"] == manilha_value:
		return MANILHA_BASE_VALUE + suit_order.size() - suit_order.find(card["suit"])
	var index = value_order.find(card["value"])
	return value_order.size() - index if index != -1 else 0

# Helper function to sort cards by power
func sort_cards_by_power(cards: Array) -> Array:
	var sorted = cards.duplicate()
	sorted.sort_custom(func(a, b): return get_card_power(a) < get_card_power(b))
	return sorted

# Helper function to check if this is the first card of the turn
func is_first_card_of_turn() -> bool:
	var played_cards = get_tree().get_nodes_in_group("played_card")
	var current_turn_cards = 0

	for card in played_cards:
		# Check if card is from current turn (not vira or previous turns)
		if card.position != game_manager.VIRA_CARD_POS:
			current_turn_cards += 1

	# If no cards played yet in this turn
	return current_turn_cards == 0

# Helper function to get the highest played card in the current turn
func get_highest_played_card() -> Dictionary:
	var played_cards = []

	# Get all played cards from the current turn
	# This is a simplified version - in a real implementation,
	# you would track the actual played cards with their data

	# For now, we'll use a placeholder
	var highest_card = {"value": "4", "suit": "diamonds"} # Lowest possible card
	var highest_power = get_card_power(highest_card)

	for player in game_manager.player_order:
		if player != "player" and game_manager.last_player_card != null:
			# This is a simplification - you would need to track actual played cards
			var card = game_manager.last_player_card
			var power = get_card_power(card)
			if power > highest_power:
				highest_card = card
				highest_power = power

	return highest_card

# Helper function to calculate hand strength
func calculate_hand_strength(cards: Array) -> String:
	var total_power = 0
	var has_manilha = false

	for card in cards:
		var power = get_card_power(card)
		total_power += power

		if power >= MANILHA_BASE_VALUE:
			has_manilha = true

	# Calculate average power
	var avg_power = total_power / max(1, cards.size())

	# Determine hand strength
	if has_manilha or avg_power > 7:
		return "strong"
	elif avg_power > 4:
		return "medium"
	else:
		return "weak"

# Helper function to get the lowest card from a set
func get_lowest_card(cards: Array) -> Dictionary:
	var sorted = sort_cards_by_power(cards)
	return sorted[0]

# Helper function to get the highest card from a set
func get_highest_card(cards: Array) -> Dictionary:
	var sorted = sort_cards_by_power(cards)
	return sorted[sorted.size() - 1]

# Helper function to get a medium strength card
func get_medium_strength_card(cards: Array) -> Dictionary:
	var sorted = sort_cards_by_power(cards)

	if sorted.size() == 1:
		return sorted[0]
	elif sorted.size() == 2:
		return sorted[0] # Play lower of two
	else:
		return sorted[1] # Play middle card of three

# Helper function to get bot's team
func get_bot_team(bot_name: String) -> String:
	if bot_name in ["player", "bot2"]:
		return "we"
	else:
		return "them"

# Helper function to check if team is winning current turn
func is_team_winning_current_turn(team: String) -> bool:
	# This is a simplified version - in a real implementation,
	# you would need to track the actual highest card played
	# and which team it belongs to
	# For now, we'll use a placeholder
	return false

# Helper function to consider whether to bluff
func consider_bluff(bot_name: String, hand_strength: String) -> bool:
	var difficulty = bot_difficulty[bot_name]

	# Base bluff probability on difficulty
	var bluff_chance = BLUFF_PROBABILITY[difficulty]

	# Adjust based on hand strength
	if hand_strength == "strong":
		bluff_chance *= 0.5 # Less need to bluff with strong hand
	elif hand_strength == "weak":
		bluff_chance *= 1.5 # More incentive to bluff with weak hand

	# Consider game state (simplified)
	var current_turn = game_manager.current_turn
	var turn_winners = game_manager.turn_winners

	# If losing, more likely to bluff
	if turn_winners.size() > 0 and turn_winners[0] != get_bot_team(bot_name):
		bluff_chance *= 1.3

	# Random chance based on calculated probability
	return randf() < bluff_chance

# Function to decide whether to call Truco
func should_call_truco(bot_name: String) -> bool:
	var difficulty = bot_difficulty[bot_name]
	var hand = game_manager.player_hands[bot_name]

	# Calculate hand strength
	var hand_strength = calculate_hand_strength(hand)

	# Get base probability based on difficulty and hand strength
	var truco_chance = TRUCO_PROBABILITY[difficulty][hand_strength]

	# Adjust based on game state
	var current_score = game_manager.team_points[get_bot_team(bot_name)]
	var opponent_score = game_manager.team_points["them" if get_bot_team(bot_name) == "we" else "we"]

	# If we're behind, more aggressive
	if current_score < opponent_score:
		truco_chance *= 1.3

	# If we're ahead, more conservative
	if current_score > opponent_score:
		truco_chance *= 0.8

	# If we're close to winning, more aggressive
	if current_score >= game_manager.max_score - 3:
		truco_chance *= 1.5

	# Random chance based on calculated probability
	return randf() < truco_chance

# Function to set difficulty for a specific bot
func set_bot_difficulty(bot_name: String, difficulty: int) -> void:
	if bot_name in bot_difficulty:
		bot_difficulty[bot_name] = difficulty

# Function to get difficulty name as string
func get_difficulty_name(difficulty: int) -> String:
	match difficulty:
		BotDifficulty.EASY:
			return "Easy"
		BotDifficulty.NORMAL:
			return "Normal"
		BotDifficulty.HARD:
			return "Hard"
		BotDifficulty.EXPERT:
			return "Expert"
		_:
			return "Unknown"
