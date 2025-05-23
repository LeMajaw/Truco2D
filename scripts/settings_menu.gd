extends CanvasLayer

signal settings_saved

# Default settings
var volume = 0.8
var fullscreen = false
var ui_scale = 1.0
var platform_detected = ""

func _ready():
	# Detect platform for UI adjustments
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		platform_detected = "Mobile"
	else:
		platform_detected = "Desktop"

	# Center the panel and adjust for platform
	_adjust_ui_for_platform()

	# Load current settings
	load_settings()

	# Set initial UI values
	$Panel/VBoxContainer/VolumeSlider.value = volume
	$Panel/VBoxContainer/FullscreenCheck.button_pressed = fullscreen

	# Add platform info
	var platform_label = $Panel/VBoxContainer.get_node("PlatformLabel") if $Panel/VBoxContainer.has_node("PlatformLabel") else null
	if platform_label:
		platform_label.text = "Platform: " + platform_detected


func _adjust_ui_for_platform():
	# Get viewport size
	var viewport_size = get_viewport().size

	# Adjust panel size based on platform and screen size
	var panel_size = $Panel.size
	if platform_detected == "Mobile":
		# Make panel larger on mobile for touch
		panel_size *= 1.2
		$Panel.size = panel_size

		# Increase font sizes
		for child in $Panel/VBoxContainer.get_children():
			if child is Label:
				var font_size = child.get("theme_override_font_sizes/font_size")
				if font_size:
					child.set("theme_override_font_sizes/font_size", font_size * 1.3)
			elif child is Button:
				var font_size = child.get("theme_override_font_sizes/font_size")
				if font_size:
					child.set("theme_override_font_sizes/font_size", font_size * 1.3)

	# Center the panel
	$Panel.position = Vector2(viewport_size) / 2 - $Panel.size / 2

	# Adjust for safe area on mobile
	if platform_detected == "Mobile":
		var safe_area = DisplayServer.get_display_safe_area()
		if safe_area != Rect2(0, 0, viewport_size.x, viewport_size.y):
			# Adjust for notch/cutout
			var safe_margin_top = safe_area.position.y
			var safe_margin_left = safe_area.position.x

			if safe_margin_top > 0:
				$Panel.position.y = max($Panel.position.y, safe_margin_top + 10)
			if safe_margin_left > 0:
				$Panel.position.x = max($Panel.position.x, safe_margin_left + 10)

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://player_settings.cfg")
	if err == OK:
		volume = config.get_value("settings", "volume", 0.8)
		fullscreen = config.get_value("settings", "fullscreen", false)
		ui_scale = config.get_value("settings", "ui_scale", 1.0)

func save_settings():
	var config = ConfigFile.new()
	var _err = config.load("user://player_settings.cfg")

	# Create new config if doesn't exist
	config.set_value("settings", "volume", volume)
	config.set_value("settings", "fullscreen", fullscreen)
	config.set_value("settings", "ui_scale", ui_scale)
	config.save("user://player_settings.cfg")

	# Apply settings
	apply_settings()

	# Emit signal
	settings_saved.emit()

func apply_settings():
	# Apply volume (would connect to audio system)
	if AudioServer.bus_count > 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))

	# Apply fullscreen - with proper transition
	if fullscreen:
		# Save current window size before going fullscreen
		var current_size = DisplayServer.window_get_size()
		var config = ConfigFile.new()
		if config.load("user://player_settings.cfg") == OK:
			config.set_value("settings", "window_width", current_size.x)
			config.set_value("settings", "window_height", current_size.y)
			config.save("user://player_settings.cfg")

		# Transition to fullscreen with animation
		var tween = create_tween()
		tween.tween_callback(func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN))
	else:
		# Return to windowed mode
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

		# Restore previous window size if available
		var config = ConfigFile.new()
		if config.load("user://player_settings.cfg") == OK:
			var width = config.get_value("settings", "window_width", 1024)
			var height = config.get_value("settings", "window_height", 600)
			DisplayServer.window_set_size(Vector2i(width, height))

	# Notify responsive UI to update
	var responsive_ui = get_tree().get_first_node_in_group("responsive_ui")
	if responsive_ui:
		responsive_ui._on_window_size_changed()

func _on_volume_slider_value_changed(value):
	volume = value

	# Preview volume change immediately
	if AudioServer.bus_count > 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))

func _on_fullscreen_check_toggled(button_pressed):
	fullscreen = button_pressed

func _on_save_button_pressed():
	save_settings()

	# Show notification
	var notif = load("res://scenes/notification.tscn").instantiate()
	notif.show_message("Settings saved!", Callable(self, "_on_close_button_pressed"))

	get_tree().get_root().add_child(notif)

func _on_close_button_pressed():
	queue_free()

# Handle window resize
func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_adjust_ui_for_platform()
