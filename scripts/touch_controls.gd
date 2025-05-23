extends Node

# Touch controls manager for mobile devices

signal card_touched(card)
signal truco_called

# Touch parameters
var touch_start_position = Vector2.ZERO
var touch_current_position = Vector2.ZERO
var is_dragging = false
var drag_threshold = 10
var swipe_threshold = 100
var double_tap_time = 0.3
var last_tap_time = 0
var last_tap_position = Vector2.ZERO

# Card being dragged
var dragged_card = null

func _ready():
	# Set up input handling
	set_process_input(true)

func _input(event):
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event):
	if event.pressed:
		# Touch began
		touch_start_position = event.position
		touch_current_position = event.position
		
		# Check for double tap (truco call)
		var current_time = Time.get_ticks_msec() / 1000.0
		var time_since_last_tap = current_time - last_tap_time
		var distance_from_last_tap = touch_start_position.distance_to(last_tap_position)
		
		if time_since_last_tap < double_tap_time and distance_from_last_tap < drag_threshold * 2:
			# Double tap detected - call truco
			truco_called.emit()
		
		# Update last tap info
		last_tap_time = current_time
		last_tap_position = touch_start_position
		
		# Check if a card was touched
		dragged_card = _find_card_under_position(touch_start_position)
		
		# Start potential drag
		is_dragging = true
	else:
		# Touch ended
		if is_dragging and dragged_card and _is_valid_card_play(dragged_card, touch_start_position, touch_current_position):
			# Valid card play
			card_touched.emit(dragged_card)
		
		# Reset drag state
		is_dragging = false
		dragged_card = null

func _handle_drag(event):
	if is_dragging:
		touch_current_position = event.position

func _find_card_under_position(position):
	# In a real implementation, this would use raycasting or collision detection
	# For this prototype, we'll use a placeholder implementation
	
	# Get all cards in the player's hand
	var game_manager = get_tree().get_nodes_in_group("game_manager")
	if game_manager.size() > 0:
		var cards = game_manager[0].player_hand_cards
		
		# Check each card
		for card in cards:
			if card.get_global_rect().has_point(position):
				return card
	
	return null

func _is_valid_card_play(card, start_pos, current_pos):
	# Check if the card was dragged upward (toward the center of the table)
	var drag_vector = current_pos - start_pos
	
	# For cards, we want an upward swipe (negative y)
	if drag_vector.y < -swipe_threshold:
		return true
	
	# If the drag was small, treat it as a tap
	if drag_vector.length() < drag_threshold:
		return true
	
	return false

# Enable/disable touch controls
func set_enabled(enabled):
	set_process_input(enabled)
