extends Character
class_name FightingAI

# AI States
class AIState:
	func act(ai: FightingAI, delta: float): pass
	func get_movement_input(ai: FightingAI) -> float: return 0.0
	func get_jump_input(ai: FightingAI) -> bool: return false
	func get_dash_input(ai: FightingAI) -> bool: return false
	func get_light_input(ai: FightingAI) -> bool: return false
	func get_heavy_input(ai: FightingAI) -> bool: return false

class IdleState extends AIState:
	func act(ai: FightingAI, delta: float):
		var player = ai.get_player()
		if not player:
			return
			
		var distance = ai.global_position.distance_to(player.global_position)
		if distance <= ai.chase_range:
			ai.change_state(ai.chase_state)

class ChaseState extends AIState:
	func act(ai: FightingAI, delta: float):
		var player = ai.get_player()
		if not player:
			ai.change_state(ai.idle_state)
			return
			
		var distance = ai.global_position.distance_to(player.global_position)
		
		if distance > ai.chase_range:
			ai.change_state(ai.idle_state)
		elif distance <= ai.attack_range:
			ai.change_state(ai.attack_state)
	
	func get_movement_input(ai: FightingAI) -> float:
		var player = ai.get_player()
		if not player:
			return 0.0
		return sign(player.global_position.x - ai.global_position.x)
	
	func get_jump_input(ai: FightingAI) -> bool:
		var player = ai.get_player()
		if not player:
			return false
		# Jump if player is significantly higher
		return player.global_position.y < ai.global_position.y - ai.jump_threshold

class AttackState extends AIState:
	var attack_timer: float = 0.0
	
	func act(ai: FightingAI, delta: float):
		var player = ai.get_player()
		if not player:
			ai.change_state(ai.idle_state)
			return
			
		var distance = ai.global_position.distance_to(player.global_position)
		
		if distance > ai.attack_range:
			ai.change_state(ai.chase_state)
			return
			
		attack_timer += delta
		if attack_timer >= ai.attack_cooldown:
			attack_timer = 0.0
			ai.change_state(ai.retreat_state)
	
	func get_movement_input(ai: FightingAI) -> float:
		var player = ai.get_player()
		if not player:
			return 0.0
		# Stay close to player for attacking
		var direction = sign(player.global_position.x - ai.global_position.x)
		var distance = ai.global_position.distance_to(player.global_position)
		if distance < ai.optimal_attack_distance:
			return -direction * 0.5  # Back away slightly
		return direction
	
	func get_light_input(ai: FightingAI) -> bool:
		return attack_timer >= ai.attack_cooldown * 0.5
	
	func get_heavy_input(ai: FightingAI) -> bool:
		return randf() < ai.heavy_attack_chance and attack_timer >= ai.attack_cooldown * 0.7

class RetreatState extends AIState:
	var retreat_timer: float = 0.0
	
	func act(ai: FightingAI, delta: float):
		retreat_timer += delta
		if retreat_timer >= ai.retreat_duration:
			retreat_timer = 0.0
			ai.change_state(ai.chase_state)
	
	func get_movement_input(ai: FightingAI) -> float:
		var player = ai.get_player()
		if not player:
			return 0.0
		# Move away from player
		return -sign(player.global_position.x - ai.global_position.x)
	
	func get_dash_input(ai: FightingAI) -> bool:
		return retreat_timer < ai.retreat_duration * 0.3  # Dash early in retreat

# AI Configuration
@export_group("AI Behavior")
@export var chase_range: float = 400.0
@export var attack_range: float = 120.0
@export var optimal_attack_distance: float = 80.0
@export var jump_threshold: float = 50.0
@export var attack_cooldown: float = 1.5
@export var retreat_duration: float = 0.8
@export var heavy_attack_chance: float = 0.3

# State instances
var idle_state = IdleState.new()
var chase_state = ChaseState.new()
var attack_state = AttackState.new()
var retreat_state = RetreatState.new()

# Current state
var current_state: AIState
var update_timer: float = 0.0
var update_frequency: float = 0.1  # Update AI logic 10 times per second

func _ready():
	super._ready()
	current_state = idle_state

func _physics_process(delta):
	super._physics_process(delta)
	
	# Update AI logic at fixed intervals for performance
	update_timer += delta
	if update_timer >= update_frequency:
		current_state.act(self, delta)
		update_timer = 0.0

# State management
func change_state(new_state: AIState):
	current_state = new_state

# Override character input methods
func get_movement_input() -> float:
	return current_state.get_movement_input(self)

func get_jump_input() -> bool:
	return current_state.get_jump_input(self)

func get_dash_input() -> bool:
	return current_state.get_dash_input(self)

func get_light_input() -> bool:
	return current_state.get_light_input(self)

func get_heavy_input() -> bool:
	return current_state.get_heavy_input(self)

# Utility functions
func get_player() -> Node:
	var players = get_tree().get_nodes_in_group("Players")
	return players[0] if players.size() > 0 else null

func get_state_name() -> String:
	if current_state == idle_state:
		return "Idle"
	elif current_state == chase_state:
		return "Chase"
	elif current_state == attack_state:
		return "Attack"
	elif current_state == retreat_state:
		return "Retreat"
	return "Unknown"
