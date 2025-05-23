extends Node
class_name BotNormal

# Normal Bot - Uses basic card ranking comparison and simple strategy
# This bot understands card values and makes decisions based on card strength

# Reference to game manager for accessing game state
var game_manager: Node

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

	# Sort cards by power (highest to lowest)
	var sorted_hand = hand.duplicate()
	sorted_hand.sort_custom(func(a, b):
		var power_a = _get_card_power(a, manilha_value, value_order, suit_order)
		var power_b = _get_card_power(b, manilha_value, value_order, suit_order)
		return power_a > power_b
	)

	var selected_card: Dictionary

	# Strategy based on turn
	if current_turn == 0:
		# First turn: Play middle-strength card to preserve strongest for later
		if hand.size() >= 3:
			selected_card = sorted_hand[1] # Middle card
		else:
			selected_card = sorted_hand[0] # Strongest card if only 1-2 cards
	else:
		# Later turns: Play strongest card to secure the win
		selected_card = sorted_hand[0]

	print("🤖 Normal Bot " + bot_name + " selected card: " + selected_card.value + " of " + selected_card.suit)

	return selected_card

# Calculate card power (similar to game manager's logic)
func _get_card_power(card: Dictionary, manilha_value: String, value_order: Array, suit_order: Array) -> int:
	if card.value == manilha_value:
		return 100 + suit_order.size() - suit_order.find(card.suit)
	var index = value_order.find(card.value)
	return value_order.size() - index if index != -1 else 0

# Decide whether to call truco
func should_call_truco(bot_name: String) -> bool:
	# Get bot's hand
	var hand = game_manager.player_hands[bot_name]
	if hand.size() == 0:
		return false

	# Calculate average card power in hand
	var total_power = 0
	var manilha_value = game_manager.manilha_value
	var value_order = game_manager.value_order
	var suit_order = game_manager.suit_order

	for card in hand:
		total_power += _get_card_power(card, manilha_value, value_order, suit_order)

	var avg_power = total_power / hand.size()

	# Call truco if average card power is high enough (has good cards)
	var threshold = 7 # Threshold for "good enough" hand
	var call_truco = avg_power > threshold

	if call_truco:
		print("🤖 Normal Bot " + bot_name + " decided to call truco based on card strength!")

	return call_truco

# Decide whether to accept truco
func should_accept_truco(bot_name: String) -> bool:
	# Get bot's hand
	var hand = game_manager.player_hands[bot_name]
	if hand.size() == 0:
		return false

	# Calculate highest card power in hand
	var highest_power = 0
	var manilha_value = game_manager.manilha_value
	var value_order = game_manager.value_order
	var suit_order = game_manager.suit_order

	for card in hand:
		var power = _get_card_power(card, manilha_value, value_order, suit_order)
		highest_power = max(highest_power, power)

	# Accept truco if highest card is strong enough
	var threshold = 6 # Threshold for accepting truco
	var accept_truco = highest_power >= threshold

	if accept_truco:
		print("🤖 Normal Bot " + bot_name + " decided to accept truco with highest card power: " + str(highest_power))
	else:
		print("🤖 Normal Bot " + bot_name + " decided to decline truco with highest card power: " + str(highest_power))

	return accept_truco

# Get bot name for display
func get_bot_name() -> String:
	return "Normal Bot"

# Get bot difficulty level (1-4)
func get_difficulty_level() -> int:
	return 2
