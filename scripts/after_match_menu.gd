extends CanvasLayer

signal play_again(difficulty)
signal main_menu

# Bot difficulty enum (must match the one in bot_ai.gd)
enum BotDifficulty {EASY, NORMAL, HARD, EXPERT}

var current_difficulty = BotDifficulty.NORMAL
var selected_button = null

func _ready():
	# Set initial difficulty button as selected
	_on_normal_button_pressed()
	
	# Load saved difficulty if available
	var config = ConfigFile.new()
	var err = config.load("user://player_settings.cfg")
	if err == OK and config.has_section_key("game", "difficulty"):
		current_difficulty = config.get_value("game", "difficulty", BotDifficulty.NORMAL)
		update_selected_button()

func set_result(winner_team: String, we_score: int, them_score: int):
	$Panel/VBoxContainer/ResultLabel.text = winner_team.capitalize() + " WIN!"
	$Panel/VBoxContainer/ScoreLabel.text = "Final Score: %d x %d" % [we_score, them_score]

func update_selected_button():
	# Reset all buttons
	for button in $Panel/VBoxContainer/DifficultyOptions.get_children():
		button.modulate = Color(1, 1, 1, 1)
		button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	# Highlight selected button
	match current_difficulty:
		BotDifficulty.EASY:
			selected_button = $Panel/VBoxContainer/DifficultyOptions/EasyButton
		BotDifficulty.NORMAL:
			selected_button = $Panel/VBoxContainer/DifficultyOptions/NormalButton
		BotDifficulty.HARD:
			selected_button = $Panel/VBoxContainer/DifficultyOptions/HardButton
		BotDifficulty.EXPERT:
			selected_button = $Panel/VBoxContainer/DifficultyOptions/ExpertButton
	
	if selected_button:
		selected_button.modulate = Color(1, 0.8, 0, 1)
		selected_button.add_theme_color_override("font_color", Color(0, 0, 0, 1))

func save_difficulty():
	var config = ConfigFile.new()
	var err = config.load("user://player_settings.cfg")
	
	# Create new config if doesn't exist
	config.set_value("game", "difficulty", current_difficulty)
	config.save("user://player_settings.cfg")

func _on_easy_button_pressed():
	current_difficulty = BotDifficulty.EASY
	update_selected_button()

func _on_normal_button_pressed():
	current_difficulty = BotDifficulty.NORMAL
	update_selected_button()

func _on_hard_button_pressed():
	current_difficulty = BotDifficulty.HARD
	update_selected_button()

func _on_expert_button_pressed():
	current_difficulty = BotDifficulty.EXPERT
	update_selected_button()

func _on_play_again_button_pressed():
	save_difficulty()
	play_again.emit(current_difficulty)
	queue_free()

func _on_main_menu_button_pressed():
	save_difficulty()
	main_menu.emit()
	queue_free()
