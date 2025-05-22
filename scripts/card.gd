extends Node2D
class_name Card

@export var value: String = ""
@export var suit: String = ""
@export var face_up := true : set = set_face_up

@onready var card_image: TextureRect = $Front
@onready var back_image: TextureRect = $Back

const HOVER_SCALE := Vector2(0.48, 0.48)
const HOVER_OFFSET := Vector2(0, -20)
const NORMAL_SCALE := Vector2(0.4, 0.4)
const NORMAL_OFFSET := Vector2(0, 0)
const HOVER_OFFSET_Y := -20

# Store original position to restore accurately
var original_position := Vector2.ZERO

func _ready():
	update_texture()
	card_image.connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	card_image.connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func set_face_up(show_face: bool):
	face_up = show_face
	if is_instance_valid(card_image):
		card_image.visible = show_face
	if is_instance_valid(back_image):
		back_image.visible = not show_face
	update_texture()

func update_texture():
	if not face_up:
		if back_image:
			back_image.texture = preload("res://assets/images/backgrounds/background-1.jpg")
		if card_image:
			card_image.texture = null
		return

	var filename = "%s_%s.png" % [value, suit]
	var path = "res://assets/images/cards_pixel/" + filename
	var texture = load(path)

	if card_image:
		card_image.texture = texture
	if back_image:
		back_image.texture = null

# --- Hover FX ---
func _on_mouse_entered():
	var parent = get_parent()
	if parent and parent.has_method("is_card_in_player_hand") and parent.is_card_in_player_hand(self):
		original_position = position
		var tex_size = card_image.texture.get_size() if card_image.texture else Vector2.ZERO
		scale = HOVER_SCALE
		position = original_position + Vector2((NORMAL_SCALE.x - HOVER_SCALE.x) * 0.5 * tex_size.x, HOVER_OFFSET.y)
		z_index = 1

func _on_mouse_exited():
	var parent = get_parent()
	if parent and parent.has_method("is_card_in_player_hand") and parent.is_card_in_player_hand(self):
		scale = NORMAL_SCALE
		position = original_position
		z_index = 0
