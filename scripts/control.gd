extends Control
class_name HealthBarUI

# Health bar constants
const MAX_HEALTH: float = 100.0

# Player references
@export var player1: CharacterBody2D = null
@export var player2: CharacterBody2D = null

# UI Node references
@onready var player1_health_bar: ProgressBar = $HBoxContainer/Player1HealthBar
@onready var player2_health_bar: ProgressBar = $HBoxContainer/Player2HealthBar


# Health tracking
var player1_health: float = MAX_HEALTH
var player2_health: float = MAX_HEALTH

func _ready():
	# Set up health bars
	player1_health_bar.max_value = MAX_HEALTH
	player2_health_bar.max_value = MAX_HEALTH
	player1_health_bar.value = MAX_HEALTH
	player2_health_bar.value = MAX_HEALTH

func _process(delta):
	update_health_bars()

func update_health_bars():
	# Update Player 1 health
	if player1 and player1.has_method("get_health"):
		var new_health = player1.get_health()
		if new_health != player1_health:
			player1_health = new_health
			player1_health_bar.value = player1_health
			update_health_bar_color(player1_health_bar)
	
	# Update Player 2 health
	if player2 and player2.has_method("get_health"):
		var new_health = player2.get_health()
		if new_health != player2_health:
			player2_health = new_health
			player2_health_bar.value = player2_health
			update_health_bar_color(player2_health_bar)

func update_health_bar_color(health_bar: ProgressBar):
	var health_percent = health_bar.value / MAX_HEALTH
	
	if health_percent > 0.5:
		health_bar.modulate = Color.GREEN
	elif health_percent > 0.25:
		health_bar.modulate = Color.ORANGE
	else:
		health_bar.modulate = Color.RED

# Public methods
func set_player1_health(health: float):
	player1_health = health
	player1_health_bar.value = health
	update_health_bar_color(player1_health_bar)

func set_player2_health(health: float):
	player2_health = health
	player2_health_bar.value = health
	update_health_bar_color(player2_health_bar)
