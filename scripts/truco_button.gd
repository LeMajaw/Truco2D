extends Button

var pulse_tween: Tween
var is_pulsing := false

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	start_pulse_animation()

func _on_mouse_entered():
	if not disabled:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
		
func _on_mouse_exited():
	if not disabled:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func start_pulse_animation():
	if is_pulsing or disabled:
		return
		
	is_pulsing = true
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	
	# Pulse effect
	pulse_tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.2, 1), 0.8)
	pulse_tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.8)
	
	# Label effect
	pulse_tween.parallel().tween_property($Label, "theme_override_colors/font_color", Color(1, 1, 0.3, 1), 0.8)
	pulse_tween.parallel().tween_property($Label, "theme_override_colors/font_color", Color(1, 0.8, 0, 1), 0.8)

func stop_pulse_animation():
	is_pulsing = false
	if pulse_tween:
		pulse_tween.kill()
	modulate = Color(0.7, 0.7, 0.7, 0.7) if disabled else Color(1, 1, 1, 1)

func _process(delta):
	if disabled and is_pulsing:
		stop_pulse_animation()
	elif not disabled and not is_pulsing:
		start_pulse_animation()
