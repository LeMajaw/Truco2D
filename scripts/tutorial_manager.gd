extends Node

# Tutorial and Help System for Truco Paulista
# Provides in-game tutorials, tooltips, and help for new players

signal tutorial_completed
signal tutorial_step_changed(step)

# Tutorial state
var tutorial_active = false
var current_step = 0
var tutorial_completed_before = false

# Tutorial steps
var tutorial_steps = [
	{
		"title": "Welcome to Truco Paulista!",
		"description": "This tutorial will teach you the basics of playing Truco. Let's get started!",
		"action": "continue",
		"highlight": null
	},
	{
		"title": "The Goal",
		"description": "The goal of Truco is to win rounds by playing cards of higher value than your opponents. The first team to reach 12 points wins the game.",
		"action": "continue",
		"highlight": null
	},
	{
		"title": "Card Values",
		"description": "Cards are ranked from strongest to weakest: 3, 2, A, K, J, Q, 7, 6, 5, 4. The suit order (strongest to weakest) is: clubs, hearts, spades, diamonds.",
		"action": "continue",
		"highlight": null
	},
	{
		"title": "The Manilha",
		"description": "The card turned face up (vira) determines the manilha, which is the next card in sequence. Manilhas are the strongest cards in the game.",
		"action": "continue",
		"highlight": "vira_card"
	},
	{
		"title": "Playing Cards",
		"description": "Click on a card in your hand to play it. Try to win the round by playing cards of higher value than your opponents.",
		"action": "play_card",
		"highlight": "player_hand"
	},
	{
		"title": "Truco Call",
		"description": "Click the TRUCO button to increase the round value to 3 points. Your opponents can accept, decline, or raise the stakes even higher!",
		"action": "call_truco",
		"highlight": "truco_button"
	},
	{
		"title": "Truco Escalation",
		"description": "After TRUCO (3 points), you can raise to SEIS (6 points), NOVE (9 points), and finally DOZE (12 points).",
		"action": "continue",
		"highlight": "truco_button"
	},
	{
		"title": "Winning Rounds",
		"description": "Win 2 out of 3 turns to win the round. The first team to reach 12 points wins the game!",
		"action": "continue",
		"highlight": "score_label"
	},
	{
		"title": "You're Ready!",
		"description": "You now know the basics of Truco Paulista. Good luck and have fun!",
		"action": "finish",
		"highlight": null
	}
]

# Tooltip information for UI elements
var tooltips = {
	"truco_button": "Call TRUCO to raise the stakes! The round will be worth 3 points instead of 1.",
	"score_label": "Current score. First team to reach 12 points wins the game.",
	"vira_card": "The vira card determines the manilha (strongest cards).",
	"turn_indicators": "Shows which team won each turn. Green = your team, Red = opponent team, Yellow = draw.",
	"player_hand": "Your cards. Click to play a card.",
	"settings_button": "Access game settings including volume and fullscreen options.",
	"menu_button": "Return to the main menu.",
	"restart_button": "Restart the current game."
}

# Configuration
var config_path = "user://player_settings.cfg"

func _ready():
	# Load tutorial state
	load_tutorial_state()

	# Check if first time playing
	if !tutorial_completed_before:
		# Show tutorial option on first launch
		call_deferred("offer_tutorial")

func load_tutorial_state():
	var config = ConfigFile.new()
	var err = config.load(config_path)

	if err == OK:
		tutorial_completed_before = config.get_value("tutorial", "completed", false)

func save_tutorial_state():
	var config = ConfigFile.new()
	config.load(config_path) # Load existing config if any

	config.set_value("tutorial", "completed", true)
	config.save(config_path)

func offer_tutorial():
	# Create tutorial offer dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Welcome to Truco Paulista!"
	dialog.dialog_text = "Would you like to play the tutorial to learn the basics of the game?"
	dialog.add_button("Skip Tutorial", true, "skip_tutorial")
	dialog.get_ok_button().text = "Play Tutorial"

	# Connect signals
	dialog.confirmed.connect(start_tutorial)
	dialog.custom_action.connect(func(action): dialog.queue_free())

	# Add to scene and show
	get_tree().get_root().add_child(dialog)
	dialog.popup_centered()

func start_tutorial():
	tutorial_active = true
	current_step = 0
	show_tutorial_step(current_step)

func show_tutorial_step(step_index):
	if step_index >= tutorial_steps.size():
		end_tutorial()
		return

	var step = tutorial_steps[step_index]

	# Create tutorial panel
	var panel = Panel.new()
	panel.name = "TutorialPanel"
	panel.size = Vector2(500, 200)
	panel.position = Vector2(get_viewport().size.x / 2 - 250, get_viewport().size.y - 250)

	# Add title
	var title = Label.new()
	title.text = step["title"]
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0))
	panel.add_child(title)

	# Add description
	var description = Label.new()
	description.text = step["description"]
	description.position = Vector2(20, 60)
	description.size = Vector2(460, 80)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(description)

	# Add continue button
	var button = Button.new()
	button.text = "Continue"
	if step["action"] == "finish":
		button.text = "Finish Tutorial"

	button.position = Vector2(350, 150)
	button.size = Vector2(120, 40)
	button.pressed.connect(func(): advance_tutorial())
	panel.add_child(button)

	# Add to scene
	get_tree().get_root().add_child(panel)

	# Highlight relevant UI element if specified
	if step["highlight"]:
		highlight_element(step["highlight"])

	# Emit signal
	tutorial_step_changed.emit(step_index)

func advance_tutorial():
	# Remove current tutorial panel
	var panel = get_tree().get_root().get_node_or_null("TutorialPanel")
	if panel:
		panel.queue_free()

	# Remove any highlights
	remove_highlights()

	# Move to next step
	current_step += 1
	show_tutorial_step(current_step)

