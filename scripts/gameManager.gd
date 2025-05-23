extends Node

const CARD_SCENE = preload("res://scenes/card.tscn")
const PLAYER_NAME_INPUT = preload("res://scenes/player_name_input.tscn")

@onready var end_game_ui := get_node("../../OverlayLayer/EndGameUI")
@onready var win_label := end_game_ui.get_node("Panel/WinLabel")
@onready var restart_button := end_game_ui.get_node("Panel/RestartButton")
@onready var truco_button := get_node("../../UILayer/TrucoButton")
@onready var score_label := get_node("../../UILayer/ScoreContainer/ScoreLabel")
@onready var player_name_label := get_node("../../UILayer/PlayerNameLabel")
@onready var bot_manager := $BotManager

var player_hands = {
	"player": [],
	"bot1": [],
	"bot2": [],
	"bot3": []
}
var deck: Array[Dictionary] = []
var used_cards: Array[Dictionary] = []
var manilha_value = ""
var vira_card_data = null
var vira_card_node = null
var last_player_card = null
var current_turn := 0

var player_order := ["player", "bot1", "bot2", "bot3"]
var pe_index := 0
var current_pe_index := 0

# Strongest → Weakest
var value_order := ["3", "2", "ace", "king", "jack", "queen", "7", "6", "5", "4"]
var suit_order := ["clubs", "hearts", "spades", "diamonds"]

var current_score_value := 1
var max_score := 12
var truco_called := false

var team_points = {
	"we": 0,
	"them": 0
}

var player_hand_cards: Array[Node2D] = []
var bot_hand_previews = {
	"bot1": [],
	"bot2": [],
	"bot3": []
}

var turn_winners: Array[String] = []
var player_name := "Player"

const CENTER := Vector2(512, 300)
const PLAYED_CARD_POSITIONS = {
	"bot1": CENTER + Vector2(-95, -46.5),
	"bot2": CENTER + Vector2(5, -191),
	"bot3": CENTER + Vector2(105, -46.5),
	"player": CENTER + Vector2(5, 97.5),
}
const VIRA_CARD_POS := CENTER + Vector2(0, -55)
const VIRA_SCALE := Vector2(0.2, 0.2)
const PLAYER_HAND_SPACING := 200
const PLAYER_CARD_SCALE := Vector2(0.4, 0.4)
const PLAYER_HAND_Y := 534
const BOT_CARD_SCALE := Vector2(0.3, 0.3)
const BOT_CARD_SPACE := 80

func _ready():
	get_tree().paused = false
	end_game_ui.visible = false

	# Load player name from config
	var config = ConfigFile.new()
	var err = config.load("user://player_settings.cfg")
	if err == OK:
		player_name = config.get_value("player", "name", "Player")

		# Load bot difficulty if available
		if config.has_section_key("game", "difficulty"):
			var difficulty = config.get_value("game", "difficulty", 1) # Default to Normal
			bot_manager.set_all_bot_difficulties(difficulty)

	if has_node("BotManager"):
		bot_manager.setup(self)

	# Show player name input if first time
	if player_name == "Player" and not config.has_section("player"):
		show_player_name_input()
	else:
		start_game()

func show_player_name_input():
	var name_input = PLAYER_NAME_INPUT.instantiate()
	name_input.name_confirmed.connect(_on_name_confirmed)
	add_child(name_input)

func _on_name_confirmed(input_name):
	player_name = input_name
	if player_name_label:
		player_name_label.text = player_name
	start_game()

func start_game():
	set_pe()
	reset_score_label()
	start_new_round()
	if player_name_label:
		player_name_label.text = player_name

func set_pe():
	randomize()
	pe_index = randi() % 4
	current_pe_index = pe_index
	print("🎲 Starting Pe:", player_order[pe_index])

func prepare_deck():
	var all_cards: Array[Dictionary] = []
	var suits = ["hearts", "spades", "diamonds", "clubs"]
	var values = value_order.duplicate()
	values.reverse()

	for suit in suits:
		for value in values:
			all_cards.append({"value": value, "suit": suit})

	for used in used_cards:
		if randf() < 0.1:
			if not all_cards.any(func(c): return c["value"] == used["value"] and c["suit"] == used["suit"]):
				all_cards.append(used)

	deck.clear()
	for card in all_cards:
		deck.append(card.duplicate(true))

	deck.shuffle()

