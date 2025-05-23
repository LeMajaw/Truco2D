extends Node
class_name BotHard

# Hard Bot - Uses advanced strategy considering manilha, opponent risk, and hand strength
# This bot has deeper game understanding and adapts to the current game state

# Reference to game manager for accessing game state
var game_manager: Node

# Memory of played cards
var played_cards_memory = []

# Initialization
func setup(manager: Node):
	game_manager = manager

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

	# Update memory of played cards
	_update_memory(played_cards)

	# Sort cards by power (highest to lowest)
	var sorted_hand = hand.duplicate()
	sorted_hand.sort_custom(func(a, b):
		var power_a = _get_card_power(a, manilha_value, value_order, suit_order)
		var power_b = _get_card_power(b, manilha_value, value_order, suit_order)
		return power_a > power_b
	)

	var selected_card: Dictionary

	# Advanced strategy based on game state
	if current_turn == 0:
		# First turn strategy
		if _has_strong_hand(hand, manilha_value, value_order, suit_order):
			# With strong hand, play medium card to bait opponents
			selected_card = _get_medium_strength_card(sorted_hand)
		else:
			# With weak hand, play strongest card to secure at least one win
			selected_card = sorted_hand[0]
	else:
		# Later turns strategy
		var team = "we" if bot_name in ["player", "bot2"] else "them"
		var opponent_team = "them" if team == "we" else "we"

		# Check if we already won a turn
		var team_won = turn_winners.has(team)
		var opponent_won = turn_winners.has(opponent_team)

		if team_won and not opponent_won:
			# We're ahead, play strongest card to secure the round
			selected_card = sorted_hand[0]
		elif opponent_won and not team_won:
			# We're behind, must play strongest card to stay in the game
			selected_card = sorted_hand[0]
		else:
			# Tied or both won once, use strategic card selection
			selected_card = _select_strategic_card(sorted_hand, current_turn)

	print("🤖 Hard Bot " + bot_name + " selected card: " + selected_card.value + " of " + selected_card.suit + " using advanced strategy")

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

# Check if hand has strong cards
func _has_strong_hand(hand: Array, manilha_value: String, value_order: Array, suit_order: Array) -> bool:
	var total_power = 0
	var has_manilha = false

	for card in hand:
		var power = _get_card_power(card, manilha_value, value_order, suit_order)
		total_power += power
		if card.value == manilha_value:
			has_manilha = true

	var avg_power = float(total_power) / float(hand.size())
	return avg_power > 7 or has_manilha

# Get medium strength card from sorted hand
func _get_medium_strength_card(sorted_hand: Array) -> Dictionary:
	if sorted_hand.size() >= 3:
		return sorted_hand[1] # Middle card
	else:
		return sorted_hand[sorted_hand.size() - 1] # Weakest card if only 1-2 cards

# Select card strategically based on turn
func _select_strategic_card(sorted_hand: Array, current_turn: int) -> Dictionary:
	if current_turn == 1:
		# Second turn, play strongest card to secure win
		return sorted_hand[0]
	else:
		# Third turn, evaluate if we need to win
		# For Hard bot, always try to win the last turn
		return sorted_hand[0]

# Decide whether to call truco
func should_call_truco(bot_name: String) -> bool:
	# Get bot's hand
	var hand = game_manager.player_hands[bot_name]
	if hand.size() == 0:
		return false

	# Calculate hand strength
	var manilha_value = game_manager.manilha_value
	var value_order = game_manager.value_order
	var suit_order = game_manager.suit_order

	var hand_strength = _calculate_hand_strength(hand, manilha_value, value_order, suit_order)

	# Consider game state
	var current_turn = game_manager.current_turn
	var turn_winners = game_manager.turn_winners
	var team = "we" if bot_name in ["player", "bot2"] else "them"

	# Call truco if hand is strong or if we're ahead
	var call_truco = false

	if hand_strength > 0.7: # Very strong hand
		call_truco = true
	elif hand_strength > 0.5 and current_turn == 0: # Strong hand at start
		call_truco = true
	elif turn_winners.has(team) and hand_strength > 0.4: # We won a turn and have decent cards
		call_truco = true

	if call_truco:
		print("🤖 Hard Bot " + bot_name + " decided to call truco with hand strength: " + str(hand_strength))

	return call_truco

# Calculate overall hand strength (0.0 to 1.0)
func _calculate_hand_strength(hand: Array, manilha_value: String, value_order: Array, suit_order: Array) -> float:
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
	var manilha_bonus = 0.1 if has_manilha else 0.0

	# Calculate strength ratio and add manilha bonus
	var strength = float(total_power) / float(max_possible_power) + manilha_bonus

	# Cap at 1.0
	return min(strength, 1.0)

# Decide whether to accept truco
func should_accept_truco(bot_name: String) -> bool:
	# Get bot's hand
	var hand = game_manager.player_hands[bot_name]
	if hand.size() == 0:
		return false

	# Calculate hand strength
	var manilha_value = game_manager.manilha_value
	var value_order = game_manager.value_order
	var suit_order = game_manager.suit_order

	var hand_strength = _calculate_hand_strength(hand, manilha_value, value_order, suit_order)

	# Consider game state
	var current_turn = game_manager.current_turn
	var turn_winners = game_manager.turn_winners
	var team = "we" if bot_name in ["player", "bot2"] else "them"

	# Accept truco based on hand strength and game state
	var accept_truco = false

	if hand_strength > 0.5: # Strong hand
		accept_truco = true
	elif turn_winners.has(team) and hand_strength > 0.3: # We won a turn and have decent cards
		accept_truco = true
	elif current_turn == 0 and hand_strength > 0.4: # Start of round with decent hand
		accept_truco = true

	if accept_truco:
		print("🤖 Hard Bot " + bot_name + " decided to accept truco with hand strength: " + str(hand_strength))
	else:
		print("🤖 Hard Bot " + bot_name + " decided to decline truco with hand strength: " + str(hand_strength))

	return accept_truco

# Get bot name for display
func get_bot_name() -> String:
	return "Hard Bot"

# Get bot difficulty level (1-4)
func get_difficulty_level() -> int:
	return 3
