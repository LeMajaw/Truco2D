extends Node

# Cross-platform input handler for Truco Paulista
# Manages input events for both desktop and mobile platforms

signal card_selected(card_node)
signal truco_action(action_type, level)

# Input constants
enum TrucoAction {CALL, ACCEPT, DECLINE, RAISE}
enum Platform {DESKTOP, MOBILE}

# Platform detection
var current_platform = Platform.DESKTOP
var ui_scale = 1.0

# Touch/click tracking
var touch_start_position = Vector2.ZERO
var touch_current_position = Vector2.ZERO
var is_dragging = false
var drag_threshold = 10
var swipe_threshold = 100
var double_tap_time = 0.3
var last_tap_time = 0
var last_tap_position = Vector2.ZERO

# Card interaction
var selected_card = null
var hover_scale_factor = 1.2
var hover_y_offset = 20

# Keyboard shortcuts (desktop)
var truco_key = KEY_T
var accept_key = KEY_Y
var decline_key = KEY_N
var raise_key = KEY_R

func _ready():
	# Detect platform
	current_platform = Platform.MOBILE if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") else Platform.DESKTOP
	
	# Get UI scale from responsive UI
	var responsive_ui = get_tree().get_first_node_in_group("responsive_ui")
	if responsive_ui:
		ui_scale = responsive_ui.get_ui_scale()
	
	# Adjust thresholds based on platform and screen size
	_adjust_input_thresholds()
	
	# Enable input processing
	set_process_input(true)

func _adjust_input_thresholds():
	if current_platform == Platform.MOBILE:
		# Mobile devices need larger thresholds for touch
		var viewport_size = get_viewport().size
		var screen_diagonal = sqrt(viewport_size.x * viewport_size.x + viewport_size.y * viewport_size.y)
		drag_threshold = screen_diagonal * 0.015  # 1.5% of screen diagonal
		swipe_threshold = screen_diagonal * 0.1   # 10% of screen diagonal
		hover_scale_factor = 1.3                  # Larger scale change for touch
		hover_y_offset = 30 * ui_scale            # Larger offset for touch
	else:
		# Desktop can use smaller thresholds
		drag_threshold = 5
		swipe_threshold = 50
		hover_scale_factor = 1.2
		hover_y_offset = 20 * ui_scale

func _input(event):
	if current_platform == Platform.MOBILE:
		_handle_mobile_input(event)
	else:
		_handle_desktop_input(event)

func _handle_mobile_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			# Touch began
			_handle_touch_begin(event.position)
		else:
			# Touch ended
			_handle_touch_end(event.position)
	
	elif event is InputEventScreenDrag:
		# Touch drag
		_handle_touch_drag(event.position)

func _handle_desktop_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Mouse button down
				_handle_touch_begin(event.position)
			else:
				# Mouse button up
				_handle_touch_end(event.position)
	
	elif event is InputEventMouseMotion:
		# Mouse movement
		_handle_mouse_motion(event.position)
	
	# Handle keyboard shortcuts
	elif event is InputEventKey and event.pressed:
		_handle_keyboard_shortcut(event.keycode)

func _handle_touch_begin(position):
	touch_start_position = position
	touch_current_position = position
	
	# Check for double tap/click
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_since_last_tap = current_time - last_tap_time
	var distance_from_last_tap = touch_start_position.distance_to(last_tap_position)
	
	if time_since_last_tap < double_tap_time and distance_from_last_tap < drag_threshold * 2:
		# Double tap/click detected - call truco
		truco_action.emit(TrucoAction.CALL, 0)
	
	# Update last tap info
	last_tap_time = current_time
	last_tap_position = touch_start_position
	
	# Check if a card was touched
	selected_card = _find_card_under_position(touch_start_position)
	if selected_card:
		_highlight_card(selected_card)
	
	# Start potential drag
	is_dragging = true

func _handle_touch_end(position):
	touch_current_position = position
	
	if is_dragging and selected_card:
		if _is_valid_card_play(selected_card, touch_start_position, touch_current_position):
			# Valid card play
			card_selected.emit(selected_card)
		else:
			# Invalid play, reset card
			_reset_card_highlight(selected_card)
	
	# Reset drag state
	is_dragging = false
	selected_card = null

func _handle_touch_drag(position):
	if is_dragging:
		touch_current_position = position
		
		# Update card position if dragging a card
		if selected_card:
			# Optional: Add visual feedback during drag
			pass

func _handle_mouse_motion(position):
	if is_dragging:
		touch_current_position = position
	else:
		# Hover effect for desktop
		var card_under_cursor = _find_card_under_position(position)
		
		# Handle hover state changes
		if card_under_cursor != selected_card:
			if selected_card:
				_reset_card_highlight(selected_card)
			
			selected_card = card_under_cursor
			
			if selected_card:
				_highlight_card(selected_card)

func _handle_keyboard_shortcut(keycode):
	match keycode:
		truco_key:
			# T key for truco call
			truco_action.emit(TrucoAction.CALL, 0)
		accept_key:
			# Y key to accept truco
			truco_action.emit(TrucoAction.ACCEPT, 0)
		decline_key:
			# N key to decline truco
			truco_action.emit(TrucoAction.DECLINE, 0)
		raise_key:
			# R key to raise truco
			truco_action.emit(TrucoAction.RAISE, 0)

func _find_card_under_position(position):
	# Get game manager
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		return null
	
	# Get player hand cards
	var cards = game_manager.player_hand_cards
	if cards.size() == 0:
		return null
	
	# Check each card (in reverse order to get top card first)
	for i in range(cards.size() - 1, -1, -1):
		var card = cards[i]
		if not is_instance_valid(card):
			continue
			
		# Get card's front node for collision detection
		var front = card.get_node("Front")
		if not front:
			continue
			
		# Calculate card's global rect
		var card_size = front.size * card.scale
		var card_pos = card.global_position - card_size/2
		var card_rect = Rect2(card_pos, card_size)
		
		if card_rect.has_point(position):
			return card
	
	return null

func _is_valid_card_play(card, start_pos, current_pos):
	if current_platform == Platform.MOBILE:
		# For mobile: Check for upward swipe or short tap
		var drag_vector = current_pos - start_pos
		
		# Upward swipe (negative y)
		if drag_vector.y < -swipe_threshold:
			return true
		
		# Short tap
		if drag_vector.length() < drag_threshold:
			return true
	else:
		# For desktop: More lenient, just check if it's a click or small drag
		var drag_vector = current_pos - start_pos
		if drag_vector.length() < drag_threshold * 3:
			return true
	
	return false

func _highlight_card(card):
	# Store original scale and position if not already stored
	if not card.has_meta("original_scale"):
		card.set_meta("original_scale", card.scale)
	
	if not card.has_meta("original_position"):
		card.set_meta("original_position", card.position)
	
	# Apply highlight effect
	var tween = create_tween()
	tween.tween_property(card, "scale", card.get_meta("original_scale") * hover_scale_factor, 0.1)
	tween.parallel().tween_property(card, "position", Vector2(card.get_meta("original_position").x, card.get_meta("original_position").y - hover_y_offset), 0.1)

func _reset_card_highlight(card):
	if card.has_meta("original_scale") and card.has_meta("original_position"):
		var tween = create_tween()
		tween.tween_property(card, "scale", card.get_meta("original_scale"), 0.1)
		tween.parallel().tween_property(card, "position", card.get_meta("original_position"), 0.1)

# Public methods
func get_platform():
	return current_platform

func is_mobile():
	return current_platform == Platform.MOBILE

func set_enabled(enabled):
	set_process_input(enabled)
