extends CanvasLayer

func _ready():
	# Center the panel
	$Panel.position = Vector2(get_viewport().size) / 2 - $Panel.size / 2

func show_message(message: String):
	$Panel/VBoxContainer/MessageLabel.text = message

func _on_ok_button_pressed():
	queue_free()
