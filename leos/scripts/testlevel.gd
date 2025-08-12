extends Node2D
class_name GameManager

@onready var death_menu = $Control2

func _ready():
	# Connect to all players in the Players group
	_connect_to_players()

func _connect_to_players():
	# Wait one frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Find all players and connect to their death signals
	var players = get_tree().get_nodes_in_group("Players")
	for player in players:
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
			print("Connected to player: ", player.name)
		else:
			print("Warning: Player ", player.name, " doesn't have player_died signal")

func _on_player_died(player: Node):
	print("Player died: ", player.name)
	death_menu.show_death_menu()
