extends Button

# Enhanced Truco Button with escalation support
# Handles truco calls, responses, and visual feedback

signal truco_called(level)
signal truco_response(response, level)

# Truco state constants
enum TrucoState {NONE, CALLED, ACCEPTED, DECLINED, RAISED}
enum TrucoResponse {ACCEPT, DECLINE, RAISE}
enum TrucoLevel {NONE, TRUCO, SIX, NINE, TWELVE}

# Current state
var current_state = TrucoState.NONE
var current_level = TrucoLevel.NONE
var is_pulsing := false
var pulse_tween: Tween
var is_player_turn_to_respond := false

# Visual elements
@onready var label = $Label
@onready var response_panel = $ResponsePanel
@onready var accept_button = $ResponsePanel/HBoxContainer/AcceptButton
@onready var raise_button = $ResponsePanel/HBoxContainer/RaiseButton
@onready var decline_button = $ResponsePanel/HBoxContainer/DeclineButton

# Level-specific properties
var level_data = {
	TrucoLevel.NONE: {
		"label": "TRUCO",
		"points": 1,
		"color": Color(1, 0.8, 0, 1)
	},
	TrucoLevel.TRUCO: {
		"label": "TRUCO (3)",
		"points": 3,
		"color": Color(1, 0.7, 0, 1)
	},
	TrucoLevel.SIX: {
		"label": "SEIS (6)",
		"points": 6,
		"color": Color(1, 0.5, 0, 1)
	},
	TrucoLevel.NINE: {
		"label": "NOVE (9)",
		"points": 9,
		"color": Color(1, 0.3, 0, 1)
	},
	TrucoLevel.TWELVE: {
		"label": "DOZE (12)",
		"points": 12,
		"color": Color(1, 0, 0, 1)
	}
}

func _ready():
	# Connect button signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_truco_button_pressed)

	# Connect response buttons
	accept_button.pressed.connect(_on_accept_pressed)
	raise_button.pressed.connect(_on_raise_pressed)
	decline_button.pressed.connect(_on_decline_pressed)

	# Hide response panel initially
	response_panel.visible = false

	# Set initial label
	_update_button_appearance()

	# Start pulse animation
	start_pulse_animation()

func _on_mouse_entered():
	if not disabled:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)

func _on_mouse_exited():
	if not disabled:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _on_truco_button_pressed():
	if disabled or current_state != TrucoState.NONE:
		return

	# Call truco
	call_truco()

func call_truco():
	# Update state
	current_state = TrucoState.CALLED
	current_level = TrucoLevel.TRUCO

	# Update appearance
	_update_button_appearance()

	# Disable button temporarily
	disabled = true

	# Emit signal
	truco_called.emit(current_level)

	# Play animation
	_play_truco_call_animation()

func show_response_options():
	# Only show response panel if it's player's turn to respond
	if not is_player_turn_to_respond:
		return
	
	if is_instance_valid(raise_button):
		raise_button.disabled = (current_level == TrucoLevel.TWELVE)
	else:
		print("⚠️ raise_button is not initialized yet.")

	# Show response panel with animation
	response_panel.scale = Vector2(0.5, 0.5)
	response_panel.modulate = Color(1, 1, 1, 0)
	response_panel.visible = true

	var tween = create_tween()
	tween.tween_property(response_panel, "scale", Vector2(1, 1), 0.2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(response_panel, "modulate", Color(1, 1, 1, 1), 0.2)

func hide_response_options():
	# Hide response panel with animation
	if response_panel.visible:
		var tween = create_tween()
		tween.tween_property(response_panel, "scale", Vector2(0.5, 0.5), 0.2).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(response_panel, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.tween_callback(func(): response_panel.visible = false)

func _on_accept_pressed():
	# Accept the truco call
	current_state = TrucoState.ACCEPTED
	is_player_turn_to_respond = false

	# Hide response panel
	hide_response_options()

	# Update appearance
	_update_button_appearance()

	# Emit signal
	truco_response.emit(TrucoResponse.ACCEPT, current_level)

func _on_raise_pressed():
	# Raise the truco call
	current_state = TrucoState.RAISED
	is_player_turn_to_respond = false

	# Escalate to next level
	current_level += 1
	if current_level > TrucoLevel.TWELVE:
		current_level = TrucoLevel.TWELVE

	# Hide response panel
	hide_response_options()

	# Update appearance
	_update_button_appearance()

	# Emit signal
	truco_response.emit(TrucoResponse.RAISE, current_level)

	# Play raise animation
	_play_truco_raise_animation()

func _on_decline_pressed():
	# Decline the truco call
	current_state = TrucoState.DECLINED
	is_player_turn_to_respond = false

	# Hide response panel
	hide_response_options()

	# Update appearance
	_update_button_appearance()

	# Emit signal
	truco_response.emit(TrucoResponse.DECLINE, current_level)

func start_pulse_animation():
	if is_pulsing or disabled:
		return

	is_pulsing = true
	pulse_tween = create_tween()
	pulse_tween.set_loops()

	# Get color based on current level
	var base_color = level_data[current_level].color
	var highlight_color = base_color.lightened(0.3)

	# Pulse effect
	pulse_tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.2, 1), 0.8)
	pulse_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.8)

	# Label effect
	pulse_tween.parallel().tween_callback(func():
		label.add_theme_color_override("font_color", highlight_color)
	)
	pulse_tween.parallel().tween_callback(func():
		label.add_theme_color_override("font_color", base_color)
	)