func deal_cards():
	for key in player_hands.keys():
		player_hands[key].clear()

	for i in range(3):
		player_hands["player"].append(deck.pop_back())
		player_hands["bot1"].append(deck.pop_back())
		player_hands["bot2"].append(deck.pop_back())
		player_hands["bot3"].append(deck.pop_back())

func pick_vira():
	vira_card_data = deck.pop_back()

func identify_manilha():
	var index = value_order.find(vira_card_data["value"])
	var next_index = (index - 1 + value_order.size()) % value_order.size()
	manilha_value = value_order[next_index]
	print("🃏 Vira:", vira_card_data)
	print("🔥 Manilha:", manilha_value)

func show_vira_card():
	# Remove previous vira card if it exists
	if is_instance_valid(vira_card_node):
		vira_card_node.queue_free()

	var vira = CARD_SCENE.instantiate()
	vira.value = vira_card_data["value"]
	vira.suit = vira_card_data["suit"]
	vira.position = VIRA_CARD_POS
	vira.scale = VIRA_SCALE
	vira.face_up = true
	add_child(vira)
	vira_card_node = vira

	# Add visual emphasis
	var tween = create_tween()
	vira.modulate = Color(1, 1, 1, 0)
	tween.tween_property(vira, "modulate", Color(1, 1, 1, 1), 0.5)

func show_hands():
	for card in player_hand_cards:
		if is_instance_valid(card):
			card.queue_free()
	player_hand_cards.clear()

	var hand_size: int = player_hands["player"].size()
	var total_width: float = float(hand_size - 1) * PLAYER_HAND_SPACING
	var start_x: float = CENTER.x - total_width / 2.0

	for i in range(hand_size):
		var card_data = player_hands["player"][i]
		var card = CARD_SCENE.instantiate()
		card.value = card_data["value"]
		card.suit = card_data["suit"]
		card.position = Vector2(start_x + i * PLAYER_HAND_SPACING, PLAYER_HAND_Y)
		card.scale = PLAYER_CARD_SCALE
		card.face_up = true
		add_child(card)

		var front = card.get_node("Front")
		front.connect("gui_input", Callable(self, "_on_card_clicked").bind(card_data, card))

		player_hand_cards.append(card)

func is_card_in_player_hand(card: Node2D) -> bool:
	return player_hand_cards.has(card)

func _on_card_clicked(event: InputEvent, card_data, card_node):
	if event is InputEventMouseButton and event.pressed:
		card_node.queue_free()
		player_hand_cards.erase(card_node)
		player_hands["player"].erase(card_data)

		last_player_card = card_data
		show_played_card(card_data, PLAYED_CARD_POSITIONS["player"])

		await get_tree().create_timer(0.2).timeout
		play_all_turns()
		show_hands()

func show_bot_hand_preview():
	for key in bot_hand_previews.keys():
		for preview in bot_hand_previews[key]:
			if is_instance_valid(preview):
				preview.queue_free()
		bot_hand_previews[key] = []

	for bot in ["bot1", "bot2", "bot3"]:
		for i in range(player_hands[bot].size()):
			var back_card = CARD_SCENE.instantiate()
			back_card.face_up = false
			back_card.scale = BOT_CARD_SCALE

			match bot:
				"bot1": back_card.position = CENTER + Vector2(-410, -67 + i * BOT_CARD_SPACE); back_card.rotation_degrees = 90
				"bot2": back_card.position = CENTER + Vector2(-17 + i * BOT_CARD_SPACE, -350)
				"bot3": back_card.position = CENTER + Vector2(540, -17 + i * BOT_CARD_SPACE); back_card.rotation_degrees = -90

			add_child(back_card)
			bot_hand_previews[bot].append(back_card)

func play_all_turns():
	var order = []
	for i in range(4):
		var index = (pe_index + i) % 4
		order.append(player_order[index])

	var played_cards = {}

	for player in order:
		var card_data: Dictionary
		if player == "player":
			card_data = last_player_card
		else:
			# Use bot manager to select card based on difficulty
			card_data = bot_manager.select_card(player, player_hands[player])
			player_hands[player].erase(card_data)
			show_played_card(card_data, PLAYED_CARD_POSITIONS[player])
		played_cards[player] = card_data

	print("🧑 Player played:", played_cards["player"])
	print("🤖 Bot1 played:", played_cards["bot1"])
	print("🤖 Bot2 played:", played_cards["bot2"])
	print("🤖 Bot3 played:", played_cards["bot3"])

	show_bot_hand_preview()
	determine_turn_result(
		played_cards["player"],
		played_cards["bot1"],
		played_cards["bot2"],
		played_cards["bot3"]
	)

