extends Area2D
class_name Attack

@export var damage: int = 1

func _ready():
	monitoring = true

func _on_life_span_timeout() -> void:
	pass
