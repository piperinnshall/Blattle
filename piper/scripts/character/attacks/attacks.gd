extends Area2D
class_name Attacks

@export var damage: int = 1

signal hitbox_expired

func _ready():
	monitoring = true

func _on_life_span_timeout() -> void:
	emit_signal("hitbox_expired")
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