func show_played_card(card_data: Dictionary, position: Vector2):
	var card = CARD_SCENE.instantiate()
	card.value = card_data["value"]
	card.suit = card_data["suit"]
	card.position = position
	card.scale = VIRA_SCALE * 0.9
	card.face_up = true
	add_child(card)
	card.add_to_group("played_card")
	used_cards.append(card_data)

func determine_turn_result(player_card, bot1_card, bot2_card, bot3_card):
	current_turn += 1

	var played = [
		{"player": "player", "card": player_card},
		{"player": "bot1", "card": bot1_card},
		{"player": "bot2", "card": bot2_card},
		{"player": "bot3", "card": bot3_card}
	]

	for p in played:
		p["power"] = get_card_power(p["card"])

	# 🟢 Sort by descending power; if tied, keep original order (first wins)
	played.sort_custom(func(a, b):
		if a["power"] == b["power"]:
			return false # maintain original order (play order)
		return a["power"] > b["power"]
	)

	for p in played:
		print(p["player"], ":", p["card"], "→ power:", p["power"])

	var first = played[0]
	var second = played[1]

	var winner_team := ""

	if first["power"] == second["power"]:
		var first_team = "we" if first["player"] in ["player", "bot2"] else "them"
		var second_team = "we" if second["player"] in ["player", "bot2"] else "them"

		if first_team == second_team:
			print("🤝 Same team draw — earlier card wins")
			winner_team = first_team
			turn_winners.append(winner_team)
		else:
			print("⚖️ Turn Drawn")
			turn_winners.append("draw")

			# 🟨 Draw logic
			if current_turn == 2 and turn_winners[0] in ["we", "them"]:
				print("🏆 Round decided by 1st turn after 2nd was draw")
				end_round_with_forced_winner(turn_winners[0])
				return
			elif current_turn == 3 and turn_winners[0] in ["we", "them"]:
				print("🏆 Round decided by 1st turn after 3rd was draw")
				end_round_with_forced_winner(turn_winners[0])
				return
	else:
		var winner = first["player"]
		winner_team = "we" if winner in ["player", "bot2"] else "them"
		print("🏆 Turn Winner:", winner, "→", winner_team)
		turn_winners.append(winner_team)

		# ✅ First turn was a draw, this turn decides the round
		if current_turn == 2 and turn_winners[0] == "draw":
			print("🏁 1st draw + 2nd win → round ends early")
			end_round_with_forced_winner(winner_team)
			return

	update_turn_indicators()

	# 🔁 End round early if team has 2 wins
	var we_count = turn_winners.count("we")
	var them_count = turn_winners.count("them")

	if we_count == 2:
		print("🏁 'We' won 2 turns → round ends early")
		end_round_with_forced_winner("we")
	elif them_count == 2:
		print("🏁 'Them' won 2 turns → round ends early")
		end_round_with_forced_winner("them")
	elif current_turn >= 3:
		end_round()

func update_turn_indicators():
	var turn_nodes = [
		score_label.get_parent().get_node("TurnIndicators/Turn1"),
		score_label.get_parent().get_node("TurnIndicators/Turn2")
	]

	for i in range(2):
		var ball = turn_nodes[i]
		var stylebox := ball.get("theme_override_styles/panel") as StyleBoxFlat
		if not stylebox:
			continue

		if i < turn_winners.size():
			match turn_winners[i]:
				"we":
					stylebox.bg_color = Color(0, 1, 0) # Green
				"them":
					stylebox.bg_color = Color(1, 0, 0) # Red
				_:
					stylebox.bg_color = Color(1, 1, 0) # Yellow
		else:
			stylebox.bg_color = Color(0, 0, 0, 0) # Transparent

func get_card_power(card: Dictionary) -> int:
	if card["value"] == manilha_value:
		return 100 + suit_order.size() - suit_order.find(card["suit"])
	var index = value_order.find(card["value"])
	return value_order.size() - index if index != -1 else 0

