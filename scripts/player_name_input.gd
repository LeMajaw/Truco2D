extends CanvasLayer

signal name_confirmed(player_name)

func _ready():
	# Center the panel
	$Panel.position = get_viewport().size / 2 - $Panel.size / 2
	
	# Focus the name input field
	$Panel/VBoxContainer/NameInput.grab_focus()

func _on_confirm_button_pressed():
	submit_name()

func _on_name_input_submitted(_text):
	submit_name()

func submit_name():
	var player_name = $Panel/VBoxContainer/NameInput.text.strip_edges()
	
	# Use default name if empty
	if player_name.is_empty():
		player_name = "Player"
	
	# Save to config file
	var config = ConfigFile.new()
	var err = config.load("user://player_settings.cfg")
	
	# Create new config if doesn't exist
	config.set_value("player", "name", player_name)
	config.save("user://player_settings.cfg")
	
	# Emit signal to continue game
	name_confirmed.emit(player_name)
	
	# Remove this UI
	queue_free()
