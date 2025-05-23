extends CanvasLayer

signal settings_saved

# Default settings
var volume = 0.8
var fullscreen = false

func _ready():
	# Center the panel
	$Panel.position = Vector2(get_viewport().size) / 2 - $Panel.size / 2

	# Load current settings
	load_settings()

	# Set initial UI values
	$Panel/VBoxContainer/VolumeSlider.value = volume
	$Panel/VBoxContainer/FullscreenCheck.button_pressed = fullscreen

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://player_settings.cfg")
	if err == OK:
		volume = config.get_value("settings", "volume", 0.8)
		fullscreen = config.get_value("settings", "fullscreen", false)

func save_settings():
	var config = ConfigFile.new()
	var err = config.load("user://player_settings.cfg")

	# Create new config if doesn't exist
	config.set_value("settings", "volume", volume)
	config.set_value("settings", "fullscreen", fullscreen)
	config.save("user://player_settings.cfg")

	# Apply settings
	apply_settings()

	# Emit signal
	settings_saved.emit()

func apply_settings():
	# Apply volume (would connect to audio system)
	# AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))
	# Apply fullscreen
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_volume_slider_value_changed(value):
	volume = value

func _on_fullscreen_check_toggled(button_pressed):
	fullscreen = button_pressed

func _on_save_button_pressed():
	save_settings()

	# Show notification
	var notif = load("res://scenes/notification.tscn").instantiate()
	notif.show_message("Settings saved!")
	get_tree().get_root().add_child(notif)

func _on_close_button_pressed():
	queue_free()
