extends CanvasLayer

var callback

func _ready():
	# Ensure this layer is always on top
	layer = 100  # Arbitrary high number to out-prioritize other CanvasLayers

	# Center the panel
	$Panel.position = Vector2(get_viewport().size) / 2 - $Panel.size / 2

func show_message(message: String, cb = null):
	$Panel/VBoxContainer/MessageLabel.text = message
	callback = cb if cb != null and cb is Callable and cb.is_valid() else null

func _on_ok_button_pressed():
	if callback is Callable and callback.is_valid():
		callback.call()
	queue_free()
