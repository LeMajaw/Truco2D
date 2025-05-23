extends CanvasLayer

signal setup_confirmed(player_name, difficulty)

# Bot difficulty enum (must match the one in bot_ai.gd)
enum BotDifficulty {EASY, NORMAL, HARD, EXPERT}

var current_difficulty = BotDifficulty.NORMAL
var selected_button: Button = null

const DebugUtils = preload("res://utils/debug_utils.gd")

@onready var name_input: LineEdit = $Panel/VBoxContainer/NameInput
@onready var difficulty_options: HBoxContainer = $Panel/VBoxContainer/DifficultyOptions
@onready var difficulty_group := ButtonGroup.new()

func _ready():
	# DebugUtils.save_node_properties_as_json($Panel/VBoxContainer/BackButton) # Get Properties
	# Setup toggle behavior for buttons
	for button in difficulty_options.get_children():
		if button is Button:
			button.toggle_mode = true
			button.button_group = difficulty_group

	# Load saved config
	var config = ConfigFile.new()
	var err = config.load("user://player_settings.cfg")

	if err == OK:
		if config.has_section_key("player", "name"):
			name_input.text = config.get_value("player", "name", "Player")
		if config.has_section_key("game", "difficulty"):
			current_difficulty = config.get_value("game", "difficulty", BotDifficulty.NORMAL)
	else:
		current_difficulty = BotDifficulty.NORMAL

	await get_tree().process_frame
	update_selected_button()

	selected_button.grab_focus()

func update_selected_button():
	# Reset all buttons
	for button in difficulty_options.get_children():
		if button is Button:
			button.set_pressed(false)
			button.modulate = Color(1, 1, 1, 1)
			button.remove_theme_color_override("font_color")
			button.remove_theme_stylebox_override("normal")

	# Map enum to button names
	var difficulty_map = {
		BotDifficulty.EASY: "EasyButton",
		BotDifficulty.NORMAL: "NormalButton",
		BotDifficulty.HARD: "HardButton",
		BotDifficulty.EXPERT: "ExpertButton"
	}

	var button_name: String = difficulty_map.get(current_difficulty, "")
	selected_button = difficulty_options.get_node_or_null(button_name)

	if selected_button:
		selected_button.set_pressed(true)
		selected_button.modulate = Color(1, 0.8, 0, 1)
		selected_button.add_theme_color_override("font_color", Color(0, 0, 0, 1))

		# 🔥 Manual override with a replica of the pressed style
		var pressed_style := selected_button.get_theme_stylebox("pressed", "Button")
		if pressed_style:
			selected_button.add_theme_stylebox_override("normal", pressed_style.duplicate())

func _on_name_input_submitted(_text):
	_on_start_button_pressed()

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

func _on_start_button_pressed():
	var player_name := name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	setup_confirmed.emit(player_name, current_difficulty)
	queue_free()

func _on_back_button_pressed():
	queue_free()