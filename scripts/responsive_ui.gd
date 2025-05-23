extends Node

# Enhanced Responsive UI manager for cross-platform support (Steam and Android)

signal layout_updated

# Reference resolution (design resolution)
var reference_width = 1024
var reference_height = 600

# Current screen properties
var current_width = 0
var current_height = 0
var is_mobile = false
var is_landscape = true

# Scaling factors
var scale_factor_x = 1.0
var scale_factor_y = 1.0
var ui_scale = 1.0

# Platform-specific settings
var touch_deadzone = 10 # pixels
var double_tap_time = 0.3 # seconds
var last_tap_time = 0.0
var last_tap_position = Vector2.ZERO

# Safe area for notch/cutout devices
var safe_area_margin = Vector2.ZERO

func _ready():
	# Connect to window resize signal
	get_tree().get_root().size_changed.connect(_on_window_size_changed)
	
	# Detect platform
	is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	
	# Set up safe area for mobile devices
	if is_mobile:
		_update_safe_area()
	
	# Initial update with a slight delay to ensure all nodes are ready
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()
	
	# Apply any saved display settings
	_apply_saved_display_settings()

func _on_timer_timeout():
	# Delayed initial update to ensure all nodes are ready
	_update_screen_metrics()
	_apply_responsive_layout()

func _on_window_size_changed():
	# Update metrics when window size changes
	_update_screen_metrics()
	if is_mobile:
		_update_safe_area()
	_apply_responsive_layout()

func _update_screen_metrics():
	# Get current screen size
	var viewport = get_viewport()
	if viewport:
		current_width = viewport.size.x
		current_height = viewport.size.y
		
		# Calculate scaling factors
		scale_factor_x = current_width / float(reference_width)
		scale_factor_y = current_height / float(reference_height)
		
		# Use the smaller factor for UI scaling to ensure everything fits
		ui_scale = min(scale_factor_x, scale_factor_y)
		
		# Determine orientation
		is_landscape = current_width >= current_height
		
		print("Screen updated: ", current_width, "x", current_height, 
			  " Scale: ", ui_scale, " Mobile: ", is_mobile, 
			  " Landscape: ", is_landscape)

func _update_safe_area():
	# Get safe area for notched devices
	var window_safe_area = DisplayServer.get_display_safe_area()
	var window_size = DisplayServer.window_get_size()
	
	# Calculate margins
	safe_area_margin.x = window_safe_area.position.x
	safe_area_margin.y = window_safe_area.position.y
	
	print("Safe area updated: ", safe_area_margin)

func _apply_responsive_layout():
	# Find all UI containers and adjust them
	_adjust_main_ui()
	_adjust_card_positions()
	_adjust_player_positions()
	_adjust_truco_button()
	
	# Emit signal for other nodes to update
	layout_updated.emit()

func _adjust_main_ui():
	# Find main UI elements and adjust their scale/position
	var ui_elements = get_tree().get_nodes_in_group("responsive_ui")
	for element in ui_elements:
		if element.has_method("apply_responsive_scale"):
			element.apply_responsive_scale(ui_scale, is_mobile, is_landscape)
		elif element is Control:
			# Apply basic scaling for Controls
			_apply_basic_control_scaling(element)

func _apply_basic_control_scaling(control: Control):
	# Apply basic scaling to control elements
	if control.has_meta("original_size"):
		var original_size = control.get_meta("original_size")
		control.size = original_size * ui_scale
	else:
		control.set_meta("original_size", control.size)
		control.size = control.size * ui_scale
	
	# Adjust for safe area on mobile
	if is_mobile and safe_area_margin != Vector2.ZERO:
		# Apply safe area adjustments based on anchor
		if control.anchor_left < 0.1 and control.anchor_right < 0.1:
			# Left-aligned element
			control.position.x = max(control.position.x, safe_area_margin.x)
		elif control.anchor_left > 0.9 and control.anchor_right > 0.9:
			# Right-aligned element
			control.position.x = min(control.position.x, current_width - safe_area_margin.x - control.size.x)
		
		if control.anchor_top < 0.1 and control.anchor_bottom < 0.1:
			# Top-aligned element
			control.position.y = max(control.position.y, safe_area_margin.y)
		elif control.anchor_top > 0.9 and control.anchor_bottom > 0.9:
			# Bottom-aligned element
			control.position.y = min(control.position.y, current_height - safe_area_margin.y - control.size.y)

