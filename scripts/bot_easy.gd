extends Node
class_name BotEasy

# Easy Bot - Uses random card selection with minimal strategy
# This is the simplest AI that just plays randomly

# Reference to game manager for accessing game state
var game_manager: Node

# Initialization
func setup(manager: Node):
	game_manager = manager

# Select a card from the bot's hand
func select_card(bot_name: String, hand: Array) -> Dictionary:
	# Simply select a random card from the hand
	if hand.size() == 0:
		push_error("Bot " + bot_name + " has no cards to play!")
		return {}

	# Randomize selection
	randomize()
	var card_index = randi() % hand.size()

	print("🤖 Easy Bot " + bot_name + " randomly selected card: " + hand[card_index].value + " of " + hand[card_index].suit)

	return hand[card_index]

# Decide whether to call truco
func should_call_truco(bot_name: String) -> bool:
	# Easy bot rarely calls truco - only 10% chance
	randomize()
	var call_truco = randf() < 0.1

	if call_truco:
		print("🤖 Easy Bot " + bot_name + " randomly decided to call truco!")

	return call_truco

# Decide whether to accept truco
func should_accept_truco(bot_name: String) -> bool:
	# Easy bot accepts truco 70% of the time without any strategy
	randomize()
	var accept_truco = randf() < 0.7

	if accept_truco:
		print("🤖 Easy Bot " + bot_name + " randomly decided to accept truco!")
	else:
		print("🤖 Easy Bot " + bot_name + " randomly decided to decline truco!")

	return accept_truco

# Get bot name for display
func get_bot_name() -> String:
	return "Easy Bot"

# Get bot difficulty level (1-4)
func get_difficulty_level() -> int:
	return 1
