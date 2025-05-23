extends Node

# Fullscreen Manager for Truco Paulista
# Handles fullscreen toggling, transitions, and responsive layout updates

signal fullscreen_changed(is_fullscreen)

# Fullscreen state
var is_fullscreen = false
var previous_window_size = Vector2i(1024, 600)
var previous_window_position = Vector2i(100, 100)
var transition_in_progress = false

# Configuration
var config_path = "user://player_settings.cfg"
var save_window_info = true

func _ready():
	# Load initial state
	load_fullscreen_state()
	
	# Apply initial state if needed
	if is_fullscreen:
		set_fullscreen(true, false)
	
	# Connect to input for shortcut handling
	set_process_input(true)

func _input(event):
	# Handle Alt+Enter or F11 for fullscreen toggle
	if event is InputEventKey and event.pressed:
		if (event.keycode == KEY_ENTER and event.alt_pressed) or event.keycode == KEY_F11:
			toggle_fullscreen()

func load_fullscreen_state():
	var config = ConfigFile.new()
	var err = config.load(config_path)
	
	if err == OK:
		is_fullscreen = config.get_value("settings", "fullscreen", false)
		
		# Load previous window size and position
		previous_window_size.x = config.get_value("settings", "window_width", 1024)
		previous_window_size.y = config.get_value("settings", "window_height", 600)
		previous_window_position.x = config.get_value("settings", "window_x", 100)
		previous_window_position.y = config.get_value("settings", "window_y", 100)
	else:
		# Default to windowed mode
		is_fullscreen = false

func save_fullscreen_state():
	var config = ConfigFile.new()
	config.load(config_path) # Load existing config if any
	
	# Save fullscreen state
	config.set_value("settings", "fullscreen", is_fullscreen)
	
	# Save window info if in windowed mode
	if !is_fullscreen and save_window_info:
		var current_size = DisplayServer.window_get_size()
		var current_position = DisplayServer.window_get_position()
		
		config.set_value("settings", "window_width", current_size.x)
		config.set_value("settings", "window_height", current_size.y)
		config.set_value("settings", "window_x", current_position.x)
		config.set_value("settings", "window_y", current_position.y)
	
	config.save(config_path)

func toggle_fullscreen():
	set_fullscreen(!is_fullscreen)

func set_fullscreen(fullscreen_enabled, save_state = true):
	# Prevent multiple transitions at once
	if transition_in_progress:
		return
	
	transition_in_progress = true
	
	if fullscreen_enabled:
		# Save current window info before going fullscreen
		if save_window_info:
			previous_window_size = DisplayServer.window_get_size()
			previous_window_position = DisplayServer.window_get_position()
		
		# Transition to fullscreen with animation
		var tween = create_tween()
		tween.tween_property(Engine.get_main_loop().root, "content_scale_factor", 1.05, 0.1)
		tween.tween_callback(func():
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			Engine.get_main_loop().root.content_scale_factor = 1.0
		)
		tween.tween_callback(func():
			# Update responsive UI
			notify_responsive_ui()
			transition_in_progress = false
		)
	else:
		# Transition to windowed mode
		var tween = create_tween()
		tween.tween_property(Engine.get_main_loop().root, "content_scale_factor", 0.95, 0.1)
		tween.tween_callback(func():
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(previous_window_size)
			DisplayServer.window_set_position(previous_window_position)
			Engine.get_main_loop().root.content_scale_factor = 1.0
		)
		tween.tween_callback(func():
			# Update responsive UI
			notify_responsive_ui()
			transition_in_progress = false
		)
	
	# Update state
	is_fullscreen = fullscreen_enabled
	
	# Save state if requested
	if save_state:
		save_fullscreen_state()
	
	# Emit signal
	fullscreen_changed.emit(is_fullscreen)

func notify_responsive_ui():
	# Find and notify responsive UI to update layout
	var responsive_ui = get_tree().get_first_node_in_group("responsive_ui")
	if responsive_ui:
		responsive_ui._on_window_size_changed()

# Check if fullscreen is supported on this platform
func is_fullscreen_supported():
	# Most platforms support fullscreen, but some mobile platforms might have limitations
	return true

# Get current fullscreen state
func get_fullscreen_state():
	return is_fullscreen