func get_round_winner() -> String:
	var we_count = turn_winners.count("we")
	var them_count = turn_winners.count("them")

	if we_count == 2:
		return "we"
	if them_count == 2:
		return "them"

	if turn_winners.size() >= 2:
		if turn_winners[0] == "draw" and (turn_winners[1] == "we" or turn_winners[1] == "them"):
			return turn_winners[1]

		if (turn_winners[1] == "draw" or (turn_winners.size() >= 3 and turn_winners[2] == "draw")):
			if turn_winners[0] == "we" or turn_winners[0] == "them":
				return turn_winners[0]

	if we_count > them_count:
		return "we"
	elif them_count > we_count:
		return "them"

	return "draw"

func end_round():
	var winner_team = get_round_winner()

	if winner_team == "draw":
		print("🤝 Round tied, no points awarded.")
		start_new_round()
		return

	update_score_label(winner_team, current_score_value)
	print("🔢 Score → We:", team_points["we"], "| Them:", team_points["them"])

	if team_points["we"] >= max_score:
		show_end_game_ui("we")
	elif team_points["them"] >= max_score:
		show_end_game_ui("them")
	else:
		current_score_value = 1
		truco_called = false
		truco_button.disabled = false
		start_new_round()

func end_round_with_forced_winner(team: String):
	update_score_label(team, current_score_value)
	print("🔢 Score → We:", team_points["we"], "| Them:", team_points["them"])

	if team_points["we"] >= max_score:
		show_end_game_ui("we")
	elif team_points["them"] >= max_score:
		show_end_game_ui("them")
	else:
		current_score_value = 1
		truco_called = false
		truco_button.disabled = false
		start_new_round()

func start_new_round():
	# Remove all played cards except the vira
	for node in get_tree().get_nodes_in_group("played_card"):
		if is_instance_valid(node):
			node.queue_free()

	current_turn = 0
	turn_winners.clear()
	update_turn_indicators()
	prepare_deck()
	deal_cards()
	pick_vira()
	show_vira_card()
	identify_manilha()
	show_hands()
	show_bot_hand_preview()
	pe_index = (pe_index + 1) % 4
	current_pe_index = pe_index

	# Check if bots should call truco based on their difficulty
	check_bot_truco_calls()

func check_bot_truco_calls():
	if truco_called:
		return

	# Only allow truco calls at the beginning of a round
	if current_turn > 0:
		return

	# Check each bot in turn order
	for i in range(4):
		var player_index = (pe_index + i) % 4
		var player = player_order[player_index]

		# Skip player (human)
		if player == "player":
			continue

		# Check if this bot should call truco
		if bot_manager.should_call_truco(player):
			truco_called = true
			current_score_value = 3
			truco_button.disabled = true

			# Show truco call notification
			print("🃏 " + player + " CALLED TRUCO! Round is now worth 3 points")

			# Could add visual/audio feedback here

			break

func reset_score_label():
	team_points["we"] = 0
	team_points["them"] = 0
	score_label.text = "0 x 0"

func update_score_label(winner_team: String, points: int) -> void:
	if not team_points.has(winner_team):
		push_error("Unknown team: %s" % winner_team)
		return

	team_points[winner_team] += points
	score_label.text = "%d x %d" % [team_points["we"], team_points["them"]]

func _on_truco_button_pressed():
	if truco_called:
		return
	truco_called = true
	current_score_value = 3
	truco_button.disabled = true
	print("🃏 TRUCO CALLED! Round is now worth 3 points")

func show_end_game_ui(winner_team: String):
	end_game_ui.visible = true
	win_label.text = winner_team.capitalize() + " WIN!"
	get_tree().paused = true

	# Record game result for Expert bots to learn
	bot_manager.record_game_result(winner_team)

func _on_restart_button_pressed():
	reset_score_label()
	get_tree().paused = false
	get_tree().reload_current_scene()

# Set difficulty for all bots
func set_all_bot_difficulties(difficulty: int):
	bot_manager.set_all_bot_difficulties(difficulty)

# Set difficulty for a specific bot
func set_bot_difficulty(bot_name: String, difficulty: int):
	bot_manager.set_bot_difficulty(bot_name, difficulty)