func _adjust_card_positions():
	# Adjust card positions and scales based on screen size
	var game_manager = get_tree().get_nodes_in_group("game_manager")
	if game_manager.size() > 0:
		var manager = game_manager[0]
		
		# Update card constants based on screen size and platform
		if is_mobile:
			if is_landscape:
				# Landscape mobile
				manager.PLAYER_HAND_SPACING = 150 * ui_scale
				manager.PLAYER_CARD_SCALE = Vector2(0.35, 0.35) * ui_scale
				manager.PLAYER_HAND_Y = current_height - 70 * ui_scale - safe_area_margin.y
			else:
				# Portrait mobile - more compact layout
				manager.PLAYER_HAND_SPACING = 120 * ui_scale
				manager.PLAYER_CARD_SCALE = Vector2(0.3, 0.3) * ui_scale
				manager.PLAYER_HAND_Y = current_height - 60 * ui_scale - safe_area_margin.y
		else:
			# Desktop
			manager.PLAYER_HAND_SPACING = 200 * ui_scale
			manager.PLAYER_CARD_SCALE = Vector2(0.4, 0.4) * ui_scale
			manager.PLAYER_HAND_Y = current_height - 80 * ui_scale
		
		# Update played card positions
		var center = Vector2(current_width / 2, current_height / 2)
		manager.PLAYED_CARD_POSITIONS = {
			"bot1": center + Vector2(-95, -46.5) * ui_scale,
			"bot2": center + Vector2(5, -191) * ui_scale,
			"bot3": center + Vector2(105, -46.5) * ui_scale,
			"player": center + Vector2(5, 97.5) * ui_scale,
		}
		
		# Update vira position
		manager.VIRA_CARD_POS = center + Vector2(0, -55) * ui_scale
		manager.VIRA_SCALE = Vector2(0.2, 0.2) * ui_scale
		
		# Update bot card positions
		manager.BOT_CARD_SCALE = Vector2(0.3, 0.3) * ui_scale
		manager.BOT_CARD_SPACE = 80 * ui_scale
		
		# Refresh card display if game is in progress
		if manager.has_method("refresh_card_display"):
			manager.refresh_card_display()

func _adjust_player_positions():
	# Adjust player label positions for multiplayer
	var player_labels = get_tree().get_nodes_in_group("player_labels")
	if player_labels.size() > 0:
		var center = Vector2(current_width / 2, current_height / 2)
		
		# Position labels around the table
		for label in player_labels:
			if "player1" in label.name.to_lower():
				label.position = Vector2(center.x, current_height - 40 * ui_scale - safe_area_margin.y)
			elif "player2" in label.name.to_lower():
				label.position = Vector2(40 * ui_scale + safe_area_margin.x, center.y)
			elif "player3" in label.name.to_lower():
				label.position = Vector2(center.x, 40 * ui_scale + safe_area_margin.y)
			elif "player4" in label.name.to_lower():
				label.position = Vector2(current_width - 40 * ui_scale - safe_area_margin.x, center.y)

func _adjust_truco_button():
	# Find and adjust the truco button position
	var truco_button = get_tree().get_first_node_in_group("truco_button")
	if truco_button:
		if is_mobile:
			if is_landscape:
				# Bottom right for landscape
				truco_button.position = Vector2(
					current_width - truco_button.size.x - 20 * ui_scale - safe_area_margin.x,
					current_height - truco_button.size.y - 20 * ui_scale - safe_area_margin.y
				)
			else:
				# Bottom right for portrait, but higher up
				truco_button.position = Vector2(
					current_width - truco_button.size.x - 20 * ui_scale - safe_area_margin.x,
					current_height - truco_button.size.y - 120 * ui_scale - safe_area_margin.y
				)
		else:
			# Desktop position
			truco_button.position = Vector2(
				current_width - truco_button.size.x - 30 * ui_scale,
				current_height - truco_button.size.y - 30 * ui_scale
			)
		
		# Scale button based on platform
		var button_scale = 1.0 * ui_scale
		if is_mobile:
			button_scale = 1.2 * ui_scale  # Larger for touch
		truco_button.scale = Vector2(button_scale, button_scale)

func _apply_saved_display_settings():
	# Load and apply saved display settings
	var config = ConfigFile.new()
	var err = config.load("user://player_settings.cfg")
	if err == OK:
		var fullscreen = config.get_value("settings", "fullscreen", false)
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Public methods for other scripts to use
func get_ui_scale():
	return ui_scale

func is_mobile_device():
	return is_mobile

func is_landscape_orientation():
	return is_landscape

func get_safe_area_margin():
	return safe_area_margin

# Handle platform-specific input processing
func process_input_for_platform(event):
	if is_mobile:
		return _process_touch_input(event)
	else:
		return _process_desktop_input(event)
	
	return false

func _process_touch_input(event):
	# Process touch input for mobile devices
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check for double tap
			var current_time = Time.get_ticks_msec() / 1000.0
			var tap_position = event.position
			
			if current_time - last_tap_time < double_tap_time and tap_position.distance_to(last_tap_position) < touch_deadzone * 2:
				# Double tap detected
				print("Double tap detected")
				# Emit signal or call method for double tap action
				return true
			
			last_tap_time = current_time
			last_tap_position = tap_position
	
	return false

func _process_desktop_input(event):
	# Process mouse/keyboard input for desktop
	return false

# Toggle fullscreen mode
func toggle_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Update layout after mode change
	_update_screen_metrics()
	_apply_responsive_layout()
