extends Node

# Truco suits and values
var suits = ["h", "c", "s", "d"]  # Hearts, Clubs, Spades, Diamonds
var values = ["A", "2", "3", "4", "5", "6", "7", "Q", "J", "K"]
var manilha_order = ["4", "5", "6", "7", "Q", "J", "K", "A", "2", "3"]

# Game state
var player_score = 0
var ai_score = 0
var worth = 1
var turn = 0  # 0 = player, 1 = AI
var current_data = {}  # Game state for JSON

func _ready():
	var full_deck = create_truco_deck()
	full_deck.shuffle()

	var player_hand = full_deck.slice(0, 3)
	var ai_hand = full_deck.slice(3, 6)
	var vira = full_deck[6]

	current_data = {
		"player_score": player_score,
		"ai_score": ai_score,
		"worth": worth,
		"turn": turn,
		"ai_hand": ai_hand,
		"vira": vira,
		"truco_state": "none",
		"manilhas": get_manilhas(vira),
		"cards_played": {
			"ai_cards_played": [],
			"player_cards_played": []
		},
		"prompt": generate_prompt(ai_hand, turn)
	}

	save_to_json(current_data)
	print("Truco round started and exported!")
	get_tree().quit()

# Create the Truco deck
func create_truco_deck():
	var deck = []
	for suit in suits:
		for value in values:
			deck.append(suit + value)
	return deck

# Determine manilhas based on the vira card
func get_manilhas(vira_card: String) -> Array:
	var value = vira_card.substr(1)  # remove suit
	var index = manilha_order.find(value)
	if index == -1:
		return []
	var next_value = manilha_order[(index + 1) % manilha_order.size()]
	return ["c" + next_value, "s" + next_value, "h" + next_value, "d" + next_value]

# Play a card and update state
func play_card(player: String, card: String):
	if player == "player":
		current_data["cards_played"]["player_cards_played"].append(card)
	elif player == "ai":
		current_data["cards_played"]["ai_cards_played"].append(card)
	update_prompt()
	save_to_json(current_data)

# Call Truco / Seis / Nove / Doze
func request_truco_raise():
	match current_data["truco_state"]:
		"none":
			current_data["truco_state"] = "truco"
			current_data["worth"] = 3
		"truco":
			current_data["truco_state"] = "seis"
			current_data["worth"] = 6
		"seis":
			current_data["truco_state"] = "nove"
			current_data["worth"] = 9
		"nove":
			current_data["truco_state"] = "doze"
			current_data["worth"] = 12
	update_prompt()
	save_to_json(current_data)

# Generate prompt for AI decision
func generate_prompt(ai_hand: Array, current_turn: int) -> String:
	if current_turn != 1:
		return "Wait for your turn."
	var hand_count = ai_hand.size() - current_data["cards_played"]["ai_cards_played"].size()
	return "It is your turn. You are the AI. Choose one of your " + str(hand_count) + " remaining cards to play. Respond only with its code, like 'sA'."

# Update the prompt field
func update_prompt():
	current_data["prompt"] = generate_prompt(current_data["ai_hand"], current_data["turn"])

# Save current game state to JSON
func save_to_json(data: Dictionary):
	var file = FileAccess.open("user://truco_hand.json", FileAccess.WRITE)
	var json_text = JSON.stringify(data, "\t")
	file.store_string(json_text)
	file.close()
