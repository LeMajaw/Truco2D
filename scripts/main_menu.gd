extends CanvasLayer

signal start_game(difficulty)
signal start_multiplayer

# Game version
const VERSION = "1.0.0"

func _ready():
	# Set version label
	$Version.text = "v" + VERSION

	# Add animations and visual effects
	_setup_button_effects()

func _setup_button_effects():
	# Add hover effects to all buttons
	for button in $MenuPanel/VBoxContainer.get_children():
		if button is Button:
			button.mouse_entered.connect(_on_button_hover.bind(button))
			button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_button_hover(button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)

func _on_button_unhover(button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_play_button_pressed():
	$MenuPanel.visible = false

	var player_setup = load("res://scenes/player_setup.tscn").instantiate()
	player_setup.setup_confirmed.connect(_on_player_setup_confirmed)
	player_setup.connect("tree_exited", Callable(self, "_on_child_screen_closed"))
	add_child(player_setup)

func _on_child_screen_closed():
	$MenuPanel.visible = true

func _on_player_setup_confirmed(player_name, difficulty):
	# Save player name and difficulty
	var config = ConfigFile.new()
	var err = config.load("user://player_settings.cfg")

	# Create new config if doesn't exist
	config.set_value("player", "name", player_name)
	config.set_value("game", "difficulty", difficulty)
	config.save("user://player_settings.cfg")

	# Start the game
	start_game.emit(difficulty)
	queue_free()

func _on_multiplayer_button_pressed():
	$MenuPanel.visible = false

	var multiplayer_menu = load("res://scenes/multiplayer_menu.tscn").instantiate()
	multiplayer_menu.connect("tree_exited", Callable(self, "_on_child_screen_closed"))
	add_child(multiplayer_menu)

func _on_settings_button_pressed():
	$MenuPanel.visible = false

	var settings = load("res://scenes/settings_menu.tscn").instantiate()
	settings.connect("tree_exited", Callable(self, "_on_child_screen_closed"))
	add_child(settings)


func _on_exit_button_pressed():
	# Quit the game
	get_tree().quit()
