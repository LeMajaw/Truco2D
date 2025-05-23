extends CanvasLayer

signal create_room(player_name)
signal join_room(player_name, room_code)

var player_name = "Player"

func _ready():
	# Center the panel
	$Panel.position = Vector2(get_viewport().size) / 2 - $Panel.size / 2

	# Load player name if available
	var config = ConfigFile.new()
	var err = config.load("user://player_settings.cfg")
	if err == OK and config.has_section_key("player", "name"):
		player_name = config.get_value("player", "name", "Player")

	# Focus the room code input field
	$Panel/VBoxContainer/RoomCodeInput.grab_focus()

func _on_create_room_button_pressed():
	# Generate a random 6-character room code
	var room_code = generate_room_code()

	# Show the room code
	$Panel/VBoxContainer/StatusLabel.text = "Creating room with code: " + room_code

	# Emit signal to create room
	create_room.emit(player_name)

func _on_join_room_button_pressed():
	var room_code = $Panel/VBoxContainer/RoomCodeInput.text.strip_edges().to_upper()

	if room_code.length() < 4:
		$Panel/VBoxContainer/StatusLabel.text = "Room code must be at least 4 characters"
		return

	# Show joining status
	$Panel/VBoxContainer/StatusLabel.text = "Joining room: " + room_code

	# Emit signal to join room
	join_room.emit(player_name, room_code)

func _on_room_code_input_submitted(text):
	_on_join_room_button_pressed()

func _on_back_button_pressed():
	queue_free()

func generate_room_code() -> String:
	var chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var code = ""
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(6):
		var idx = rng.randi_range(0, chars.length() - 1)
		code += chars[idx]

	return code