func stop_pulse_animation():
	is_pulsing = false
	if pulse_tween:
		pulse_tween.kill()
	modulate = Color(0.7, 0.7, 0.7, 0.7) if disabled else Color(1, 1, 1, 1)

func _process(delta):
	if disabled and is_pulsing:
		stop_pulse_animation()
	elif not disabled and not is_pulsing and current_state == TrucoState.NONE:
		start_pulse_animation()

func _update_button_appearance():
	if not is_instance_valid(label):
		return

	# Update label text and color based on current level and state
	var level_info = level_data[current_level]

	match current_state:
		TrucoState.NONE:
			label.text = "TRUCO"
			label.add_theme_color_override("font_color", level_data[TrucoLevel.NONE].color)
		TrucoState.CALLED:
			label.text = level_info.label + "!"
			label.add_theme_color_override("font_color", level_info.color)
		TrucoState.ACCEPTED:
			label.text = level_info.label + " ✓"
			label.add_theme_color_override("font_color", level_info.color)
		TrucoState.DECLINED:
			label.text = "RECUSADO"
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		TrucoState.RAISED:
			label.text = level_info.label + " ↑"
			label.add_theme_color_override("font_color", level_info.color)

func _play_truco_call_animation():
	# Animate the truco call for visual feedback
	var original_scale = scale
	var original_position = position

	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale * 1.3, 0.1)
	tween.tween_property(self, "scale", original_scale, 0.1)
	tween.tween_property(self, "scale", original_scale * 1.2, 0.1)
	tween.tween_property(self, "scale", original_scale, 0.1)

	# Shake effect
	for i in range(5):
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		tween.tween_property(self, "position", original_position + offset, 0.05)

	tween.tween_property(self, "position", original_position, 0.1)

func _play_truco_raise_animation():
	# Animate the truco raise for visual feedback
	var original_scale = scale

	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale * 1.4, 0.2)
	tween.tween_property(self, "scale", original_scale, 0.1)

	# Flash effect
	var flash_panel = ColorRect.new()
	flash_panel.color = level_data[current_level].color.lightened(0.5)
	flash_panel.color.a = 0.7
	flash_panel.size = Vector2(get_viewport_rect().size)
	flash_panel.position = Vector2.ZERO
	get_tree().get_root().add_child(flash_panel)

	var flash_tween = create_tween()
	flash_tween.tween_property(flash_panel, "color:a", 0.0, 0.5)
	flash_tween.tween_callback(flash_panel.queue_free)

# Public methods
func reset():
	# Reset to initial state
	current_state = TrucoState.NONE
	current_level = TrucoLevel.NONE
	is_player_turn_to_respond = false
	disabled = false

	# Hide response panel
	hide_response_options()

	# Update appearance
	_update_button_appearance()

	# Restart pulse animation
	stop_pulse_animation()
	start_pulse_animation()

func handle_bot_truco_call(bot_name: String, level: int):
	# Bot called truco
	current_state = TrucoState.CALLED
	current_level = level
	is_player_turn_to_respond = true

	# Update appearance
	_update_button_appearance()

	# Show response options
	call_deferred("show_response_options")

	# Show notification
	var notification = load("res://scenes/notification.tscn").instantiate()
	notification.show_message(bot_name + " called " + level_data[level].label + "!")
	get_tree().get_root().add_child(notification)

	# Play animation
	_play_truco_call_animation()

func handle_bot_truco_response(bot_name: String, response: int, level: int):
	# Bot responded to truco
	is_player_turn_to_respond = false

	match response:
		TrucoResponse.ACCEPT:
			current_state = TrucoState.ACCEPTED
			# Level stays the same
		TrucoResponse.DECLINE:
			current_state = TrucoState.DECLINED
			# Level stays the same
		TrucoResponse.RAISE:
			current_state = TrucoState.RAISED
			current_level = level

	# Update appearance
	_update_button_appearance()

	# Show notification
	var notification = load("res://scenes/notification.tscn").instantiate()

	match response:
		TrucoResponse.ACCEPT:
			notification.show_message(bot_name + " accepted " + level_data[current_level].label + "!")
		TrucoResponse.DECLINE:
			notification.show_message(bot_name + " declined " + level_data[current_level].label + "!")
		TrucoResponse.RAISE:
			notification.show_message(bot_name + " raised to " + level_data[current_level].label + "!")
			_play_truco_raise_animation()

	get_tree().get_root().add_child(notification)

func get_current_points():
	# Return the current point value based on truco level
	if current_state == TrucoState.NONE:
		return 1
	elif current_state == TrucoState.DECLINED:
		# If declined, previous level points are awarded
		var previous_level = max(current_level - 1, TrucoLevel.NONE)
		return level_data[previous_level].points
	else:
		return level_data[current_level].points
