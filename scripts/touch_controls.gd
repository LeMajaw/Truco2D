extends Node

# Enhanced Touch Controls for cross-platform support
# Handles touch input for mobile and mouse input for desktop

signal card_touched(card)
signal truco_called
signal truco_escalated(level) # New signal for truco escalation

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

# Platform detection
var is_mobile = false

# Truco escalation tracking
var current_truco_level = 0 # 0=none, 1=truco(3), 2=six, 3=nine, 4=twelve

func _ready():
	# Detect platform
	is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	
	# Adjust thresholds based on platform and screen size
	if is_mobile:
		# Mobile devices need larger thresholds for touch
		var viewport_size = get_viewport().size
		var screen_diagonal = sqrt(viewport_size.x * viewport_size.x + viewport_size.y * viewport_size.y)
		drag_threshold = screen_diagonal * 0.01  # 1% of screen diagonal
		swipe_threshold = screen_diagonal * 0.08  # 8% of screen diagonal
	else:
		# Desktop can use smaller thresholds
		drag_threshold = 5
		swipe_threshold = 50
	
	# Set up input handling
	set_process_input(true)

func _input(event):
	if is_mobile:
		_handle_mobile_input(event)
	else:
		_handle_desktop_input(event)

func _handle_mobile_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			# Touch began
			touch_start_position = event.position
			touch_current_position = event.position
			
			# Check for double tap (truco call)
			var current_time = Time.get_ticks_msec() / 1000.0
			var time_since_last_tap = current_time - last_tap_time
			var distance_from_last_tap = touch_start_position.distance_to(last_tap_position)
			
			if time_since_last_tap < double_tap_time and distance_from_last_tap < drag_threshold * 2:
				# Double tap detected - call truco or escalate
				_handle_truco_action()
			
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
	
	elif event is InputEventScreenDrag:
		if is_dragging:
			touch_current_position = event.position

func _handle_desktop_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Mouse button down
				touch_start_position = event.position
				touch_current_position = event.position
				
				# Check for double click (truco call)
				var current_time = Time.get_ticks_msec() / 1000.0
				var time_since_last_tap = current_time - last_tap_time
				var distance_from_last_tap = touch_start_position.distance_to(last_tap_position)
				
				if time_since_last_tap < double_tap_time and distance_from_last_tap < drag_threshold * 2:
					# Double click detected - call truco or escalate
					_handle_truco_action()
				
				# Update last click info
				last_tap_time = current_time
				last_tap_position = touch_start_position
				
				# Check if a card was clicked
				dragged_card = _find_card_under_position(touch_start_position)
				
				# Start potential drag
				is_dragging = true
			else:
				# Mouse button up
				if is_dragging and dragged_card:
					# For desktop, we're more lenient with card plays
					card_touched.emit(dragged_card)
				
				# Reset drag state
				is_dragging = false
				dragged_card = null
	
	elif event is InputEventMouseMotion:
		if is_dragging:
			touch_current_position = event.position
	
	# Handle keyboard shortcuts
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			# T key for truco
			_handle_truco_action()

func _handle_truco_action():
	# Handle truco call or escalation
	if current_truco_level == 0:
		# Call truco (3 points)
		current_truco_level = 1
		truco_called.emit()
	elif current_truco_level < 4:
		# Escalate to next level
		current_truco_level += 1
		truco_escalated.emit(current_truco_level)

func _find_card_under_position(position):
	# Get all cards in the player's hand
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		var cards = game_manager.player_hand_cards
		
		# Check each card
		for card in cards:
			# Convert card's local rect to global
			var card_rect = Rect2(
				card.global_position - (card.scale * card.get_node("Front").size / 2),
				card.scale * card.get_node("Front").size
			)
			
			if card_rect.has_point(position):
				return card
	
	return null

func _is_valid_card_play(card, start_pos, current_pos):
	# For mobile: Check if the card was dragged upward (toward the center of the table)
	if is_mobile:
		var drag_vector = current_pos - start_pos
		
		# For cards, we want an upward swipe (negative y)
		if drag_vector.y < -swipe_threshold:
			return true
		
		# If the drag was small, treat it as a tap
		if drag_vector.length() < drag_threshold:
			return true
	else:
		# For desktop: More lenient, just check if it's a click or small drag
		var drag_vector = current_pos - start_pos
		if drag_vector.length() < drag_threshold * 3:
			return true
	
	return false

# Reset truco state for new round
func reset_truco_state():
	current_truco_level = 0

# Get current truco level
func get_truco_level():
	return current_truco_level

# Enable/disable touch controls
func set_enabled(enabled):
	set_process_input(enabled)
