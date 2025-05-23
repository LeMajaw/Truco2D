extends Node
# Bot Manager - Handles bot selection and integration with game manager
# This script serves as a factory for creating bots of different difficulty levels

# Reference to game manager
var game_manager: Node

# Bot instances
var bots = {}

# Bot difficulty enum
enum BotDifficulty {
	EASY = 1,
	NORMAL = 2,
	HARD = 3,
	EXPERT = 4
}

# Default difficulty for each bot
var bot_difficulties = {
	"bot1": BotDifficulty.NORMAL,
	"bot2": BotDifficulty.NORMAL,
	"bot3": BotDifficulty.NORMAL
}

# Initialization
func setup(manager: Node):
	game_manager = manager
	_initialize_bots()

# Initialize bots with default difficulties
func _initialize_bots():
	for bot_name in bot_difficulties.keys():
		_create_bot(bot_name, bot_difficulties[bot_name])

# Create a bot of specified difficulty
func _create_bot(bot_name: String, difficulty: int):
	var bot

	match difficulty:
		BotDifficulty.EASY:
			bot = BotEasy.new()
		BotDifficulty.NORMAL:
			bot = BotNormal.new()
		BotDifficulty.HARD:
			bot = BotHard.new()
		BotDifficulty.EXPERT:
			bot = BotExpert.new()
		_:
			bot = BotNormal.new()

	bot.setup(game_manager) # ✅ Setup game_manager correctly
	bots[bot_name] = bot
	print("🤖 Created " + bot.get_bot_name() + " for " + bot_name)

# Select a card for a bot to play
func select_card(bot_name: String, hand: Array) -> Dictionary:
	if not bots.has(bot_name):
		push_error("Bot " + bot_name + " not found!")
		return {}

	return bots[bot_name].select_card(bot_name, hand)

# Check if a bot should call truco
func should_call_truco(bot_name: String) -> bool:
	if not bots.has(bot_name):
		return false

	return bots[bot_name].should_call_truco(bot_name)

# Check if a bot should accept truco
func should_accept_truco(bot_name: String) -> bool:
	if not bots.has(bot_name):
		return false

	return bots[bot_name].should_accept_truco(bot_name)

# Set difficulty for a specific bot
func set_bot_difficulty(bot_name: String, difficulty: int):
	if not bot_difficulties.has(bot_name):
		push_error("Bot " + bot_name + " not found!")
		return

	bot_difficulties[bot_name] = difficulty
	_create_bot(bot_name, difficulty)

	print("🤖 Set " + bot_name + " difficulty to " + str(difficulty))

# Set difficulty for all bots
func set_all_bot_difficulties(difficulty: int):
	for bot_name in bot_difficulties.keys():
		set_bot_difficulty(bot_name, difficulty)

# Get difficulty for a specific bot
func get_bot_difficulty(bot_name: String) -> int:
	if not bot_difficulties.has(bot_name):
		return BotDifficulty.NORMAL

	return bot_difficulties[bot_name]

# Record game result for learning (Expert bots only)
func record_game_result(winner_team: String):
	var team_bots = []
	var opponent_bots = []

	# Determine which bots were on which team
	for bot_name in bots.keys():
		if (bot_name == "bot2" and winner_team == "we") or (bot_name != "bot2" and winner_team == "them"):
			team_bots.append(bot_name)
		else:
			opponent_bots.append(bot_name)

	# Record results for Expert bots
	for bot_name in bots.keys():
		if bot_difficulties[bot_name] == BotDifficulty.EXPERT:
			var bot = bots[bot_name]
			var won = team_bots.has(bot_name)

			# For simplicity, we're not tracking if this specific bot called truco
			# In a more complex implementation, you'd track this per bot
			var truco_called_by_bot = false
			var truco_successful = false

			if "record_game_result" in bot:
				bot.record_game_result(won, truco_called_by_bot, truco_successful)
