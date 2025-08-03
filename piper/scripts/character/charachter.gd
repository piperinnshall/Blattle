extends CharacterBody2D
class_name Character

@export_group("Properties")

@export_subgroup("Move")
@export var move_speed: float = 0.0
@export var gravity: float = 0.0
@export_subgroup("Jump")

@export var jump_force: float = 0.0
@export var max_jumps: int = 2
@export var coyote_time: float = 0.15

func _physics_process(delta: float) -> void:
	pass
