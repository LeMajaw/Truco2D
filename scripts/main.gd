extends Node2D

@onready var game_manager = $GameManager

var player_order := ["player", "bot1", "bot2", "bot3"]
var pe_index := 0
var current_turn_index := 0

func _ready():
	game_manager._ready()
