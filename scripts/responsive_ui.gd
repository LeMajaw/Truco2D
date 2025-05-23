extends Node

# Responsive UI manager for different screen sizes and orientations

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

func _ready():
	# Connect to window resize signal
	get_tree().get_root().size_changed.connect(_on_window_size_changed)
	
	# Detect platform
	is_mobile = OS.has_feature("mobile")
	
	# Initial update
	_update_screen_metrics()

func _on_timer_timeout():
	# Delayed initial update to ensure all nodes are ready
	_update_screen_metrics()
	_apply_responsive_layout()

func _on_window_size_changed():
	# Update metrics when window size changes
	_update_screen_metrics()
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

func _apply_responsive_layout():
	# Find all UI containers and adjust them
	_adjust_main_ui()
	_adjust_card_positions()
	_adjust_player_positions()
	
	# Emit signal for other nodes to update
	layout_updated.emit()

func _adjust_main_ui():
	# Find main UI elements and adjust their scale/position
	var ui_elements = get_tree().get_nodes_in_group("responsive_ui")
	for element in ui_elements:
		if element.has_method("apply_responsive_scale"):
			element.apply_responsive_scale(ui_scale, is_mobile, is_landscape)

func _adjust_card_positions():
	# Adjust card positions and scales based on screen size
	var game_manager = get_tree().get_nodes_in_group("game_manager")
	if game_manager.size() > 0:
		var manager = game_manager[0]
		
		# Update card constants based on screen size
		if is_mobile:
			if is_landscape:
				# Landscape mobile
				manager.PLAYER_HAND_SPACING = 150 * ui_scale
				manager.PLAYER_CARD_SCALE = Vector2(0.35, 0.35) * ui_scale
				manager.PLAYER_HAND_Y = current_height - 70 * ui_scale
			else:
				# Portrait mobile
				manager.PLAYER_HAND_SPACING = 120 * ui_scale
				manager.PLAYER_CARD_SCALE = Vector2(0.3, 0.3) * ui_scale
				manager.PLAYER_HAND_Y = current_height - 60 * ui_scale
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
				label.position = Vector2(center.x, current_height - 40 * ui_scale)
			elif "player2" in label.name.to_lower():
				label.position = Vector2(40 * ui_scale, center.y)
			elif "player3" in label.name.to_lower():
				label.position = Vector2(center.x, 40 * ui_scale)
			elif "player4" in label.name.to_lower():
				label.position = Vector2(current_width - 40 * ui_scale, center.y)

# Public methods for other scripts to use
func get_ui_scale():
	return ui_scale

func is_mobile_device():
	return is_mobile

func is_landscape_orientation():
	return is_landscape