func end_tutorial():
	tutorial_active = false
	remove_highlights()

	# Mark tutorial as completed
	tutorial_completed_before = true
	save_tutorial_state()

	# Emit signal
	tutorial_completed.emit()

func highlight_element(element_name):
	# Find the element to highlight
	var target = null

	match element_name:
		"truco_button":
			target = get_tree().get_first_node_in_group("truco_button")
		"score_label":
			target = get_tree().get_first_node_in_group("score_label")
		"vira_card":
			var game_manager = get_tree().get_first_node_in_group("game_manager")
			if game_manager:
				target = game_manager.vira_card_node
		"player_hand":
			var game_manager = get_tree().get_first_node_in_group("game_manager")
			if game_manager and game_manager.player_hand_cards.size() > 0:
				target = game_manager.player_hand_cards[0]
		"turn_indicators":
			var score_label = get_tree().get_first_node_in_group("score_label")
			if score_label:
				target = score_label.get_parent().get_node("TurnIndicators")

	if target:
		# Create highlight effect
		var highlight = ColorRect.new()
		highlight.name = "ElementHighlight"
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Position and size based on target
		var global_rect = Rect2(target.global_position, target.size * target.scale)
		highlight.position = global_rect.position - Vector2(10, 10)
		highlight.size = global_rect.size + Vector2(20, 20)

		# Style
		highlight.color = Color(1, 0.8, 0, 0.3)

		# Add to scene
		get_tree().get_root().add_child(highlight)

		# Add animation
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(highlight, "color", Color(1, 0.8, 0, 0.5), 0.5)
		tween.tween_property(highlight, "color", Color(1, 0.8, 0, 0.3), 0.5)

func remove_highlights():
	var highlight = get_tree().get_root().get_node_or_null("ElementHighlight")
	if highlight:
		highlight.queue_free()

# Show tooltip for a specific UI element
func show_tooltip(element_name, position):
	if !tooltips.has(element_name):
		return

	# Create tooltip
	var tooltip = Panel.new()
	tooltip.name = "Tooltip"
	tooltip.position = position

	# Add text
	var label = Label.new()
	label.text = tooltips[element_name]
	label.position = Vector2(10, 10)
	label.size = Vector2(200, 60)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip.add_child(label)

	# Adjust tooltip size based on text
	tooltip.size = label.size + Vector2(20, 20)

	# Add to scene
	get_tree().get_root().add_child(tooltip)

	# Auto-hide after delay
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(func(): hide_tooltip())
	tooltip.add_child(timer)
	timer.start()

func hide_tooltip():
	var tooltip = get_tree().get_root().get_node_or_null("Tooltip")
	if tooltip:
		tooltip.queue_free()

# Show help screen with game rules and controls
func show_help_screen():
	# Create help panel
	var panel = Panel.new()
	panel.name = "HelpPanel"
	panel.size = Vector2(800, 500)
	panel.position = Vector2(get_viewport().size.x / 2 - 400, get_viewport().size.y / 2 - 250)

	# Add title
	var title = Label.new()
	title.text = "Truco Paulista - Game Rules"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0))
	panel.add_child(title)

	# Add scrollable content
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 70)
	scroll.size = Vector2(760, 370)
	panel.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	# Add rule sections
	add_rule_section(content, "Game Objective",
		"The goal of Truco is to be the first team to reach 12 points by winning rounds. " +
		"Each round consists of up to 3 turns, and the team that wins 2 turns wins the round.")

	add_rule_section(content, "Card Values",
		"Cards are ranked from strongest to weakest: 3, 2, A, K, J, Q, 7, 6, 5, 4.\n" +
		"The suit order (strongest to weakest) is: clubs, hearts, spades, diamonds.")

	add_rule_section(content, "Manilha",
		"The card turned face up (vira) determines the manilha, which is the next card in sequence. " +
		"For example, if the vira is a 7, then all 6s become manilhas. " +
		"Manilhas are the strongest cards in the game, ranked by suit.")

	add_rule_section(content, "Truco Call",
		"Any player can call 'Truco' to raise the round value to 3 points. " +
		"The opposing team can accept, decline, or raise to 6 points ('Seis'). " +
		"This can continue to 9 points ('Nove') and finally 12 points ('Doze').\n\n" +
		"If a team declines, the calling team wins the round with the previous point value.")

	add_rule_section(content, "Controls",
		"- Click on cards to play them\n" +
		"- Click the TRUCO button to call truco\n" +
		"- Use the Accept/Decline/Raise buttons to respond to truco calls\n" +
		"- Press Alt+Enter or F11 to toggle fullscreen\n" +
		"- Press T to call truco (keyboard shortcut)")

	# Add close button
	var button = Button.new()
	button.text = "Close"
	button.position = Vector2(350, 450)
	button.size = Vector2(100, 40)
	button.pressed.connect(func(): panel.queue_free())
	panel.add_child(button)

	# Add to scene
	get_tree().get_root().add_child(panel)

func add_rule_section(parent, title, text):
	var section = VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(section)

	var section_title = Label.new()
	section_title.text = title
	section_title.add_theme_font_size_override("font_size", 20)
	section_title.add_theme_color_override("font_color", Color(0.9, 0.7, 0))
	section.add_child(section_title)

	var section_text = Label.new()
	section_text.text = text
	section_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_child(section_text)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	section.add_child(spacer)

# Check if tutorial is active
func is_tutorial_active():
	return tutorial_active

# Get current tutorial step
func get_current_tutorial_step():
	return current_step
